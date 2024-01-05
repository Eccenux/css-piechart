/**
 * Vega to timeline (bar chart).
 * 
 * graph: type=rect (Vega)
 * Wykres demograficzny (timeline).
 */
y=[34849, 23930, 25008, 29776, 32642, 35061, 37879, 38183, 38610, 38654, 38191, 38167.329, 38529.866, 38538.447, 38496, 38446, 38434, 38383, 37778 ]
rok=[1938, 1946, 1950, 1960, 1970, 1978, 1988, 1990, 1995, 2000, 2005, 2009, 2010, 2011, 2013, 2015, 2017, 2019, 2022]

var line = (i,rok,y)=>`\n |rok${i+1}=${rok[i]} ||pop${i+1}=${y[i]}`
var sz = `{{Wykres demograficzny
 |tytuł= 
 |szerokość= 
 |wysokość= `
;
for (var i=0; i<rok.length; i++) {
  sz+=line(i,rok,y);
}
sz+=`
 |źródło= 
}}`
console.log(sz);
