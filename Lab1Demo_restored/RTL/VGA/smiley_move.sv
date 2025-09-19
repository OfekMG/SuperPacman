module smiley_move(    
    input  logic clk,
    input  logic resetN,
    input  logic startOfFrame,
    input  logic Y_direction_key,
    input  logic toggle_x_key,
    input  logic collision,
    input  logic Y_direction_key_up,
    input  logic toggle_x_key_left,
    input  logic collision_ghost_smiley,
    input  logic [2:0] HitEdgeCode,
    output logic signed [10:0] topLeftX,
    output logic signed [10:0] topLeftY
);

parameter int INITIAL_X = 280;
parameter int INITIAL_Y = 160;
parameter int INITIAL_X_SPEED = 40;
parameter int INITIAL_Y_SPEED = 20;
parameter int PAUSE_DURATION_FRAMES = 90; // 3 sec @ 30Hz

const int FIXED_POINT_MULTIPLIER = 64;
const int OBJECT_WIDTH_X  = 64;
const int OBJECT_HIGHT_Y  = 64;
const int SafetyMargin    = 2;

const int x_FRAME_LEFT   = SafetyMargin * FIXED_POINT_MULTIPLIER;
const int x_FRAME_RIGHT  = (639 - SafetyMargin - OBJECT_WIDTH_X) * FIXED_POINT_MULTIPLIER;
const int y_FRAME_TOP    = SafetyMargin * FIXED_POINT_MULTIPLIER;
const int y_FRAME_BOTTOM = (479 - SafetyMargin - OBJECT_HIGHT_Y) * FIXED_POINT_MULTIPLIER;

const logic [4:0] CORNER = 5'b10000;
const logic [3:0] TOP    = 4'b1000;
const logic [3:0] RIGHT  = 4'b0100;
const logic [3:0] LEFT   = 4'b0010;
const logic [3:0] BOTTOM = 4'b0001;

enum logic [2:0] {IDLE_ST, MOVE_ST, START_OF_FRAME_ST, POSITION_CHANGE_ST, POSITION_LIMITS_ST, PAUSE_ST} SM_Motion;

int Xspeed;
int Yspeed;
int Xposition;
int Yposition;
logic toggle_x_key_D;
logic [6:0] pause_counter;
logic [4:0] hit_reg = 5'b00000;

always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
        SM_Motion <= IDLE_ST;
        Xspeed <= 0;
        Yspeed <= 0;
        Xposition <= 0;
        Yposition <= 0;
        toggle_x_key_D <= 0;
        hit_reg <= 5'b0;
        pause_counter <= 0;
    end else begin
        toggle_x_key_D <= toggle_x_key;

        case(SM_Motion)
            IDLE_ST: begin
                Xspeed <= INITIAL_X_SPEED;
                Yspeed <= INITIAL_Y_SPEED;
                Xposition <= INITIAL_X * FIXED_POINT_MULTIPLIER;
                Yposition <= INITIAL_Y * FIXED_POINT_MULTIPLIER;
                pause_counter <= 0;
                if (startOfFrame)
                    SM_Motion <= MOVE_ST;
            end

            MOVE_ST: begin
                if (Y_direction_key) begin Xspeed <= 0; Yspeed <= 60; end
                if (toggle_x_key) begin Yspeed <= 0; Xspeed <= 60; end
                if (Y_direction_key_up) begin Xspeed <= 0; Yspeed <= -60; end
                if (toggle_x_key_left) begin Yspeed <= 0; Xspeed <= -60; end

                if (collision) hit_reg[HitEdgeCode] <= 1'b1;

                if (collision_ghost_smiley) begin
                    Xspeed <= 0;
                    Yspeed <= 0;
                    pause_counter <= 0;
                    SM_Motion <= PAUSE_ST;
                end else if (startOfFrame) begin
                    SM_Motion <= START_OF_FRAME_ST;
                end
            end

            PAUSE_ST: begin
                if (startOfFrame) begin
                    if (pause_counter < PAUSE_DURATION_FRAMES - 1)
                        pause_counter <= pause_counter + 1;
                    else
                        SM_Motion <= IDLE_ST;
                end
            end

            START_OF_FRAME_ST: begin
                if (hit_reg[3:0] & TOP && Yspeed < 0) Yspeed <= 0;
                if (hit_reg[3:0] & BOTTOM && Yspeed > 0) Yspeed <= 0;
                if (hit_reg[3:0] & LEFT && Xspeed < 0) Xspeed <= 0;
                if (hit_reg[3:0] & RIGHT && Xspeed > 0) Xspeed <= 0;

                hit_reg <= 5'b00000;
                SM_Motion <= POSITION_CHANGE_ST;
            end

            POSITION_CHANGE_ST: begin
                Xposition <= Xposition + Xspeed;
                Yposition <= Yposition + Yspeed;
                SM_Motion <= POSITION_LIMITS_ST;
            end

            POSITION_LIMITS_ST: begin
                if (Xposition < x_FRAME_LEFT) Xposition <= x_FRAME_LEFT;
                if (Xposition > x_FRAME_RIGHT) Xposition <= x_FRAME_RIGHT;
                if (Yposition < y_FRAME_TOP) Yposition <= y_FRAME_TOP;
                if (Yposition > y_FRAME_BOTTOM) Yposition <= y_FRAME_BOTTOM;
                SM_Motion <= MOVE_ST;
            end
        endcase
    end
end

assign topLeftX = Xposition / FIXED_POINT_MULTIPLIER;
assign topLeftY = Yposition / FIXED_POINT_MULTIPLIER;

endmodule
