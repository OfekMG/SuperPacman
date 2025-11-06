//===============================================================
//  Module: pacman_move
//  Description: 
//    Handles Pac-Man’s movement logic, including direction control,
//    collisions, pause behavior after being hit, and speed boost
//    when in "Super" mode. Positions are tracked in fixed-point
//    precision for smoother motion.
//
//  Author’s notes:
//    - Keeps all motion states inside a clear state machine (FSM).
//    - Uses fixed-point arithmetic for subpixel accuracy.
//    - Designed for 30 FPS game loop using `startOfFrame` signal.
//===============================================================

module pacman_move(    
    input  logic clk,
    input  logic resetN,
    input  logic startOfFrame,          // triggers once per display frame
    input  logic Y_direction_key,       // move down
    input  logic toggle_x_key,          // move right
    input  logic collision,             // collision with wall or barrier
    input  logic Y_direction_key_up,    // move up
    input  logic toggle_x_key_left,     // move left
    input  logic collision_ghost_smiley,// collision with enemy
    input  logic [2:0] HitEdgeCode,     // identifies which edge was hit
    input  logic Super,                 // indicates Super mode active
    output logic signed [10:0] topLeftX,
    output logic signed [10:0] topLeftY
);

//---------------------------------------------------------------
//  PARAMETERS AND CONSTANTS
//---------------------------------------------------------------
parameter int INITIAL_X = 280;
parameter int INITIAL_Y = 160;
parameter int INITIAL_X_SPEED = 40;
parameter int INITIAL_Y_SPEED = 20;
parameter int PAUSE_DURATION_FRAMES = 90; // 3 seconds @ 30 FPS

// Fixed-point scaling factor (helps keep motion smooth)
const int FIXED_POINT_MULTIPLIER = 64;

// Object dimensions (in pixels)
const int OBJECT_WIDTH_X  = 64;
const int OBJECT_HIGHT_Y  = 64;
const int SafetyMargin    = 2;

// Frame boundaries in fixed-point units
const int x_FRAME_LEFT   = SafetyMargin * FIXED_POINT_MULTIPLIER;
const int x_FRAME_RIGHT  = (639 - SafetyMargin - OBJECT_WIDTH_X) * FIXED_POINT_MULTIPLIER;
const int y_FRAME_TOP    = SafetyMargin * FIXED_POINT_MULTIPLIER;
const int y_FRAME_BOTTOM = (479 - SafetyMargin - OBJECT_HIGHT_Y) * FIXED_POINT_MULTIPLIER;

// Edge codes for collision handling
const logic [4:0] CORNER = 5'b10000;
const logic [3:0] TOP    = 4'b1000;
const logic [3:0] RIGHT  = 4'b0100;
const logic [3:0] LEFT   = 4'b0010;
const logic [3:0] BOTTOM = 4'b0001;

//---------------------------------------------------------------
//  FSM STATES
//---------------------------------------------------------------
enum logic [2:0] {
    IDLE_ST,             // Waiting or just initialized
    MOVE_ST,             // Normal movement
    START_OF_FRAME_ST,   // Frame-based processing
    POSITION_CHANGE_ST,  // Update positions
    POSITION_LIMITS_ST,  // Apply boundaries
    PAUSE_ST,            // Temporary stop after ghost hit
    SUPER_MOVE_ST        // Faster movement during Super mode
} SM_Motion;

//---------------------------------------------------------------
//  INTERNAL SIGNALS
//---------------------------------------------------------------
int Xspeed;
int Yspeed;
int Xposition;
int Yposition;

logic toggle_x_key_D;       // registered copy (useful for edge detect)
logic [6:0] pause_counter;  // used for 3s delay after death
logic [4:0] hit_reg = 5'b00000;  // stores which edge was hit

//---------------------------------------------------------------
//  MAIN FSM
//---------------------------------------------------------------
always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
        // Reset all registers
        SM_Motion <= IDLE_ST;
        Xspeed <= 0;
        Yspeed <= 0;
        Xposition <= 0;
        Yposition <= 0;
        toggle_x_key_D <= 0;
        hit_reg <= 5'b0;
        pause_counter <= 0;
    end else begin
        toggle_x_key_D <= toggle_x_key;  // keep 1-cycle history

        case(SM_Motion)

        //-------------------------------------------------------
        // IDLE_ST
        // Initialization of position and speed before movement
        //-------------------------------------------------------
        IDLE_ST: begin
            Xspeed <= INITIAL_X_SPEED;
            Yspeed <= INITIAL_Y_SPEED;
            Xposition <= INITIAL_X * FIXED_POINT_MULTIPLIER;
            Yposition <= INITIAL_Y * FIXED_POINT_MULTIPLIER;
            pause_counter <= 0;
            if (startOfFrame)
                SM_Motion <= MOVE_ST;
        end

        //-------------------------------------------------------
        // MOVE_ST
        // Handles key inputs and collision logic
        //-------------------------------------------------------
        MOVE_ST: begin
            // Movement control: only one axis at a time
            if (Y_direction_key)     begin Xspeed <= 0; Yspeed <=  60; end // down
            if (toggle_x_key)        begin Yspeed <= 0; Xspeed <=  60; end // right
            if (Y_direction_key_up)  begin Xspeed <= 0; Yspeed <= -60; end // up
            if (toggle_x_key_left)   begin Yspeed <= 0; Xspeed <= -60; end // left

            // Register collision hits
            if (collision)
                hit_reg[HitEdgeCode] <= 1'b1;

            // Enter Super mode if active
            if (Super) begin
                SM_Motion <= SUPER_MOVE_ST;

            // If Pac-Man collides with ghost, pause for 3 seconds
            end else if (collision_ghost_smiley) begin
                Xspeed <= 0;
                Yspeed <= 0;
                pause_counter <= 0;
                SM_Motion <= PAUSE_ST;

            // Otherwise advance once per frame
            end else if (startOfFrame) begin
                SM_Motion <= START_OF_FRAME_ST;
            end
        end

        //-------------------------------------------------------
        // SUPER_MOVE_ST
        // Same as MOVE_ST but faster speed when Super is active
        //-------------------------------------------------------
        SUPER_MOVE_ST: begin
            if (Y_direction_key)     begin Xspeed <= 0; Yspeed <=  80; end
            if (toggle_x_key)        begin Yspeed <= 0; Xspeed <=  80; end
            if (Y_direction_key_up)  begin Xspeed <= 0; Yspeed <= -80; end
            if (toggle_x_key_left)   begin Yspeed <= 0; Xspeed <= -80; end

            if (collision)
                hit_reg[HitEdgeCode] <= 1'b1;
            else if (startOfFrame)
                SM_Motion <= START_OF_FRAME_ST;
        end

        //-------------------------------------------------------
        // PAUSE_ST
        // Keeps Pac-Man frozen after being hit
        //-------------------------------------------------------
        PAUSE_ST: begin
            if (startOfFrame) begin
                if (pause_counter < PAUSE_DURATION_FRAMES - 1)
                    pause_counter <= pause_counter + 1;
                else
                    SM_Motion <= IDLE_ST; // reset to starting position
            end
        end

        //-------------------------------------------------------
        // START_OF_FRAME_ST
        // Edge hit handling and cleanup
        //-------------------------------------------------------
        START_OF_FRAME_ST: begin
            // Stop movement in the direction of the collision
            if (hit_reg[3:0] & TOP    && Yspeed < 0) Yspeed <= 0;
            if (hit_reg[3:0] & BOTTOM && Yspeed > 0) Yspeed <= 0;
            if (hit_reg[3:0] & LEFT   && Xspeed < 0) Xspeed <= 0;
            if (hit_reg[3:0] & RIGHT  && Xspeed > 0) Xspeed <= 0;

            // Clear collision flags
            hit_reg <= 5'b00000;

            SM_Motion <= POSITION_CHANGE_ST;
        end

        //-------------------------------------------------------
        // POSITION_CHANGE_ST
        // Update Pac-Man’s position using current speed
        //-------------------------------------------------------
        POSITION_CHANGE_ST: begin
            Xposition <= Xposition + Xspeed;
            Yposition <= Yposition + Yspeed;
            SM_Motion <= POSITION_LIMITS_ST;
        end

        //-------------------------------------------------------
        // POSITION_LIMITS_ST
        // Keep Pac-Man inside screen boundaries
        //-------------------------------------------------------
        POSITION_LIMITS_ST: begin
            if (Xposition < x_FRAME_LEFT)
                Xposition <= x_FRAME_LEFT;

            // Wraparound to left edge (tunnel effect)
            if (Xposition > x_FRAME_RIGHT - 10)
                Xposition <= 68 * FIXED_POINT_MULTIPLIER;

            // Teleport vertically if crossing top (optional behavior)
            if (Yposition < y_FRAME_TOP)
                Yposition <= y_FRAME_BOTTOM;

            if (Yposition > y_FRAME_BOTTOM)
                Yposition <= y_FRAME_BOTTOM;

            SM_Motion <= MOVE_ST;
        end
        endcase
    end
end

//---------------------------------------------------------------
//  OUTPUT ASSIGNMENTS
//  Convert from fixed-point to integer coordinates for display
//---------------------------------------------------------------
assign topLeftX = Xposition / FIXED_POINT_MULTIPLIER;
assign topLeftY = Yposition / FIXED_POINT_MULTIPLIER;

endmodule
