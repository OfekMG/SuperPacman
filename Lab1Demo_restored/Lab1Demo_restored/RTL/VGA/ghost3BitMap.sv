// System-Verilog 'written by Alex Grinshpun May 2018
// New bitmap dudy February 2025
// (c) Technion IIT, Department of Electrical Engineering 2025 


module ghost3BitMap ( 
    input  logic        clk,
    input  logic        resetN,
    input  logic [10:0] offsetX, // offset from top left position 
    input  logic [10:0] offsetY,
    input  logic        InsideRectangle, // input that the pixel is within a bracket
    input  logic        Super, 
    output logic        drawingRequest, // output that the pixel should be displayed 
    output logic [7:0]  RGBout,  // rgb value from the bitmap 
    output logic [2:0]  HitEdgeCode  
);

localparam int OBJECT_NUMBER_OF_Y_BITS = 5;
localparam int OBJECT_NUMBER_OF_X_BITS = 5;

localparam int OBJECT_HEIGHT_Y = 32;
localparam int OBJECT_WIDTH_X  = 32;

parameter int PAUSE_DURATION_FRAMES = 90; // 3 sec @ 30Hz


logic [3:0] HitCodeX; 
logic [3:0] HitCodeY; 
logic [6:0] pause_counter;
logic inPause;


assign HitCodeX = offsetX[OBJECT_NUMBER_OF_X_BITS-1:0] >> 1; 
assign HitCodeY = offsetY[OBJECT_NUMBER_OF_Y_BITS-1:0] >> 1;

enum logic [1:0] {NORMAL_ST, SUPER_ST} SM_LOOK;

localparam logic [7:0] TRANSPARENT_ENCODING = 8'hFF;  

// שני אובייקטים שונים
logic [0:OBJECT_HEIGHT_Y-1][0:OBJECT_WIDTH_X-1][7:0] object_colors_normal = {	
  
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'hff,8'hff,8'hff,8'hff,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'hff,8'hff,8'hff,8'hff,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'hff,8'hff,8'hff,8'hff,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'hff,8'hff,8'hff,8'hff,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'h1f,8'h1f,8'h1f,8'h1f,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h1f,8'h1f,8'h1f,8'h1f,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h1f,8'h1f,8'h1f,8'h1f,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'h1f,8'h1f,8'h1f,8'h1f,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h1f,8'h1f,8'h1f,8'h1f,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'h1f,8'h1f,8'h1f,8'h1f,8'hFF,8'hFF},
	{8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'hff,8'hff,8'hFF,8'hFF,8'hFF,8'hFF,8'hff,8'hff,8'h1f,8'h1f,8'h1f,8'h1f,8'hff,8'hff,8'hFF,8'hFF,8'hFF,8'hFF,8'hff,8'hff,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f},
	{8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'hff,8'hff,8'hFF,8'hFF,8'hFF,8'hFF,8'hff,8'hff,8'h1f,8'h1f,8'h1f,8'h1f,8'hff,8'hff,8'hFF,8'hFF,8'hFF,8'hFF,8'hff,8'hff,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f},
	{8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'hff,8'hff,8'hFF,8'hFF,8'hFF,8'hFF,8'hff,8'hff,8'h1f,8'h1f,8'h1f,8'h1f,8'hff,8'hff,8'hFF,8'hFF,8'hFF,8'hFF,8'hff,8'hff,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f},
	{8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'hff,8'hff,8'hFF,8'hFF,8'hFF,8'hFF,8'hff,8'hff,8'h1f,8'h1f,8'h1f,8'h1f,8'hff,8'hff,8'hFF,8'hFF,8'hFF,8'hFF,8'hff,8'hff,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f},
	{8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'hff,8'hff,8'hff,8'hff,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'hff,8'hff,8'hff,8'hff,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f},
	{8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'hff,8'hff,8'hff,8'hff,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'hff,8'hff,8'hff,8'hff,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f},
	{8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f},
	{8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f},
	{8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f},
	{8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f},
	{8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f},
	{8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f},
	{8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f},
	{8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f},
	{8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f},
	{8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f},
	{8'h1f,8'h1f,8'h1f,8'h1f,8'hFF,8'hFF,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'hFF,8'hFF,8'hFF,8'hFF,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'hFF,8'hFF,8'h1f,8'h1f,8'h1f,8'h1f},
	{8'h1f,8'h1f,8'h1f,8'h1f,8'hFF,8'hFF,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'hFF,8'hFF,8'hFF,8'hFF,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'h1f,8'hFF,8'hFF,8'h1f,8'h1f,8'h1f,8'h1f},
	{8'h1f,8'h1f,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'h1f,8'h1f,8'h1f,8'h1f,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'h1f,8'h1f,8'h1f,8'h1f,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'h1f,8'h1f},
	{8'h1f,8'h1f,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'h1f,8'h1f,8'h1f,8'h1f,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'h1f,8'h1f,8'h1f,8'h1f,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'h1f,8'h1f}};
logic [0:OBJECT_HEIGHT_Y-1][0:OBJECT_WIDTH_X-1][7:0] object_colors_super = {
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'hFF,8'hFF,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'hFF,8'hFF,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'hff,8'hff,8'hff,8'hff,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'hff,8'hff,8'hff,8'hff,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'hFF,8'hFF},
	{8'hFF,8'hFF,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'hff,8'hff,8'hff,8'hff,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'hff,8'hff,8'hff,8'hff,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'hFF,8'hFF},
	{8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'hff,8'hff,8'hff,8'hff,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'hff,8'hff,8'hff,8'hff,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03},
	{8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'hff,8'hff,8'hff,8'hff,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'hff,8'hff,8'hff,8'hff,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03},
	{8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03},
	{8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03},
	{8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03},
	{8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03},
	{8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03},
	{8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03},
	{8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'hff,8'hff,8'hff,8'hff,8'h03,8'h03,8'h03,8'h03,8'hff,8'hff,8'hff,8'hff,8'h03,8'h03,8'h03,8'h03,8'hff,8'hff,8'hff,8'hff,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03},
	{8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'hff,8'hff,8'hff,8'hff,8'h03,8'h03,8'h03,8'h03,8'hff,8'hff,8'hff,8'hff,8'h03,8'h03,8'h03,8'h03,8'hff,8'hff,8'hff,8'hff,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03},
	{8'h03,8'h03,8'h03,8'h03,8'hff,8'hff,8'h03,8'h03,8'h03,8'h03,8'hff,8'hff,8'hff,8'hff,8'h03,8'h03,8'h03,8'h03,8'hff,8'hff,8'hff,8'hff,8'h03,8'h03,8'h03,8'h03,8'hff,8'hff,8'h03,8'h03,8'h03,8'h03},
	{8'h03,8'h03,8'h03,8'h03,8'hff,8'hff,8'h03,8'h03,8'h03,8'h03,8'hff,8'hff,8'hff,8'hff,8'h03,8'h03,8'h03,8'h03,8'hff,8'hff,8'hff,8'hff,8'h03,8'h03,8'h03,8'h03,8'hff,8'hff,8'h03,8'h03,8'h03,8'h03},
	{8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03},
	{8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03},
	{8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03},
	{8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03},
	{8'h03,8'h03,8'h03,8'h03,8'hFF,8'hFF,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'hFF,8'hFF,8'hFF,8'hFF,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'hFF,8'hFF,8'h03,8'h03,8'h03,8'h03},
	{8'h03,8'h03,8'h03,8'h03,8'hFF,8'hFF,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'hFF,8'hFF,8'hFF,8'hFF,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'hFF,8'hFF,8'h03,8'h03,8'h03,8'h03},
	{8'h03,8'h03,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'h03,8'h03,8'h03,8'h03,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'h03,8'h03,8'h03,8'h03,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'h03,8'h03},
	{8'h03,8'h03,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'h03,8'h03,8'h03,8'h03,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'h03,8'h03,8'h03,8'h03,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'h03,8'h03}
	};


logic [0:15][0:15][2:0] hit_colors = '{
    48'o4433333333333344, 
    48'o4443333333333444, 
    48'o1444333333334442, 
    48'o1144433333344422, 
    48'o1114443333444222, 
    48'o1111444334442222, 
    48'o1111144444422222, 
    48'o1111114444222222, 
    48'o1111114444222222, 
    48'o1111144444422222, 
    48'o1111444004442222, 
    48'o1114440000444222, 
    48'o1144400000044422, 
    48'o1444000000004442, 
    48'o4440000000000444, 
    48'o4400000000000044
};

// pipeline (ff) to get the pixel color from the array 
always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
        SM_LOOK     <= NORMAL_ST;
        RGBout      <= 8'h00;
        HitEdgeCode <= 3'h0;
        pause_counter <= 0;
		  inPause <= 0;
    end else begin
	     if (Super)
            SM_LOOK <= SUPER_ST;
        else
            SM_LOOK <= NORMAL_ST;

        case (SM_LOOK)
            NORMAL_ST: begin
                if (InsideRectangle) begin
                    RGBout      <= object_colors_normal[offsetY[4:0]][offsetX[4:0]];
                    HitEdgeCode <= hit_colors[HitCodeY][HitCodeX];
                end else begin
                    RGBout      <= TRANSPARENT_ENCODING;
                    HitEdgeCode <= 3'h0;
                end
            end

            SUPER_ST: begin
                if (InsideRectangle) begin
                    RGBout      <= object_colors_super[offsetY[4:0]][offsetX[4:0]];
                    HitEdgeCode <= hit_colors[HitCodeY][HitCodeX];
                end else begin
                    RGBout      <= TRANSPARENT_ENCODING;
                    HitEdgeCode <= 3'h0;
                end
            end
        endcase
    end
end
// decide if to draw the pixel or not 
assign drawingRequest = (RGBout != TRANSPARENT_ENCODING);

endmodule
