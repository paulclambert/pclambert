// JavaScript Document

margin = {top: 30, right: 20, bottom: 50, left: 50}
		, width = 600 - margin.left - margin.right
		, height = 300 - margin.top - margin.bottom;

lambda1 = 0.2
lambda2 = 0.4
gamma1 = 1.3
gamma2 = 0.8
pi = 0.5
N = 1000
fixaxis = 0
showmixtures = 1

time = []
maxtime = 10
for (var i=0;i<N;i++) {
		time[i] = i/(N-1)*((maxtime)-(0))+(0);
}
genfunctions()

// Slider positions and starting values
Sliders = [{
	"name":"lambda1",
	"textname":"\u03BB1",
	"min":0.01,
	"max":3,
	"paramval":0.2,
	"xpos":0,
	"ypos":0.1,
	"width":0.7,
	"height":0.05
},{
	"name":"gamma1",
	"textname":"\u03B31",
	"min":0.1,
	"max":3,
	"paramval":0.8,
	"xpos":0,
	"ypos":0.2,
	"width":0.7,
	"height":0.05
},{
	"name":"lambda2",
	"textname":"\u03BB2",
	"min":0.01,
	"max":3,
	"paramval":0.2,
	"xpos":0,
	"ypos":0.3,
	"width":0.7,
	"height":0.05
},{
	"name":"gamma2",
	"textname":"\u03B32",
	"min":0.1,
	"max":3,
	"paramval":0.8,
	"xpos":0,
	"ypos":0.4,
	"width":0.7,
	"height":0.05
},{
	"name":"pi",
	"textname":"pi",
	"min":0.01,
	"max":0.99,
	"paramval":0.5,
	"xpos":0,
	"ypos":0.5,
	"width":0.7,
	"height":0.05
}];

var knotdrag = d3.behavior.drag()
		.on("dragstart", function() {
			d3.event.sourceEvent.stopPropagation();
			paramindex =  Number(this.id);
			parammin = Sliders[paramindex].xpos
			parammax = Sliders[paramindex].xpos + Sliders[paramindex].width
		})
		.on("drag", function(){
			var x = d3.event.x;
			if (inrange(x/width, parammin, parammax)) {
				d3.select(this)
					.attr("cx", x)
					.attr("opacity",0.5);
				if(paramindex==0) {
					lambda1 = Sliders[paramindex].min + (x / width - Sliders[paramindex].xpos)*(Sliders[paramindex].max - Sliders[paramindex].min)/Sliders[paramindex].width
					Sliders[paramindex].paramval = lambda1
				}
				else if(paramindex == 1) {
					gamma1 = Sliders[paramindex].min + (x / width - Sliders[paramindex].xpos)*(Sliders[paramindex].max - Sliders[paramindex].min)/Sliders[paramindex].width
					Sliders[paramindex].paramval = gamma1
				}
				else if(paramindex == 2) {
					lambda2 = Sliders[paramindex].min + (x / width - Sliders[paramindex].xpos)*(Sliders[paramindex].max - Sliders[paramindex].min)/Sliders[paramindex].width
					Sliders[paramindex].paramval = lambda2
				}
				else if(paramindex == 3) {
					gamma2 = Sliders[paramindex].min + (x / width - Sliders[paramindex].xpos)*(Sliders[paramindex].max - Sliders[paramindex].min)/Sliders[paramindex].width
					Sliders[paramindex].paramval = gamma2
				}
				else if(paramindex == 4) {
					pi = Sliders[paramindex].min + (x / width - Sliders[paramindex].xpos)*(Sliders[paramindex].max - Sliders[paramindex].min)/Sliders[paramindex].width
					Sliders[paramindex].paramval = pi
				}
				d3.selectAll("path.St").remove();
				d3.selectAll("path.ht").remove();
				d3.selectAll("g.Yaxis").remove();
				d3.selectAll("text.parameters").remove();
				updateSliderText()
				updateyaxis()
				genfunctions()
				drawfunctions()
			}
		})
    
		.on("dragend", function(){
				d3.select(this)
					.attr("opacity",0.7);
		});


var chartSt = d3.select("#survival")
	.append('svg:svg')
	.attr('width', width + margin.right + margin.left)
	.attr('height', height + margin.top + margin.bottom)
	.attr('class', 'chart')

var chartht = d3.select("#hazard")
	.append('svg:svg')
	.attr('width', width + margin.right + margin.left)
	.attr('height', height + margin.top + margin.bottom)
	.attr('class', 'chart')
	
var chartSlider = d3.select("#parameters")
	.append('svg:svg')
	.attr('width', width + margin.right + margin.left)
	.attr('height', height + margin.top + margin.bottom)
	.attr('class', 'chart')	

/*
var chartEquations = d3.select("#equations")
	.append('svg:svg')
	.attr('width', width + margin.right + margin.left)
	.attr('height', height + margin.top + margin.bottom)
	.attr('class', 'chart')	
*/	

var mainSt = chartSt.append("g")
	.attr('transform', 'translate(' + margin.left + ',' + margin.top + ')')
	.attr('width', width)
	.attr('height', height)
	.attr('class', 'main')   

var mainht = chartht.append("g")
	.attr('transform', 'translate(' + margin.left + ',' + margin.top + ')')
	.attr('width', width)
	.attr('height', height)
	.attr('class', 'main')   

/*
var mainEquations = chartEquations.append("g")
	.attr('transform', 'translate(' + margin.left + ',' + margin.top + ')')
	.attr('width', width)
	.attr('height', height)
	.attr('class', 'main')   
*/

var mainSlider = chartSlider.append("g")
	.attr('transform', 'translate(' + margin.left + ',' + margin.top + ')')
	.attr('width', width)
	.attr('height', height)
	.attr('class', 'main')   

var linefunctionSt = d3.svg.line()
	.x(function(d,i) {return x(time[i]);})
	.y(function(d) {return ySt(d);})
	.interpolate("linear")
	.defined(function(d,i) { if(isFinite(d)) {
								return 1}
							 else {
								return 0}})

var linefunctionht = d3.svg.line()
	.x(function(d,i) {return x(time[i]);})
	.y(function(d) {return yht(d);})
	.interpolate("linear")
	.defined(function(d,i) { if(isFinite(d)) {
								return 1}
							 else {
								return 0}})

xslider = d3.scale.linear()
	.domain([0, 1])
	.range([ 0, width]);
	
yslider = d3.scale.linear()
	.domain([0, 1])
	.range([ 0, height]);

x = d3.scale.linear()
	.domain([0, maxtime])
	.range([ 0, width]);
		

drawsliders()
updateSliderText()
addtitles()
addaxischeckbox()
addshowmixturesbox()
	         
// draw the x axis
updateyaxis()

// draw the y axis
// Draw X-axis grid lines
mainSt.selectAll("line.xref")
  .data(x.ticks(10).slice(1))
  .enter().append("line")
  .attr("class", "xref")
  .attr("x1", x)
  .attr("x2", x)
  .attr("y1", ySt(0))
  .attr("y2", ySt(1))
  .style("stroke", "#ccc");

mainht.selectAll("line.xref")
  .data(x.ticks(10).slice(1))
  .enter().append("line")
  .attr("class", "xref")
  .attr("x1", x)
  .attr("x2", x)
  .attr("y1", ySt(0))
  .attr("y2", ySt(1))
  .style("stroke", "#ccc");


var xAxis = d3.svg.axis()
    .scale(x)
    .orient("bottom")
    .ticks(5);
	

mainSt.append("g")
	.attr("class", "x axis")
	.attr("transform", "translate(0," + height + ")")
	.call(xAxis);




mainht.append("g")
	.attr('transform', 'translate(0,' + height + ')')
	.attr('class', 'main axis date')
	.call(xAxis);

mainSt.append("text")
    .attr("class", "x label")
    .attr("text-anchor", "middle")
    .attr("x", (width/2))
    .attr("y", height  + 40)
    .text("Time (years)")

mainht.append("text")
    .attr("class", "x label")
    .attr("text-anchor", "middle")
    .attr("x", (width/2))
    .attr("y", height  + 40)
    .text("Time (years)");





drawfunctions()


function genfunctions(){
	St = []
	ht= []
	S1 = []
	S2 = []
	for (i=0;i<N;i++) {
		S1[i] = Math.exp(-lambda1*Math.pow(time[i],gamma1))
		S2[i] = Math.exp(-lambda2*Math.pow(time[i],gamma2))
		
		St[i] = pi*S1[i] + (1-pi)*S2[i]
		ht[i] = (lambda1*gamma1*Math.pow(time[i],gamma1-1)*pi*S1[i] + lambda2*gamma2*Math.pow(time[i],gamma2-1)*pi*S2[i]) /St[i]
	}
}


function drawfunctions() {
	mainSt.append("svg:path")
		.attr("class","St")
		.attr("d",linefunctionSt(St))
		.style("stroke","red")

	mainht.append("svg:path")
		.attr("class","ht")
		.attr("d",linefunctionht(ht))	
		.style("stroke","red")
		
	if(showmixtures==1) {
		mainSt.append("svg:path")
			.attr("class","St")
			.attr("d",linefunctionSt(S1))
			.style("stroke","red")
			.style("stroke-width",1)
			.style("opacity",0.5)		
		mainSt.append("svg:path")
			.attr("class","St")
			.attr("d",linefunctionSt(S2))
			.style("stroke","red")
			.style("stroke-width",1)
			.style("opacity",0.5)		
	}
}

function drawsliders() {
	mainSlider.selectAll("rect.rangerect")
 		.data(Sliders)
		.enter()
		.append("svg:rect")
		.attr("class","rangerect")
		.attr("x",function(d) {return xslider(d.xpos)} )
		.attr("y",function(d) {return yslider(d.ypos)})
		.attr("rx",function(d) {return yslider(d.height)} )
		.attr("ry",function(d) {return yslider(d.height)} )
		.attr("width",function(d) {return xslider(d.width)})
		.attr("height",function(d) {return yslider(d.height)})
		.style("fill","#CCCCCC")

	mainSlider.selectAll("circle.movecircle")
		.data(Sliders)
		.enter()
		.append("svg:circle")
		.attr("class","movecircle")
		.attr("cx",function(d) {return xslider(((d.paramval - d.min)/(d.max-d.min))*(d.width) + d.xpos) } )
		.attr("cy",function(d) {return yslider(d.ypos + d.height/2)})
		.attr("r",function(d) {return xslider(d.height/4)})
		.attr("id", function(d,i) {return i;})
		.style("fill","297ACC")
		.attr("opacity",0.7)		
		.call(knotdrag);
}	

function updateSliderText() {
	mainSlider.selectAll("text.parameters")
		.data(Sliders)
		.enter()
		.append("svg:text")	
		.attr("class","parameters")
		.attr("text-anchor", "start")		
		.attr("x",function(d) {return xslider(d.xpos + d.width + 0.02)})
		.attr("y",function(d) {return yslider(d.ypos + d.height)})
		.text(function(d) {return d.textname +" = "+Math.round(d.paramval*1000)/1000})	
}

function updateyaxis() {
	ySt = d3.scale.linear()
		  .domain([0,1])
		  .range([ height, 0 ]);
  
	if(fixaxis == 0) {
		yht = d3.scale.linear()
		  .domain([0,d3.max(ht,function(d) {if(isFinite(d)) {return d}
			else {return NaN}})])
		  .range([ height, 0 ]);
	}
	
 	var yAxisSt = d3.svg.axis()
		.scale(ySt)
		.orient('left')
  
	var yAxisht = d3.svg.axis()
		.scale(yht)
		.orient('left')
	  
	mainSt.append('g')
		.attr('transform', 'translate(0,0)')
	  .attr('class', 'Yaxis')
	  .call(yAxisSt);
  
	mainht.append('g')
		.attr('transform', 'translate(0,0)')
		.attr('class', 'Yaxis')
		.call(yAxisht);
}

function addtitles() {
	mainSt.append("text")
		.attr("class","titleText")	
		.text("Survival function")
		.attr("x",width/2)
		.style("text-anchor", "middle")
		.attr("y",-10)
		.style("font-size","20px")

	mainht.append("text")
		.attr("class","titleText")	
		.text("Hazard	 function")
		.attr("x",width/2)
		.style("text-anchor", "middle")
		.attr("y",-10)
		.style("font-size","20px")
}

function addaxischeckbox() {
	var xpos = 0.02
	var ypos = 0.05
	mainSlider.append("circle")
		.attr("class","selectaxis")
		.attr("cx",xslider(xpos))
		.attr("cy",yslider(ypos))
		.attr("r",xslider(0.01))
		.style("fill","white")
		.style("stroke","black")
	
	mainSlider.append("circle")
		.attr("class","selectaxis")
		.attr("cx",xslider(xpos))
		.attr("cy",yslider(ypos))
		.attr("r",xslider(0.008))
		.style("fill","white")
		.style("stroke","white")
		.on("click", function(d) {
			d3.select(this)
				.style("fill",function(d) {
					if(fixaxis==0) {
						var retcolour = "black"
					}
					else {
						var retcolour = "white"
					}
					fixaxis = 1 - fixaxis
					if(fixaxis == 0) {
						d3.selectAll("path.ht").remove();
						d3.selectAll("g.Yaxis").remove();
						updateyaxis()
						drawfunctions()
					}
					return retcolour})})
					
	mainSlider.append("text")
		.attr("x",xslider(xpos + 0.02))				
		.attr("y",yslider(ypos + 0.01))
		.text("Fix y-axis range")	
		.style("text-anchor", "start")
}

function addshowmixturesbox() {
	var xpos = 0.4
	var ypos = 0.05
	mainSlider.append("circle")
		.attr("class","selectmixture")
		.attr("cx",xslider(xpos))
		.attr("cy",yslider(ypos))
		.attr("r",xslider(0.01))
		.style("fill","white")
		.style("stroke","black")
	
	mainSlider.append("circle")
		.attr("class","selectmixture")
		.attr("cx",xslider(xpos))
		.attr("cy",yslider(ypos))
		.attr("r",xslider(0.008))
		.style("fill","black")
		.style("stroke","white")
		.on("click", function(d) {
			d3.select(this)
				.style("fill",function(d) {
					if(showmixtures==0) {
						var retcolour = "black"
					}
					else {
						var retcolour = "white"
					}
					showmixtures = 1 - showmixtures
					d3.selectAll("path.St").remove();
					drawfunctions()
					return retcolour})})
					
	mainSlider.append("text")
		.attr("x",xslider(xpos + 0.02))				
		.attr("y",yslider(ypos + 0.01))
		.text("Show component distributions")	
		.style("text-anchor", "start")
}

function inrange(x, min, max) {
  return x >= min && x <= max;
}