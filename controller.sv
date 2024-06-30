module controller 
   (input logic clk,
    input logic reset,

    input logic sensor_l,
    input logic sensor_m,
    input logic sensor_r,

    input logic [7:0]command_routeplanner,
    input logic tx_ready,
    input logic rx_valid,

    input logic [24:0] count,
    
    output logic count_reset,

    output logic [7:0]tx_data,
    output logic tx_valid,
    output logic rx_ready,


    output logic motor_l_reset,
    output logic motor_l_direction,

    output logic motor_r_reset,
    output logic motor_r_direction);

    logic [24:0] StateTime;
	logic turn_around_logic_counter=0;
        logic crossing_logic_counter= 0;
	logic [7:0]command_planner_old;
       typedef enum logic [2:0]{motor_off, motor_on, turn_right, turn_left, forward_crossing, forward, turn_around}            motor_controller_state;
    motor_controller_state state, next_state;
    


always_ff @(posedge clk) begin
  state <= next_state;

end
always_comb begin
  
        // Other initialization code

        // Initialize the counters
        if (reset) begin
            turn_around_logic_counter <= 0;
            crossing_logic_counter <= 0;
	        command_planner_old <= 8'd0;
            tx_valid <= 0;
	    end
	    else begin 
	        turn_around_logic_counter <= turn_around_logic_counter;
            crossing_logic_counter <= crossing_logic_counter;
	        command_planner_old <= command_planner_old;
            tx_valid <= tx_valid;
	    end


case(state)
`// linefollower state
    motor_on:
    begin
    if ((count > 25'd2000000) || (reset == 1))begin
            next_state <= motor_off;
            motor_l_direction <= 1;
            motor_r_direction <= 0;
            motor_l_reset <= 1;
            motor_r_reset <= 1;
            count_reset <= 0;
    end
    else begin
    motor_l_direction <= 1;
    motor_r_direction <= 0;
    motor_l_reset <= 1;
    motor_r_reset <= 1;
    count_reset <= 0;
    next_state <= motor_on;
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
        // Forward motion
        motor_l_direction <= 0;
        motor_r_direction <= 0;
        motor_l_reset <= 0;
        motor_r_reset <= 0;
    end else if (sensor_l == 1 && sensor_m == 0 && sensor_r == 0) begin
        // Sharp left turn
        motor_l_direction <= 1;
        motor_r_direction <= 0;
        motor_l_reset <= 0;
        motor_r_reset <= 1;
    end else if (sensor_l == 1 && sensor_m == 0 && sensor_l == 1) begin
        // Gentle right turn
        motor_l_direction <= 1;
        motor_r_direction <= 0;
        motor_l_reset <= 0;
        motor_r_reset <= 1;
    end else if (sensor_l == 1 && sensor_m == 1 &&sensor_r == 0) begin
        // Forward motion
        motor_l_direction <= 1;
        motor_r_direction <= 1;
        motor_l_reset <= 0;
        motor_r_reset <= 0;
    end else if (sensor_l == 1 && sensor_m == 1 && sensor_r == 0) begin 
        // Sharp right turn
        motor_l_direction <= 1;
        motor_r_direction <= 0;
        motor_l_reset <= 0;
        motor_r_reset <= 0;
    end
    end
    end
    

    motor_off:
begin
    motor_l_reset <= 1;
    motor_r_reset <= 1;
    motor_l_direction <= 1;
    motor_r_direction <= 0;
    // following code checks when tx_data has been sent to the uart
    // this might not work, not exactly sure how tx_ready should be used
    if (tx_ready == 1 && tx_valid == 1) begin
        tx_valid <= 0;
    end
    else begin
        tx_valid <= tx_valid;
    end
    
	// following code checks when the controller receives new commands from the uart and then sends a confirmation back to the uart
    if (rx_valid == 1) begin
	    if (command_routeplanner != command_planner_old) begin
	        rx_ready <= 1;
	        command_planner_old <= command_routeplanner;
        end
	    else begin
	        command_planner_old <= command_routeplanner;
	        rx_ready <=0;
	    end
	
    end
	else begin
	    command_planner_old <= command_planner_old;
        rx_ready <= 1;
    end



    // following code checks when there is a crossing and then checks the command given by the routeplanner to go to the right state
    if (sensor_l && sensor_r && sensor_m) begin
        
        if (crossing_logic_counter == 0) begin
            crossing_logic_counter <= 1; //this part is still missing a counter so that it doesnt count the same crossing twice.
            next_state <= motor_on; 
            count_reset <= 1;
        end
        else if (crossing_logic_counter == 1 && count > 25'd8000000)begin
        
            crossing_logic_counter <= 0;
            if (command_routeplanner == 8'd1) begin
                next_state <= turn_right;
                count_reset <= 1;
            end
            else if (command_routeplanner == 8'd2) begin
                next_state <= turn_left;
                count_reset <= 1;
            end
            else if (command_routeplanner == 8'd3) begin
                next_state = forward_crossing;
                count_reset <= 1;
            end
            else if (command_routeplanner == 8'd4) begin
                next_state <= turn_around;
                count_reset <= 1;
            end
            else begin
                next_state <= motor_off;
                count_reset <= 0;
            end
            end
            end
	    
    else begin
	    next_state <= motor_on;
        count_reset <= 1;
        crossing_logic_counter <= crossing_logic_counter;
        end
end





    turn_right:
begin
    count_reset <= 0;
    motor_l_direction <= 1;
    motor_r_direction <= 0;
    motor_l_reset <= 0;
    motor_r_reset <= 0;
	if ((sensor_l || sensor_m || sensor_r) && count > 25'd8000000) begin
		tx_data <= 8'd11;
		next_state <= motor_off;
        tx_valid <= 1;
    end
	else begin
		next_state <= turn_right;
		tx_data <= tx_data;
        tx_valid <= 0;
		end
    end
    turn_left:
    begin
    count_reset <= 0;
    motor_l_direction <= 1;
    motor_r_direction <= 0;
    motor_l_reset <= 0;
    motor_r_reset <= 1;
	if ((sensor_l || sensor_m || sensor_r) && count > 25'd8000000) begin
        next_state <= motor_off
        tx_data <= 8'd21;
        tx_valid <= 1;
    end
	else begin
		next_state <= turn_left;
        tx_data <= tx_data;
        tx_valid <= 0;
    end
    end
    forward_crossing:
    begin
    count_reset <= 0;
    motor_l_direction <= 1;
    motor_r_direction <= 0;
    motor_l_reset <= 0;
    motor_r_reset <= 0;
	if ((sensor_l || sensor_m || sensor_r) && count > 25'd2000000) begin
		next_state <= motor_off;
        tx_data <= 8'd31;
        tx_valid <= 1;
end    
	else begin
		next_state <= forward_crossing;
        tx_data <= tx_data;
        tx_valid <= 0;
    end
    end
    turn_around:
    begin
    count_reset <= 0;
    motor_l_direction <= 1;
    motor_r_direction <= 0;
    motor_l_reset <= 0;
    motor_r_reset <= 0;
	    if ((sensor_l || sensor_m || sensor_r) && count > 25'd20000000 && turn_around_logic_counter == 0) begin
		    turn_around_logic_counter <= 1;
	        count_reset <= 1;
		    next_state <= turn_around;
            tx_data <= tx_data;
            tx_valid <= 0;
	    end
	    else if ((sensor_l || sensor_m || sensor_r) && count > 25'd20000000 && turn_around_logic_counter == 1) begin
		    next_state <= motor_off;
            turn_around_logic_counter <= 0;
            count_reset <= 1;
            tx_data <= 8'd41;
            tx_valid <= 1;
        end
	    else begin
            turn_around_logic_counter <= turn_around_logic_counter;
		    next_state <= turn_around;
            count_reset <= 0;
            tx_data <= tx_data;
            tx_valid <= 0;
        end
    end

   default:
   begin
     next_state <= motor_on;
     
   end

    endcase
    end
    

	
            


endmodule
