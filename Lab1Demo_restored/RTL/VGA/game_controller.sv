// game controller dudy Febriary 2020
// (c) Technion IIT, Department of Electrical Engineering 2021 
// updated --Eyal Lev 2021

module game_controller (	
    input  logic clk,
    input  logic resetN,
    input  logic startOfFrame,          // short pulse every start of frame 30Hz 
    input  logic drawing_request_smiley,
    input  logic drawing_request_boarders,
    input  logic drawing_request_box,
    input  logic drawing_request_hart,
    input  logic drawing_request_ghost,

    output logic collision,             // active in case of collision between two objects
    output logic SingleHitPulse,        // critical code, generating a single pulse in a frame 
    output logic strike,
    output logic collision_Smiley_Hart, // active in case of collision between Smiley and hart
    output logic collision_ghost_Hart   // active in case of collision between Ghost and hart
);

//----------------------------------------------
// Internal
//----------------------------------------------
logic collision_smiley_number = 0;
logic flag; 

//----------------------------------------------
// Base collisions
//----------------------------------------------
assign collision_smiley_number = (drawing_request_smiley && drawing_request_box);

// collisions that always matter (smiley vs borders, smiley vs number, smiley vs hart, ghost vs hart, smiley vs ghost)
assign collision_Smiley_Hart  = (drawing_request_smiley && drawing_request_hart || drawing_request_smiley && drawing_request_boarders);
assign collision_ghost_Hart   = (drawing_request_ghost  && drawing_request_hart || drawing_request_ghost && drawing_request_boarders);
assign strike = (drawing_request_ghost  && drawing_request_smiley);
logic collision_before;
assign collision_before = (drawing_request_smiley && drawing_request_boarders) 
                        || collision_smiley_number;

// final collision signal (now includes ghost-hart and ghost_smiley!)
assign collision = collision_before 
                 || collision_Smiley_Hart 
                 || collision_ghost_Hart;

//----------------------------------------------
// Single-hit pulse logic
//----------------------------------------------
always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin 
        flag           <= 1'b0;
        SingleHitPulse <= 1'b0; 
    end else begin 
        SingleHitPulse <= 1'b0; // default 

        if (startOfFrame) 
            flag <= 1'b0; // reset once per frame 
        // trigger pulse on first new collision in a frame
				
        if ((collision_smiley_number || collision_Smiley_Hart || collision_ghost_Hart || strike) && !flag) begin 
            flag           <= 1'b1; 
            SingleHitPulse <= 1'b1; 
        end
    end 
end

endmodule
