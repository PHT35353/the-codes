module starting
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

       typedef enum logic [3:0]{motor_off, done, motor_on, idle, forward, motor_off_2, forward_state2, motor_off_3, sending} motor_controller_state;
    motor_controller_state state, next_state;

logic count_reset_2;
logic [29:0]count_2;
logic count_reset_3;
logic [29:0]count_3;

timebase timebase2(.clk(clk),.reset(count_reset_2),.count(count_2));
timebase timebase3(.clk(clk),.reset(count_reset_3),.count(count_3));
always_ff @(posedge clk) begin
    if (reset == 1) begin
        state <= idle;
    end
    else begin
	state <= next_state;
end
end
always_comb begin
    // Check if all sensors are black
 case(state)
    idle:
    begin
   
    motor_l_direction <= 1;
    motor_r_direction <= 0;
    motor_l_reset <= 1;
    motor_r_reset <= 1;
    count_reset <= 1;
    done_or_no <= 0;
    count_reset_2 <= 1;
    count_reset_3 <= 1;
    next_state = sending;
    tx_data <= 8'd0;
    tx_valid <= 0;
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
        next_state = forward;
        tx_valid <= 1; // sends a signal to the uart to start sending the tx_data that it received.
    end
    else begin
        next_state = sending;
        tx_valid <= 0;
    end
    end


    forward:
    begin
    count_reset_3 <= 1;
    motor_l_direction <= 1;
    motor_r_direction <= 0;
    motor_l_reset <= 0;
    motor_r_reset <= 0;
    count_reset <= 0;
    count_reset_2 <= 0;
    done_or_no <= 0;
    tx_data <= 8'd68;
    tx_valid <= 1;

    if (sensor_l == 0 || sensor_m == 0 || sensor_r == 0) begin
        next_state = motor_on;
    end
    
    else if (count > 30'd2000000) begin
	    next_state = motor_off_2;
    end	
    else begin
        next_state = forward;
    end
    end


    motor_off_2:
        begin
        count_reset_3 <= 1;
	    count_reset_2 <= 1;
        next_state = forward;
        motor_l_reset <= 1;
        motor_r_reset <= 1;
        motor_l_direction <= 1;
        motor_r_direction <= 0;
        count_reset <= 1;
        done_or_no <= 0;
        tx_data <= 8'd0;
        tx_valid <= 0;

        end

    motor_on: // linefollower
    begin
    count_reset_3 <= 1;
    motor_l_direction <= 1;
    motor_r_direction <= 0;
    motor_l_reset <= 1;
    motor_r_reset <= 1;
    count_reset <= 0;
    done_or_no <= 0;
    count_reset_2 <= 1;
    tx_data <= 8'd0;
    tx_valid <= 0;

    if (sensor_l == 0 && sensor_m == 0 && sensor_r == 0) begin
        // Forward motion
        motor_l_direction <= 1;
        motor_r_direction <= 0;
        motor_l_reset <= 0;
        motor_r_reset <= 0;
    end else if (sensor_l == 0 && sensor_m == 0 && sensor_r == 1) begin
        // Gentle left turn
        motor_l_direction <= 1;
        motor_r_direction <= 0;
        motor_l_reset <= 1; // Stop the left motor
        motor_r_reset <= 0;
    end else if (sensor_l == 0 && sensor_m == 1 && sensor_r == 0) begin
        // Forward motion
        motor_l_direction <= 1;
        motor_r_direction <= 0;
        motor_l_reset <= 0;
        motor_r_reset <= 0;
    end else if (sensor_l == 0 && sensor_m == 1 && sensor_r == 1) begin
        // Sharp left turn
        motor_l_direction <= 0;
        motor_r_direction <= 0;
        motor_l_reset <= 0;
        motor_r_reset <= 0;
    end else if (sensor_l == 1 && sensor_m == 0 && sensor_r == 0) begin
        // Gentle right turn
        motor_l_direction <= 1;
        motor_r_direction <= 0;
        motor_l_reset <= 0;
        motor_r_reset <= 1;
    end else if (sensor_l == 1 && sensor_m == 0 && sensor_l == 1) begin
        // Forward motion
        motor_l_direction <= 1;
        motor_r_direction <= 0;
        motor_l_reset <= 0;
        motor_r_reset <= 0;
    end else if (sensor_l == 1 && sensor_m == 1 &&sensor_r == 0) begin
        // Sharp right turn
        motor_l_direction <= 1;
        motor_r_direction <= 1;
        motor_l_reset <= 0;
        motor_r_reset <= 0;
    end else begin // stop
	    motor_l_reset <= 1;
        motor_r_reset <= 1;
        motor_l_direction <= 1;
        motor_r_direction <= 0;
    end


    if (~sensor_l && ~sensor_m && ~sensor_r) begin // looking for crossings
	    next_state = forward_state2;
	    count_reset <= 1;
    end
    else if (count > 30'd2000000) begin
	    next_state = motor_off;
	    count_reset <= 1;
    end	
    
    else begin
	    next_state = motor_on;
	    count_reset <= 0;
    end
    end
    
    
       motor_off:
        begin
        count_reset_3 <= 1;
	    count_reset_2 <= 0;
        next_state = motor_on;
        motor_l_reset <= 1;
        motor_r_reset <= 1;
        motor_l_direction <= 1;
        motor_r_direction <= 0;
        count_reset <= 1;
        done_or_no <= 0;
        tx_data <= 8'd0;
        tx_valid <= 0;


        end
 forward_state2: begin
    motor_l_direction <= 1;
    motor_r_direction <= 0;
    motor_l_reset <= 0;
    motor_r_reset <= 0;
    done_or_no <= 0;
    count_reset_2 <= 1;
    count_reset_3 <= 0;
    tx_data <= 8'd0;
    tx_valid <= 0;

   if (count_3 > 30'd30000000) begin // waits for 300 ms before looking at sensor data
        next_state = done;
        count_reset <= 1;
    end
    else begin
	    if (count > 30'd2000000) begin
	    next_state = motor_off_3;
	    count_reset <= 1;
        end	
        else begin
	    next_state = forward_state2;
	    count_reset <= 0;
	end
    end
    end
    
    motor_off_3:	//motor off state where the motor_l_reset gets put on 1 for a small amount of time
    begin
    count_reset <= 1;
    next_state = forward_state2;
    motor_l_reset <= 1;
    motor_r_reset <= 1;
    motor_l_direction <= 1;
    motor_r_direction <= 0;
    done_or_no <= 0;
    count_reset_2 <= 1;   
    count_reset_3 <= 0;
    tx_data <= 8'd0;
    tx_valid <= 0;

    end
 

    done: // sends a done signal to the main module
        begin
	    count_reset_2 <= 1;
        next_state = done;
        count_reset_3 <= 1;
        motor_l_reset <= 1;
        motor_r_reset <= 1;
        motor_l_direction <= 1;
        motor_r_direction <= 0;
        count_reset <= 1;
        done_or_no <= 1;
        tx_data <= 8'd0;
        tx_valid <= 0;


        end

    default: begin
	    count_reset_2 <= 1;
        next_state = forward;
        motor_l_reset <= 1;
        motor_r_reset <= 1;
        motor_l_direction <= 0;
        motor_r_direction <= 0;
        count_reset <= 1;
        done_or_no <= 0;
        tx_data <= 8'd0;
        tx_valid <= 0;
        count_reset_3 <= 1;


end
    endcase
    end
    
            


endmodule
   
