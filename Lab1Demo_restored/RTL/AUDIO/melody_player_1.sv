module melody_player_1
(
    input  logic resetN,
    input  logic CLOCK_31p5,
    input  logic startMelodyKey,
    input  logic [3:0] melodySelect,
    input  logic collision,
    input  logic superi,
    input  logic win,
    input  logic gameover,
    output logic [3:0] tone,
    output logic EnableSoundOut,
    output logic melodyEnded
);

localparam logic [5:0] beat_duration = 6'd12;
localparam logic [4:0] gap_duration  = 5'd3;

enum logic [2:0] {s_idle, s_playNote, s_gap, s_ended, s_wait_release} SM_Maestro;

logic [9:0] noteTimeCounter;
logic [9:0] noteDuration;
logic hundredthSecPulse;

logic [3:0] note_length;
logic silenceN;
logic [4:0] noteIndex;

assign noteDuration = beat_duration * note_length;

Mili_sec_counter #(
    .SIMULATION_MODE(1'h0),
    .mSecPerTick(10),
    .PLLClock(315)
) mili_sec_counter_inst (
    .clk(CLOCK_31p5),
    .resetN(resetN),
    .turbo(1'h0),
    .hundredth_sec(hundredthSecPulse)
);

JukeBox1 JukeBox1 (
    .clk(CLOCK_31p5),
    .melodySelect(melodySelect),
    .noteIndex(noteIndex),
    .collision(collision),
    .superi(superi),
    .tone(tone),
    .note_length(note_length),
    .silenceOutN(silenceN),
    .win(win),
    .gameover(gameover)
);

always_ff @(posedge CLOCK_31p5 or negedge resetN) begin
    if (!resetN) begin
        SM_Maestro <= s_idle;
        noteIndex <= 5'b0;
        noteTimeCounter <= noteDuration;
        EnableSoundOut <= 1'b0;
        melodyEnded <= 1'b0;
    end else begin
        EnableSoundOut <= 1'b0;
        melodyEnded <= 1'b0;

        case (SM_Maestro)
            s_idle: begin
                noteIndex <= 5'b0;
                if (startMelodyKey || gameover || win || superi) begin
                    noteTimeCounter <= noteDuration;
                    SM_Maestro <= s_playNote;
                end
            end

            s_playNote: begin
                EnableSoundOut <= silenceN;
                if (!(note_length == 4'b0)) begin
                    if (hundredthSecPulse)
                        noteTimeCounter <= noteTimeCounter - 10'b1;
                    if (noteTimeCounter == 10'b0) begin
                        noteIndex <= noteIndex + 1'b1;
                        SM_Maestro <= s_gap;
                        noteTimeCounter <= gap_duration;
                    end
                end else
                    SM_Maestro <= s_ended;
            end

            s_gap: begin
                if (hundredthSecPulse)
                    noteTimeCounter <= noteTimeCounter - 10'b1;
                if (noteTimeCounter == 10'b0) begin
                    SM_Maestro <= s_playNote;
                    noteTimeCounter <= noteDuration;
                end
            end

            s_ended: begin
                melodyEnded <= 1'b1;
                SM_Maestro <= s_wait_release; // NEW
            end

            s_wait_release: begin
                // Wait for all trigger signals to go low before returning to idle
                if (!startMelodyKey && !gameover && !win && !superi) begin
                    SM_Maestro <= s_idle;
                end
            end

            default: begin
                SM_Maestro <= s_idle;
            end
        endcase
    end
end

endmodule
