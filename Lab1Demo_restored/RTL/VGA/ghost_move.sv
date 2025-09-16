// (c) Technion IIT, Department of Electrical Engineering 2025 

module ghost_move (
    input  logic clk,
    input  logic resetN,
    input  logic startOfFrame,      // short pulse every start of frame 30Hz 
    input  logic collision,         // collision if ghost hits a wall
    input  logic [2:0] HitEdgeCode, // which side we hit (0:TOP,1:BOTTOM,2:LEFT,3:RIGHT,4:CORNER)
    output logic signed [10:0] topLeftX,
    output logic signed [10:0] topLeftY,
    input  logic [1:0] rnd_dir      // random direction input (optional if no free path)
);

// Parameters
parameter int INITIAL_X = 280;
parameter int INITIAL_Y = 185;
parameter int SPEED     = 60;

const int FIXED_POINT_MULTIPLIER = 64; 
const int OBJECT_WIDTH_X = 32;
const int OBJECT_HIGHT_Y = 32;
const int SafetyMargin   = 2;

const int x_FRAME_LEFT   = (SafetyMargin)* FIXED_POINT_MULTIPLIER; 
const int x_FRAME_RIGHT  = (639 - SafetyMargin - OBJECT_WIDTH_X)* FIXED_POINT_MULTIPLIER; 
const int y_FRAME_TOP    = (SafetyMargin)* FIXED_POINT_MULTIPLIER;
const int y_FRAME_BOTTOM = (479 - SafetyMargin - OBJECT_HIGHT_Y)* FIXED_POINT_MULTIPLIER; 

// Direction encoding
typedef enum logic [1:0] {DIR_UP=2'b00, DIR_DOWN=2'b01, DIR_LEFT=2'b10, DIR_RIGHT=2'b11} direction_t;
direction_t dir;

// FSM states
enum logic [1:0] {IDLE_ST, MOVE_ST, COLLISION_PROCESS_ST} SM;

// Fixed-point positions
int Xposition;
int Yposition;

// Collision hit register
logic [4:0] hit_reg; // track edges: TOP/BOTTOM/LEFT/RIGHT/CORNER

// ----------------------------
always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
        SM        <= IDLE_ST;
        dir       <= DIR_LEFT;
        Xposition <= INITIAL_X * FIXED_POINT_MULTIPLIER;
        Yposition <= INITIAL_Y * FIXED_POINT_MULTIPLIER;
        hit_reg   <= 5'b0;
    end else begin
        case (SM)
            // ----------------
            IDLE_ST: begin
                if (startOfFrame)
                    SM <= MOVE_ST;
            end

            // ----------------
            MOVE_ST: begin
                if (startOfFrame) begin
                    // Move ghost according to current direction
                    case (dir)
                        DIR_UP:    Yposition <= Yposition - SPEED;
                        DIR_DOWN:  Yposition <= Yposition + SPEED;
                        DIR_LEFT:  Xposition <= Xposition - SPEED;
                        DIR_RIGHT: Xposition <= Xposition + SPEED;
                    endcase

                    // register collisions
                    if (collision)
                        hit_reg[HitEdgeCode] <= 1'b1;

                    // if any collision detected, process next frame
                    if (hit_reg != 0)
                        SM <= COLLISION_PROCESS_ST;
                end
            end

            // ----------------
            COLLISION_PROCESS_ST: begin
                // Edge-by-edge bounce logic
                if (hit_reg[0] && dir == DIR_UP)      dir <= DIR_DOWN;  // TOP
                if (hit_reg[1] && dir == DIR_DOWN)    dir <= DIR_UP;    // BOTTOM
                if (hit_reg[2] && dir == DIR_LEFT)    dir <= DIR_RIGHT; // LEFT
                if (hit_reg[3] && dir == DIR_RIGHT)   dir <= DIR_LEFT;  // RIGHT
                if (hit_reg[4])                        dir <= direction_t'(rnd_dir); // CORNER: pick random

                // clear hits
                hit_reg <= 5'b0;

                SM <= MOVE_ST;
            end
        endcase

        // keep inside frame
        if (Xposition < x_FRAME_LEFT)   Xposition <= x_FRAME_LEFT;
        if (Xposition > x_FRAME_RIGHT)  Xposition <= x_FRAME_RIGHT;
        if (Yposition < y_FRAME_TOP)    Yposition <= y_FRAME_TOP;
        if (Yposition > y_FRAME_BOTTOM) Yposition <= y_FRAME_BOTTOM;
    end
end

// Output (convert from fixed-point)
assign topLeftX = Xposition / FIXED_POINT_MULTIPLIER;
assign topLeftY = Yposition / FIXED_POINT_MULTIPLIER;

endmodule
