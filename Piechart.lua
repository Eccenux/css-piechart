local p = {}
--[[
	Debug:
	
	-- labels and auto-value
	local json_data = '[{"label": "k: $v", "value": 33.1}, {"label": "m: $v", "value": -1}]'
	local html = p.renderPie(json_data)
	mw.logObject(html)
	
	-- autoscale values
	local json_data = '[{"value": 700}, {"value": 300}]'
	local html = p.renderPie(json_data, options)
	mw.logObject(html)	
	
	-- size option
	local json_data = '[{"label": "k: $v", "value": 33.1}, {"label": "m: $v", "value": -1}]'
	local options = '{"size":200}'
	local html = p.renderPie(json_data, options)
	mw.logObject(html)	

	-- custom colors
	local json_data = '[{"label": "k: $v", "value": 33.1, "color":"black"}, {"label": "m: $v", "value": -1, "color":"green"}]'
	local html = p.renderPie(json_data)
	mw.logObject(html)
	
	-- 4-cuts
	local entries = {
	    '{"label": "ciastka: $v", "value": 2, "color":"goldenrod"}',
	    '{"label": "słodycze: $v", "value": 4, "color":"darkred"}',
	    '{"label": "napoje: $v", "value": 1, "color":"lightblue"}',
	    '{"label": "kanapki: $v", "value": 3, "color":"wheat"}'
	}
	local json_data = '['..table.concat(entries, ',')..']'
	local html = p.renderPie(json_data, '{"autoscale":true}')
	mw.logObject(html)
]]

--[[
	Piechart.
	
	{{{1}}}:
	[
        { "label": "k: $v", "value": 33.1  },
        { "label": "m: $v", "value": -1  },
    ]
    where $v is a formatted label

    TODO:
    - [x] basic 2-element pie chart
        - read json
        - calculate value with -1
        - generate html
        - new css + tests
        - provide dumb labels (just v%)
    - [x] colors in json
    - [x] 1st value >= 50%
    - [x] custom labels support
    - [x] pie size from 'meta' param (options json)
    - [x] pl formatting for numbers?
    - [x] support undefined value (instead of -1)
    - [x] undefined in any order
    - [x] scale values to 100% (autoscale)
    - [x] order values clockwise (not left/right)
    - [x] multi-cut pie
    - [x] sanitize user values
    - [x] auto colors
    - function to get color by number (for custom legend)
    - generate a legend
    	- (?) $info: $values.join(separator)
    	- (?) or a list with css formatting (that could be overriden)
    - (?) option to sort entries by value
]] 
function p.pie(frame)
	local json_data = trim(frame.args[1])
	local options = nil
	if (frame.args.meta) then
		options = trim(frame.args.meta)
	end
	
	local html = p.renderPie(json_data, options)
	return trim(html)
end

--[[
	Render piechart.
	
	@param json_data JSON string with pie data.
]]
function p.renderPie(json_data, json_options)
	local data = mw.text.jsonDecode(json_data)
	local options = nil
	if json_options then
		options = mw.text.jsonDecode(json_options)
	end
	local size = options and type(options.size) == "number" and math.floor(options.size) or 100 -- circle size in [px]
	local autoscale = options and options.autoscale or false -- autoscale values

	-- Move the last element to the first position
	local lastEntry = table.remove(data)
	table.insert(data, 1, lastEntry)

	local html = ""
	local sum = sumValues(data);
	-- force autoscale when over 100
	if (sum > 100) then
		autoscale = true
	end
	local first = true
	local previous = 0
	local totalCount = #data
	for index, entry in ipairs(data) do
	    local html_slice, value = renderSlice(entry, previous, sum, size, index, autoscale, totalCount)
	    html = html .. html_slice
	    if not first then
	    	previous = previous + value
	    end
	    first = false
	end
	html = html .. '\n</div>'

	return html
end

function sumValues(data)
	local sum = 0;
	for _, entry in ipairs(data) do
		local value = entry.value
		if not (type(value) ~= "number" or value < 0) then
		    sum = sum + value
		end
	end
	return sum
end

--[[
	Render a single slice.
	
	@param entry Current entry.
	@param sum Sum of all entries.
]]
function renderSlice(entry, previous, sum, size, index, autoscale, totalCount)
	local value, label, bcolor = genSlice(entry, sum, index, autoscale, totalCount)
	local html = ""
	if (index==1) then
		html = renderFinal(label, bcolor, size)
	else
		html = renderOther(value, previous, label, bcolor, size)
	end
	return html, value
end
-- Prepare single slice data.
function genSlice(entry, sum, index, autoscale, totalCount)
	local value = entry.value
	if (type(value) ~= "number" or value < 0) then
		if autoscale then
			return "<!-- cannot autoscale unknown value -->"
		end
        value = 100 - sum
	end
	if autoscale then
        value = (value / sum) * 100
	end

	local label = formatValue(entry.label, value)
	local bcolor = backColor(entry, index, totalCount)
	
	return value, label, bcolor
end
-- final, but header...
function renderFinal(label, bcolor, size)
	local html =  ""
	local style = 'width:'..size..'px; height:'..size..'px;'..bcolor
	html = [[
<div class="smooth-pie"
     style="]]..style..[["
     title="]]..label..[["
>]]
	return html
end
-- any other then final
function renderOther(value, previous, label, bcolor, size)
	local html =  ""
	
	local trans = string.format("translatex(%.0fpx)", size/2)
	local maskStyle = getMaskStyle(previous)
	if (value < 50) then
		local rotate = string.format("rotate(-%.3fturn)", value/100)
		local transform = 'transform: scale(-1, 1) ' .. rotate .. ' ' .. trans ..';'
		html = html .. '\n\t<div class="piemask" '..maskStyle..'><div class="slice" style="'..transform..' '..bcolor..'" title="'..label..'"></div></div>'
	else
		-- 50%
		html = html .. '\n\t<div class="piemask" '..maskStyle..'><div class="slice" style="'..bcolor..'" title="'..label..'"></div></div>'
		-- value overflowing 50% (extra slice)
		if (value > 50) then
			maskStyle = getMaskStyle(previous + 50)
			local rotate = string.format("rotate(-%.3fturn)", (value-50)/100)
			local transform = 'transform: scale(-1, 1) ' .. rotate .. ' ' .. trans ..';'
			html = html .. '\n\t<div class="piemask" '..maskStyle..'><div class="slice" style="'..transform..' '..bcolor..'" title="'..label..'"></div></div>'
		end
	end
	
	return html
end
-- style of a mask (rotate into place)
function getMaskStyle(previous)
	if (previous>0) then
		local maskRotate = string.format("rotate(%.3fturn)", previous/100)
		local maskStyle = 'style="transform: '..maskRotate..';"'
		return maskStyle
	end
	return ''
end

function formatNum(value)
	local lang = mw.language.getContentLanguage()
	
	-- doesn't do precision :(
	-- local v = lang:formatNum(value)
	
	local v = string.format("%.1f", value)
	if (lang:getCode() == 'pl') then
		v = v:gsub("%.", ",")
	end
	return v
end

function formatValue(label, value)
	local v = formatNum(value)
	local l = "" 
	if label then
		l = label:gsub("%$v", v..'%%')
	else
		l = v .. "%"
	end
	return l
end

-- default colors
local colorPalette = {
    '#005744',
    '#006c52',
    '#00814e',
    '#009649',
    '#00ab45',
    '#00c140',
    '#00d93b',
    '#00f038',
}
local lastColor = '#cdf099'
function backColor(entry, no, totalCount)
    if (type(entry.color) == "string") then
    	-- Remove unsafe characters from entry.color
    	local sanitizedColor = entry.color:gsub("[^a-zA-Z0-9#%-]", "")
        return 'background-color: ' .. sanitizedColor
    else
    	local color = lastColor
    	if (no > 1) then 
			local cIndex = (no - 1) % #colorPalette + 1
			color = colorPalette[cIndex]
    	end
    	mw.log(no, color)
        return 'background-color: ' .. color
    end
end

--[[
	trim string
	
	note:
	`(s:gsub(...))` returns only a string
	`s:gsub(...)` returns a string and a number
]]
function trim(s)
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

return p
