// (c) Technion IIT, Department of Electrical Engineering 2025

module ghost3_move (
    input  logic clk,
    input  logic resetN,
    input  logic startOfFrame,      // short pulse every start of frame 30Hz
    input  logic collision,         // collision if ghost hits a wall (pulse)
    input  logic [2:0] HitEdgeCode, // optional, could bias random direction (0..4)
    input  logic [1:0] rnd_dir,     // optional seed bits (used at reset)
    input  logic collision_ghost_smiley,
    input  logic Super,
	 input  logic strike,
	 input  logic second_phase,

    output logic signed [10:0] topLeftX,
    output logic signed [10:0] topLeftY
);

    // Parameters
    parameter int INITIAL_X = 280;
    parameter int INITIAL_Y = 185;
    parameter int SPEED     = 60;
    parameter int PAUSE_DURATION_FRAMES = 90; // 3 sec @ 30Hz

    const int FIXED_POINT_MULTIPLIER = 64;  
    const int OBJECT_WIDTH_X = 32;
    const int OBJECT_HIGHT_Y = 32;
    const int SafetyMargin   = 2;
	 
	 int multiplier;


    const int x_FRAME_LEFT   = (SafetyMargin) * FIXED_POINT_MULTIPLIER; 
    const int x_FRAME_RIGHT  = (639 - SafetyMargin - OBJECT_WIDTH_X) * FIXED_POINT_MULTIPLIER; 
    const int y_FRAME_TOP    = (SafetyMargin) * FIXED_POINT_MULTIPLIER;
    const int y_FRAME_BOTTOM = (479 - SafetyMargin - OBJECT_HIGHT_Y) * FIXED_POINT_MULTIPLIER; 

    // FSM states
    enum logic [2:0] {
        IDLE_ST,
        MOVE_ST,
        START_OF_FRAME_ST,
        POSITION_CHANGE_ST,
        POSITION_LIMITS_ST,
        PAUSE_ST,
        SUPER_MOVE_ST
    } SM;

    int Xposition;
    int Yposition;
    int Xspeed;
    int Yspeed;

    logic [4:0] hit_reg;
    logic [6:0] pause_counter;
    logic [6:0] lfsr;            
    logic [1:0] go_direction;   

    // ----------------------------
    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            // Reset to initial state
            SM        <= IDLE_ST;
            Xposition <= INITIAL_X * FIXED_POINT_MULTIPLIER;
            Yposition <= INITIAL_Y * FIXED_POINT_MULTIPLIER;
            Xspeed    <= SPEED;
            Yspeed    <= 0;
            hit_reg   <= 5'b00000;
            pause_counter <= 0;
            lfsr      <= {rnd_dir, 5'b10101}; 
            go_direction <= {rnd_dir[1], rnd_dir[0]};
        end else begin
		  if (second_phase) begin
				multiplier = 1.5;
		  end else begin
		  multiplier = 1;
		  end
            case (SM)
                IDLE_ST: begin
                    Xposition <= INITIAL_X * FIXED_POINT_MULTIPLIER + 800;
                    Yposition <= INITIAL_Y * FIXED_POINT_MULTIPLIER;
                    if (startOfFrame)
                        SM <= MOVE_ST;
                end

                MOVE_ST: begin
                    if (collision) begin
                        hit_reg[HitEdgeCode] <= 1'b1;
                    end else if (Super) begin
                        SM <= SUPER_MOVE_ST;
                    end
						  if (collision_ghost_smiley) begin
                    Xspeed <= 0;
                    Yspeed <= 0;
                    pause_counter <= 0;
                    SM <= PAUSE_ST;
                end else if (strike) 
								SM <= IDLE_ST;
					 if (startOfFrame)
                        SM <= START_OF_FRAME_ST;
                end

                SUPER_MOVE_ST: begin 
                    if (collision) begin
                        hit_reg[HitEdgeCode] <= 1'b1;
                    end

                    if (collision_ghost_smiley) begin
                        Xspeed <= 0;
                        Yspeed <= 0;
                        pause_counter <= 0;
                        SM <= PAUSE_ST;

                    end else if (!Super) begin
                        SM <= MOVE_ST;

                    end else if (startOfFrame) begin
                        SM <= START_OF_FRAME_ST;
                    end
                end
						
                PAUSE_ST: begin
                    if (startOfFrame) begin
                        if (pause_counter < PAUSE_DURATION_FRAMES - 1)
                            pause_counter <= pause_counter + 1;
                        else begin
                            Xposition <= INITIAL_X * FIXED_POINT_MULTIPLIER + 800;
                            Yposition <= INITIAL_Y * FIXED_POINT_MULTIPLIER;
                            Xspeed    <= SPEED;
                            Yspeed    <= 0;
                            hit_reg   <= 5'b00000;
                            SM        <= MOVE_ST;
									 
                        end
                    end
                end
                
                START_OF_FRAME_ST: begin
                    if (hit_reg != 5'b00000) begin
                        lfsr <= {lfsr[5:0], (lfsr[6] ^ lfsr[5])};
                        go_direction <= {lfsr[1], lfsr[0]};
                    end

                    if (hit_reg == 5'b00000) begin
                        // no change
                        Xspeed <= Xspeed;
                        Yspeed <= Yspeed;
                    end else begin
                        if (hit_reg[3]) begin // top
                            if (Yspeed < 0) begin
                                case (go_direction)
                                    2'b01: begin Yspeed <=  SPEED; Xspeed <= 0; end // down
                                    2'b10: begin Yspeed <=  0;    Xspeed <= -SPEED; end // left
                                    2'b11: begin Yspeed <=  0;    Xspeed <=  SPEED; end // right
                                    default: begin Yspeed <=  SPEED; Xspeed <= 0; end
                                endcase
                            end
                        end

                        if (hit_reg[0]) begin // bottom
                            if (Yspeed > 0) begin
                                case (go_direction)
                                    2'b01: begin Yspeed <= -SPEED; Xspeed <= 0; end // up
                                    2'b10: begin Yspeed <=  0;    Xspeed <= -SPEED; end // left
                                    2'b11: begin Yspeed <=  0;    Xspeed <=  SPEED; end // right
                                    default: begin Yspeed <= -SPEED; Xspeed <= 0; end
                                endcase
                            end
                        end

                        if (hit_reg[1]) begin // left
                            if (Xspeed < 0) begin
                                case (go_direction)
                                    2'b01: begin Yspeed <=  SPEED; Xspeed <= 0; end // down
                                    2'b10: begin Yspeed <=  0;    Xspeed <=  SPEED; end // right
                                    2'b11: begin Yspeed <=  0;    Xspeed <=  SPEED; end // right (same)
                                    default: begin Yspeed <= -SPEED; Xspeed <= 0; end // up
                                endcase
                            end
                        end

                        if (hit_reg[2]) begin // right
                            if (Xspeed > 0) begin
                                case (go_direction)
                                    2'b01: begin Yspeed <=  SPEED; Xspeed <= 0; end // down
                                    2'b10: begin Yspeed <=  0;    Xspeed <= -SPEED; end // left
                                    2'b11: begin Yspeed <=  0;    Xspeed <= -SPEED; end // left (same)
                                    default: begin Yspeed <= -SPEED; Xspeed <= 0; end // up
                                endcase
                            end
                        end
                    end

                    // clear hits and continue
                    hit_reg <= 5'b00000;
                    SM <= POSITION_CHANGE_ST;
                end

                POSITION_CHANGE_ST: begin
                    // Normal movement update per frame
                    Xposition <= Xposition + Xspeed*multiplier;
                    Yposition <= Yposition + Yspeed*multiplier;
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
