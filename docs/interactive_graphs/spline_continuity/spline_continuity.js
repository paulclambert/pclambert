// To Do
// add confidence intervals?

ExampleList = [{
	"Number": 1
	},{
	"Number": 2
	},{
	"Number": 3
	},{
	"Number": 4
	},{
	"Number": 5
	}	
]

knots = [0.05,0.25,0.75,0.95];
degree = 3;
contstart = 3
Example = 1;
Genxy(1,150);
fitmodel(ydata,xdata,degree);

margin = {top: 20, right: 250, bottom: 100, left: 60}
		, width = 1210 - margin.left - margin.right
		, height = 600 - margin.top - margin.bottom;

SplineType = [{
	"name":"Linear",
	"degree": 1
	},{
	"name":"Quadratic",
	"degree": 2	
	},{
	"name":"Cubic",
	"degree": 3
	}];		
boxwidth = 0.14		

Continuity = [{
	"name":"None",
	"contstart": 0
	},{
	"name":"0th Derivative",
	"contstart": 1	
	},{
	"name":"1st Derivative",
	"contstart": 2
	},{	
	"name":"2nd Derivative",
	"contstart": 3
	}
	];		

ModelText = [{
	"name":"Type of Spline",
	"x":920,
	"y":10
},{
	"name":"No of Parameters: ",
	"x":920,
	"y":40
},{
	"name":"R-squared: ",
	"x":920,
	"y":70
},{
	"name":"Adj. R-squared: ",
	"x":920,
	"y":100
}];

		
var knotdrag = d3.behavior.drag()
		.on("dragstart", function() {
			d3.event.sourceEvent.stopPropagation();
			knotindex =  Number(this.id);
			knotmin = (knotindex == 0) ? 0:(knots[knotindex-1]) + 0.01;
			knotmax = (knotindex == knots.length-1) ? 1:(knots[knotindex+1])-0.01;
		})
		
		.on("drag", function(){
			var x = d3.event.x;
			if (inrange(x/width, knotmin, knotmax)) {
				d3.select(this)
					.attr("x1", x)
					.attr("x2", x)
					.attr("stroke","rgb(255,180,0)");
				knots[knotindex] = x/width;
				d3.selectAll("path.line").remove();
				fitmodel(ydata,xdata,degree);
				drawfitted();
			}
		})
    
		.on("dragend", function(){
			d3.select(this)
				.attr("stroke","rgb(100,200,140)");
			d3.selectAll("path.line").remove();
			fitmodel(ydata,xdata,degree);
			drawfitted();
		});

var linefunction = d3.svg.line()
	.x(function(d,i) {return x(xdata[i]);})
	.y(function(d) {return y(d);})
	.interpolate("linear")
	.defined(function(d,i) { return linedefine[i]});

var chart = d3.select('.content')
	.append('svg:svg')
	.attr('width', width + margin.right + margin.left)
	.attr('height', height + margin.top + margin.bottom)
	.attr('class', 'chart')

var main = chart.append('g')
	.attr('transform', 'translate(' + margin.left + ',' + margin.top + ')')
	.attr('width', width)
	.attr('height', height)
	.attr('class', 'main')   
	
		
updategraph()	

g = main.append("svg:g"); 
    
g.selectAll("scatter-dots")
	.data(ydata)
	.enter().append("svg:circle")
		.attr("cy", function(d) { return y(d); } )
		.attr("cx", function (d,i) { return x(xdata[i]);} )
		.attr("r", 5);

drawsplinemenu();
drawexamplemenu();
drawcontmenu();	
drawknots();
drawfitted();

function Genxy(eg,N){
	var d = {};
	d.x = [];
	d.y = [];
	var ysum = 0
	var maxx = ((N-1)-3/8)/(N+0.25)
	for (i=0;i<N;i++) {
		d.x[i] = (i+1)/N;
		if(eg == 1) {d.y[i] =  1 + 20*Math.log(d.x[i]) + 2*Math.sqrt(d.x[i]) + 0.2*Math.pow(d.x[i],3) + 16*Normal()}
		else if(eg == 2) {d.y[i] =  Math.sin(d.x[i]*10) + 0.4*Normal()}
		else if(eg == 3) {d.y[i] =  -4*Math.log(d.x[i]) + Math.pow(2*d.x[i],3) + 2/d.x[i] + 13*Normal()}
		else if(eg == 4) {d.y[i] =  0.23*Math.pow(d.x[i],3) + 3*Math.pow(3*d.x[i],2) + 4*Normal()}
		else if(eg == 5) {d.y[i] =  0.05*d.x[i] - 0.05*Math.pow(d.x[i],2) + 0.007*Math.log(d.x[i]) + 0.003*Normal()}
	
		ysum = ysum + d.y[i]
	}
	ybar = ysum/N
	xdata = d.x;
	ydata = d.y;
};

function Normal(mu, sigma) {
	var n = arguments.length;
	if (n < 2) sigma = 1;
	if (n < 1) mu = 0;
	do {
		var x, y, r;
		x = Math.random() * 2 - 1;
		y = Math.random() * 2 - 1;
		r = x * x + y * y;
	}
	while(r>=1);
	return mu + sigma * x * Math.sqrt(-2 * Math.log(r) / r);
}

function ClickAxis(d) {
		coordinates = d3.mouse(this);
		xpos = coordinates[0]/width;
		knots.push(xpos);
		knots = knots.sort(d3.ascending);
		d3.selectAll("line.knots").remove();
		drawknots();
		fitmodel(ydata,xdata,degree);
		d3.selectAll("path.line").transition()
			.delay(0)
			.duration(1000)
			.attr("d",linefunction(mu));
		d3.selectAll("text.ModelText").remove()
		addmodeltext();			
}

function inrange(x, min, max) {
  return x >= min && x <= max;
}

function updategraph() {
	x = d3.scale.linear()
		.domain([0, d3.max(xdata)])
		.range([ 0, width ]);
	yrange = d3.max(ydata) -  d3.min(ydata)	
	y = d3.scale.linear()
		.domain([d3.min(ydata)-0.25*yrange, d3.max(ydata)+0.25*yrange])
		.range([ height, 0 ]);
         
// draw the x axis
	var xAxis = d3.svg.axis()
		.scale(x)
		.orient('bottom')
		.tickFormat(function (d) { return ''; });	

	main.append('g')
		.attr('transform', 'translate(0,' + height + ')')
		.attr('class', 'main axis date')
		.call(xAxis)
		.on("click", ClickAxis);

// draw the y axis
	var yAxis = d3.svg.axis()
		.scale(y)
		.orient('left')
		.tickFormat(function (d) { return ''; });	

	main.append('g')
		.attr('transform', 'translate(0,0)')
		.attr('class', 'main axis date')
		.call(yAxis);
}

function drawsplinemenu() {
	g.selectAll("rect.Spline")
		.data(SplineType)
		.enter()
		.append("rect")
		.attr("class","Spline")
		.attr("width",x(boxwidth-0.005))
		.attr("height",30)
		.attr("x", function(d,i) { return x(boxwidth*i+0.01); })
		.attr("y", 520)
	    .attr("rx", 6)
	    .attr("ry", 6)
		.attr("fill", function(d) { if(degree==d.degree) {return "rgb(10, 150, 20)"}
									else {return "rgb(10, 150, 200)"}})
		.on("click",SplineSelect);

	g.append("text")
		.attr("class","SplineTitle")
		.text("Type of Spline")
		.attr("x",x(0.2))
		.attr("y",515)
		.style("text-anchor", "middle")
		.style("font-size","20px")
		.style("font-weight","bold")		
	
	g.selectAll("text.SplineList")		  
		.data(SplineType)
		.enter()
		.append("text")
		.attr("class","SplineList")	
		.text(function(d){ return d.name;})
		.attr("x", function(d,i) {return x(boxwidth*i + boxwidth/2 + 0.01);})
		.attr("y", 540)
		.attr("fill",function(d){return "white";})
		.style("text-anchor", "middle")
		.style("font-size","15px")
		.on("click", SplineSelect);
}

function SplineSelect(d) { 
		d3.selectAll("rect.Spline").remove();
		d3.selectAll("text.SplineList").remove();
		d3.selectAll("text.SplineTitle").remove();
		degree = d.degree;
		if(contstart>degree) {
			contstart = degree
			d3.selectAll("rect.Cont").remove();
			d3.selectAll("text.ContList").remove();
			d3.selectAll("text.ContTitle").remove();			
		}		
		fitmodel(ydata,xdata,degree);
		d3.selectAll("path.line").transition()
			.delay(10)
			.duration(1000)
			.attr("d",linefunction(mu));
		drawsplinemenu();
		d3.selectAll("text.ModelText").remove()
		addmodeltext();
		drawcontmenu();
}	

function drawcontmenu() {
	g.selectAll("rect.Cont")
	.data(Continuity)
	.enter()
	.append("rect")
	.attr("class","Cont")
	.attr("width",x(boxwidth-0.005))
	.attr("height",30)
	.attr("x", function(d,i) { return x(0.5+boxwidth*i+0.01); })
	.attr("y", 520)
    .attr("rx", 6)
    .attr("ry", 6)
	.attr("fill", function(d) { if(contstart==d.contstart) {return "rgb(10, 150, 20)"}
	else {return "rgb(10, 150, 200)"}})
	.on("click",ContSelect);

	g.append("text")
		.attr("class","ContTitle")
		.text("Continuity Restrictions")
		.attr("x",x(0.75))
		.attr("y",515)
		.style("text-anchor", "middle")
		.style("font-size","20px")
		.style("font-weight","bold")

	g.selectAll("text.ContList")		  
	.data(Continuity)
	.enter()
	.append("text")
	.attr("class","ContList")	
	.text(function(d){ return d.name;})
	.attr("x", function(d,i) {return x(0.5+boxwidth*i + boxwidth/2 + 0.01);})
	.attr("y", 540)
	.attr("fill",function(d){return "white";})
	.style("text-anchor", "middle")
	.style("font-size","15px")
	.on("click", ContSelect);
}

function ContSelect(d) { 
		d3.selectAll("rect.Cont").remove();
		d3.selectAll("text.ContList").remove();
		d3.selectAll("text.ContTitle").remove();
		if(degree>=d.contstart) {
			contstart = d.contstart;
			fitmodel(ydata,xdata,degree);
			d3.selectAll("path.line").transition()
				.delay(10)
				.duration(1000)
				.attr("d",linefunction(mu));
		}
			drawcontmenu();
			d3.selectAll("text.ModelText").remove()
			addmodeltext();	
	
}	

function drawexamplemenu() {
	g.selectAll("rect.Example")
	.data(ExampleList)
	.enter()
	.append("rect")
	.attr("class","Example")
	.attr("width",x(boxwidth))
	.attr("height",28)
	.attr("x", 960)
	.attr("y", function(d) {return 200 + d.Number*30})
    .attr("rx", 6)
    .attr("ry", 6)
	.attr("fill", function(d) { if(Example==d.Number) {return "rgb(10, 150, 20)"}
	else {return "rgb(10, 150, 200)"}})
	.on("click",ExampleSelect);
	
	g.selectAll("text.Example")		  
	.data(ExampleList)
	.enter()
	.append("text")
	.attr("class","Example")	
	.text(function(d){ return "Example:" + d.Number;})
	.attr("x", 940 + x(boxwidth/2))
	.attr("y", function(d) {return 200 + 20 + d.Number*30})
	.attr("fill",function(d){return "white";})
	.style("text-anchor", "middle")
	.style("font-size","15px")
	.on("click",ExampleSelect);
}

function ExampleSelect(d) {
	d3.selectAll("rect.Example").remove();
	d3.selectAll("text.Example").remove();
	Example = d.Number;
	Genxy(Example,150);
	d3.selectAll(".axis").remove();		
	updategraph()	
		
	d3.selectAll("circle")
		.transition()
		.duration(1000)
		.attr("cy", function(d,i) {return(y(ydata[i]));})
	
	fitmodel(ydata,xdata,degree);
	d3.selectAll("path.line").transition()
		.delay(0)
		.duration(1000)
		.attr("d",linefunction(mu));
	drawexamplemenu();
	d3.selectAll("text.ModelText").remove()
	addmodeltext();		
}	

function drawfitted() {
	main.append("svg:path")
		.attr("class","line")
		.attr("d",linefunction(mu));
	d3.selectAll("text.ModelText").remove()
	addmodeltext();
};

function addmodeltext() {
	g.selectAll("text.ModelText")
		.data(ModelText)
		.enter()
		.append("text")
		.attr("class","ModelText")	
		.text(function(d,i){ 
			if (i==0) {return SplineType[degree-1].name + " Spline";}
			else if(i==1) {return d.name + Nparams;}
			else if(i==2) {return d.name + R2}
			else if(i==3) {return d.name + R2adj}})
		.attr("x", function(d) {return d.x})
		.attr("y", function(d) {return d.y})
		.attr("fill",function(d){return "b";})
		.style("text-anchor", "left")
		.style("font-size","20px")
		.style("text-decoration",function(d,i) {if(i==0) return "underline"
												else return "none"	})		
};
	
function drawknots(){
	gk = main.append("svg:g").selectAll("line.knots")
		.data(knots, function(d) { return(d); })
		.enter().append("svg:line")
		.attr("class","knots")
		.attr("y1",0)
		.attr("y2",height)
		.attr("x1", function(d){ return (d*width)})
		.attr("x2", function(d){ return (d*width)})
		.attr("stroke", "rgb(100,200,140)") 
		.attr("stroke-width",3)
		.attr("id", function(d,i) {return i;})
		.on("click",dropknot)
		.on("mouseover",function() {
			d3.select(this)
				.attr("stroke-width",5)})
		.on("mouseout",function() {
			d3.select(this)
				.attr("stroke-width",3)})
		.call(knotdrag);
}

function dropknot(d) {
	if (d3.event.defaultPrevented) return;
	knots.splice(Number(this.id),1);
	d3.selectAll("line.knots").remove();
	drawknots();
	fitmodel(ydata,xdata,degree);
	d3.selectAll("path.line").transition()
		.delay(0)
		.duration(1000)
		.attr("d",linefunction(mu));
	d3.selectAll("text.ModelText").remove()
	addmodeltext();		
}

function fitmodel(y,x,degree) {
	Xmatrix = gensplines(x,degree,contstart);
	Q = QR(Xmatrix);
	Nparams = Q[0].length;
	R = Rmatrix(Xmatrix,Q);
	Qty = []
	for(var j = 0;j<Nparams;j++) {
		var sum = 0;
		for(var i =0;i<Q.length;i++) {
			sum = sum + Q[i][j]*y[i];
		};
		Qty[j] = sum;
	};
	
	//beta matrix
	beta = [];
	var betarows = Nparams - 1
	
	beta[betarows] = Qty[betarows]/R[betarows][betarows];
	for(var j = 0;j<=(betarows-1);j++) {
		var k = betarows - j - 1;
		var sum = Qty[k]
		for(var i = (k+1);i<=betarows;i++) {
			sum = sum - R[k][i]*beta[i]

		}
		beta[k] = sum/R[k][k]
	}
	// predicted values & R2
	mu = []
	linedefine = []
	var TSS = 0
	var SSE = 0
	var startknot = 0
	for(var i=0;i<x.length;i++) {
		mu[i] = 0;
		for(var j =0;j<Nparams;j++) {
			mu[i] = mu[i] + beta[j]*Xmatrix[i][j]
		}
		TSS = TSS + Math.pow(y[i]-ybar,2);
		SSE = SSE + Math.pow(y[i]-mu[i],2);

		linedefine[i] = 1
		var found = 0
		if(contstart==0) {
			for(var k = startknot;k<knots.length;k++) {
				if(x[i]>knots[k] & !found) {
					linedefine[i] = 0;
					var found = 1;
					startknot = startknot + 1;
				}
			}
		}
	}
	R2 = (TSS - SSE)/TSS;
	R2 = R2.toFixed(3);
	R2adj = R2 - (1-R2)*Nparams/(x.length - Nparams - 1);
	R2adj = R2adj.toFixed(3);
};

function gensplines(x,degree,contstart) {
	var Xmat = []
	for(i=0;i<=x.length-1;i++){
		Xmat[i] = [];
		for(var j=1;j<=degree;j++){
			Xmat[i][j-1] = Math.pow(x[i],j);
		}
		var index = degree
		for(var k=0;k<=knots.length-1;k++) {
			for(var j=contstart;j<=degree;j++) {
				Xmat[i][index] = (x[i]>knots[k])*Math.pow((x[i] - knots[k]),j);
				index = index + 1
			}
		}
		Xmat[i][index] = 1
	}
	return Xmat;
};

function QR(A) {
	var rows = A.length;
	var cols = A[1].length;
	var Q = [];
	var normc = normalise(A,0);
	for(var i=0;i<rows;i++) {
		Q[i] = [];
		Q[i][0] = -A[i][0]/Math.sqrt(normc)
	}	
	for(var j=1;j<cols;j++) {
		var cp = [];
		for(var k=0, tmp = j-1;k<=tmp;k++) {
			cp[k] = Cprod(Q,k,A,j);
		};
	
		normc = 0;

		for(var i=0;i<rows;i++) {
			Q[i][j] = A[i][j];
				for(k=0;k<=j-1;k++) {
					Q[i][j] = Q[i][j] - cp[k]*Q[i][k];
				}
				normc = normc + Math.pow(Q[i][j],2);
		}
		for(i=0;i<rows;i++) {
			Q[i][j] = -Q[i][j]/Math.sqrt(normc);
		}
	}
	return Q
};

function Rmatrix(A,Q) { // Triangular R matrix
	var R = []
	var cols = Q[1].length
	for(var j=0;j<cols;j++) {
		R[j] = [];
		for(var k=j;k<cols;k++) {
			R[j][k] = Cprod(A,k,Q,j);
		}
	}
	return R
};

function normalise(Z,col) {
	var rows = Z.length;
	var sum = 0;
	for(var ii=0;ii<rows;ii++) {
		sum = sum + Math.pow(Z[ii][col],2);
	};
	return sum;
};

function Cprod(X1,col1,X2,col2) {
	var sum = 0;
	for(var kk=0;kk<X1.length;kk++) {
		sum = sum + X1[kk][col1] * X2[kk][col2]
	};
	return sum;
};


