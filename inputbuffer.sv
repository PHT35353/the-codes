module inputbuffer (
    input logic clk,
    input logic input_1,
    input logic input_2,
    input logic input_3,
    output logic output_1,
    output logic output_2,
    output logic output_3
);

    // Register declarations
    logic reg1_1, reg2_1;
    logic reg1_2, reg2_2;
    logic reg1_3, reg2_3;

    // Register 1
    always_ff @(posedge clk) begin
        reg1_1 <= input_1;
        reg1_2 <= input_2;
        reg1_3 <= input_3;
    end

    // Register 2
    always_ff @(posedge clk) begin
        reg2_1 <= reg1_1;
        reg2_2 <= reg1_2;
        reg2_3 <= reg1_3;
    end

    // Output assignments
    assign output_1 = reg2_1;
    assign output_2 = reg2_2;
    assign output_3 = reg2_3;

endmodule
