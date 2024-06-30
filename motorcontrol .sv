`timescale 1 ns / 1 ps
typedef enum {
  S0,
  S1,
  S2,
  S3
} State;

module motorcontrol 
   (input logic clk,
    input logic reset,
    input logic direction, 
    input logic [29:0] count_in,
    input logic motor_brake,
    output logic pwm);
  	State state, stateNext;
 always_ff @(posedge clk) begin
    	if (reset) begin
      	state <= S0;
   	end
   	else begin
      	state <= stateNext;
    	end
  	end
 always_comb begin
    case (state)
      S0: begin
        pwm = 0;
	if (motor_brake == 1) begin
		stateNext <= S3;
	end
	else begin
		if (direction & ~reset)
		stateNext <= S1;
		else if (~direction & ~reset)
		stateNext <= S2;
		else
		stateNext <= S0;
	end
      end
	
      S1: begin
        if (count_in < 30'd200000) begin
	pwm = 1;
	stateNext <= S1;
	end
	else begin
	pwm = 0;
	stateNext <= S0;
	end
      end
      S2: begin
      if (count_in < 30'd100000) begin
	pwm = 1;
	stateNext <= S2;
	end
	else begin
	stateNext <= S0;
	pwm = 0;
	end
      end
	
      S3: begin
	if (count_in < 30'd149200) begin
		pwm = 1;
		stateNext <= S3;
	end
	else begin
		stateNext <= S0;
		pwm = 0;
	end

      end
	default: begin
        pwm = 0;
        stateNext <= S0;
      end
    endcase
  end


endmodule
