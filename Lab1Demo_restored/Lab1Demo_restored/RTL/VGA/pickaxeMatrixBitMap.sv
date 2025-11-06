module pickaxeMatrixBitMap (
    input  logic        clk,
    input  logic        resetN,
    input  logic [10:0] offsetX,  // offset from top-left position
    input  logic [10:0] offsetY,
    input  logic        InsideRectangle,            // pixel is in bar
	 input  logic [3:0]  lives,

    output logic        drawingRequest,             // pixel must be drawn
    output logic [7:0]  RGBout
);
 

    localparam logic [7:0] TRANSPARENT_ENCODING = 8'hFF ;
	 

    localparam int TILE_NUMBER_OF_X_BITS   = 5;  // 2^5 = 32
    localparam int TILE_NUMBER_OF_Y_BITS   = 5;  // 2^5 = 32
    localparam int MAZE_NUMBER_OF__X_BITS  = 2;  // 2^2 = 4

    localparam int TILE_WIDTH_X  = 2 ** TILE_NUMBER_OF_X_BITS ;
    localparam int TILE_HEIGHT_Y = 2 ** TILE_NUMBER_OF_Y_BITS ;
    localparam int MAZE_WIDTH_X  = 2 ** MAZE_NUMBER_OF__X_BITS ;

    logic [TILE_NUMBER_OF_X_BITS-1:0] offsetX_LSB;
    logic [TILE_NUMBER_OF_Y_BITS-1:0] offsetY_LSB;
    logic [MAZE_NUMBER_OF__X_BITS-1:0] offsetX_MSB;

	
    assign offsetX_LSB = offsetX[TILE_NUMBER_OF_X_BITS-1:0];
    assign offsetY_LSB = offsetY[TILE_NUMBER_OF_Y_BITS-1:0];
    assign offsetX_MSB = offsetX[TILE_NUMBER_OF_X_BITS+MAZE_NUMBER_OF__X_BITS-1:
                                 TILE_NUMBER_OF_X_BITS];


    	
    logic [0:MAZE_WIDTH_X-1] LivesBitMapMask ;

 logic [2:0] [0:(TILE_HEIGHT_Y-1)][0:(TILE_WIDTH_X-1)] [7:0]  heartBitmap  = {
	//pickaxe 1
	{{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h0c,8'h0c,8'h0c,8'h0c,8'h0c,8'h0c,8'h0c,8'h0c,8'h0c,8'h0c,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h0c,8'h0c,8'h0c,8'h0c,8'h0c,8'h0c,8'h0c,8'h0c,8'h0c,8'h0c,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hda,8'hba,8'h15,8'h15,8'h11,8'h11,8'h11,8'h11,8'h11,8'h11,8'h11,8'h11,8'hda,8'hba,8'hda,8'hda,8'hda,8'hda,8'hfa,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h0c,8'h0c,8'h3f,8'h3f,8'h3e,8'h3e,8'h3a,8'h3a,8'h3a,8'h3a,8'h3e,8'h3e,8'h0c,8'h0c,8'h24,8'h64,8'h6c,8'h8c,8'h8c,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h0c,8'h0c,8'h3f,8'h3f,8'h3e,8'h3e,8'h3a,8'h3a,8'h3a,8'h3a,8'h3e,8'h3e,8'h0c,8'h04,8'h24,8'h64,8'h6c,8'h8c,8'h90,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h0c,8'h0c,8'h04,8'h04,8'h04,8'h04,8'h04,8'h04,8'h3a,8'h3a,8'h3a,8'h3a,8'h95,8'hb0,8'h64,8'h20,8'h24,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h0c,8'h0c,8'h04,8'h04,8'h04,8'h04,8'h04,8'h04,8'h3a,8'h3a,8'h3a,8'h3a,8'h95,8'hb0,8'h64,8'h20,8'h24,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'h3e,8'h3e,8'h3a,8'h3a,8'h11,8'h04,8'h24,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'h3e,8'h3e,8'h3a,8'h3a,8'h11,8'h04,8'h24,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h8c,8'h8c,8'h8c,8'h8c,8'h04,8'h04,8'h35,8'h3a,8'h3a,8'h3a,8'h3a,8'h2c,8'h04,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'h8c,8'h8c,8'h20,8'h20,8'h31,8'h3a,8'h3a,8'h3e,8'h3a,8'h04,8'h04,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'h8c,8'h8c,8'h20,8'h20,8'h35,8'h3a,8'h3e,8'h3e,8'h3a,8'h04,8'h04,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'hb0,8'hb0,8'h20,8'h20,8'hff,8'hff,8'h91,8'h04,8'h11,8'h3a,8'h3a,8'h04,8'h04,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'hb0,8'hb0,8'h20,8'h20,8'hff,8'hff,8'h91,8'h04,8'h11,8'h3a,8'h3a,8'h04,8'h04,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'h8c,8'h8c,8'h24,8'h20,8'hff,8'hff,8'hff,8'hff,8'h91,8'h04,8'h11,8'h3a,8'h3a,8'h04,8'h04,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'h8c,8'h8c,8'h20,8'h20,8'hff,8'hff,8'hff,8'hff,8'h91,8'h04,8'h11,8'h3a,8'h3a,8'h04,8'h04,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'hb0,8'hb0,8'h24,8'h20,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h91,8'h04,8'h11,8'h3e,8'h3a,8'h04,8'h04,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'hb0,8'hb0,8'h24,8'h20,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h91,8'h04,8'h11,8'h3e,8'h3a,8'h04,8'h04,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'hb0,8'hb0,8'h24,8'h20,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h71,8'h04,8'h11,8'h3e,8'h3a,8'h04,8'h04,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'h8c,8'h8c,8'h20,8'h20,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h91,8'h04,8'h15,8'h3f,8'h3e,8'h04,8'h04,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'h8c,8'h8c,8'h20,8'h20,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h91,8'h04,8'h15,8'h3f,8'h7e,8'h04,8'h04,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'hb0,8'hb0,8'h20,8'h20,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h96,8'h04,8'h24,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'hb0,8'hb0,8'h20,8'h20,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h96,8'h04,8'h24,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'h8c,8'h8c,8'h20,8'h20,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'h8c,8'h8c,8'h20,8'h20,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h6c,8'h6c,8'h6c,8'h6c,8'h6c,8'h6c,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'hb0,8'hb0,8'h20,8'h24,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'hb0,8'hb0,8'h24,8'h24,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'h20,8'h20,8'h20,8'h20,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'h20,8'h20,8'h20,8'h20,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff}},
	//pickaxe 2
	{{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h0c,8'h0c,8'h0c,8'h0c,8'h0c,8'h0c,8'h0c,8'h0c,8'h0c,8'h0c,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h0c,8'h0c,8'h0c,8'h0c,8'h0c,8'h0c,8'h0c,8'h0c,8'h0c,8'h0c,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hda,8'hba,8'h15,8'h15,8'h11,8'h11,8'h11,8'h11,8'h11,8'h11,8'h11,8'h11,8'hda,8'hba,8'hda,8'hda,8'hda,8'hda,8'hfa,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h0c,8'h0c,8'h3f,8'h3f,8'h3e,8'h3e,8'h3a,8'h3a,8'h3a,8'h3a,8'h3e,8'h3e,8'h0c,8'h0c,8'h24,8'h64,8'h6c,8'h8c,8'h8c,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h0c,8'h0c,8'h3f,8'h3f,8'h3e,8'h3e,8'h3a,8'h3a,8'h3a,8'h3a,8'h3e,8'h3e,8'h0c,8'h04,8'h24,8'h64,8'h6c,8'h8c,8'h90,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h0c,8'h0c,8'h04,8'h04,8'h04,8'h04,8'h04,8'h04,8'h3a,8'h3a,8'h3a,8'h3a,8'h95,8'hb0,8'h64,8'h20,8'h24,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h0c,8'h0c,8'h04,8'h04,8'h04,8'h04,8'h04,8'h04,8'h3a,8'h3a,8'h3a,8'h3a,8'h95,8'hb0,8'h64,8'h20,8'h24,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'h3e,8'h3e,8'h3a,8'h3a,8'h11,8'h04,8'h24,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'h3e,8'h3e,8'h3a,8'h3a,8'h11,8'h04,8'h24,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h8c,8'h8c,8'h8c,8'h8c,8'h04,8'h04,8'h35,8'h3a,8'h3a,8'h3a,8'h3a,8'h2c,8'h04,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'h8c,8'h8c,8'h20,8'h20,8'h31,8'h3a,8'h3a,8'h3e,8'h3a,8'h04,8'h04,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'h8c,8'h8c,8'h20,8'h20,8'h35,8'h3a,8'h3e,8'h3e,8'h3a,8'h04,8'h04,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'hb0,8'hb0,8'h20,8'h20,8'hff,8'hff,8'h91,8'h04,8'h11,8'h3a,8'h3a,8'h04,8'h04,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'hb0,8'hb0,8'h20,8'h20,8'hff,8'hff,8'h91,8'h04,8'h11,8'h3a,8'h3a,8'h04,8'h04,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'h8c,8'h8c,8'h24,8'h20,8'hff,8'hff,8'hff,8'hff,8'h91,8'h04,8'h11,8'h3a,8'h3a,8'h04,8'h04,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'h8c,8'h8c,8'h20,8'h20,8'hff,8'hff,8'hff,8'hff,8'h91,8'h04,8'h11,8'h3a,8'h3a,8'h04,8'h04,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'hb0,8'hb0,8'h24,8'h20,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h91,8'h04,8'h11,8'h3e,8'h3a,8'h04,8'h04,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'hb0,8'hb0,8'h24,8'h20,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h91,8'h04,8'h11,8'h3e,8'h3a,8'h04,8'h04,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'hb0,8'hb0,8'h24,8'h20,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h71,8'h04,8'h11,8'h3e,8'h3a,8'h04,8'h04,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'h8c,8'h8c,8'h20,8'h20,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h91,8'h04,8'h15,8'h3f,8'h3e,8'h04,8'h04,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'h8c,8'h8c,8'h20,8'h20,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h91,8'h04,8'h15,8'h3f,8'h7e,8'h04,8'h04,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'hb0,8'hb0,8'h20,8'h20,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h96,8'h04,8'h24,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'hb0,8'hb0,8'h20,8'h20,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h96,8'h04,8'h24,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'h8c,8'h8c,8'h20,8'h20,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'h8c,8'h8c,8'h20,8'h20,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h6c,8'h6c,8'h6c,8'h6c,8'h6c,8'h6c,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'hb0,8'hb0,8'h20,8'h24,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'hb0,8'hb0,8'h24,8'h24,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'h20,8'h20,8'h20,8'h20,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'h20,8'h20,8'h20,8'h20,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff}},
	// pickaxe 3
	{{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h0c,8'h0c,8'h0c,8'h0c,8'h0c,8'h0c,8'h0c,8'h0c,8'h0c,8'h0c,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h0c,8'h0c,8'h0c,8'h0c,8'h0c,8'h0c,8'h0c,8'h0c,8'h0c,8'h0c,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hda,8'hba,8'h15,8'h15,8'h11,8'h11,8'h11,8'h11,8'h11,8'h11,8'h11,8'h11,8'hda,8'hba,8'hda,8'hda,8'hda,8'hda,8'hfa,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h0c,8'h0c,8'h3f,8'h3f,8'h3e,8'h3e,8'h3a,8'h3a,8'h3a,8'h3a,8'h3e,8'h3e,8'h0c,8'h0c,8'h24,8'h64,8'h6c,8'h8c,8'h8c,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h0c,8'h0c,8'h3f,8'h3f,8'h3e,8'h3e,8'h3a,8'h3a,8'h3a,8'h3a,8'h3e,8'h3e,8'h0c,8'h04,8'h24,8'h64,8'h6c,8'h8c,8'h90,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h0c,8'h0c,8'h04,8'h04,8'h04,8'h04,8'h04,8'h04,8'h3a,8'h3a,8'h3a,8'h3a,8'h95,8'hb0,8'h64,8'h20,8'h24,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h0c,8'h0c,8'h04,8'h04,8'h04,8'h04,8'h04,8'h04,8'h3a,8'h3a,8'h3a,8'h3a,8'h95,8'hb0,8'h64,8'h20,8'h24,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'h3e,8'h3e,8'h3a,8'h3a,8'h11,8'h04,8'h24,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'h3e,8'h3e,8'h3a,8'h3a,8'h11,8'h04,8'h24,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h8c,8'h8c,8'h8c,8'h8c,8'h04,8'h04,8'h35,8'h3a,8'h3a,8'h3a,8'h3a,8'h2c,8'h04,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'h8c,8'h8c,8'h20,8'h20,8'h31,8'h3a,8'h3a,8'h3e,8'h3a,8'h04,8'h04,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'h8c,8'h8c,8'h20,8'h20,8'h35,8'h3a,8'h3e,8'h3e,8'h3a,8'h04,8'h04,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'hb0,8'hb0,8'h20,8'h20,8'hff,8'hff,8'h91,8'h04,8'h11,8'h3a,8'h3a,8'h04,8'h04,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'hb0,8'hb0,8'h20,8'h20,8'hff,8'hff,8'h91,8'h04,8'h11,8'h3a,8'h3a,8'h04,8'h04,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'h8c,8'h8c,8'h24,8'h20,8'hff,8'hff,8'hff,8'hff,8'h91,8'h04,8'h11,8'h3a,8'h3a,8'h04,8'h04,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'h8c,8'h8c,8'h20,8'h20,8'hff,8'hff,8'hff,8'hff,8'h91,8'h04,8'h11,8'h3a,8'h3a,8'h04,8'h04,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'hb0,8'hb0,8'h24,8'h20,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h91,8'h04,8'h11,8'h3e,8'h3a,8'h04,8'h04,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'hb0,8'hb0,8'h24,8'h20,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h91,8'h04,8'h11,8'h3e,8'h3a,8'h04,8'h04,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'hb0,8'hb0,8'h24,8'h20,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h71,8'h04,8'h11,8'h3e,8'h3a,8'h04,8'h04,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'h8c,8'h8c,8'h20,8'h20,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h91,8'h04,8'h15,8'h3f,8'h3e,8'h04,8'h04,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'h8c,8'h8c,8'h20,8'h20,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h91,8'h04,8'h15,8'h3f,8'h7e,8'h04,8'h04,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'hb0,8'hb0,8'h20,8'h20,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h96,8'h04,8'h24,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'hb0,8'hb0,8'h20,8'h20,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h96,8'h04,8'h24,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'h8c,8'h8c,8'h20,8'h20,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'h8c,8'h8c,8'h20,8'h20,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h6c,8'h6c,8'h6c,8'h6c,8'h6c,8'h6c,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'hb0,8'hb0,8'h20,8'h24,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'h64,8'h64,8'hb0,8'hb0,8'h24,8'h24,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'h20,8'h20,8'h20,8'h20,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'h20,8'h20,8'h20,8'h20,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff}}};

	 // ==============================================================
    //  MazeBitMapMask CONTROLLER
    // ==============================================================


 always_ff @(posedge clk or negedge resetN) begin

				for (int i = 2'b00; i < MAZE_WIDTH_X; i++) begin
					LivesBitMapMask[MAZE_WIDTH_X-1-i] <= ( i < lives );
				end
			end
		
			
	
		
always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
			RGBout <= 8'h00;
	end
	else begin
	
			RGBout <= TRANSPARENT_ENCODING;

			if (InsideRectangle) begin
            case (LivesBitMapMask[offsetX_MSB])
                1'b1 : RGBout <= heartBitmap[offsetX_MSB]
                                          [offsetY_LSB][offsetX_LSB];
                default;
            endcase
        end
	end
end

assign drawingRequest = (RGBout != TRANSPARENT_ENCODING ) ? 1'b1 : 1'b0 ; // get optional transparent command from the bitmpap   
endmodule

