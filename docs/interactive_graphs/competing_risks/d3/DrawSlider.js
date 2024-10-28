


function DrawSlider(SliderOptions) {
// Set defaults
	var DivName = SliderOptions.DivName || undefined;
	var Xmin = SliderOptions.Xmin || 0;
	var Xmax = SliderOptions.Xmax || 100;
	var SliderWidthProp =  SliderOptions.SliderWidthProp || 0.8;
	var DrawAxis = SliderOptions.DrawAxis || "true";
	var AxisSpace = SliderOptions.AxisSpace || 25;
	var SliderHeight = SliderOptions.SliderHeight || 5;
	var Ticks = SliderOptions.Ticks || 5;
	var TickValues = SliderOptions.TickValues || undefined;
	var InitVal = SliderOptions.InitVal || (Xmin+Xmax)/2;
	var Label = SliderOptions.Label || "";
	if(Label == "") {
		var LabelWidth = 0
	}
	else {
		var LabelWidth = SliderOptions.LabelWidth || 0.1
	}
	
// Widths and Heights
	var DivWidth = parseInt(d3.select("#"+DivName).style('width'), 10)
	var	SliderWidth = DivWidth*SliderWidthProp
	var SVGHeight = AxisSpace + SliderHeight
	var marginleft = DivWidth*(1-SliderWidthProp)/2
	var marginright = DivWidth*(1-SliderWidthProp)/2
	var margintop = SliderHeight*0.5
	
	var Sliderx = d3.scale.linear()
		.domain([Xmin, Xmax])
		.range([ 0, SliderWidth]);
	
	var xAxis = d3.svg.axis().scale(Sliderx)
		.orient("bottom").ticks(Ticks)		
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
		.attr('height', SliderHeight)
		.attr("id",DivName+"Plot")
	if(DrawAxis == "true") {
		d3.select("#"+DivName+"Plot")
			.append("g")
			.attr("class", "SliderAxis")
			.attr("transform", "translate(0," + SliderHeight + ")")
			.call(xAxis);	
	}

// Draw Rectangle	
	d3.select("#"+DivName+"Plot")
		.append("rect")
		.attr("class","SliderRect")
		.attr("width",SliderWidth)
		.attr("height", SliderHeight)
		.attr("x", 0)
 		.attr("y", 0)
		.on("click", function() {
			var newx = d3.mouse(this)[0];
			d3.select("#"+DivName+"Circle")
				.attr("cx", newx)
				Sliders[DivName].CurrentValue = Sliderx.invert(newx)
		})

//	var drag = d3.behavior.drag()
//        .on("drag", function () {alert("drag")})
//       .on("dragend", function () {alert("dragEnd")});

//	add circle
	Sliders[DivName].CurrentValue = InitVal

var SliderDrag = d3.behavior.drag()
		.on("dragstart", function() {
			d3.event.sourceEvent.stopPropagation();
		})
		.on("drag", function(){
				var newx = d3.event.x;
				if(inrange(newx,Sliderx(Xmin),Sliderx(Xmax))) {
					d3.select(this)
						.attr("cx", newx)
					Sliders[DivName].CurrentValue = Sliderx.invert(newx)
					UpdateGraph()
				}
		})
		.on("dragend", function(){
				d3.select(this)
					.attr("opacity",0.8);

		});

	d3.select("#"+DivName+"Plot")
		.append("circle")
		.attr("class","SliderCircle")
		.attr("id",DivName+"Circle")
		.attr("cx", function (d) {return Sliderx(InitVal); })
		.attr("cy", SliderHeight/2)
		.attr("r", SliderHeight)
		.call(SliderDrag)
		
	function inrange(x, min, max) {
		return x >= min && x <= max;
	}		
		
}

