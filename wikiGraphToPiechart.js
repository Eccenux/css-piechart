/**
 * Replace function for pie-graphs.
 * 
 * x = label list
 * y1 = value list
 * 
 * plwiki: \{\{Wykres\s*\|[^}]+\}\}
 * @param {String} all 
 */
function (all) {
	all = all.replace(/\|\s+/g, '|')

	// Extracting values of x and y1
	const xMatches = all.match(/\|x *=([^|}]+)/);
	const y1Matches = all.match(/\|y1 *=([^|}]+)/);

	// Checking if matches are found
	if (!xMatches || !y1Matches) {
		console.log("Unable to find x or y1 values in the input text.");
		return all
	}

	// Splitting values by comma
	const labels = xMatches[1].split(',').map(value => value.trim());
	const values = y1Matches[1].split(',').map(value => parseInt(value.trim(), 10));

	// color palette for the pie
	const colorPalette = ["#ff5733", "#33ff57", "#5733ff", "#ffff33"];

	// Generating the array
	const pie = [];

	for (let i = 0; i < labels.length; i++) {
		const item = {
			"label": labels[i] + ': $v',
			"value": values[i],
			//"color": colorPalette[i % colorPalette.length]
		};
		pie.push(item);
	}

	return all + '\n\n{{Piechart|\n' + JSON.stringify(pie).replace(/},{/g, '}\n,{').replace(/}]/g, '}\n]\n|meta={"size":300}\n}}');
}