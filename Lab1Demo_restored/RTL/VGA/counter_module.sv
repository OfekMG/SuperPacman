module counter_module (
    input  logic        clk,
    input  logic        resetN,
    input  logic        score,	 
		
    output logic [3:0]  units,
    output logic [3:0]  tens,
    output logic [3:0]  hundreds,
	 output logic win,
	 output logic second_phase
);
    parameter logic [3:0] INIT_ONES     = 4'd0;
    parameter logic [3:0] INIT_TENS     = 4'd0;
    parameter logic [3:0] INIT_HUNDREDS = 4'd0;
	
	//identify rising edge
    logic score_sync0, score_sync1;
    logic score_rising;
	
	// to calculate next value
    logic [3:0] o_next, t_next, h_next;

    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            units    <= INIT_ONES;
            tens     <= INIT_TENS;
            hundreds <= INIT_HUNDREDS;
				second_phase <= 1'b0;

            score_sync0 <= 1'b0;
            score_sync1 <= 1'b0;
        end else begin
            score_sync0 <= score;
            score_sync1 <= score_sync0;

				// finding edge
            score_rising = score_sync1 && !score_sync0; // note: שים לב שסדר ההשמה כאן משתמש בבדיקת ההיסטוריה; אפשר גם לעשות בשני מצבים
				
				if (tens == 5) begin
					second_phase = 1'b1;
				end

				//default
				o_next = units;
            t_next = tens;
            h_next = hundreds;
				if (score_rising) begin
             // *** INCREMENT path ***
                if (units == 4'd9) begin
                    o_next = 4'd0;
                    if (tens == 4'd9) begin
                        t_next = 4'd0;
                        h_next = (hundreds == 4'd9) ? 4'd0 : (hundreds + 4'd1);
                    end else begin
                        t_next = tens + 4'd1;
                        h_next = hundreds;
                    end
                end else begin
                    o_next = units + 4'd1;
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
	 assign win = (hundreds == 4'd1 && tens == 4'd0 && units == 4'd5);


endmodule
