module timebase_ultra
   (input logic clk,
    input logic reset,
    output logic [22:0] count);

// 23-bits needed to fully store 60ms cycles in 100 MHz clock
// each tick represents a 10 ns interval 10e-9 * 8e6 = 0.08 s
logic [22:0] next_count;

always_ff @(posedge clk) begin
	if(reset) begin
		count <= 0;
		next_count <= 1;
	end else begin
		count <= next_count;
		next_count <= next_count + 1;
	end
end
endmodule
