module JukeBox1
(
 input  logic [3:0] melodySelect,
 input  logic [4:0] noteIndex,
 input  logic       collision,
 input  logic       superi,
 output logic [3:0] tone,
 output logic [3:0] note_length,
 output logic       silenceOutN
);

localparam MaxMelodyLength = 6'h32;

typedef enum logic [3:0] {
  do_, doD, re, reD, mi, fa, faD, sol, solD,
  la, laD, si, do_H, doDH, re_H, silence
} musicNote;

musicNote frq[(MaxMelodyLength-1'b1):0];
logic [3:0] len[(MaxMelodyLength-1'b1):0];

// final outputs
musicNote tone_int;
logic [3:0] len_int;

assign silenceOutN = !(tone_int == silence);

always_comb begin
  frq = '{default: silence};
  len = '{default: 0};

  case (melodySelect)
    2: begin
      frq[0] = do_; len[0] = 1;
      frq[3] = do_; len[3] = 0;
    end

    4: begin
      frq[0] = fa; len[0] = 1;
      frq[3] = fa; len[3] = 0;
    end

    6: begin
      frq[0] = re_H; len[0] = 1;
      frq[3] = re_H; len[3] = 0;
    end

    8: begin
      frq[0] = mi; len[0] = 1;
      frq[3] = mi; len[3] = 0;
    end

    default: begin
      frq[0] = silence; len[0] = 2;
      frq[1] = silence; len[1] = 0;
    end
  endcase

  tone_int = frq[noteIndex];
  len_int  = len[noteIndex];

  if (collision) begin
    case (noteIndex)
      0: begin tone_int = re_H; len_int = 1; end
      1: begin tone_int = si;   len_int = 1; end
      2: begin tone_int = sol;  len_int = 1; end
      3: begin tone_int = re;   len_int = 1; end
      default: begin tone_int = silence; len_int = 0; end
    endcase
  end
  if (superi) begin
    case (noteIndex)
      0: begin tone_int = la;   len_int = 1; end
      1: begin tone_int = si;   len_int = 1; end
      2: begin tone_int = do_H; len_int = 1; end
      3: begin tone_int = re_H; len_int = 1; end
      4: begin tone_int = mi;   len_int = 1; end
      default: begin tone_int = silence; len_int = 0; end
    endcase
  end
end

assign tone = tone_int;
assign note_length = len_int;

endmodule
