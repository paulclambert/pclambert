// Code to produce webpage for relative survival models sensitivity analysis

// Give the number of models here (currently the same for each site)
NModels = 18
// Give the stub of the filenames for each site here
CancerTypes = ["Bladder_male","Bladder_female","lung_male","lung_female","colon_male","colon_female","Rectum_male","Rectum_female","stomach_male","stomach_female","Hodgkins_male","Hodgkins_female","Melanoma_male","Melanoma_female","prostate_male", "breast_female", "Ovarian_female"]
LoadData()
//"Bladder_male","Bladder_female","lung_male","lung_female","colon_male","colon_female","Rectum_male","Rectum_female","stomach_male","stomach_female","Melanoma_male","Melanoma_female", "prostate_male", "breast_female"

function LoadData() {
	var q = d3.queue()
	for (var c in CancerTypes) {
		for (var m = 1; m <= NModels; m++)	{
			q.defer(d3.json,"nat_"+CancerTypes[c]+"_model"+(m)+".json")
		};
	};
	q.awaitAll(ProcessData) 
}

function ProcessData(error,FileResults) {
	if (error) throw error;	
	Models = []
	var FileIndex = 0
	for (var c in CancerTypes) {
	 	Models[CancerTypes[c]] = []
		for (var m = 1; m <= NModels; m++)	{
			Models[CancerTypes[c]]["Model"+(m)] = []
				for(var prop in FileResults[FileIndex][0]) {
						Models[CancerTypes[c]]["Model"+(m)][prop] = FileResults[FileIndex][0][prop];
				};
				FileIndex = FileIndex + 1				
		}
	}
// Now data is loaded and processed run graphs.
	RunGraphs()
}	

function jsUcfirst(string) 
{
    return string.charAt(0).toUpperCase() + string.slice(1);
}





var Cancer=[]
var CancerT=[]
var Gender=[]
var Cancertitle=[]
for (var m = 0; m <= CancerTypes.length; m++)	{
    var str = CancerTypes[m];
    var res = str.split("_");
	var res_Capital=jsUcfirst(res[0])
	 Cancer[m]= res_Capital + " cancer (" + res[1]  + ")"
	 Cancer[10]= "Hodgkin lymphoma (male)"
	 Cancer[11]= "Hodgkin lymphoma (female)"
	 CancerT[m]= res_Capital
	 Gender[m]=res[1]
	 Cancertitle[m]= res_Capital + " cancer"
	 Cancertitle[10]= "Hodgkin lymphoma"
	 Cancertitle[11]= "Hodgkin lymphoma"
	 CancerT[10]="Hodgkin lymphoma"
	 CancerT[11]="Hodgkin lymphoma"
	console.log(Cancer[m])
	console.log(CancerT[m])
    console.log(Gender[m])
	console.log(Gender[m])
 console.log(Cancertitle[m])
}


// width of graph inherited from div "Graph"
// height is 0.6*width
function RunGraphs() {
// Initial values that need to be set only one
// i.e. applicable to all cancer types	
	var margin = {top: 50, right: 20, bottom: 80, left: 80}
		, svgwidth = parseInt(d3.select('#Graph').style('width'), 10)*0.90
		, svgheight = 0.6*svgwidth
		, graphwidth = svgwidth - margin.left - margin.right
		, graphheight = svgheight - margin.top - margin.bottom;

	age = 65;
	CondSurvTime = 0 
	CurrentCancer = CancerTypes[0]
	CurrentCancerNumber = 0
	var GraphOptions = ["Survival Function","Hazard Function"]
	ShortGraphNames = ["St","ht"]
	ActiveGraph = GraphOptions[0]
	NGraphOptions = GraphOptions.length
	var ReportedMeasures = ["Age-specific estimates","Average estimates"]
	CurrentMeasure = ReportedMeasures[0]
	GraphOptNumbers = []
	CancerTypeNumbers = []
	ReportedMeasureNumbers = []
	Sliders=[]
	for(var i=0;i<GraphOptions.length;i++) {GraphOptNumbers[i] = i;};	
	for(var i=0;i<CancerTypes.length;i++) {CancerTypeNumbers[i] = i;};
	for(var i=0;i<ReportedMeasures.length;i++) {ReportedMeasureNumbers[i] = i;};	

// set colours
// could select range depending on number of models
	var LineColours = d3.schemeCategory20
	NewGraphInits()

///////////////////
// Dropdown Menus //
///////////////////
// keep for new graphs

	d3.select("#GraphSelect")
		.attr("class", "styled-select")
		.append("select").on("change", ChangeActiveGraph)
		.attr("id","GraphSelectID")
		.selectAll("option")
   		 .data(GraphOptNumbers)
   		 .enter()
   		 .append("option")
   		 // Provide available text for the dropdown options
    	.text(function(d) {return GraphOptions[d];})

	d3.select("#CancerSelect")
		.attr("class", "styled-select")
		.append("select").on("change", ChangeCancerType)
		.attr("id","CancerSelectID")
		.selectAll("option")
   		 .data(CancerTypeNumbers)
   		 .enter()
   		 .append("option")
   		 // Provide available text for the dropdown options
    	.text(function(d) {return Cancer [d];})

d3.select("#EstimatesSelect")
		.attr("class", "styled-select")
		.append("select").on("change", ChangeReportedEstimates)
		.attr("id","EstimatesSelectID")
		.selectAll("option")
   		 .data(ReportedMeasureNumbers)
   		 .enter()
   		 .append("option")
   		 // Provide available text for the dropdown options
    	.text(function(d) {return ReportedMeasures[d];})
		
	AgeSlider({DivName: "AgeSliderDiv",Xmin:18, Xmax:99, Ticks:20,InitVal:age})
	
	function NewGraphInits() {
		timevar =  Models[CurrentCancer].Model1.timevar
		Nt = timevar.length;
		maxtime = timevar[Nt-1];

// Model Titles and MouseOver Text
		var i = 0
		ModelTitles = [], ModelMouseOverText= [], ModelNames = []
//		for (var m in Models[CurrentCancer]) {
		for (var m = 1; m <= NModels; m++)	{
			var CurrentModel = Models[CurrentCancer]["Model"+m]
			ModelTitles[i] = CurrentModel.ModelTitle
			ModelNames[i] = "Model"+m
			CurrentModel.opacity = "1"
			CurrentModel.LineColour = LineColours[i+""]
			if(CurrentModel.tvcdflist.length>0) {
				CurrentModel.hastvc = true
			}
			else {
				CurrentModel.hastvc = false
			}
			var i = i + 1
		}
	}

AddCheckBoxAndTitles()
///////////////////////////////
// Model Checkbox and Titles //
///////////////////////////////
// Update when change cancer
	function AddCheckBoxAndTitles() {
		// First Remove existing
		d3.select("#ModelList")
			.selectAll("input")
			.remove()	
		
		d3.select("#ModelList")
			.selectAll(".CheckContainer")
			.remove()	
		
		d3.select("#ModelList")
			.selectAll("input")
		    .data(ModelTitles)
		    .enter()
			.append("div")
		    .attr("id", function(d,i) { return "Div"+ModelNames[i] })
			.attr("class","CheckContainer")
			.append("input")
		    .attr("id", function(d,i) { return ModelNames[i]; })
			.attr("checked", true)	
			.attr("type", "checkbox")
			.attr("class","css-checkbox")
			.on("change",ModelOnOff);

// add labels
		d3.select("#ModelList")
			.selectAll(".CheckContainer")
		    .data(ModelTitles)
			.append("label")
		    .attr("id", function(d,i) { return ModelNames[i]; })
			.attr("class","css-label")
			.style("color",function(d,i) { return LineColours[i+""]; })
			.text(function(d) {return d;})
			.attr("for", function(d,i) { return ModelNames[i]; })
			.on("mouseover", ModelMouseOver)
			.on("mouseout", ModelMouseOut);
	}
	
	
	function ModelOnOff() {
		if(this.checked) {
			plot.select("#"+this.id).style("opacity","1")
			Models[CurrentCancer][this.id].opacity = "1"
		}
		else {
			plot.select("#"+this.id).style("opacity","0")
			Models[CurrentCancer][this.id].opacity = "0"
		}
	}

	function ModelMouseOver() {
		if(Models[CurrentCancer][this.id].opacity>0){
			d3.select("#ModelDetails").append("text").text(Models[CurrentCancer][this.id].MouseOverModelTitle).style("font-family","courier")
			d3.select("#ModelDetails").append("div").append("text").text("AIC="+Models[CurrentCancer][this.id].AIC)
			d3.select("#ModelDetails").append("div").append("text").text("BIC="+Models[CurrentCancer][this.id].BIC)
			plot.select("#"+this.id).style("opacity","1")
			plot.select("#"+this.id).style("stroke-width",10);
			plot.select("#"+this.id).moveToFront();
// Now plot CI
/*
			genSurvCI(Models[this.id])
			CurrentModel = this.id
			plot.append("path")		
				.attr("class","ci")
				.attr("id","CI"+this.id)
				.attr("d",CIfunction(Models[this.id].St))
				.style("opacity",0.2)
				.style("stroke",Models[this.id].LineColour)
			*/
		}
	}

	function ModelMouseOut() {
		d3.select("#ModelDetails").selectAll("text").remove()
		plot.select("#"+this.id).style("stroke-width",3)
		plot.select("#"+"CI"+this.id).remove()
	}

////////////////////
// The main graph //
////////////////////
// Forms the total SVG area		
	var svg = d3.select("#Graph")
		.append("svg")
		.attr("width", svgwidth)
		.attr("height", svgheight)
		.attr('class', 'svg')

// Defines the Plot area 
	var plot = svg.append('g')
		.attr('transform', 'translate(' + margin.left + ',' + margin.top + ')')
		.attr('width', graphwidth)
		.attr('height', graphheight)
		.attr('class', 'plot')	

	var linefunction = d3.line()
		.x(function(d,i) {return x(timevar[i]);})
		.y(function(d) {return y(d);})
		.curve(d3.curveLinear)
		.defined(function(d,i) { if(isFinite(d)) {
								return 1}
							 else {
								return 0}})

	var CIfunction = d3.area()
		.x(function(d,i) { return x(timevar[i]); })
   		.y0(function(d,i){ return y(Models[CurrentCancer][CurrentModel].StUCI[i] ); })
   	 	.y1(function(d,i){ return y(Models[CurrentCancer][CurrentModel].StLCI[i] ); });
	
// Calculate predictions for the first time
// needed to scale hazard graph
	for (var m = 1; m <= NModels; m++)	{
		var CurrentModel = Models[CurrentCancer]["Model"+m]
		genSurvHaz(CurrentModel);
	}

// Plot the graph for the first time
// These are called again when there is a change.
updateaxes()
updategraph()

//genSurvCI(Models["Model1"])

function updatetitle() {
	// remove old title
	// add new title

	if(CurrentMeasure=="Age-specific estimates"){
	plot.append("text")
	    .attr("class", "plottitle")
    	.attr("text-anchor", "middle")
    	.attr("x", graphwidth/2)
    	.attr("y", -20)
    	.text(yTitle + " of a " + Gender[CurrentCancerNumber] + " diagnosed with " +  Cancertitle[CurrentCancerNumber]+ "  at age " + age);	
	
	}
	if(CurrentMeasure=="Average estimates"){
	plot.append("text")
	    .attr("class", "plottitle")
    	.attr("text-anchor", "middle")
    	.attr("x", graphwidth/2)
    	.attr("y", -20)
    	.text(yTitle + " of a " + Gender[CurrentCancerNumber] + " diagnosed with " +  Cancertitle[CurrentCancerNumber]);	
	
	}
}


function updateaxes() {
//	find maximum hazard function value to control y axis
	if(ActiveGraph == "Hazard Function") {
		var maxy = 0
		for (var m = 1; m <= NModels; m++)	{
			var CurrentModel = Models[CurrentCancer]["Model"+m]
			if(CurrentModel.opacity>0) {
				var maxy = Math.max(maxy,Math.max.apply(Math, CurrentModel.ht))
			}
		}
	}
	else {
		maxy = 1
	}
// this transforms the scale we want to plot on to.
	x = d3.scaleLinear()
		.domain([0, maxtime])
		.range([ 0, graphwidth]);
    bisectSurvival = d3.bisector(function(d) { return d; }).left
	
	y = d3.scaleLinear()
		.domain([0, maxy])
		.range([graphheight, 0]);
// Define the axes (do not get drawn here)
// need to change ticks with different follow-up-time.
	xAxis = d3.axisBottom().scale(x).ticks(5);
	yAxis = d3.axisLeft().scale(y).ticks(5);


	plot.selectAll(".axis").remove();
	plot.selectAll(".grid").remove();
	plot.selectAll("text").remove();

	function make_x_axis() {        
    	return d3.axisBottom().scale(x).ticks(10)
	}

	function make_y_axis() {        
    	return d3.axisLeft().scale(y).ticks(5)
	}

plot.append("g")         
        .attr("class", "grid")
        .attr("transform", "translate(0," + graphheight + ")")
        .call(make_x_axis()
            .tickSize(-graphheight, 0, 0)
            .tickFormat("")
        )

    plot.append("g")         
        .attr("class", "grid")
        .call(make_y_axis()
            .tickSize(-graphwidth, 0, 0)
            .tickFormat("")
        )

// add xaxis		
// Add and draw the X Axis
	plot.append("g")
		.attr("class", "x axis")
		.attr("transform", "translate(0," + graphheight + ")")
		.call(xAxis);
// Add and draw the Y Axis
	plot.append("g")
		.attr("class", "y axis")
		.call(yAxis);
	
// axis titles

if (ActiveGraph == "Survival Function") {
 yTitle= "Relative survival"
}
if (ActiveGraph == "Hazard Function") {
 yTitle= "Excess hazard (per 1000 person years)"
}



for (var m = 0; m <= CancerTypes.length; m++)	{
	//console.log(Gender[m])
	if (Gender[m]=="male")	{
     GenderIndex="male"
    }
    if (Gender[m]=="female")	{
     GenderIndex= "female"
    }
}


	plot.append("text")
    	.attr("class", "xlabel")
    	.attr("text-anchor", "middle")
    	.attr("x", graphwidth/2)
    	.attr("y", graphheight + margin.bottom*0.8)
    	.text("Years since diagnosis");	
	
	plot.append("text")
    	.attr("class", "ylabel")
        .attr("transform", "rotate(-90)")
        .attr("y", 0-margin.left)
        .attr("x",0 - (graphheight / 2))
        .attr("dy", "1em")
        .style("text-anchor", "middle")
        .text(yTitle);					
}

function updategraph() {
	removelines();
	for (var m = 1; m <= NModels; m++)	{
		var CurrentModel = Models[CurrentCancer]["Model"+m]
		genSurvHaz(CurrentModel);
	}
	updateaxes()
	updatetitle()
	for (var m = 1; m <= NModels; m++)	{
		var CurrentModel = Models[CurrentCancer]["Model"+m]
		plotgraph(CurrentModel,"Model"+m,ShortGraphNames[GraphOptions.indexOf(ActiveGraph)]);
	}
};

function ChangeActiveGraph() {
	var selectValue = d3.select("#GraphSelectID").property("selectedIndex")
	ActiveGraph = GraphOptions[selectValue]
	updateaxes()
	updategraph()
}

function ChangeCancerType() {
	var selectValue = d3.select("#CancerSelectID").property("selectedIndex")
	CurrentCancer = CancerTypes[selectValue]
	CurrentCancerNumber = selectValue
	d3.select("#AgeSliderDiv")
		.select("svg")
		.remove();
	AgeSlider({DivName: "AgeSliderDiv",Xmin:18, Xmax:99, Ticks:20,InitVal:age})
	NewGraphInits()
	updategraph()
	AddCheckBoxAndTitles()
}

function ChangeReportedEstimates() {
	var selectValue = d3.select("#EstimatesSelectID").property("selectedIndex")
	CurrentMeasure = ReportedMeasures[selectValue]
	d3.select("#AgeSliderDiv")
		.select("svg")
		.remove();
	AgeSlider({DivName: "AgeSliderDiv",Xmin:18, Xmax:99, Ticks:20,InitVal:age})
	updategraph()
}

// remove lines from plot
function removelines(pathname) {
	plot.selectAll("path").remove()
};

// plot the survival/hazard curves
function plotgraph(Model,modelname,graphtype){
	plot.append("path")
		.attr("class","line")
		.attr("id",modelname)
		.attr("d",linefunction(Model[graphtype]))
		.style("opacity",Model["opacity"])
		.style("stroke",Model["LineColour"])

	d3.selectAll("path")
		.on("mouseover",PathMouseOver)
		.on("mouseout",PathMouseOut)
		
	function PathMouseOver() {
		var ModelID = this.id
		var timex = x.invert(d3.mouse(this)[0])
        var Yindex = bisectSurvival(timevar, timex)
		d3.select("#ModelList")
			.select("#Div"+ModelID)
				.style("border-color", function(){
					if(Models[CurrentCancer][ModelID].opacity=="1") return("black")
					else return("white");});
		
		for (var m = 1; m <= NModels; m++)	{
			var CurrentModel = Models[CurrentCancer]["Model"+m]
			if(CurrentModel.opacity>0) {
				if(ActiveGraph == "Survival Function") {
					var Ytemp = d3.format(",.1%")(Models[CurrentCancer]["Model"+m].St[Yindex])
				}
				else {
					var Ytemp = d3.format(".3n")(Models[CurrentCancer]["Model"+m].ht[Yindex])
				}
			}
			else {
				var Ytemp = ""
			}
			d3.select("#ModelList")
				.select("#Div"+"Model"+m)
				.select("label")
				.text(Models[CurrentCancer]["Model"+m].ModelTitle + ": "+ Ytemp)
		}
	}

	function PathMouseOut() {
		var ModelID = this.id
		d3.select("#ModelList")
			.select("#Div"+ModelID)
				.style("border-color", "white")
		for (var m = 1; m <= NModels; m++)	{
			var CurrentModel = Models[CurrentCancer]["Model"+m]
				d3.select("#ModelList")
					.select("#Div"+"Model"+m)
					.select("label")
					.text(Models[CurrentCancer]["Model"+m].ModelTitle)	
		}
	}
}

// Function to generate survival function from model coefficients
function genSurvHaz(Model) {
	Model.St = []
	Model.ht = []
//	obtain age spline terms
	
	//var ageadj = Math.max(age,Model.AgeCutOffLow)
	//var ageadj = Math.min(ageadj,Model.AgeCutOffHigh)
	//var agesplinevars = gensplines(ageadj,Model.ageknots)	
	//console.log(agesplinevars)
	
	var ageadj = Math.max(age,Model.AgeCutOffLow)
	//console.log(ageadj)
	var ageadj = Math.min(ageadj,Model.AgeCutOffHigh)
	var ageindex = ageadj - Model.AgeCutOffLow
	var agesplinevars = Model.agercs[ageindex]		
	//console.log(Model.agercs)
	

	for (var i=0;i<Nt;i++) {
		var betaindex = 0
		var rcsindex = 0
		var xb = 0
		if(CurrentMeasure=="Age-specific estimates"){
		if(ActiveGraph == "Hazard Function") {
 			var dxb = 0 
		}
// covariate effects (splines)		
		for (var j=0;j<(Model.ageknots.length-1);j++) {
			xb = xb + Model.beta[betaindex]*(agesplinevars[j])
			betaindex = betaindex + 1
		}
		
// baseline splines
		for (var j=0;j<Model.basedf;j++) {
			xb = xb + (Model.beta[betaindex]*Model.rcsvars[i][rcsindex])
			if(ActiveGraph == "Hazard Function") {
				dxb = dxb + (Model.beta[betaindex]*Model.drcsvars[i][rcsindex])
			}
			betaindex = betaindex + 1
			rcsindex = rcsindex + 1
		}
		
// time-dependent effects
		for (var j=0;j<(Model.tvcdflist.length);j++) {
			for (var k=0;k<(Model.tvcdflist[j]);k++) {
				xb = xb + Model.beta[betaindex]*Model.rcsvars[i][rcsindex]*agesplinevars[j]
				if(ActiveGraph == "Hazard Function") {
					dxb = dxb + Model.beta[betaindex]*Model.drcsvars[i][rcsindex]*agesplinevars[j]
				}				
				betaindex = betaindex + 1
				rcsindex = rcsindex + 1
			}
		}
		
// intercept
		xb = xb + Model.beta[betaindex]
		if(Model.scale=="hazard") {
			if(ActiveGraph == "Survival Function") {
				if(Model.timevar[i]>CondSurvTime) {
					Model.St[i] = Math.exp(-Math.exp(xb))
				}
				else {
					Model.St[i] = 1
				}
			}
			else if(ActiveGraph == "Hazard Function") {
				Model.ht[i] = 1000*dxb*Math.exp(xb)/timevar[i]
			}
		}
		else if(Model.scale=="odds") {
			if(ActiveGraph == "Survival Function") {
				Model.St[i] = 1/(1 + Math.exp(xb))
			}
			else if(ActiveGraph == "Hazard Function") {
				Model.ht[i] = 1000*dxb*Math.exp(xb)/(timevar[i]*(1+Math.exp(xb)))
			}
		}
	}
	
	if(CurrentMeasure=="Average estimates"){
		   console.log(Model.ms[i])
		   Model.St[i] = Model.ms[i]
		   Model.ht[i] = Model.mh[i]
	   }
	if(ActiveGraph == "Survival Function") {
	}
	else if(ActiveGraph == "Hazard Function") {
	}
	}
};

// function to evaluate spline values for given age and knots
function gensplines(xvar,knots){
	var splinevars = [];
	splinevars = [];
	splinevars[0] = xvar;

	for(var j=1;j<(knots.length-1);j++) {
		var lambda = (knots[(knots.length - 1)] - knots[j])/(knots[(knots.length -1)] - knots[0]);
		splinevars[j] = (xvar>knots[j])*Math.pow((xvar - knots[j]),3) - lambda*(xvar>knots[0])*Math.pow((xvar - knots[0]),3) 
			- (1-lambda)*(xvar>knots[(knots.length-1)])*Math.pow((xvar - knots[(knots.length-1)]),3);
	}
	return splinevars;
}
	
d3.selection.prototype.moveToFront = function() {
  return this.each(function(){
    this.parentNode.appendChild(this);
  });
};	


// Function to generate CI for survival function 
function genSurvCI(Model) {
// form x matrix
	var agesplinevars = gensplines(age,Model.ageknots)
	var Xmat = []
// loop over time points
	for (var i=0;i<Nt;i++) {
		var betaindex = 0
		var rcsindex = 0	
		Xmat[i] = []
// spline variables		
		for(var j=0;j<agesplinevars.length;j++) {
			Xmat[i][betaindex] = agesplinevars[j]
			var betaindex = betaindex + 1 
		}
// baseline splines
		for(var j=0;j<Model.basedf;j++) {
			Xmat[i][betaindex] = Model.rcsvars[i][rcsindex]
			var betaindex = betaindex + 1 
			var rcsindex = rcsindex + 1 
		}
// tvc splines		
		for (var j=0;j<(Model.tvcdflist.length);j++) {
			for (var k=0;k<(Model.tvcdflist[j]);k++) {
				Xmat[i][betaindex] = Model.rcsvars[i][rcsindex]*agesplinevars[j]
				betaindex = betaindex + 1
				rcsindex = rcsindex + 1
			}
		}
		Xmat[i][betaindex] = 1
	}
	var XmatV = multiplyMatrices(Xmat,Model.Vcov)
	var se = extractVariance(XmatV,Xmat)
	Model.StLCI = []
	Model.StUCI = []
	for (var i=0;i<Nt;i++) {
		Model.StLCI[i] = Math.exp(-Math.exp(Math.log(-Math.log(Model.St[i])) + 1.96*se[i] ))
		Model.StUCI[i] = Math.exp(-Math.exp(Math.log(-Math.log(Model.St[i])) - 1.96*se[i] ))
	}
}

function multiplyMatrices(m1, m2) {
    var result = [];
    for (var i = 0; i < m1.length; i++) {
        result[i] = [];
        for (var j = 0; j < m2[0].length; j++) {
            var sum = 0;
            for (var k = 0; k < m1[0].length; k++) {
                sum += m1[i][k] * m2[k][j];
            }
            result[i][j] = sum;
        }
    }
    return result;
}

function extractVariance(m1,m2) {
	var result = []
	for(var i = 0; i < m1.length; i++) {
		result[i] = 0
		for(var j = 0; j < m1[i].length; j++) {
			result [i] += m1[i][j]*m2[i][j]
		}
		result[i] = Math.sqrt(result[i])
	}
    return result;
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
	var InitVal = SliderOptions.InitVal || (Xmin+Xmax)/2;
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
		
	var BarWidth = 9
	var Histy = d3.scaleLinear()
		.domain([0,d3.max(Models[CurrentCancer].Model1.AgeFreq)])
		.range([HistHeight, 0])
	
	var xAxis = d3.axisBottom().scale(Sliderx)
		.ticks(Ticks)		
		.tickValues(TickValues)
		.tickSize(2);

// Define SVG area	
 	Sliders[DivName] = d3.select("#"+DivName)
		.append("svg")
		.attr("width", DivWidth)
		.attr("height", SVGHeight)
		.attr('class', "SVGSlider")

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
			.call(xAxis);	
	}

// Draw Rectangle	
	d3.select("#"+DivName+"Plot")
		.append("rect")
		.attr("class","SliderRect")
		.attr("width",SliderWidth)
		.attr("height", SliderHeight)
		.attr("x", 0)
 		.attr("y", HistHeight)


	Sliders[DivName].CurrentValue = InitVal

// make all bars blue			
	d3.select("#"+DivName+"Plot")
		.selectAll("bar")
		.data(Models[CurrentCancer].Model1.AgeFreq)
			.enter().append("rect")
      		.style("fill", "steelblue")
      		.attr("x", function(d,i) {return Sliderx(Models[CurrentCancer].Model1.AgeList[i]- 0.5) ; })
      		.attr("width", BarWidth)
		     .attr("y", function(d) { return Histy(d); })
			.attr("id",function(d,i) {return "BarAge" + Models[CurrentCancer].Model1.AgeList[i]})
		    .attr("height", function(d) { return HistHeight - Histy(d);})

// make bar for current age value red			
	if(CurrentMeasure == "Age-specific estimates") {
		d3.select("#BarAge"+Math.round(age))
			.style("fill","red")
	}

var SliderDrag = d3.drag()
		.on("start", function() {
			d3.event.sourceEvent.stopPropagation();
		})
		.on("drag", function(){
				var newx = d3.event.x;
				if(inrange(newx,Sliderx(Xmin),Sliderx(Xmax)) & CurrentMeasure == "Age-specific estimates") {
					d3.select("#BarAge"+Math.round(age))
  						.style("fill","steelblue")
					age = Math.round(Sliderx.invert(newx))

					d3.select(this)
						.attr("cx", Sliderx(age))

					d3.select("#BarAge"+Math.round(age))
  						.style("fill","red")					
					updategraph()
				}
		})
		.on("end", function(){
				d3.select(this)
					.attr("opacity",0.8);

		});

// add circle to drag bar
	if(CurrentMeasure == "Age-specific estimates") {
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
		
}
	

}
// End of Main Graph Function
