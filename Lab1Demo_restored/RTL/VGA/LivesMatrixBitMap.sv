module LivesMatrixBitMap (
    input  logic        clk,
    input  logic        resetN,
    input  logic [10:0] offsetX,   // offset from top-left position
    input  logic [10:0] offsetY,
    input  logic        InsideRectangle, // pixel is in bar
    input  logic        strike,   // hit (may be longer than 1 clk)

    output logic        drawingRequest, // pixel must be drawn
    output logic [7:0]  RGBout,
    output logic        gameOver        // one-cycle when last heart vanished
);

    // ------------------------
    // Heart counter
    // ------------------------
    logic [1:0] lives;       // 0..3
    logic       strike_d;    // delayed strike
    logic       strike_rise; // detect rising edge

    // Rising edge detector
    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            strike_d    <= 1'b0;
            strike_rise <= 1'b0;
        end else begin
            strike_rise <= strike & ~strike_d;
            strike_d    <= strike;
        end
    end

    // Lives counter
    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            lives    <= 2'd3;
            gameOver <= 1'b0;
        end else begin
            gameOver <= 1'b0;
            if (strike_rise && lives != 0) begin
                lives <= lives - 1'b1;
                if (lives == 1)
                    gameOver <= 1'b1;
            end
        end
    end

    // ------------------------
    // Heart bitmap 32x32
    // ------------------------
    localparam logic [31:0] heartBitmap [0:31] = '{
        32'b00000000011111111111111100000000,
        32'b00000011111111111111111111000000,
        32'b00001111111111111111111111110000,
        32'b00011111111111111111111111111000,
        32'b00111111111111111111111111111100,
        32'b01111111111111111111111111111110,
        32'b01111111111111111111111111111110,
        32'b11111111111111111111111111111111,
        32'b11111111111111111111111111111111,
        32'b11111111111111111111111111111111,
        32'b11111111111111111111111111111111,
        32'b01111111111111111111111111111110,
        32'b01111111111111111111111111111110,
        32'b00111111111111111111111111111100,
        32'b00011111111111111111111111111000,
        32'b00001111111111111111111111110000,
        32'b00000111111111111111111111100000,
        32'b00000011111111111111111111000000,
        32'b00000001111111111111111110000000,
        32'b00000000111111111111111100000000,
        32'b00000000011111111111111000000000,
        32'b00000000001111111111110000000000,
        32'b00000000000111111111100000000000,
        32'b00000000000011111111000000000000,
        32'b00000000000001111110000000000000,
        32'b00000000000000111100000000000000,
        32'b00000000000000011000000000000000,
        32'b00000000000000000000000000000000,
        32'b00000000000000000000000000000000,
        32'b00000000000000000000000000000000,
        32'b00000000000000000000000000000000,
        32'b00000000000000000000000000000000
    };

    // ------------------------
    // ציור הלבבות (32x32 כל אחד)
    // ------------------------
    logic heartPixel;

    always_comb begin
        drawingRequest = 1'b0;
        RGBout         = 8'h00;
        heartPixel     = 1'b0;

        if (InsideRectangle) begin
            if (offsetY < 32) begin
                for (int i=0; i<3; i++) begin
                    if (i < lives) begin
                        if ((offsetX >= i*34) && (offsetX < i*34+32)) begin
                            if (heartBitmap[offsetY][31 - (offsetX - i*34)]) begin
                                heartPixel = 1'b1;
                            end
                        end
                    end
                end
            end
        end

        if (heartPixel) begin
            drawingRequest = 1'b1;
            RGBout         = 8'hE0; // אדום
        end
    end

endmodule
