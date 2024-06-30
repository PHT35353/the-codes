module ultrasensor_controller2(
    input logic clk, 
    input logic control,                // input received from the line follower the controller will automatically go to idle when 0
    input logic [22:0] count,             // time from timebase
    input logic echo,                   // input received from sensor
    output logic trigger,               // trigger needed for the sensor to begin sending pulses hold time of 10us
    output logic reset,                 // trigger to either reset the clock back to 0 ms or keep it there
    output logic[22:0] s_echo             // timestamp when echo goes from low to high (change this to an intermediate signal so that we compare datas)
);

typedef enum logic[1:0] { //The state names does NOT MATCH its functionality!
    idle, // our first and reset state. Every output will be zero until control siganl is on.
    sending, // this state is where controller sends trigger signal for 10 us to the sensor.
    wait_echo, // In this state the controller counts between the high and the low signal of echo.
    rec_echo // In this state the controller gives the calculated distance of obstacle as output and waits dor 60ms in this state.
} s_state;

s_state state, next_state;
logic [22:0] s_echo_reg; // A variable to store distance for a moment in wait_echo. This will cause an wanted latch in Vivado

always_ff @(posedge clk)  // Generic always_ff statement
begin
    if(!control) begin
        state <= idle;
    end else begin
        state <= next_state;
    end
end

always_comb begin
    
	case(state)

        idle: 
        begin
            if (control) begin // If control is high, trigger signal is sent to sensor and then it goes to next state.
		        trigger = 1'b1;
                reset = 1'b0;
                s_echo_reg = 23'b0; 
                s_echo = 23'b0;    
                next_state = sending;

            end else begin // Default cases for variable in this state.
                trigger = 1'b0;
	            reset = 1'b1; 
                s_echo_reg = 23'b0;
	             s_echo = 23'b0;
		         next_state = idle;
                 end 
                 
        end

        sending:
	    begin
            if (echo) begin //This if-statement ensures that this controller goes to next state and begins measuring distance if and  only if when echo signal is high. This if-statement is also here because we are not sure if echo goes high directly after the trigger signal goes down.
                trigger = 1'b0;
                reset = 1'b0; 
                s_echo_reg = count; //The controller is now measuring and save its measurement in s_echo_reg.
                s_echo = 23'b0;
                next_state = wait_echo;
                
            end else if(count > 10'b1111101000) begin //This if-statement ensures that trigger signal is high for only 10 us.
                trigger = 1'b0;
                reset = 1'b1; //Reset becomes high because it needs to get ready for a new counting session to measure distance.
                s_echo_reg = 23'b0;
                s_echo = 23'b0;
                next_state = sending;

            end else begin // Default cases for variable in this state.
                trigger = 1'b1; //Trigger signal is high
                reset = 1'b0;
                s_echo_reg = 23'b0;
                s_echo = 23'b0;
                next_state = sending;
                
            end
         end

      wait_echo: 
      begin
            if (echo && count > 23'd1156852) begin //This if-statement says that the controller goes to the next state if the calculated limit (the distance after the fourth node) of our sensor is reached.  //// original: 21'd1107880; new: 21'd1156852 for count
                trigger = 1'b0;
                reset = 1'b0;
                s_echo_reg = count;
                s_echo = 23'b0;
                next_state = rec_echo;

            end else if (!echo) begin //This if-statement says that the controller stops with counting when echo is signal is low. Additionally it goes to the next state.
                trigger = 1'b0;
                reset = 1'b0;   
                s_echo_reg = count;
                s_echo = 23'b0;
                next_state = rec_echo;

            end else begin // Default cases for variable in this state.
                trigger = 1'b0;
                reset = 1'b0;
               s_echo_reg = count; //Measuring distance and saves it in s_echo_reg.
               s_echo = 23'b0;
                next_state = wait_echo; 
                
            end end
            

        rec_echo:
        begin
            if(count >= 23'b10110111000110110000000) begin //Goes to idle state only after 60ms in this state to avoid errors.    
                trigger = 1'b0; 
                reset = 1'b1;
                s_echo_reg = s_echo_reg;
                s_echo = s_echo_reg;
                next_state = idle; 

            end else begin // Default cases for variable in this state.
                trigger = 1'b0;
                reset = 1'b0;
                s_echo_reg = s_echo_reg; //Redundant but this ensures that s_echo_reg value from the previous state is stored.
                 s_echo = s_echo_reg; //Output of this controller is now the same value as the stored value in s_echo_reg.
                 next_state = rec_echo;
                 
            end
        end
        default: begin
            next_state = idle;
        end
    endcase
end

endmodule
