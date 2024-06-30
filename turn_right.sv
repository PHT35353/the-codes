module turn_right
   (input logic clk,
    input logic reset,

    input logic sensor_l,
    input logic sensor_m,
    input logic sensor_r,
    input logic [29:0] count,
    output logic count_reset,

    output logic motor_l_reset,
    output logic motor_l_direction,
 
    output logic motor_r_reset,
    output logic motor_r_direction,
    output logic done_or_no,


    input logic tx_ready,
    output logic [7:0]tx_data,
    output logic tx_valid
);
typedef enum logic [2:0]{turn_right, done, motor_off, idle, sending}           
    motor_controller_state;
    motor_controller_state state, next_state;

logic count_reset_2;
logic [29:0]count_2;
logic [29:0]count_3;
logic count_reset_3;
timebase timebase9(.clk(clk),.reset(count_reset_2),.count(count_2));
timebase timebase11(.clk(clk),.reset(count_reset_3),.count(count_3));
  always_ff @(posedge clk) begin
        if (reset == 1) begin
            state <= idle;
        end
        else begin
            state <= next_state;
        end
    end
    always_comb begin
case(state)
    idle: begin // the fsm will stay in this state when it is not called upon
    motor_l_direction <= 1;
    motor_r_direction <= 0;
    motor_l_reset <= 1;
    motor_r_reset <= 1;
    count_reset_2 <= 1;
    count_reset <= 1;
    count_reset_3 <= 1;
    done_or_no <= 0;
    next_state = sending;
    tx_data <= 8'd68;
    tx_valid <= 1;
    end

    sending: begin
    count_reset <= 1;
    done_or_no <= 0;
    motor_l_direction <= 1;
    motor_r_direction <= 0;
    motor_l_reset <= 1;
    motor_r_reset <= 1;
    count_reset_2 <= 1;
    count_reset_3 <= 1;
    tx_data <= 8'd68; 
    if (tx_ready == 1) begin // checks if the uart-module is ready for inputs.
        next_state = turn_right;
        tx_valid <= 1; // sends a signal to the uart to start sending the tx_data that it received.
    end
    else begin
        next_state = sending;
        tx_valid <= 0;
    end
    end





    turn_right: begin //turn right state
    motor_l_direction <= 1;
    motor_r_direction <= 1;
    motor_l_reset <= 0;
    motor_r_reset <= 0;
    done_or_no <= 0;
    count_reset_2 <= 0;
    count_reset_3 <= 1;
    tx_data <= 8'd68;
    tx_valid <= 1;
    if (count_2 > 30'd27500000) begin // waits for 250 ms before looking at sensor data
	
    	if (~sensor_m) begin // if it finds black inthe middle it goes into the done state.
	    next_state = done;
	    count_reset <= 1;
    	end
    	else if (count > 30'd2000000) begin
	    next_state = motor_off;
	    count_reset <= 1;
    	end	
    	else begin
	    next_state = turn_right;
	    count_reset <= 0;
    	end
    end
    else begin
	    if (count > 30'd2000000) begin
	    next_state = motor_off;
	    count_reset <= 1;
        end	
        else begin
	    next_state = turn_right;
	    count_reset <= 0;
	end
    end
    end

    
    motor_off:	//motor off state where the motor_l_reset gets put on 1 for a small amount of time
    begin
    count_reset_3 <= 1;
    count_reset <= 1;
    next_state = turn_right;
    motor_l_reset <= 1;
    motor_r_reset <= 1;
    motor_l_direction <= 1;
    motor_r_direction <= 0;
    done_or_no <= 0;
    count_reset_2 <= 0;
    tx_data <= 8'd0;
    tx_valid <= 0;
    end
    
    done: //done state where it sends a signal to the actualcontroller to go to the next state
    begin
    count_reset_3 <= 1;
    count_reset <= 1;
    motor_l_direction <= 1;
    motor_r_direction <= 0;
    motor_l_reset <= 1;
    motor_r_reset <= 1;
    done_or_no <= 1;
    next_state = done;
    count_reset_2 <= 1;
    tx_data <= 8'd0;
    tx_valid <= 0;
    end
    
    default: begin
    count_reset_3 <= 1;
    count_reset <= 1;
    motor_l_direction <= 0;
    motor_r_direction <= 0;
    motor_l_reset <= 1;
    motor_r_reset <= 1;
    done_or_no <= 0;
    next_state =  turn_right;
    count_reset_2 <= 1;
    tx_data <= 8'd0;
    tx_valid <= 0;
    end
endcase
    end
endmodule
