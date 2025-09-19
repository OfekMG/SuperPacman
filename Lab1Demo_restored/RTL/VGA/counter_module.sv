module counter_module (

    input  logic        clk,
    input  logic        resetN,         
    input  logic        increment,      // one‐clk pulse: +1
    input  logic        decrement,      // one‐clk pulse: –1

    output logic [3:0]  units    = INIT_ONES,
    output logic [3:0]  tens     = INIT_TENS,
    output logic [3:0]  hundreds = INIT_HUNDREDS,
    output logic        timeEndedPulse  // one‐clk pulse when digits first become 000 in PLAY
);
    parameter logic [3:0] INIT_ONES     = 4'd9;
    parameter logic [3:0] INIT_TENS     = 4'd9;
    parameter logic [3:0] INIT_HUNDREDS = 4'd9;
	 
    logic enable;
    logic prev_zero;

    logic [3:0] o_next, t_next, h_next;
    logic       next_zero;

    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            // Asynchronous reset → load INIT values, clear prev_zero & pulse
            units           <= INIT_ONES;
            tens            <= INIT_TENS;
            hundreds        <= INIT_HUNDREDS;
            prev_zero       <= 1'b0;
            timeEndedPulse  <= 1'b0;
        end
        else begin
            o_next = units;
            t_next = tens;
            h_next = hundreds;

            if (increment && enable) begin
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
            else if (decrement && enable) begin
                // *** DECREMENT path ***
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

            next_zero = (o_next == 4'd0 && t_next == 4'd0 && h_next == 4'd0);

            if (next_zero && !prev_zero) begin
                timeEndedPulse <= 1'b1;
            end else begin
                timeEndedPulse <= 1'b0;
            end

            prev_zero <= next_zero;

            units    <= o_next;
            tens     <= t_next;
            hundreds <= h_next;
        end
    end

endmodule
