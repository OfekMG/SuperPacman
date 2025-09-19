// HartsMatrixBitMap File 
// A two level bitmap. displaying harts on the screen Feb 2025 
//(c) Technion IIT, Department of Electrical Engineering 2025 



module LivesMatrixBitMap (
    input  logic        clk,
    input  logic        resetN,
    input  logic [10:0] offsetX,  // offset from top-left position
    input  logic [10:0] offsetY,
    input  logic        InsideRectangle,            // pixel is in bar
    input  logic        strike,   // one-cycle hit

    output logic        drawingRequest,             // pixel must be drawn
    output logic [7:0]  RGBout,
    output logic        gameOver                // one-cycle when last heart has already vanished
);
 

    localparam logic [7:0] TRANSPARENT_ENCODING = 8'hFF ;

    localparam int TILE_NUMBER_OF_X_BITS   = 5;  // 2^5 = 32
    localparam int TILE_NUMBER_OF_Y_BITS   = 5;  // 2^5 = 32
    localparam int MAZE_NUMBER_OF__X_BITS  = 2;  // 2^2 = 4

    localparam int TILE_WIDTH_X  = 1 << TILE_NUMBER_OF_X_BITS ;
    localparam int TILE_HEIGHT_Y = 1 << TILE_NUMBER_OF_Y_BITS ;
    localparam int MAZE_WIDTH_X  = 1 << MAZE_NUMBER_OF__X_BITS ;

    logic [TILE_NUMBER_OF_X_BITS-1:0] offsetX_LSB;
    logic [TILE_NUMBER_OF_Y_BITS-1:0] offsetY_LSB;
    logic [MAZE_NUMBER_OF__X_BITS-1:0] offsetX_MSB;

    assign offsetX_LSB = offsetX[TILE_NUMBER_OF_X_BITS-1:0];
    assign offsetY_LSB = offsetY[TILE_NUMBER_OF_Y_BITS-1:0];
    assign offsetX_MSB = offsetX[TILE_NUMBER_OF_X_BITS+MAZE_NUMBER_OF__X_BITS-1:
                                 TILE_NUMBER_OF_X_BITS];
	 logic [1:0] lives;
	 logic oneLeft;	


    logic [0:MAZE_WIDTH_X-1] MazeBitMapMask ;
    logic [0:MAZE_WIDTH_X-1] MazeDefaultBitMapMask = 4'b1110;
 

 logic [3:0] [0:(TILE_HEIGHT_Y-1)][0:(TILE_WIDTH_X-1)] [7:0]  object_colors  = {
{8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hCD, 8'hAC, 8'hCD, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hC5, 8'hC1, 8'hC1, 8'hC5, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF },
{8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hB0, 8'h78, 8'h3C, 8'h1C, 8'h55, 8'hCD, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hA9, 8'h62, 8'h87, 8'hC7, 8'hE7, 8'hE3, 8'hC2, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF },
{8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hD1, 8'h9C, 8'h7C, 8'h3C, 8'h3C, 8'h1D, 8'h39, 8'hAD, 8'hFF, 8'hFF, 8'hFF, 8'hA9, 8'h26, 8'h47, 8'h87, 8'hC3, 8'hE7, 8'hE7, 8'hE7, 8'hC6, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF },
{8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hD4, 8'hBC, 8'h7C, 8'h3C, 8'h1C, 8'h3D, 8'h1E, 8'h3A, 8'hAD, 8'hFF, 8'hCE, 8'h26, 8'h27, 8'h67, 8'h83, 8'hC7, 8'hE7, 8'hE7, 8'hE3, 8'hE2, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF },
{8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hD8, 8'hBC, 8'h7C, 8'h5C, 8'h3C, 8'h1D, 8'h3E, 8'h1E, 8'h3A, 8'hCD, 8'h4E, 8'h0B, 8'h27, 8'h47, 8'h87, 8'hA3, 8'hE7, 8'hE7, 8'hE7, 8'hE6, 8'hEE, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF },
{8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hF1, 8'hDC, 8'hBC, 8'h7C, 8'h5C, 8'h3C, 8'h3D, 8'h1D, 8'h1E, 8'h1F, 8'h52, 8'h2F, 8'h0B, 8'h27, 8'h47, 8'h87, 8'hA7, 8'hE7, 8'hE7, 8'hE7, 8'hE7, 8'hEA, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF },
{8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hF1, 8'hFC, 8'hBC, 8'h9C, 8'h5C, 8'h3C, 8'h1D, 8'h3D, 8'h1E, 8'h1F, 8'h1B, 8'h13, 8'h0B, 8'h27, 8'h47, 8'h86, 8'hA6, 8'hE7, 8'hE7, 8'hE7, 8'hE3, 8'hE6, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF },
{8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hF0, 8'hFC, 8'hBC, 8'h9C, 8'h5C, 8'h3C, 8'h3D, 8'h1D, 8'h1E, 8'h1F, 8'h1B, 8'h13, 8'h0F, 8'h27, 8'h47, 8'hA0, 8'hA0, 8'hC6, 8'hE7, 8'hE7, 8'hE7, 8'hE6, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF },
{8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hF0, 8'hFC, 8'hBC, 8'h9C, 8'h5C, 8'h3C, 8'h1D, 8'h3D, 8'h3A, 8'h3E, 8'h3B, 8'h13, 8'h0F, 8'h07, 8'h47, 8'hA0, 8'hC0, 8'hC6, 8'hE7, 8'hE7, 8'hE3, 8'hE6, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF },
{8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hF0, 8'hFC, 8'hDC, 8'h9C, 8'h5C, 8'h3C, 8'h1C, 8'h68, 8'h6D, 8'h56, 8'h85, 8'h4E, 8'h0F, 8'h07, 8'h27, 8'h81, 8'hA1, 8'hC7, 8'hE7, 8'hE7, 8'hE7, 8'hE6, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF },
{8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hF0, 8'hFC, 8'hDC, 8'h9C, 8'h7C, 8'h3C, 8'h6C, 8'hC0, 8'h84, 8'h51, 8'hC0, 8'h85, 8'h0F, 8'h0B, 8'h27, 8'h66, 8'h86, 8'hA1, 8'hC2, 8'hE7, 8'hE7, 8'hEA, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF },
{8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hD1, 8'hF8, 8'hDC, 8'h9C, 8'h7C, 8'h3C, 8'h50, 8'hC0, 8'hA4, 8'h56, 8'hC0, 8'h69, 8'h2E, 8'h26, 8'h46, 8'h81, 8'h82, 8'hA0, 8'hC1, 8'hE7, 8'hE3, 8'hEA, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF },
{8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hF1, 8'hF8, 8'hDC, 8'hBC, 8'h7C, 8'h74, 8'h54, 8'h84, 8'h89, 8'h3E, 8'h6D, 8'h4E, 8'hA0, 8'h65, 8'h61, 8'hA0, 8'hA0, 8'hC0, 8'hC1, 8'hC7, 8'hE7, 8'hF2, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF },
{8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hF4, 8'hDC, 8'hBC, 8'h94, 8'hA0, 8'hA0, 8'h51, 8'h39, 8'h1E, 8'h1F, 8'h69, 8'hC0, 8'h81, 8'h80, 8'hC0, 8'hC0, 8'hC0, 8'hC1, 8'hC7, 8'hE2, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF },
{8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hF4, 8'hFC, 8'hBC, 8'h98, 8'hA0, 8'hA0, 8'h88, 8'h1D, 8'h3A, 8'h4D, 8'h69, 8'hC0, 8'h85, 8'h80, 8'hC0, 8'hC0, 8'hC0, 8'hC1, 8'hC6, 8'hE6, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF },
{8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hD1, 8'hFC, 8'hAC, 8'h88, 8'hC0, 8'hC0, 8'h84, 8'h3D, 8'h55, 8'hC0, 8'h69, 8'h89, 8'h66, 8'h80, 8'hC0, 8'hC0, 8'hC0, 8'hC1, 8'hC3, 8'hEA, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF },
{8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hF1, 8'hD8, 8'hA0, 8'hC0, 8'hC0, 8'hC0, 8'h84, 8'h51, 8'h69, 8'hC0, 8'h69, 8'h17, 8'h2F, 8'h65, 8'hA0, 8'hC0, 8'hC0, 8'hA1, 8'hC2, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF },
{8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hD0, 8'hC4, 8'hC0, 8'hC0, 8'hC0, 8'h84, 8'h84, 8'hC0, 8'hC0, 8'h89, 8'h17, 8'h0F, 8'h26, 8'h80, 8'hC0, 8'hC0, 8'hC6, 8'hE6, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF },
{8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hD1, 8'hC8, 8'hC0, 8'hC0, 8'hC0, 8'h88, 8'h88, 8'hC0, 8'hC0, 8'h89, 8'h33, 8'h2E, 8'h45, 8'h61, 8'hA0, 8'hC0, 8'hC2, 8'hEE, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF },
{8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hAC, 8'hC4, 8'hC0, 8'hC0, 8'h8C, 8'h70, 8'hC0, 8'hC0, 8'h89, 8'h69, 8'h65, 8'hA0, 8'h81, 8'h66, 8'hA1, 8'hC6, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF },
{8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hAD, 8'h90, 8'hC0, 8'hC0, 8'h6C, 8'h1D, 8'h6D, 8'hA4, 8'h6D, 8'hA4, 8'hC0, 8'hC0, 8'h80, 8'h47, 8'h83, 8'hCA, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF },
{8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'h94, 8'h74, 8'h88, 8'h54, 8'h1D, 8'h1E, 8'h3E, 8'h3A, 8'h85, 8'hC0, 8'hC0, 8'h81, 8'h47, 8'h82, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF },
{8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hD1, 8'h7C, 8'h5C, 8'h1C, 8'h1D, 8'h3D, 8'h69, 8'h6D, 8'h4E, 8'hA0, 8'hC0, 8'h61, 8'h43, 8'hAA, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF },
{8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'h94, 8'h5C, 8'h3C, 8'h1D, 8'h39, 8'hC0, 8'h89, 8'h37, 8'h84, 8'hC0, 8'h46, 8'h66, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF },
{8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hD1, 8'h58, 8'h3C, 8'h1D, 8'h3D, 8'hA4, 8'h6D, 8'h1B, 8'h52, 8'h85, 8'h27, 8'hAA, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF },
{8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'h90, 8'h3C, 8'h1D, 8'h1D, 8'h3A, 8'h3A, 8'h1B, 8'h13, 8'h0F, 8'h66, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF },
{8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'h54, 8'h1C, 8'h3D, 8'h1E, 8'h1E, 8'h3B, 8'h17, 8'h2A, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF },
{8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hB1, 8'h3C, 8'h1D, 8'h1E, 8'h1E, 8'h1B, 8'h17, 8'h8D, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF },
{8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'h70, 8'h1D, 8'h3E, 8'h3E, 8'h1F, 8'h6E, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF },
{8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'h55, 8'h1E, 8'h1E, 8'h56, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF },
{8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hD1, 8'h39, 8'h3A, 8'hB1, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF },
{8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hAD, 8'hAD, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF }};
//

	 // ==============================================================
    //  MazeBitMapMask CONTROLLER
    // ==============================================================
    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
		  		MazeBitMapMask <= MazeDefaultBitMapMask;
            lives        <= 2'b11;
            oneLeft  <= 1'b0;
            gameOver <= 1'b0;
        end
		  		  
        else begin
            
            gameOver <= 1'b0;

            
            if (strike && lives != 2'd0) begin
                case (lives)
                    2'b11 : MazeBitMapMask[3] <= 1'h0;
                    2'b10 : MazeBitMapMask[2] <= 1'h0;
                    2'b01 : MazeBitMapMask[1] <= 1'h0;
                endcase
                lives <= lives - 2'b01;
                if (lives == 2'b01) oneLeft <= 1'b1;
            end

            if (oneLeft && (lives == 2'b00)) begin
                gameOver <= 1'b1;
                oneLeft  <= 1'b0;
            end
        end
    end


always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
			RGBout       <= 8'h00;
	end
	else begin
	
			RGBout <= TRANSPARENT_ENCODING;

			if (InsideRectangle) begin
            case (MazeBitMapMask[offsetX_MSB])
                1'b1 : RGBout <= object_colors[0]
                                          [offsetY_LSB][offsetX_LSB];
                default;
            endcase
        end
	end
end

assign drawingRequest = (RGBout != TRANSPARENT_ENCODING ) ? 1'b1 : 1'b0 ; // get optional transparent command from the bitmpap   
endmodule

