
// (c) Technion IIT, Department of Electrical Engineering 2025 
//-- Alex Grinshpun Apr 2017
//-- Dudy Nov 13 2017
// SystemVerilog version Alex Grinshpun May 2018
// coding convention dudy December 2018

//-- Eyal Lev 31 Jan 2021

module	objects_mux	(	
//		--------	Clock Input	 	
					input		logic	clk,
					input		logic	resetN,
		   // smiley 
					input		logic	smileyDrawingRequest, // two set of inputs per unit
					input		logic	[7:0] smileyRGB, 
					     
			
			  
			  
		  ////////////////////////
		  // background 
					input    logic HartDrawingRequest, // box of numbers
					input		logic	[7:0] hartRGB,   
					input		logic	[7:0] backGroundRGB, 
					input		logic	BGDrawingRequest, 
					input		logic	[7:0] RGB_MIF, 
			  
				   output	logic	[7:0] RGBOut,
			////////////////////////
		  // Lives
					input    logic livesDrawingRequest, 
					input		logic	[7:0] livesRGB,
			 ////////////////////////
		  // Scoreboard
					input 	logic pointsDrawingRequest,
					input 	logic [7:0] pointsRGB,		
							
					
					// add the box here 
					input		logic	BoxDrwaingRequest, // two set of inputs per unit
					input		logic	[7:0] BoxRGB,
					
		//
		// ghost
					input		logic	ghostDrawingRequest, // two set of inputs per unit
					input		logic	[7:0] ghostRGB
);

always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
			RGBOut	<= 8'b0;
	end
	
	else begin
		if (smileyDrawingRequest == 1'b1 )   
			RGBOut <= smileyRGB;  //first priority 
		else if(ghostDrawingRequest == 1'b1)
			RGBOut <= ghostRGB;
//--- add logic for box here ------------------------------------------------------		
		else if (BoxDrwaingRequest == 1'b1 )   
			RGBOut <= BoxRGB;  //2nd priority 
		else if (pointsDrawingRequest == 1'b1)
			RGBOut <= pointsRGB;
		else if (livesDrawingRequest == 1'b1)
				RGBOut <= livesRGB;


	





//---------------------------------------------------------------------------------		
 		else if (HartDrawingRequest == 1'b1)
				RGBOut <= hartRGB;
		else if (BGDrawingRequest == 1'b1)
				RGBOut <= backGroundRGB ;
		else RGBOut <= RGB_MIF ;// last priority 
		end ; 
	end

endmodule


