module lives_counter_module (
    input  logic        clk,
    input  logic        resetN,
    input  logic        strike,	 
	 input  logic        Super,
	 input  logic        startOfFrame,

    output logic [3:0]  units,
    output logic [3:0]  tens,
    output logic [3:0]  hundreds
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
            units    <= INIT_ONES;
            tens     <= INIT_TENS;
            hundreds <= INIT_HUNDREDS;

            strike_sync0 <= 1'b0;
            strike_sync1 <= 1'b0;
        end else begin
            strike_sync0 <= strike;
            strike_sync1 <= strike_sync0;

				// finding edge
            strike_rising = strike_sync1 && !strike_sync0; // note: שים לב שסדר ההשמה כאן משתמש בבדיקת ההיסטוריה; אפשר גם לעשות בשני מצבים
            // ניתן לשים prev_score ולחשב: score_rising = score_sync1 && !prev_score; prev_score <= score_sync1;


				//default
				o_next = units;
            t_next = tens;
            h_next = hundreds;
				
				if (Super) begin 
				end else if (pause && startOfFrame) begin
							 if ((pause_counter < PAUSE_DURATION_FRAMES - 1))
                      pause_counter <= pause_counter + 1;
                  else
                      pause = 1'b0;
              end 

             if (strike_rising) begin
                // *** DECREMENT path ***
					 pause <= 1;
                if (units == 4'd0) begin
                    o_next = 4'd9;
                    if (tens == 4'd0) begin
                        t_next = 4'd9;
                        h_next = (hundreds == 4'd0) ? 4'd9 : (hundreds - 4'd1);
                    end else begin
                        t_next = tens - 4'd1;
                        h_next = hundreds;
                    end
                end else begin
                    o_next = units - 4'd1;
                    t_next = tens;
                    h_next = hundreds;
                end
            end

            // עדכן רגיסטרים
            units    <= o_next;
            tens     <= t_next;
            hundreds <= h_next;
        end
    end

endmodule
