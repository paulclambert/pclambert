// popmort.js
LoadData()
Data = []
function LoadData() {
	var q = d3.queue()
	q.defer(d3.json,"popmort.json");
	q.awaitAll(ProcessData) 
}

function ProcessData(error,FileResults) {
	if (error) throw error;	
	for(var prop in FileResults[0][0]) {
		Data[prop] = FileResults[0][0][prop];
	};	
// Now data is loaded and processed run graphs.
	RunGraphs()
}	

function RunGraphs() {
	margin = {top: 50, right: 20, bottom: 80, left: 80}
		, svgwidth = parseInt(d3.select('#Graph').style('width'), 10)*0.90
		, svgheight = 0.6*svgwidth
		, graphwidth = svgwidth - margin.left - margin.right
		, graphheight = svgheight - margin.top - margin.bottom;

	CurrentAge = 0;
	CurrentSex = "Male"
	SexList = ["Male","Female"]
	PlotVars = ["rate1M","rate2M","rate3M","rate4M","rate5M"]
	
	linefunction = d3.line()
		.x(function(d,i) {return x(ageplot[i]);})
		.y(function(d) {return y(d);})
		.curve(d3.curveLinear)
	var LineCols = d3.schemeCategory10
	LineColours = []
	
	var i = 0
	for(var name in Data) { 
		if(name != "age") {
			LineColours[name] = LineCols[i]
			i = i + 1
			if(i==5) i=0
		}
	}
	console.log(LineColours)
	Sliders=[]	
	InitialiseGraphs()
	AgeSlider({DivName: "AgeSliderDiv",Xmin:0, Xmax:90, Ticks:10,InitVal:CurrentAge})
	SexSelect();
	UpdateGraph()
	AddLegend()
	AddInfo()
	AgeProbText()
	PlotMouseOut()
	}

function InitialiseGraphs() {
	svg = d3.select("#Graph")
		.append("svg")
		.attr("width", svgwidth)
		.attr("height", svgheight)
		.attr('class', 'svg')
		.on("mousemove",PlotMouseOver)
		.on("mouseout",PlotMouseOut)
	// Defines the Plot area 
	plot = svg.append('g')
		.attr('transform', 'translate(' + margin.left + ',' + margin.top + ')')
		.attr('width', graphwidth)
		.attr('height', graphheight)
		.attr('class', 'plot')
}

function UpdateGraph() {
	UpdateAxes();
	GenSurvival();
	PlotLines();
	AgeText();
	UpdateTable()
}

function UpdateAxes() {
// this transforms the scale we want to plot on to.
	x = d3.scaleLinear()
		.domain([CurrentAge, 100])
		.range([ 0, graphwidth]);

	y = d3.scaleLinear()
		.domain([0, 100])
		.range([graphheight, 0]);
// Define the axes (do not get drawn here)
	plot.selectAll(".axis").remove();
	//plot.selectAll(".Graphgrid").remove();
	plot.selectAll(".xylabel").remove();
	xAxis = d3.axisBottom(x).ticks(5);
	yAxis = d3.axisLeft(y).ticks(5).tickFormat(function(d){return d+ "%"});

// add xaxis		
// Add and draw the X Axis

	plot.append("g")
		.attr("class", "x axis")
        .attr("transform", "translate(0," + graphheight + ")")
		.call(xAxis)

// Add and draw the Y Axis
	plot.append("g")
		.attr("class", "y axis")
		.call(yAxis)
	
// axis titles		
	plot.append("text")
    	.attr("class", "xylabel")
    	.attr("text-anchor", "middle")
    	.attr("x", graphwidth/2)
    	.attr("y", graphheight + margin.bottom*0.8)
        .style("stroke", "none")		
    	.text("Age");	
	
	plot.append("text")
    	.attr("class", "xylabel")
        .attr("transform", "rotate(-90)")
        .attr("y", 0-margin.left)
        .attr("x",0 - (graphheight / 2))
        .attr("dy", "1em")
        .style("text-anchor", "middle")
        .style("st	roke", "none")		
        .text("Percentage Alive")					
}

function GenSurvival(){
	ageplot = Data.age.slice(CurrentAge,Data.age.length)
	survplot = []
	for (var i = 0; i < PlotVars.length; i++) {
		var tmprate = Data[PlotVars[i]].slice(CurrentAge,Data.age.length)
		survplot[PlotVars[i]] = CumulativeSum(tmprate)
	}
}

function CumulativeSum(x) {
	var cumy = []
	var s = []
	cumy[0] = 0
	s[0] = Math.exp(-cumy)*100
	for(var i = 1;i<x.length;i++) {
		cumy[i] = x[i-1] + cumy[i-1];
		s[i] = Math.exp(-cumy[i])*100;
	};
	return s	
}	

function PlotLines() {
	RemoveLines();
	for (var i = 0; i < PlotVars.length; i++) {
		plot.append("path")
			.attr("class","line")
			.attr("id",PlotVars[i])
		.attr("d",linefunction(survplot[PlotVars[i]]))
		.style("stroke",LineColours[PlotVars[i]])
	}
//	d3.selectAll("path")
//		.on("mouseover",PathMouseOver)
//		.on("mouseout",PathMouseOut)	}	
}	

// remove lines from plot
function RemoveLines() {
	plot.selectAll("path.line").remove()
};

function AddInfo() {
	// Add information sign
	
	// alert("This is lots and lots of text")
}


function AgeText() {
	svg.selectAll(".agetext").remove()
	svg.append("text")
		.attr("class","agetext")
		.attr("x",svgwidth/2)
		.attr("y", (margin.top / 2))
		.style("font-size",30)
		.text("Age = " + CurrentAge + ", " + CurrentSex)
}

function AddLegend() {
// Rectangle
	plot.append("rect")
		.attr("class","LegendRect")
		.attr("x",(10))
		.attr("y",y(40))
		.attr("width",graphwidth*0.3)
		.attr("height",graphheight*0.35)

// Title
	var ystart = 30
	var ystep = 5
	plot.append("line")
		.attr("x1",10 + 10)
		.attr("x2",10 + 10 + graphwidth*0.25)
		.attr("y1", y(ystart + ystep*0.5))
		.attr("y2", y(ystart + ystep*0.5))
		.style("stroke","black")
		.style("stroke-width",2)

	plot.append("text")	
		.attr("x", 10 + graphwidth*0.08)
		.attr("class","LegendText")
		.attr("y", y(ystart	 + ystep))
			.attr("dy","0.35em")
			.attr("text-anchor", "start") 			
			.text("Deprivation Quintile")		
		
// Lines (clickable)?
	var legendtext = ["1: Least Deprived","2","3","4","5: Most Deprived"]
	for (var i = 0; i < PlotVars.length; i++) {
					
		plot.append("line")
			.attr("class","LegendLine")
			.attr("x1",10 + 10)
			.attr("x2",10 + 10 + graphwidth*0.05)
			.attr("y1", y(ystart - ystep*i))
			.attr("y2", y(ystart - ystep*i))
			.style("stroke",LineColours[PlotVars[i]])
			
		plot.append("text")	
			.attr("class","LegendText")
			.attr("x", 10 + graphwidth*0.08)
			.attr("y", y(ystart	 - ystep*i))
			.attr("dy","0.35em")
			.attr("text-anchor", "start") 			
			.text(legendtext[i])
			
	}
}

function SexSelect() {
var SexList = ["Males", "Females"] 
    var j = 0;  // Choose the males as default

// Create the shape selectors
var form = d3.select("#SexSelect").append("form");

labels = form.selectAll("label")
    .data(SexList)
    .enter()
    .append("label")
    .text(function(d) {return d;})
    .insert("input")
    .attr("type","radio")
    .attr("name","sexbutton")
	.attr("class","SexSelect")
	.attr("value", function(d, i) {return i;})
	.property("checked",function(d, i) {return i==0;})
    .on("change", ChangeSex);
}

function ChangeSex() {
	CurrentSex = SexList[this.value]
	OldPlotVars = PlotVars
	if(CurrentSex == "Male") {
		PlotVars = ["rate1M","rate2M","rate3M","rate4M","rate5M"]
	}
	else {
		PlotVars = ["rate1F","rate2F","rate3F","rate4F","rate5F"]
	}
	GenSurvival()
	LineTransition()
	//UpdateGraph()
}

function LineTransition() {
	for (var i = 0; i < PlotVars.length; i++) {
		plot.select("#"+OldPlotVars[i]	)
			.transition().duration(1500).ease(d3.easeCubicInOut)
		.attr("d",linefunction(survplot[PlotVars[i]]))
		.on("start",function(){	UpdateTable();AgeText();})
		.on("end",function() {UpdateGraph()})
	}
}			


function UpdateTable() {
	d3.selectAll(".CentileTable").remove()
	// calculate centiles
	
	var DivWidth = parseInt(d3.select("#CentileTable").style('width'), 10)
	var	TableWidth = DivWidth*0.8
	var SVGHeight = 300
	var marginleft = 10
	var marginright = 10
	var margintop = 10
	var centiles = [75,50,25]
	
	centvals = GenCentiles(centiles);

	var TabSVG = d3.select("#CentileTable")
		.append("svg")
		.attr("width", DivWidth)
		.attr("height", SVGHeight)
		.attr('class', "CentileTable")
	
	var TabPlot = TabSVG.append('g')
		.attr('transform', 'translate(' + marginleft + ',' + margintop + ')')
		.attr('width', TableWidth)
		.attr('height', SVGHeight)

	var starty  = 0.3*SVGHeight
	var ygap = 40

	TabPlot.append("text")	
		.attr("class","CentileText")
		.attr("x", (0))
		.attr("y", ygap/2)
		.attr("dy","0.35em")
		.attr("text-anchor", "start") 
		.style("font-size","20px")		
		.text("Age at which 75%, 50% or 25% still alive.")
	
	var RowTitle = ["1: Least Deprived","2","3","4","5: Most Deprived"]
	for(var j = 0;j<5;j++) {
		TabPlot.append("text")	
			.attr("class","CentileText")
			.attr("x", (0))
			.attr("y", starty+j*ygap)
			.attr("dy","0.35em")
			.attr("text-anchor", "start") 			
			.text(RowTitle[j])
			.style("fill",LineColours[PlotVars[j]])		
	}		

	var TableX = [0.5*TableWidth,0.7*TableWidth,0.9*TableWidth]
	var ColTitle = ["75%","50%","25%"]
	for(var j = 0;j<3;j++) {
		TabPlot.append("text")	
			.attr("class","CentileText")
			.attr("x", TableX[j])
			.attr("y", 0.2*SVGHeight)
			.attr("dy","0.35em")
			.attr("text-anchor", "start") 			
			.text(ColTitle[j])
			.style("fill",LineColours[PlotVars[i]])		
	}
	for(var i = 0; i < PlotVars.length; i++) {
		for(var j = 0;j<3;j++) {
			TabPlot.append("text")	
				.attr("class","CentileText")
				.attr("x", TableX[j])
				.attr("y", starty+i*ygap)
				.attr("dy","0.35em")
				.attr("text-anchor", "start") 			
				.text(d3.format(".1f")(centvals[PlotVars[i]][j]))
				.style("fill",LineColours[PlotVars[i]])
		}
	}

}

function GenCentiles(c) {
    bisectSurvival = d3.bisector(function(d) { return d	; }).left
	centvalues = []
	var agerev = ageplot
	agerev.reverse()	
	for(var i = 0; i < PlotVars.length; i++) {
	centvalues[PlotVars[i]] = []
		var F = survplot[PlotVars[i]]
		F.reverse()
		for(var j=0;j<c.length;j++) {
			var survindex =	bisectSurvival(F,c[j])
			var change = (survplot[PlotVars[i]][survindex] - c[j])/(survplot[PlotVars[i]][survindex] - survplot[PlotVars[i]][survindex-1])
			var getage = d3.interpolate(ageplot[survindex],ageplot[survindex-1]);
			centvalues[PlotVars[i]][j] = getage(change)

			//console.log(i,j,c[j],survindex,F[survindex],F[survindex-1],agerev[survindex],agerev[survindex-1],centvalues[PlotVars[i]][j])
		}
	}
	return centvalues;
}
function PlotMouseOver() {
	// remove lines
	plot.selectAll(".MouseOverLine").remove()
	var xtmp = d3.scaleLinear()
		.domain([CurrentAge, 100])
		.range([ 0, graphwidth]);	
	var agex = Math.ceil(xtmp.invert(d3.mouse(this)[0]))
	// addline
	if(agex <= 100) {			
		var ageindex = ageplot.indexOf(agex)
		plot.append("line")
			.attr("x1",x(agex))
			.attr("x2",x(agex))
			.attr("y1", y(0))
			.attr("y2", y(survplot[PlotVars[0]][ageindex]))
			.attr("class","MouseOverLine")
			.style("stroke","black")
			.style("stroke-width",1)	
			.style("stroke-dasharray", ("3, 3"))
			.moveToBack()
			
		for(var i = 0; i < PlotVars.length; i++) {
			plot.append("line")
				.attr("x1",x(CurrentAge))
				.attr("x2",x(agex))
				.attr("y1", y(survplot[PlotVars[i]][ageindex]))
				.attr("y2", y(survplot[PlotVars[i]][ageindex]))
				.attr("class","MouseOverLine")
				.style("stroke",LineColours[PlotVars[i]])
				.style("stroke-width",1)	
				.style("stroke-dasharray", ("3, 3"))
				.moveToBack()		
		}
		AgeProbText(agex)
	}
	else PlotMouseOut()
}
function PlotMouseOut() {
	plot.selectAll(".MouseOverLine").remove()
	d3.selectAll(".AgeProbText")
		.style("opacity",0)
	TabPlot.append("text")	
		.attr("class","AgeProbText")
		.attr("x", (0))
		.attr("y", 20)
		.attr("dy","0.35em")
		.attr("text-anchor", "start") 
		.style("font-size","18px")		
		.style("opacity",1)
		.text("Hover over graph to give % alive at specific ages")
}

function AgeProbText(agex) {
	d3.selectAll(".AgeProbTable").remove()
	var DivWidth = parseInt(d3.select("#AgeProbTable").style('width'), 10)
	var	TableWidth = DivWidth*0.95
	var SVGHeight = 250
	var marginleft = 10
	var marginright = 10
	var margintop = 10
	
	var TabSVG = d3.select("#AgeProbTable")
		.append("svg")
		.attr("width", DivWidth)
		.attr("height", SVGHeight)
		.attr('class', "AgeProbTable")
	
	 TabPlot = TabSVG.append('g')
		.attr('transform', 'translate(' + marginleft + ',' + margintop + ')')
		.attr('width', TableWidth)
		.attr('height', SVGHeight)

	var starty  = 0.2*SVGHeight
	var ygap = 40
	var sextext = "males"
	TabPlot.append("text")	
		.attr("class","AgeProbText")
		.attr("x", (0))
		.attr("y", ygap/2)
		.attr("dy","0.35em")
		.attr("text-anchor", "start") 
		.style("font-size","20px")		
		.text("Percentage of " + CurrentSex.toLowerCase() + "s aged " + CurrentAge + " alive at " + agex)

	var RowTitle = ["1: Least Deprived","2","3","4","5: Most Deprived"]
	var TableX = [0.5*TableWidth]
	var ageindex = ageplot.indexOf(agex)
	for(var j = 0;j<5;j++) {
		TabPlot.append("text")	
			.attr("class","AgeProbText")
			.attr("x", 0)
			.attr("y", starty+j*ygap)
			.attr("dy","0.35em")
			.attr("text-anchor", "start") 			
			.text(RowTitle[j])
			.style("fill",LineColours[PlotVars[j]])		
	}				
		
	for(var i = 0; i < PlotVars.length; i++) {
		TabPlot.append("text")	
			.attr("class","AgeProbText")
			.attr("x", TableX)
			.attr("y", starty+i*ygap)
			.attr("dy","0.35em")
			.attr("text-anchor", "start") 			
			.text(d3.format(".1f")(survplot[PlotVars[i]][ageindex])+"%")
			.style("fill",LineColours[PlotVars[i]])
	}		
}


///////////////////////
/// Slider Functions //
///////////////////////
function AgeSlider(SliderOptions) {
	var DivName = SliderOptions.DivName || undefined;
	var Xmin = SliderOptions.Xmin || 0;
	var Xmax = SliderOptions.Xmax || 100;
	var SliderWidthProp =  SliderOptions.SliderWidthProp || 0.8;
	var DrawAxis = SliderOptions.DrawAxis || "true";
	var AxisSpace = SliderOptions.AxisSpace || 25;
	var SliderHeight = SliderOptions.SliderHeight || 10;
	var Ticks = SliderOptions.Ticks || 5;
	var TickValues = SliderOptions.TickValues || undefined;
	var InitVal = SliderOptions.InitVal || 0;
	var Label = SliderOptions.Label || "";
	var HistHeight = SliderOptions.HistHeight || 50	
	if(Label == "") {
		var LabelWidth = 0
	}
	else {
		var LabelWidth = SliderOptions.LabelWidth || 0.1
	}
	
// Widths and Heights
	var DivWidth = parseInt(d3.select("#"+DivName).style('width'), 10)
	var	SliderWidth = DivWidth*SliderWidthProp
	var SVGHeight = AxisSpace + SliderHeight + HistHeight
	var SliderHistHeight = SliderHeight + HistHeight
	
	var marginleft = DivWidth*(1-SliderWidthProp)/2
	var marginright = DivWidth*(1-SliderWidthProp)/2
	var margintop = SliderHeight*0.5
	
	var Sliderx = d3.scaleLinear()
		.domain([Xmin, Xmax])
		.range([ 0, SliderWidth]);
		
	var xAxisSlide = d3.axisBottom().scale(Sliderx)
		.ticks(Ticks)		
		.tickValues(TickValues)
		.tickSize(4);

// Define SVG area	
 	Sliders[DivName] = d3.select("#"+DivName)
		.append("svg")
		.attr("width", DivWidth)
		.attr("height", SVGHeight)
		.attr('class', "SVGSlider")
// Add Title
	Sliders[DivName].append("text")
		.attr("class","SliderText")
		.attr("x",(20))
		.attr("y",30)
		.text("Drag to change starting age")
		
// Define Plot area
	Sliders[DivName].append('g')
		.attr('transform', 'translate(' + marginleft + ',' + margintop + ')')
		.attr('width', SliderWidth)
		.attr('height', SliderHeight + HistHeight)
		.attr("id",DivName+"Plot")
	if(DrawAxis == "true") {
		d3.select("#"+DivName+"Plot")
			.append("g")
			.attr("class", "SliderAxis")
			.attr("transform", "translate(0," + SliderHistHeight + ")")
			.call(xAxisSlide);	
	}

// Draw Rectangle	
	d3.select("#"+DivName+"Plot")
		.append("rect")
		.attr("class","SliderRect")
		.attr("width",SliderWidth)
		.attr("height", SliderHeight)
		.attr("x", 0)
 		.attr("y", HistHeight)
		.on("click", function() {
			var newx = d3.mouse(this)[0];
			d3.select("#"+DivName+"Circle")
				.attr("cx", newx)
			CurrentAge = Sliderx.invert(newx)
			UpdateGraph()
		})

	Sliders[DivName].CurrentValue = InitVal

var SliderDrag = d3.drag()
		.on("start", function() {
			d3.event.sourceEvent.stopPropagation();
		})
		.on("drag", DragCircle)
		.on("end", function(){
				d3.select(this)
					.attr("opacity",0.8);

		});
		
function DragCircle(){
	var newx = d3.event.x;
	if(inrange(newx,Sliderx(Xmin),Sliderx(Xmax))) {
		d3.select(this)
			.attr("cx", newx)
		CurrentAge = Math.round(Sliderx.invert(newx),0)
		UpdateGraph()
	}
}
	d3.select("#"+DivName+"Plot")
		.append("circle")
		.attr("class","SliderCircle")
		.attr("id",DivName+"Circle")
		.attr("cx", function (d) {return Sliderx(InitVal); })
		.attr("cy", HistHeight + SliderHeight/2)
		.attr("r", SliderHeight)
		.call(SliderDrag)
}

function inrange(x, min, max) {
	return x >= min && x <= max;
}	

d3.selection.prototype.moveToBack = function() {  
	return this.each(function() { 
		var firstChild = this.parentNode.firstChild; 
		if (firstChild) { 
			this.parentNode.insertBefore(this, firstChild); 
		} 
	});
};
