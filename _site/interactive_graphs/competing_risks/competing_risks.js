// JavaScript Document

// Create sliders
Sliders = []
DrawSlider({DivName: "Lambda1",Xmin:0, Xmax:0.2, Ticks:4,InitVal:0.05})
//DrawSlider({DivName: "Gamma1", Xmin:0.1, Xmax:2})
DrawSlider({DivName: "HR1", Xmin:0.5, Xmax:5})

DrawSlider({DivName: "Lambda2", Xmin:0.0, Xmax:0.2, Ticks:4,InitVal:0.05})
//DrawSlider({DivName: "Gamma2", Xmin:0.1, Xmax:2})
DrawSlider({DivName: "HR2", Xmin:0.5, Xmax:5})
UpdateParameters()

function UpdateParameters() {
	lambda1 = Sliders["Lambda1"].CurrentValue
	lambda2 = Sliders["Lambda2"].CurrentValue
//	gamma1 = Sliders["Gamma1"].CurrentValue
//	gamma2 = Sliders["Gamma2"].CurrentValue
	gamma1 = 1
	gamma2 = 1
	HR1 = Sliders["HR1"].CurrentValue
	HR2 = Sliders["HR2"].CurrentValue
}

// Margins and heights of graphs 
var margin = {top: 50, right: 20, bottom: 40, left: 50}
	, svgwidth = parseInt(d3.select('#cshazard').style('width'), 10)*0.98
	, svgheight = 0.8*svgwidth
	, graphwidth = svgwidth - margin.left - margin.right
	, graphheight = svgheight - margin.top - margin.bottom;

// Define time variable
time = []
N=1000
var maxtime = 10
for (var i=0;i<N;i++) {
		time[i] = i/(N-1)*((maxtime)-(0))+(0);
}
GenFunctions()

// Forms the total SVG and plot area for all 4 graphs
GraphNames = ["cshazard",	"cssurvival", "csCIF1", "csCIF2"]
PlotType = ["ht","St","csCIF1","csCIF2"]
PlotTitle = ["Cause-specific hazard"," 1 - Cause-specific survival","CIF for unexposed","CIF for exposed"]
Ylabel = ["h(t)","1 - S(t)","CIF(t)","CIF(t)"]
Cause = ["cancer","other"]
CauseColour = ["red","blue"]
Exposure = ["unexposed","exposed"]
ExpLineType = ["none","5,5"]
var SVG = []
var plot = []
for (var gindex in GraphNames) {
	SVG[GraphNames[gindex]] = d3.select("#"+GraphNames[gindex])
		.append("svg")
		.attr("width", svgwidth)
		.attr("height", svgheight)
		.attr('class', 'svg')
	plot[GraphNames[gindex]] = SVG[GraphNames[gindex]].append('g')
		.attr('transform', 'translate(' + margin.left + ',' + margin.top + ')')
		.attr('width', graphwidth)
		.attr('height', graphheight)
		.attr('class', 'plot')	
}

x = d3.scale.linear()
		.domain([0, maxtime])
		.range([ 0, graphwidth]);

ySt = d3.scale.linear()
		  .domain([0,1])
		  .range([ graphheight, 0 ]);

var linefunction = d3.svg.line()
	.x(function(d,i) {return x(time[i]);})
	.y(function(d) {return ySt(d);})
	.interpolate("linear")
	.defined(function(d,i) { if(isFinite(d)) {
								return 1}
							 else {
								return 0}})

var AreaFunction = d3.svg.area()
	.x(function(d,i) {return x(time[i]);})
	.y0(function(d) {return ySt(d[0]);})
	.y1(function(d) {return ySt(d[1]);})
	.interpolate("linear")
	.defined(function(d,i) { if(isFinite(d[0])) {
								return 1}
							 else {
								return 0}})	

// Plot axes that do not change
xAxis = d3.svg.axis().scale(x)
	.orient("bottom").ticks(5);
yAxis = d3.svg.axis().scale(ySt)
	.orient("left").ticks(5);
		
function make_x_axis() {        
   	return d3.svg.axis()
       	.scale(x)
       	.orient("bottom")
       	.ticks(10)
}

function make_y_axis() {        
   	return d3.svg.axis()
       	.scale(y)
       	.orient("left")
       	.ticks(5)
}

for (var gindex in GraphNames) {
// add xaxis		
// Add and draw the X Axis
	plot[GraphNames[gindex]].append("g")
		.attr("class", "x axis")
		.attr("transform", "translate(0," + graphheight + ")")
		.call(xAxis);
// Add and draw the Y Axis
	plot[GraphNames[gindex]].append("g")
		.attr("class", "y axis")
		.call(yAxis);

// Graph title
	plot[GraphNames[gindex]].append("text")
    	.attr("class", "GraphTitle")
    	.attr("text-anchor", "middle")
    	.attr("x", graphwidth/2)
    	.attr("y", 0)
    	.text(PlotTitle[gindex]);	

	
// axis titles		
	plot[GraphNames[gindex]].append("text")
    	.attr("class", "xlabel")
    	.attr("text-anchor", "middle")
    	.attr("x", graphwidth/2)
    	.attr("y", graphheight + margin.bottom)
    	.text("Years since diagnosis");	
	
	plot[GraphNames[gindex]].append("text")
    	.attr("class", "ylabel")
        .attr("transform", "rotate(-90)")
        .attr("y", 0-margin.left)
        .attr("x",0 - (graphheight / 2))
        .attr("dy", "1em")
        .style("text-anchor", "middle")
        .text(Ylabel[gindex]);					
}
			
UpdateGraph()

function UpdateGraph() {
	UpdateParameters()	
	GenFunctions();
	for (var gindex in GraphNames) {
		RemoveLines(gindex);
		PlotGraph(gindex);
	}	
}

function PlotGraph(gindex) {
// Line graphs
	if(gindex<=1) {
		for(var cindex in Cause) {
			var LineColour = CauseColour[cindex]
			for(var eindex in Exposure) {
				var LineType = ExpLineType[eindex]	
				var tmpy = Outcomes[gindex][Exposure[eindex]][Cause[cindex]]
					plot[GraphNames[gindex]].append("path")
						.attr("class","line")
						.attr("id",GraphNames[gindex]+Exposure[eindex]+Cause[cindex])
						.attr(	"d",linefunction(tmpy))
						.style("opacity",0.8)
						.style("stroke",LineColour)
						.style("stroke-dasharray",LineType)
			}
		}
	}
// Area Graphs
	else {
		var TmpExposure = [gindex-2]
		for(var cindex in Cause) {		
			var AreaData = []
			var LineColour = CauseColour[cindex]
			if(cindex==0) {
				zeros = Array.apply(0, Array(N)).map(function (x, y) { return 0; })
				AreaData =  d3.zip(Outcomes[gindex][Cause[0]],zeros)
			}
			else {	
				AreaData = d3.zip(Outcomes[gindex][Cause[0]],Outcomes[gindex].total)
			}
			plot[GraphNames[gindex]].append("path")
				.attr("class","area")
				.attr("id",GraphNames[gindex]+Exposure[TmpExposure]+Cause[cindex])
				.datum(AreaData)
				.attr("d",AreaFunction)
				.style("opacity",0.8)
				.style("stroke",LineColour)
				.style("fill",LineColour)
				.style("stroke-dasharray",LineType)	
		}
	}
}

function RemoveLines(gindex) {
	plot[GraphNames[gindex]].selectAll(".line").remove()
	plot[GraphNames[gindex]].selectAll(".area").remove()

};


function GenFunctions(){
	var St = []
	St.unexposed = []
	St.unexposed.cancer = []
	St.unexposed.other = []
	St.exposed = []
	St.exposed.cancer = []
	St.exposed.other = []
	var ht = []
	ht.unexposed = []
	ht.unexposed.cancer = []
	ht.unexposed.other = []
	ht.exposed = []
	ht.exposed.cancer = []
	ht.exposed.other = []
	var csCIF = []
	csCIF.unexposed = []
	csCIF.unexposed.cancer = []
	csCIF.unexposed.other = []
	csCIF.unexposed.total = []
	csCIF.exposed = []
	csCIF.exposed.cancer = []
	csCIF.exposed.other = []
	csCIF.exposed.total = []

	for (var i=0;i<N;i++) {
// Survival		
		St.unexposed.cancer[i] = Math.exp(-lambda1*Math.pow(time[i],gamma1))
		St.exposed.cancer[i] = Math.exp(-lambda1*HR1*Math.pow(time[i],gamma1))
		St.unexposed.other[i] = Math.exp(-lambda2*Math.pow(time[i],gamma2))
		St.exposed.other[i] = Math.exp(-lambda2*HR2*Math.pow(time[i],gamma2))
// Hazard function		
		ht.unexposed.cancer[i] = lambda1*gamma1*Math.pow(time[i],(gamma1-1))
		ht.exposed.cancer[i] = lambda1*HR1*gamma1*Math.pow(time[i],(gamma1-1))
		ht.unexposed.other[i] = lambda2*gamma2*Math.pow(time[i],(gamma2-1))
		ht.exposed.other[i] = lambda2*HR2*gamma2*Math.pow(time[i],(gamma2-1))
// CIF
		if(i==0) {
			csCIF.unexposed.cancer[i] = 0
			csCIF.exposed.cancer[i] = 0
			csCIF.unexposed.other[i] = 0
			csCIF.exposed.other[i] = 0
		}
		else {
			csCIF.unexposed.cancer[i] = csCIF.unexposed.cancer[i-1] + (time[i]-time[i-1])*ht.unexposed.cancer[i]*St.unexposed.cancer[i]*St.unexposed.other[i]
			csCIF.exposed.cancer[i] = csCIF.exposed.cancer[i-1] + (time[i]-time[i-1])*ht.exposed.cancer[i]*St.exposed.cancer[i]*St.exposed.other[i]
			csCIF.unexposed.other[i] = csCIF.unexposed.other[i-1] + (time[i]-time[i-1])*ht.unexposed.other[i]*St.unexposed.cancer[i]*St.unexposed.other[i]
			csCIF.exposed.other[i] = csCIF.exposed.other[i-1] + (time[i]-time[i-1])*ht.exposed.other[i]*St.exposed.cancer[i]*St.exposed.other[i]
		}
		csCIF.unexposed.total[i] = csCIF.unexposed.cancer[i] + csCIF.unexposed.other[i]
		csCIF.exposed.total[i] = csCIF.exposed.cancer[i] + csCIF.exposed.other[i]
		
// change to failure distribution
	St.unexposed.cancer[i]  = 1 - St.unexposed.cancer[i]		
	St.exposed.cancer[i]  = 1 - St.exposed.cancer[i]		
	St.unexposed.other[i]  = 1 - St.unexposed.other[i]		
	St.exposed.other[i]  = 1 - St.exposed.other[i]		
	}
	Outcomes = [ht,St,csCIF.unexposed,csCIF.exposed]
}
