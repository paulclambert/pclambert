// JavaScript Document

margin = {top: 30, right: 20, bottom: 50, left: 50}
		, width = 600 - margin.left - margin.right
		, height = 300 - margin.top - margin.bottom;

lambda = 0.2
gamma = 1.3
hr = 0.8
N = 1000
fixaxis = 0

time = []
maxtime = 10
for (var i=0;i<N;i++) {
		time[i] = i/(N-1)*((maxtime)-(0))+(0);
}
genfunctions()

// Slider positions and starting values
Sliders = [{
	"name":"lambda",
	"textname":"\u03BB",
	"min":0.05,
	"max":3,
	"paramval":0.2,
	"xpos":0,
	"ypos":0.1,
	"width":0.7,
	"height":0.05
},{
	"name":"gamma",
	"textname":"\u03B3",
	"min":0.1,
	"max":3,
	"paramval":0.8,
	"xpos":0,
	"ypos":0.2,
	"width":0.7,
	"height":0.05
},{
	"name":"HR",
	"textname":"HR",
	"min":0.1,
	"max":1,
	"paramval":0.8,
	"xpos":0,
	"ypos":0.3,
	"width":0.7,
	"height":0.05
}];

SurvDiff = [{
	"time":1,
	"xpos":0.1,
	"ypos":0.5
},{
	"time":5,
	"xpos":0.1,
	"ypos":0.7
},{
	"time":10,
	"xpos":0.1,
	"ypos":0.9
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
					lambda = Sliders[paramindex].min + (x / width - Sliders[paramindex].xpos)*(Sliders[paramindex].max - Sliders[paramindex].min)/Sliders[paramindex].width
					Sliders[paramindex].paramval = lambda
				}
				else if(paramindex == 1) {
					gamma = Sliders[paramindex].min + (x / width - Sliders[paramindex].xpos)*(Sliders[paramindex].max - Sliders[paramindex].min)/Sliders[paramindex].width
					Sliders[paramindex].paramval = gamma

				}
				else if(paramindex == 2) {
					hr = Sliders[paramindex].min + (x / width - Sliders[paramindex].xpos)*(Sliders[paramindex].max - Sliders[paramindex].min)/Sliders[paramindex].width
					Sliders[paramindex].paramval = hr
					
				}
				d3.selectAll("path.St").remove();
				d3.selectAll("path.ht").remove();
				d3.selectAll("path.pdf").remove();
				d3.selectAll("g.Yaxis").remove();
				d3.selectAll("text.parameters").remove();
				d3.selectAll("text.survdiff").remove();
				updateSliderText()
				updateyaxis()
				genfunctions()
				drawfunctions()
				updateSurvivalText()				
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
	
var chartpdf = d3.select("#pdf")
	.append('svg:svg')
	.attr('width', width + margin.right + margin.left)
	.attr('height', height + margin.top + margin.bottom)
	.attr('class', 'chart')	

var chartSlider = d3.select("#parameters")
	.append('svg:svg')
	.attr('width', width + margin.right + margin.left)
	.attr('height', height + margin.top + margin.bottom)
	.attr('class', 'chart')	
	

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

var mainpdf = chartpdf.append("g")
	.attr('transform', 'translate(' + margin.left + ',' + margin.top + ')')
	.attr('width', width)
	.attr('height', height)
	.attr('class', 'main')   

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

var linefunctionpdf = d3.svg.line()
	.x(function(d,i) {return x(time[i]);})
	.y(function(d) {return ypdf(d);})
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
updateSurvivalText()
//draw border
/*
d3.select("#survival")
	.attr("style", "outline: thin solid red;")   //This will do the job
	.attr("width", width)
	.attr("height", height);
d3.select("#hazard")
	.attr("style", "outline: thin solid red;")   //This will do the job
	.attr("width", width)
	.attr("height", height);
d3.select("#pdf")
	.attr("style", "outline: thin solid red;")   //This will do the job
	.attr("width", width)
	.attr("height", height);
*/
         
// draw the x axis
var xAxis = d3.svg.axis()
		.scale(x)
		.orient('bottom')
//		.tickFormat(function (d) { return ''; });	

mainSt.append("g")
	.attr('transform', 'translate(0,' + height + ')')
	.attr('class', 'main axis date')
	.call(xAxis)

mainht.append("g")
	.attr('transform', 'translate(0,' + height + ')')
	.attr('class', 'main axis date')
	.call(xAxis)

mainpdf.append("g")
	.attr('transform', 'translate(0,' + height + ')')
	.attr('class', 'main axis date')
	.call(xAxis)

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

mainpdf.append("text")
    .attr("class", "x label")
    .attr("text-anchor", "middle")
    .attr("x", (width/2))
    .attr("y", height  + 40)
    .text("Time (years)");


// draw the y axis
updateyaxis()
drawfunctions()




function genfunctions(){
	St = []
	St.ref = []
	St.treat = []
	ht= []
	ht.ref = []
	ht.treat= []
	pdf = []
	pdf.ref=[]
	pdf.treat=[]
	for (i=0;i<N;i++) {
		St.ref[i] = Math.exp(-lambda*Math.pow(time[i],gamma))
		St.treat[i] = Math.exp(-lambda*hr*Math.pow(time[i],gamma))
		ht.ref[i] = lambda*gamma*Math.pow(time[i],(gamma-1))
		ht.treat[i] = lambda*hr*gamma*Math.pow(time[i],(gamma-1))
		pdf.ref[i] = St.ref[i]*ht.ref[i]
		pdf.treat[i] = St.treat[i]*ht.treat[i]
	}
}


function drawfunctions() {
	mainSt.append("svg:path")
		.attr("class","St")
		.attr("d",linefunctionSt(St.ref))

	mainSt.append("svg:path")
		.attr("class","St")
		.attr("d",linefunctionSt(St.treat))
		.style("stroke", "red") 		
		
	mainht.append("svg:path")
		.attr("class","ht")
		.attr("d",linefunctionht(ht.ref));		

	mainht.append("svg:path")
		.attr("class","ht")
		.style("stroke", "red")
		.attr("d",linefunctionht(ht.treat))		

	mainpdf.append("svg:path")
		.attr("class","pdf")
		.attr("d",linefunctionpdf(pdf.ref));		

	mainpdf.append("svg:path")
		.attr("class","pdf")
		.style("stroke", "red")
		.attr("d",linefunctionpdf(pdf.treat))	
				 		
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

function updateSurvivalText() {
	mainSlider.selectAll("text.survdiff")
		.data(SurvDiff)
		.enter()
		.append("svg:text")	
		.attr("class","survdiff")
		.attr("text-anchor", "start")		
		.attr("x",function(d) {return xslider(d.xpos)})
		.attr("y",function(d) {return yslider(d.ypos)})
		.text(function(d) {return "Survival Difference at " + d.time + " years = " + Math.round((Math.exp(-lambda*hr*Math.pow(d.time,gamma)) - + Math.exp(-lambda*Math.pow(d.time,gamma)))*1000)/1000}) 
}

//+ Math.exp(-lambda*Math.pow(d.time,gamma)) - Math.exp(-lambda*hr*Math.pow(d.time,gamma))

function updateyaxis() {
  ySt = d3.scale.linear()
		  .domain([0,1])
		  .range([ height, 0 ]);
  
  if(fixaxis == 0) {
	  yht = d3.scale.linear()
		  .domain([0,d3.max(ht.ref,function(d) {if(isFinite(d)) {
								  return d}
							   else {
								  return NaN}})])
		  .range([ height, 0 ]);
  
  
  	ypdf = d3.scale.linear()
		  .domain([0,d3.max(pdf.ref,function(d) {if(isFinite(d)) {
								  return d}
							   else {
								  return NaN}})])
		  .range([ height, 0 ]);
  	}
  var yAxisSt = d3.svg.axis()
	  .scale(ySt)
	  .orient('left')
  
  var yAxisht = d3.svg.axis()
	  .scale(yht)
	  .orient('left')
	  
  var yAxispdf = d3.svg.axis()
	  .scale(ypdf)
	  .orient('left')	
  //	.tickFormat(function (d) { return ''; });	
  
  mainSt.append('g')
	  .attr('transform', 'translate(0,0)')
	  .attr('class', 'Yaxis')
	  .call(yAxisSt);
  
  mainht.append('g')
	.attr('transform', 'translate(0,0)')
	.attr('class', 'Yaxis')
	.call(yAxisht);
  
  mainpdf.append('g')
	  .attr('transform', 'translate(0,0)')
	  .attr('class', 'Yaxis')
	  .call(yAxispdf);	
}

function addtitles() {
	mainpdf.append("text")
		.attr("class","titleText")	
		.text("Probability density function")
		.attr("x",width/2)
		.style("text-anchor", "middle")
		.attr("y",-10)
		.style("font-size","20px")

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
					if(fixaxis==0) {var retcolour = "black"}
					else {var retcolour = "white"}
					fixaxis = 1 - fixaxis
					return retcolour})})
					
	mainSlider.append("text")
		.attr("x",xslider(xpos + 0.02))				
		.attr("y",yslider(ypos + 0.01))
		.text("Fix y-axis range")	
		.style("text-anchor", "start")
					

// rectangle
// check click
// text (fix yaxis)
}


function inrange(x, min, max) {
  return x >= min && x <= max;
}