module JukeBox1
(
  input  logic       clk,
  input  logic [3:0] melodySelect,
  input  logic [4:0] noteIndex,
  input  logic       collision,
  input  logic       superi,
  input  logic       gameover,
  input  logic       win,
  output logic [3:0] tone,
  output logic [3:0] note_length,
  output logic       silenceOutN
);

localparam MaxMelodyLength = 6'h32;

typedef enum logic [3:0] {
  do_, doD, re, reD, mi, fa, faD, sol, solD,
  la, laD, si, do_H, doDH, re_H, silence
} musicNote;

typedef enum logic [1:0] {
  NORMAL_MODE   = 2'd0,
  GAMEOVER_MODE = 2'd1,
  SUPERI_MODE   = 2'd2,
  WIN_MODE      = 2'd3
} mode_t;

mode_t mode, next_mode;

musicNote frq[(MaxMelodyLength-1):0];
logic [3:0] len[(MaxMelodyLength-1):0];
musicNote tone_int;
logic [3:0] len_int;

assign silenceOutN = !(tone_int == silence);

// This block registers the mode, which is fine for
// controlling state machines (like the noteIndex counter)
always_ff @(posedge clk) begin
  if (gameover)
    mode <= GAMEOVER_MODE;
  else if (win)
    mode <= WIN_MODE;
  else if (superi)
    mode <= SUPERI_MODE;
  else
    mode <= NORMAL_MODE;
end

// This block combinatorially selects the sound.
// It now checks the inputs directly for immediate override.
always_comb begin
  // 1. Set default melody from melodySelect
  frq = '{default: silence};
  len = '{default: 0};

  case (melodySelect)
    2: begin frq[0] = do_;   len[0] = 1; frq[3] = do_;   len[3] = 0; end
    4: begin frq[0] = fa;   len[0] = 1; frq[3] = fa;   len[3] = 0; end
    6: begin frq[0] = re_H; len[0] = 1; frq[3] = re_H; len[3] = 0; end
    8: begin frq[0] = mi;   len[0] = 1; frq[3] = mi;   len[3] = 0; end
    default: begin frq[0] = silence; len[0] = 2; end
  endcase

  // 2. Assign default tone and length
  tone_int = frq[noteIndex];
  len_int  = len[noteIndex];

  // 3. (FIX) Combinatorially override based on inputs
  //    This logic now has priority and is immediate.
  if (gameover) begin
    case (noteIndex)
      0: begin tone_int = re_H; len_int = 1; end
      1: begin tone_int = si;   len_int = 1; end
      2: begin tone_int = sol;  len_int = 1; end
      default: begin tone_int = silence; len_int = 0; end
    endcase
  end
  else if (superi || win) begin // Combined like your original logic
    case (noteIndex)
      0: begin tone_int = la;   len_int = 1; end
      1: begin tone_int = si;   len_int = 1; end
      2: begin tone_int = do_H; len_int = 1; end
      3: begin tone_int = re_H; len_int = 1; end
      4: begin tone_int = mi;   len_int = 1; end
      default: begin tone_int = silence; len_int = 0; end
    endcase
  end
  // 'else' (NORMAL_MODE) - no action needed,
  // tone_int and len_int keep their default melody values.
end

assign tone = tone_int;
assign note_length = len_int;

endmodule