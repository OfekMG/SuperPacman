module lives_counter_module (
    input  logic        clk,
    input  logic        resetN,
    input  logic        strike,	 
    input  logic        Super,
    input  logic        startOfFrame,

    output logic [3:0]  units,
    output logic [3:0]  tens, // not used
    output logic [3:0]  hundreds //not used
);
    // Initial values
    parameter logic [3:0] INIT_ONES     = 4'd4;
    parameter logic [3:0] INIT_TENS     = 4'd0;
    parameter logic [3:0] INIT_HUNDREDS = 4'd0;

    // Parameters
    parameter int FRAME_RATE_HZ = 60;
    parameter int INVINCIBILITY_DURATION_FRAMES = 3 * FRAME_RATE_HZ; // 3 seconds

    // Internal logic
    logic invincible;
    logic [8:0] invincibility_counter; // supports up to 512 frames

    logic [3:0] o_next, t_next, h_next;

    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            units                <= INIT_ONES + 2;
            tens                 <= INIT_TENS;
            hundreds             <= INIT_HUNDREDS;
            invincible           <= 1'b0;
            invincibility_counter <= 0;
        end else begin
            o_next = units;
            t_next = tens;
            h_next = hundreds;

            // Handle invincibility timing
            if (invincible && startOfFrame) begin
                if (invincibility_counter < INVINCIBILITY_DURATION_FRAMES - 1)
                    invincibility_counter <= invincibility_counter + 1;
                else begin
                    invincible <= 1'b0;
                    invincibility_counter <= 0;
                end
            end

            // Strike event: only trigger if not invincible and not Super
            if (strike && !invincible && !Super) begin
                invincible <= 1'b1;
                invincibility_counter <= 0;

                // Decrement logic
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

            units    <= o_next;
            tens     <= t_next;
            hundreds <= h_next;
        end
    end

endmodule
