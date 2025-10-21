module pickaxe_lives_counter_module (
    input  logic        clk,
    input  logic        resetN,
    input  logic        collision_Smiley_Hart,	
	 input  logic        collision_Smiley_pickaxe,
	 input  logic        startOfFrame,

    output logic [3:0]  units
);
    parameter logic [3:0] INIT_ONES     = 4'd3;
    parameter logic [3:0] INIT_TENS     = 4'd0;
    parameter logic [3:0] INIT_HUNDREDS = 4'd0;
	 
	 logic [6:0] pause_counter;
	 parameter int PAUSE_DURATION_FRAMES = 90;// 3 sec @ 30Hz

	
	//identify rising edge
    logic strike_sync0, strike_sync1;
    logic strike_rising;
	 logic pause;

	// to calculate next value
    logic [3:0] o_next, t_next, h_next;

    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            units    <= 0;
            strike_sync0 <= 1'b0;
            strike_sync1 <= 1'b0;
        end else begin
            strike_sync0 <= collision_Smiley_Hart;
            strike_sync1 <= strike_sync0;

				// finding edge
            strike_rising = strike_sync1 && !strike_sync0; // note: שים לב שסדר ההשמה כאן משתמש בבדיקת ההיסטוריה; אפשר גם לעשות בשני מצבים
            // ניתן לשים prev_score ולחשב: score_rising = score_sync1 && !prev_score; prev_score <= score_sync1;


				if (collision_Smiley_pickaxe) begin
				//default
				o_next = units;
				end 

             else if (strike_rising) begin
                // *** DECREMENT path ***
                    o_next = units - 4'd1;
            end

            // עדכן רגיסטרים
            units    <= o_next;

        end
    end

endmodule
