/**
 * Triangle-cut of pie (triangle side calculator).
 * 
 * Calculates cache for 50 values of 0-5% (with 0.1 step)
 */

/**
 * Calculate smaller side of triangle.
 * 
 * Assumes:
 * h = 100% => alfa = 45deg => v = 12.5%
 * 
 * @param {Number} v Percantage of the circle.
 * @returns Height in percantage (for clip-path).
 */
function cutHeight(v) {
    const x = (90 * v) / 25;
    const angleRadians = mathRadians(x);
    const tgValue = Math.tan(angleRadians);
    const proc = tgValue * 100;
    return proc;
}

/** Convert degrees to radians. */
function mathRadians (degrees) {
    return degrees * (Math.PI / 180);
};

function calculateValues() {
	let values = [];
    for (let i = 1; i <= 50; i ++) {
		let v = 0.1 * i;
        const h = cutHeight(v);
        values.push({v, h});
    }
	return values
}

function formatNumber(value, precision) {
	const formattedValue = value.toFixed(precision);
	return formattedValue;
}

// Calling the function to calculate and print values
var values = calculateValues();
/*
console.log(values
	.map(r => `v=${formatNumber(r.v, 1)}%: h=${formatNumber(r.h, 8)}%`)
	.join('\n')
);
*/
// for lua-json
console.log(JSON.stringify(values
	.map(r => formatNumber(r.h, 8))
, null, '\t'));

