// (c) Technion IIT, Department of Electrical Engineering 2025

module ghost_move (
    input  logic clk,
    input  logic resetN,
    input  logic startOfFrame,      // short pulse every start of frame 30Hz
    input  logic collision,         // collision if ghost hits a wall
    input  logic [2:0] HitEdgeCode, // optional, could bias random direction
    input  logic [1:0] rnd_dir,     // random direction input
    output logic signed [10:0] topLeftX,
    output logic signed [10:0] topLeftY
);

    // Parameters
    parameter int INITIAL_X = 280;
    parameter int INITIAL_Y = 185;
    parameter int SPEED     = 60;

    const int FIXED_POINT_MULTIPLIER = 64;  
    const int OBJECT_WIDTH_X = 32;
    const int OBJECT_HIGHT_Y = 32;
    const int SafetyMargin   = 2;

    const int x_FRAME_LEFT   = (SafetyMargin) * FIXED_POINT_MULTIPLIER; 
    const int x_FRAME_RIGHT  = (639 - SafetyMargin - OBJECT_WIDTH_X) * FIXED_POINT_MULTIPLIER; 
    const int y_FRAME_TOP    = (SafetyMargin) * FIXED_POINT_MULTIPLIER;
    const int y_FRAME_BOTTOM = (479 - SafetyMargin - OBJECT_HIGHT_Y) * FIXED_POINT_MULTIPLIER; 

    // FSM states
    enum logic [2:0] {IDLE_ST, MOVE_ST, START_OF_FRAME_ST, POSITION_CHANGE_ST, POSITION_LIMITS_ST} SM;

    // Fixed-point positions
    int Xposition;
    int Yposition;

    // Current velocity
    int Xspeed;
    int Yspeed;

    // Cooldown for collision blocking
    int cooldown_frames;
    logic collision_blocked;

    // ----------------------------
    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            SM <= IDLE_ST;
            Xposition <= INITIAL_X * FIXED_POINT_MULTIPLIER;
            Yposition <= INITIAL_Y * FIXED_POINT_MULTIPLIER;
            Xspeed <= SPEED;
            Yspeed <= 0;
            cooldown_frames <= 0;
            collision_blocked <= 0;
        end else begin
            // Update collision block cooldown
            if (startOfFrame && collision_blocked) begin
                if (cooldown_frames > 0)
                    cooldown_frames <= cooldown_frames - 1;
                else
                    collision_blocked <= 0;
            end

            case (SM)
                IDLE_ST: begin
                    Xspeed <= SPEED;
                    Yspeed <= 0;
                    Xposition <= INITIAL_X * FIXED_POINT_MULTIPLIER;
                    Yposition <= INITIAL_Y * FIXED_POINT_MULTIPLIER;
                    if (startOfFrame)
                        SM <= MOVE_ST;
                end

                MOVE_ST: begin
                    // Process collision only if not blocked
                    if (collision && !collision_blocked) begin
                        // 1. REVERT the last move to push the ghost out of the wall
                        Xposition <= Xposition - Xspeed;
                        Yposition <= Yposition - Yspeed;

                        // 2. Force a 90-degree turn
                        if (Xspeed != 0) begin 
                            Xspeed <= 0;
                            Yspeed <= (rnd_dir[0]) ? SPEED : -SPEED; 
                        end else begin 
                            Yspeed <= 0;
                            Xspeed <= (rnd_dir[0]) ? SPEED : -SPEED;
                        end

                        // 3. Block further collision checks
                        collision_blocked <= 1;
                        cooldown_frames   <= 15; 
							
                    end

                    if (startOfFrame)
                        SM <= START_OF_FRAME_ST;
                end

                START_OF_FRAME_ST: begin
                    SM <= POSITION_CHANGE_ST;
                end

                POSITION_CHANGE_ST: begin
                    Xposition <= Xposition + Xspeed;
                    Yposition <= Yposition + Yspeed;
                    SM <= POSITION_LIMITS_ST;
                end

                POSITION_LIMITS_ST: begin
                    if (Xposition < x_FRAME_LEFT)   Xposition <= x_FRAME_LEFT;
                    if (Xposition > x_FRAME_RIGHT)  Xposition <= x_FRAME_RIGHT;
                    if (Yposition < y_FRAME_TOP)    Yposition <= y_FRAME_TOP;
                    if (Yposition > y_FRAME_BOTTOM) Yposition <= y_FRAME_BOTTOM;
                    SM <= MOVE_ST;
                end
            endcase
        end
    end

    // Output (convert from fixed-point)
    assign topLeftX = Xposition / FIXED_POINT_MULTIPLIER;
    assign topLeftY = Yposition / FIXED_POINT_MULTIPLIER;

endmodule