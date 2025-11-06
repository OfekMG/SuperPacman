
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
			 ////////////////////////
		  // Dots
					input    logic DotsDrawingRequest, 
					input		logic	[7:0] DotsRGB,

					// add the box here 
					input		logic	BoxDrwaingRequest, // two set of inputs per unit
					input		logic	[7:0] BoxRGB,
					
		//
		// ghost
					input		logic	ghostDrawingRequest, // two set of inputs per unit
					input		logic	[7:0] ghostRGB,
									 ////////////////////////
		  // Superpacman
					input    logic SuperDrawingRequest, 
					input		logic	[7:0] SuperRGB,	
			 ////////////////////////
		  // pickaxe
					input    logic pickaxeDrawingRequest, 
					input		logic	[7:0] pickaxeRGB,
			// pickaxe_cntr
					input    logic pickaxecntrDrawingRequest, 
					input		logic	[7:0] pickaxecntrRGB,
			// ghost2
					input		logic	ghost2DrawingRequest, // two set of inputs per unit
					input		logic	[7:0] ghost2RGB,
		// ghost3
					input		logic	ghost3DrawingRequest, // two set of inputs per unit
					input		logic	[7:0] ghost3RGB,
		// ghost4
					input		logic	ghost4DrawingRequest, // two set of inputs per unit
					input		logic	[7:0] ghost4RGB,
					
		// gameover
					input logic darken,
		// woodenwall
					input		logic	woodenwallDrawingRequest, // two set of inputs per unit
					input		logic	[7:0] woodenwallRGB,
					input    logic win
								
					
);

always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
			RGBOut	<= 8'b0;
	end
	
	else begin
		if (darken) begin
            if (pointsDrawingRequest)
                RGBOut <= pointsRGB;       // Show score even when darkened
            else
                RGBOut <= 8'h00;           // Everything else black
        end
		 else if (win) begin
            if (pointsDrawingRequest)
                RGBOut <= pointsRGB;       // Show score even when darkened
            else
                RGBOut <= 8'hFF;           // Everything else black
        end
		else if (smileyDrawingRequest == 1'b1 )   
			RGBOut <= smileyRGB;  //first priority 
		else if(ghostDrawingRequest == 1'b1)
			RGBOut <= ghostRGB;
		else if (woodenwallDrawingRequest == 1'b1)
				RGBOut <= woodenwallRGB;
		else if(ghost2DrawingRequest == 1'b1)
			RGBOut <= ghost2RGB;
		else if(ghost3DrawingRequest == 1'b1)
			RGBOut <= ghost3RGB;
		else if(ghost4DrawingRequest == 1'b1)
			RGBOut <= ghost4RGB;
		else if (BoxDrwaingRequest == 1'b1 )   
			RGBOut <= BoxRGB;  //2nd priority 
		else if (DotsDrawingRequest == 1'b1)
				RGBOut <= DotsRGB;
		else if (SuperDrawingRequest == 1'b1)
				RGBOut <= SuperRGB;
		else if (pointsDrawingRequest == 1'b1)
			RGBOut <= pointsRGB;
		else if (livesDrawingRequest == 1'b1)
				RGBOut <= livesRGB;
		else if (pickaxeDrawingRequest == 1'b1)
				RGBOut <= pickaxeRGB;
		else if (pickaxecntrDrawingRequest == 1'b1)
				RGBOut <= pickaxecntrRGB;



	





//---------------------------------------------------------------------------------		
 		else if (HartDrawingRequest == 1'b1)
				RGBOut <= hartRGB;
		else if (BGDrawingRequest == 1'b1)
				RGBOut <= backGroundRGB ;
		else RGBOut <= RGB_MIF ;// last priority 
		end ; 
	end

endmodule


