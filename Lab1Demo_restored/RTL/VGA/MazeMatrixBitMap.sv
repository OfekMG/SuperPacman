
// HartsMatrixBitMap File
// A two level bitmap. displaying harts on the screen Feb 2025
// (c) Technion IIT, Department of Electrical Engineering 2025

module MazeMatrixBitMap (
    input  logic        clk,
    input  logic        resetN,
    input  logic [10:0] offsetX, // offset from top-left position
    input  logic [10:0] offsetY,
    input  logic        InsideRectangle, // input that the pixel is within a bracket
    input  logic        random_hart,
    input  logic        collision_Smiley_Hart, // used as "smiley is drawing / colliding at this pixel"
    input  logic        collision_ghost_Hart,
	 input  logic        collision_smiley_Dot,
	 input  logic        collision_smiley_Super,
	 input  logic        startOfFrame,
	 input  logic        strike, // not used
	 input  logic        collision_smiley_pickaxe,
	 input  logic        change,
	 input  logic        PICKAXE_KEY,
	 input  logic        second_phase,

    output logic        drawingRequest,    // output that the pixel should be displayed (full tile)
    output logic [7:0]  RGBout,           // rgb value from the bitmap (full tile)
    output logic        drawingRequestDot, // output that the pixel should be displayed as a dot (for index 2)
    output logic [7:0]  RGBoutDot,         // rgb value for the dot
    output logic        score,              // pulses 1 clock when a dot is eaten
	 output logic        drawingRequestSuper,
	 output logic [7:0]  RGBoutSuper,
	 output logic        Super,
	 output logic 			drawingRequestPickaxe,
	 output logic [7:0]  RGBoutpickaxe,
	 output logic        pickaxe, //not used
	 output logic [1:0]  counter, //not used
	 output logic        drawingRequestwoodenwall,
	 output logic [7:0]  RGBoutwoodenwall           // rgb value from the bitmap (full tile)

);

localparam logic [7:0] TRANSPARENT_ENCODING = 8'hFF; // RGB value representing transparent pixel

localparam int TILE_NUMBER_OF_X_BITS = 5;  // 2^5 = 32
localparam int TILE_NUMBER_OF_Y_BITS = 5;  // 2^5 = 32

localparam int MAZE_NUMBER_OF__X_BITS = 5; // 2^5 = 32
localparam int MAZE_NUMBER_OF__Y_BITS = 4; // 2^4 = 16

localparam int TILE_WIDTH_X  = 1 << TILE_NUMBER_OF_X_BITS;
localparam int TILE_HEIGHT_Y = 1 << TILE_NUMBER_OF_Y_BITS;
localparam int MAZE_WIDTH_X  = 1 << MAZE_NUMBER_OF__X_BITS;
localparam int MAZE_HEIGHT_Y = 1 << MAZE_NUMBER_OF__Y_BITS;

logic [10:0] offsetX_LSB;
logic [10:0] offsetY_LSB;
logic [10:0] offsetX_MSB;
logic [10:0] offsetY_MSB;
logic [10:0] pause_counter;

parameter int PAUSE_DURATION_FRAMES = 300;// 10 sec @ 30Hz
parameter int PICKAXE_WALLS = 3;


// Get the pixel's coordinates WITHIN a 32x32 tile (lower 5 bits)
assign offsetX_LSB  = offsetX[(TILE_NUMBER_OF_X_BITS-1):0];
assign offsetY_LSB  = offsetY[(TILE_NUMBER_OF_Y_BITS-1):0];

// Get the TILE's coordinates on the map grid (the higher bits)
assign offsetX_MSB  = offsetX[(TILE_NUMBER_OF_X_BITS + MAZE_NUMBER_OF__X_BITS - 1):TILE_NUMBER_OF_X_BITS];
assign offsetY_MSB  = offsetY[(TILE_NUMBER_OF_Y_BITS + MAZE_NUMBER_OF__Y_BITS - 1):TILE_NUMBER_OF_Y_BITS];

// maze bitmap mask
logic [3:0] MazeBitMapMask [0:MAZE_HEIGHT_Y-1][0:MAZE_WIDTH_X-1];

// default maze (kept as you provided)
logic [0:15][0:31][3:0] MazeDefaultBitMapMask = '{
  '{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1 ,1,1,1,1,1,1,1,1,1,1,1,1,1,1}, //second part is out of frame
  '{1,2,2,2,1,0,2,2,4,1,2,2,2,2,2,2,2,1 ,1,2,2,2,2,1,2,2,2,2,2,2,2,1},
  '{1,2,1,2,1,2,1,1,2,1,2,1,1,5,1,1,2,1 ,1,2,1,1,2,1,1,2,1,1,2,1,2,1},
  '{1,2,1,2,2,2,2,1,2,2,2,1,2,2,2,1,3,1 ,1,2,2,1,2,2,2,1,2,2,2,1,2,1},
  '{1,2,1,1,1,2,1,1,1,1,2,1,1,2,1,1,1,1 ,1,2,1,1,2,1,1,2,1,1,2,1,2,1},
  '{1,2,2,2,2,2,2,2,2,2,2,3,1,2,2,2,2,1 ,2,2,2,2,2,2,1,2,2,2,2,2,2,1},
  '{1,2,1,1,1,2,1,1,1,2,1,1,1,1,1,1,5,1 ,1,1,1,2,1,1,1,2,1,1,2,1,1,1},
  '{1,2,2,2,2,2,2,2,1,2,2,2,2,2,2,2,2,1 ,2,2,2,2,2,2,2,2,2,2,2,2,2,1},
  '{1,1,1,2,1,1,1,5,1,1,2,1,1,1,1,1,2,1 ,1,2,1,1,2,1,1,1,1,2,1,1,1,1},
  '{1,2,2,2,2,2,2,2,2,2,2,1,4,2,2,2,2,1 ,2,2,2,2,2,2,2,2,2,2,2,2,2,1},
  '{1,2,1,1,1,2,1,1,2,1,2,1,1,2,1,1,2,1 ,1,2,1,1,2,1,1,2,1,1,2,1,2,1},
  '{1,2,2,3,1,2,2,2,2,2,2,2,2,2,2,2,2,1 ,2,2,2,2,2,2,1,2,2,2,2,2,2,1},
  '{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1 ,1,1,1,2,1,1,1,2,1,1,2,1,1,1},
    // not part of the map 
  '{1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1 ,2,2,2,2,2,2,2,2,2,2,2,2,2,1},
  '{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1 ,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
  '{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1 ,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
};

logic [0:15][0:31][3:0] MazeDefaultBitMapMask2 = '{
        '{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1 ,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
        '{1,2,2,2,2,2,2,2,2,2,2,2,2,2,4,2,2,1 ,2,2,2,2,2,2,2,2,2,2,2,2,2,1},
        '{1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,1 ,1,1,1,1,1,1,1,1,1,1,1,1,2,1},
        '{1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1 ,2,2,2,2,2,2,2,2,2,2,2,2,2,1},
        '{1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1 ,1,1,1,1,1,1,1,1,1,1,1,1,2,1},
        '{1,2,2,2,2,4,2,2,2,2,2,2,2,2,2,2,2,1 ,2,2,2,2,2,2,2,2,2,2,2,2,2,1},
        '{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,1 ,1,1,1,1,1,1,1,1,1,1,1,1,2,1},
        '{1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1 ,2,2,2,2,2,2,2,2,2,2,2,2,2,1},
        '{1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,1 ,1,1,1,1,1,1,1,1,1,1,1,1,2,1},
        '{1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1 ,2,2,2,2,2,2,2,2,2,2,2,2,2,1},
        '{1,5,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1 ,1,1,1,1,1,1,1,1,1,1,1,1,2,1},
        '{1,2,2,2,2,2,2,2,2,2,4,2,2,2,2,2,2,1 ,2,2,2,2,2,2,2,2,2,2,2,2,2,1},
        '{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1 ,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
        '{1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1 ,2,2,2,2,2,2,2,2,2,2,2,2,2,1},
        '{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1 ,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
        '{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1 ,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
    };

// object colors array: index mapping = maze_value - 1
// index 0 : full tile color (8'h73)
// index 1 : DOT pattern (transparent except central pixels = 8'h00)
// index 2 : full tile color (8'h73)
// index 3 : full tile color (8'h73)
logic [4:0][0:(TILE_HEIGHT_Y-1)][0:(TILE_WIDTH_X-1)][7:0] object_colors = '{
	'{{8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfa,8'hfa,8'hfa,8'hfe},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfa,8'hfe,8'hfe,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfa,8'hfa},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfa,8'hfa,8'hfe,8'hfa,8'hfa,8'hfa,8'hfe,8'hfe,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfe,8'hfe,8'hfe},
	{8'hfa,8'hfa,8'hfa,8'hfe,8'hfe,8'hfe,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfe,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h64,8'h24,8'h64,8'h64,8'h64,8'h64,8'h64},
	{8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hf9,8'hfa,8'hfa,8'hfa,8'hf5,8'hf9,8'hf5,8'hf9,8'hfa,8'hfa,8'hfa,8'hf9,8'hf9,8'hf9,8'hf5,8'hf9,8'hf5,8'hf5,8'hf9,8'hf9,8'hf9,8'hfa,8'hfa,8'hfa},
	{8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hf9,8'hf5,8'hf5,8'hf5,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa},
	{8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hf5,8'hf9,8'hf5,8'hfa,8'hfa,8'hfa,8'hf6,8'hf5,8'hf5,8'hfa,8'hf5,8'hfa,8'hfa,8'hf5,8'hf9,8'hfa,8'hf9,8'hf9,8'hfa,8'hfa},
	{8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hf9,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfe,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfe,8'hfe,8'hfa,8'hfe,8'hfa,8'hfe,8'hfe,8'hfe,8'hfe,8'hfa,8'hfa,8'hfa,8'hfa},
	{8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h64,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h64,8'h64,8'h24,8'h24,8'h64,8'h64,8'h64,8'h64},
	{8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfe,8'hfe,8'hfa,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hf9,8'hf9,8'hf9,8'hf9},
	{8'hf9,8'hfa,8'hfa,8'hfa,8'hfa,8'hf5,8'hf9,8'hf9,8'hf5,8'hfa,8'hf9,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hf9,8'hf5,8'hfa},
	{8'hfa,8'hfe,8'hfe,8'hfa,8'hfa,8'hfe,8'hfe,8'hfe,8'hfe,8'hfa,8'hfe,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hf9,8'hf9,8'hf9,8'hf9,8'hfa,8'hfa,8'hfa,8'hfa},
	{8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfe,8'hfe,8'hfe},
	{8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24},
	{8'hfe,8'hfa,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfe,8'hfa,8'hfa,8'hfa,8'hfa,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfe,8'hfa,8'hfa,8'hfe,8'hfa,8'hfa,8'hfa},
	{8'hfe,8'hfe,8'hfa,8'hfe,8'hfe,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfe,8'hfe,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa},
	{8'hfa,8'hfa,8'hfa,8'hfa,8'hfe,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfe,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe},
	{8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h20,8'h20,8'h20,8'h24,8'h20,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24},
	{8'hfe,8'hfe,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfa,8'hfa,8'hfa,8'hfa,8'hfe,8'hfa},
	{8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfe,8'hfe,8'hfa,8'hfa,8'hfa,8'hfe,8'hfe,8'hfa,8'hfa,8'hf5,8'hf5,8'hf5,8'hf5,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa},
	{8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfe,8'hfe,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hf5,8'hf5,8'hf5,8'hf9,8'hfa,8'hf9,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa},
	{8'hfe,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfe,8'hfa,8'hfe,8'hfe,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfe,8'hfe},
	{8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h24,8'h24,8'h24,8'h24,8'h20,8'h20,8'h20,8'h20,8'h20,8'h24,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20},
	{8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hd5,8'hd5,8'hd5,8'hf5,8'hd5,8'hf5,8'hf5,8'hd5,8'hf1,8'hf1,8'hf5,8'hf5,8'hf5},
	{8'hf5,8'hf5,8'hd5,8'hf5,8'hf5,8'hf5,8'hf5,8'hf5,8'hfa,8'hf9,8'hf9,8'hf9,8'hf5,8'hf9,8'hfa,8'hf6,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hf9,8'hf9,8'hfa,8'hf9,8'hf5,8'hf5,8'hf5,8'hf9,8'hf5,8'hf5},
	{8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hf9,8'hf9,8'hf5,8'hfa,8'hfa,8'hfa,8'hfa,8'hf5,8'hf5,8'hfa,8'hfa,8'hf9,8'hf5,8'hfa,8'hfa,8'hf5,8'hf5,8'hd1},
	{8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfe,8'hfa,8'hfa,8'hfe,8'hfe,8'hfe,8'hfa,8'hfa,8'hfa,8'hfa,8'hfe,8'hfa,8'hfa,8'hfe,8'hfe,8'hfa},
	{8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h24,8'h20,8'h24,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h24,8'h24,8'h20,8'h20,8'h24,8'h20,8'h24,8'h20,8'h24,8'h24,8'h24,8'h20,8'h24,8'h20,8'h24},
	{8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfe,8'hfe,8'hfa,8'hfa},
	{8'hf5,8'hf5,8'hf5,8'hf9,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfe,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfa,8'hfe,8'hfe,8'hfa,8'hfa}},
    // index 3
    '{{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h7c,8'h7c,8'h7c,8'h7c,8'h7c,8'h7c,8'h00,8'h00,8'h7c,8'h7c,8'h7c,8'h7c,8'h7c,8'h7c,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h7c,8'h7c,8'h7c,8'h7c,8'h7c,8'h7c,8'h00,8'h00,8'h7c,8'h7c,8'h7c,8'h7c,8'h7c,8'h7c,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'he0,8'he0,8'he0,8'he0,8'h7c,8'h7c,8'h7c,8'h7c,8'h7c,8'h7c,8'h7c,8'h7c,8'h7c,8'h7c,8'he0,8'he0,8'he0,8'he0,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'he0,8'he0,8'he0,8'he0,8'h7c,8'h7c,8'h7c,8'h7c,8'h7c,8'h7c,8'h7c,8'h7c,8'h7c,8'h7c,8'he0,8'he0,8'he0,8'he0,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'he0,8'he0,8'hff,8'hff,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'h7c,8'h7c,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'hff,8'hff,8'he0,8'he0,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'he0,8'he0,8'hff,8'hff,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'h7c,8'h7c,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'hff,8'hff,8'he0,8'he0,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'he0,8'he0,8'he0,8'he0,8'hff,8'hff,8'he0,8'he0,8'hff,8'hff,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'hff,8'hff,8'he0,8'he0,8'he0,8'he0,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'he0,8'he0,8'he0,8'he0,8'hff,8'hff,8'he0,8'he0,8'hff,8'hff,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'hff,8'hff,8'he0,8'he0,8'he0,8'he0,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'hff,8'hff,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'hff,8'hff,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'he0,8'he0,8'he0,8'he0,8'hff,8'hff,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'he0,8'he0,8'he0,8'he0,8'hff,8'hff,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'hff,8'hff,8'he0,8'he0,8'he0,8'he0,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'hff,8'hff,8'he0,8'he0,8'he0,8'he0,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'he0,8'he0,8'he0,8'he0,8'hff,8'hff,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'he0,8'he0,8'he0,8'he0,8'hff,8'hff,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'hff,8'hff,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'hff,8'hff,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'he0,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'he0,8'he0,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'he0,8'he0,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
	{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00}},
	    // index 1
    '{{8'h64,8'h6c,8'h64,8'h6c,8'h6c,8'h6d,8'h8d,8'h8d,8'h91,8'h8d,8'h8d,8'h8d,8'h8d,8'h8d,8'h8d,8'h6d,8'h64,8'h8d,8'h8d,8'h8d,8'h8d,8'h8d,8'h8d,8'h8d,8'h8d,8'h8d,8'h8d,8'h8d,8'h85,8'h8d,8'h64,8'h24},
	{8'had,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hf1,8'hb1,8'had,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'h8d},
	{8'had,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hcd,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hb1,8'hb1,8'hd1,8'hd1,8'hd1,8'hcd,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'h8d},
	{8'h8d,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hf1,8'hd1,8'hf1,8'hb1,8'hb1,8'hd1,8'hd1,8'hd1,8'hd1,8'had,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'h8d},
	{8'h8d,8'hd1,8'hd1,8'hd1,8'hd1,8'hcd,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hf1,8'hf1,8'hd1,8'hb1,8'had,8'hd1,8'hd1,8'hd1,8'hd1,8'had,8'had,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'h8d},
	{8'h8d,8'hd1,8'hd1,8'hcd,8'had,8'hcd,8'hcd,8'hcd,8'had,8'hd1,8'hd1,8'hd1,8'hd1,8'had,8'hd1,8'hb1,8'had,8'had,8'had,8'hd1,8'hd1,8'hcd,8'had,8'had,8'had,8'had,8'had,8'had,8'had,8'hd1,8'had,8'h64},
	{8'h64,8'h64,8'h64,8'h64,8'h64,8'h64,8'h64,8'h64,8'h64,8'h64,8'h64,8'h64,8'h64,8'h64,8'h64,8'h64,8'h24,8'h24,8'h24,8'h24,8'h64,8'h65,8'h64,8'h64,8'h24,8'h24,8'h24,8'h64,8'h64,8'h64,8'h6d,8'h64},
	{8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'h8d,8'h8d,8'hb1,8'hb1,8'hb1,8'had,8'had,8'had,8'hb1,8'hb1,8'hb1,8'hb1,8'hb1,8'hb1,8'hb1,8'hb1,8'h8d,8'hb1,8'hb1,8'hb1,8'hb1,8'hb1,8'hb1,8'hb1},
	{8'hd1,8'hf1,8'hd1,8'hd1,8'hf1,8'hd1,8'hf1,8'hd1,8'h8d,8'had,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hb1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'h8d,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1},
	{8'hd1,8'hd1,8'hcd,8'had,8'hcd,8'hd1,8'hd1,8'hcd,8'h8d,8'had,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'h8d,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1},
	{8'hcd,8'hd1,8'hd1,8'hd1,8'hd1,8'had,8'had,8'hd1,8'h8d,8'had,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'h8d,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hf1,8'hd1},
	{8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'h8d,8'had,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'h8d,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1},
	{8'h8d,8'had,8'had,8'had,8'had,8'had,8'had,8'had,8'h6d,8'h8d,8'had,8'had,8'had,8'had,8'had,8'had,8'had,8'had,8'had,8'had,8'had,8'had,8'had,8'hd1,8'h8d,8'had,8'had,8'had,8'had,8'had,8'hb1,8'hd1},
	{8'h24,8'h8d,8'h8d,8'h8d,8'h8d,8'h8d,8'h8d,8'h8d,8'h8d,8'h8c,8'h8c,8'h64,8'h64,8'h64,8'h64,8'h24,8'h64,8'h64,8'h64,8'h64,8'h64,8'h64,8'h64,8'h65,8'h6d,8'h64,8'h64,8'h64,8'h64,8'h64,8'h24,8'h24},
	{8'h8d,8'hd1,8'hf1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hf1,8'hf1,8'h8d,8'hb1,8'hb1,8'hb1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'h8d,8'h6d},
	{8'h8d,8'hd1,8'hd1,8'hf1,8'hf1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'h8d,8'hb1,8'hb1,8'hb1,8'hd1,8'hd1,8'hb1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hb1,8'h65},
	{8'h84,8'hd1,8'hf1,8'hd1,8'hd1,8'hf1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'h8d,8'hb1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'h8d},
	{8'h8d,8'hd1,8'hd1,8'hd1,8'hd1,8'hf1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'h8d,8'hb1,8'hb1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'h8d},
	{8'h8d,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'h8d,8'had,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'h8d},
	{8'h24,8'h64,8'h64,8'h64,8'h64,8'h64,8'h64,8'h64,8'h64,8'h64,8'h64,8'h6c,8'h64,8'h6c,8'h65,8'h6d,8'h64,8'h64,8'h64,8'h64,8'h64,8'h64,8'h64,8'h64,8'h64,8'h64,8'h64,8'h64,8'h64,8'h64,8'h6d,8'h6d},
	{8'hb1,8'hb1,8'hb1,8'hb1,8'hb1,8'had,8'hb1,8'hb1,8'h6d,8'hb1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hb1,8'hb1,8'hb1,8'hb1,8'hb1,8'hb1,8'h6d,8'had,8'had,8'had,8'had,8'had,8'had,8'hb1},
	{8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'h8d,8'hf1,8'hd1,8'hf1,8'hd1,8'hd1,8'hf1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hf1,8'hd1,8'hd1,8'hd1,8'h8c,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1},
	{8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'h8d,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'had,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'h6d,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1},
	{8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'h8d,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hf1,8'hf1,8'hf1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hf1,8'hd1,8'h8d,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1},
	{8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'h8d,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'h84,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1},
	{8'h8d,8'h8d,8'h8d,8'h8d,8'had,8'had,8'had,8'had,8'h24,8'had,8'hb1,8'had,8'had,8'had,8'h8d,8'had,8'had,8'had,8'hd1,8'had,8'had,8'hd1,8'had,8'hb1,8'h8d,8'had,8'had,8'had,8'had,8'had,8'had,8'had},
	{8'h6c,8'h8d,8'h8d,8'had,8'had,8'had,8'had,8'had,8'had,8'h8d,8'h8d,8'h8d,8'h8d,8'h8d,8'h8d,8'h8d,8'h24,8'h6d,8'h8d,8'h8d,8'h64,8'h8c,8'h64,8'h64,8'h8d,8'h8d,8'h8d,8'h6d,8'h6d,8'h6d,8'h6d,8'h64},
	{8'had,8'hd1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'h8d,8'hd1,8'hd1,8'hf1,8'hd1,8'hd1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf5,8'hf5,8'hd1},
	{8'had,8'hd1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf5,8'h8d,8'hb1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hd1},
	{8'h8d,8'hd1,8'hf1,8'hf1,8'hf1,8'hf1,8'hd1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf5,8'h8d,8'hd1,8'hb1,8'hb1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hd1},
	{8'h8d,8'hd1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'h8d,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hf1,8'hf5,8'hf1,8'hf1,8'hf1,8'hf5,8'hf1,8'hd1},
	{8'h8d,8'hd1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'hf1,8'h8d,8'hb1,8'hd1,8'hd1,8'hd1,8'hd1,8'hd1,8'hf5,8'hf1,8'hf5,8'hf5,8'hf1,8'hf1,8'hd1,8'hd1,8'hd1}},


    // index 2 => DOT pattern (32 rows x 32 cols)
  '{
	
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'h00,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'h00,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'h00,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h00,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff}},
 
	 //index 4 - pickaxe
	 '{
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
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
	{8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff}}
	

};




logic dot_pixel_will_be_drawn;
assign dot_pixel_will_be_drawn = (InsideRectangle &&
                                  (MazeBitMapMask[offsetY_MSB][offsetX_MSB] == 4'h2) &&
                                  (object_colors[1][offsetY_LSB][offsetX_LSB] != TRANSPARENT_ENCODING));

always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
        RGBout           <= TRANSPARENT_ENCODING;
        RGBoutDot        <= TRANSPARENT_ENCODING;
		  RGBoutSuper      <= TRANSPARENT_ENCODING;
		  RGBoutpickaxe    <= TRANSPARENT_ENCODING;
		  RGBoutwoodenwall <= TRANSPARENT_ENCODING;
        drawingRequest    <= 1'b0;
        drawingRequestDot <= 1'b0;
		  drawingRequestSuper <= 1'b0;
		  drawingRequestPickaxe <= 1'b0;
        score             <= 1'b0;
		  Super				  <= 1'b0;
		  pickaxe           <= 1'b0;
        // reset maze
        for (int y = 0; y < MAZE_HEIGHT_Y; y++) begin
            for (int x = 0; x < MAZE_WIDTH_X; x++) begin
                MazeBitMapMask[y][x] <= MazeDefaultBitMapMask[y][x];
            end
        end
    end
	 else if (change) begin
        for (int y = 0; y < MAZE_HEIGHT_Y; y++) begin
            for (int x = 0; x < MAZE_WIDTH_X; x++) begin
                MazeBitMapMask[y][x] <= MazeDefaultBitMapMask2[y][x];
            end
        end
    end
    else begin
        // default outputs
        RGBout    <= TRANSPARENT_ENCODING;
        RGBoutDot <= TRANSPARENT_ENCODING;
		  RGBoutSuper <= TRANSPARENT_ENCODING;
		  RGBoutpickaxe <= TRANSPARENT_ENCODING;
		  RGBoutwoodenwall <= TRANSPARENT_ENCODING;

        score     <= 1'b0;
		  if (second_phase) begin 
			  for (int y = 0; y < MAZE_HEIGHT_Y; y++) begin
					for (int x = 0; x < MAZE_WIDTH_X; x++) begin
						if (MazeBitMapMask[y][x] == 4'h5) begin
						 MazeBitMapMask[y][x] <= 4'h0;
						 end
					end
			  end
		 end
			
        if (Super && startOfFrame) begin
							 if (!strike && (pause_counter < PAUSE_DURATION_FRAMES - 1))
                      pause_counter <= pause_counter + 1;
                  else
                      Super = 1'b0;
              end else
		  if (pickaxe && collision_Smiley_Hart) begin
					 if (MazeBitMapMask[offsetY_MSB][offsetX_MSB] == 4'h1) begin
							if (PICKAXE_KEY) begin
                    MazeBitMapMask[offsetY_MSB][offsetX_MSB] <= 4'h0; // מחק את הנקודה הספציפית
                    RGBout <= TRANSPARENT_ENCODING;
						  counter <= counter + 1;
						  if (counter == 3) begin
								pickaxe <= 0;
							end
						end 
               end
				end else
							
        if (collision_smiley_pickaxe) begin
				if ((offsetX_MSB < MAZE_WIDTH_X) && (offsetY_MSB < MAZE_HEIGHT_Y)) begin
                if (MazeBitMapMask[offsetY_MSB][offsetX_MSB] == 4'h4) begin
                    MazeBitMapMask[offsetY_MSB][offsetX_MSB] <= 4'h0; // מחק את הנקודה הספציפית
                    RGBoutDot <= TRANSPARENT_ENCODING;
                    pickaxe <= 1'b1; 
                end
            end
		  end else
        
        if (collision_smiley_Dot) begin
             if ((offsetX_MSB < MAZE_WIDTH_X) && (offsetY_MSB < MAZE_HEIGHT_Y)) begin
                if (MazeBitMapMask[offsetY_MSB][offsetX_MSB] == 4'h2) begin
                    MazeBitMapMask[offsetY_MSB][offsetX_MSB] <= 4'h0; // מחק את הנקודה הספציפית
                    RGBoutDot <= TRANSPARENT_ENCODING;
                    score <= 1'b1; // רק אם אכן נחסמה נקודה - נסמן נקודה נאכלת
                end
            end
			end
        else if (collision_smiley_Super) begin
				if ((offsetX_MSB < MAZE_WIDTH_X) && (offsetY_MSB < MAZE_HEIGHT_Y)) begin
                if (MazeBitMapMask[offsetY_MSB][offsetX_MSB] == 4'h3) begin
                    MazeBitMapMask[offsetY_MSB][offsetX_MSB] <= 4'h0; // מחק את הנקודה הספציפית
                    RGBoutSuper <= TRANSPARENT_ENCODING;
                     Super <= 1'b1; 
							pause_counter <= 0;
                end
            end
        end
		  else begin
            if (InsideRectangle) begin
                case (MazeBitMapMask[offsetY_MSB][offsetX_MSB])
                    4'h0: ; // transparent, do nothing
						  4'h1: RGBout <= object_colors[2][offsetY_LSB][offsetX_LSB];
                    4'h2: RGBoutDot <= object_colors[1][offsetY_LSB][offsetX_LSB];
						  4'h3: RGBoutSuper <= object_colors[3][offsetY_LSB][offsetX_LSB];
 						  4'h4: RGBoutpickaxe <= object_colors[0][offsetY_LSB][offsetX_LSB];
						  4'h5: RGBoutwoodenwall <= object_colors[4][offsetY_LSB][offsetX_LSB];
						  
                    default: RGBout <= object_colors[MazeBitMapMask[offsetY_MSB][offsetX_MSB] - 1][offsetY_LSB][offsetX_LSB];
                endcase
            end
        end

        drawingRequest    <= (RGBout != TRANSPARENT_ENCODING);
        drawingRequestDot <= (RGBoutDot != TRANSPARENT_ENCODING);
		  drawingRequestSuper <= (RGBoutSuper != TRANSPARENT_ENCODING);
		  drawingRequestPickaxe <= (RGBoutpickaxe != TRANSPARENT_ENCODING);
		  drawingRequestwoodenwall <=  (RGBoutwoodenwall != TRANSPARENT_ENCODING);


    end
end

endmodule
