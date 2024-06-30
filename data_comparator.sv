module data_comparator(
    input logic [22:0] data_input,
    output logic [2:0] blockade_output
);

    always_comb begin
         
        if (data_input == 23'd0) begin 
            blockade_output = 3'd7; //7 means we are still meausuring
        end else if (data_input < 23'd289213) begin    ///// original: 291545  new: 289213
            blockade_output = 3'd1; // blockade directly in front
        end else if (data_input < 23'd578426) begin     ///// original: 583090  new: 578426
            blockade_output = 3'd2; // blockade between node 1 and node 2
        end else if (data_input < 23'd867639) begin    ///// original: 874630 new: 867639
            blockade_output = 3'd3; // blockade between node 2 and node 3
        end else if (data_input < 23'd1127930) begin    ///// original: 1107871  new: 1084549
            blockade_output = 3'd4; // blockade between node 3 and node 4
        end else  begin
            blockade_output = 3'd0; // No blockade
        end
    end

endmodule
