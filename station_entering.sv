module station_entering
(   input logic clk,
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
    output logic motor_brake,
    output logic done_or_no,

     input logic tx_ready,
    output logic [7:0]tx_data,
    output logic tx_valid

);
typedef enum logic [2:0]{forward, motor_off_2, reversing, motor_off, done, idle, sending}           
    motor_controller_state;
    motor_controller_state state, next_state;

logic count_reset_2;
logic [29:0]count_2;

timebase timebase40(.clk(clk),.reset(count_reset_2),.count(count_2));


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
        motor_l_direction <= 0;
        motor_r_direction <= 0;
        motor_l_reset <= 1;
        motor_r_reset <= 1;
        motor_brake <= 0;
        count_reset <= 1;
        done_or_no <= 0;
        next_state = sending;
        tx_data <= 8'd0;
        tx_valid <= 0;
        count_reset_2 <= 1;

    end 

    sending: begin
    count_reset <= 1;
    done_or_no <= 0;
    motor_l_direction <= 1;
    motor_r_direction <= 0;
    motor_l_reset <= 1;
    motor_r_reset <= 1;
    motor_brake <= 1;
    tx_data <= 8'd68;
    count_reset_2 <= 1;
    if (tx_ready == 1) begin // checks if the uart-module is ready for inputs.
        next_state = forward;
        tx_valid <= 1; // sends a signal to the uart to start sending the tx_data that it received.
    end
    else begin
        next_state = sending;
        tx_valid <= 0;
    end
    end

    forward: begin // linefollower state to adjust the robot direction
    motor_l_direction <= 1;
    motor_r_direction <= 0;
    motor_l_reset <= 1;
    motor_r_reset <= 1;
    count_reset <= 0;
    done_or_no <= 0;
    count_reset_2 <= 0;
    motor_brake <= 0;
    tx_data <= 8'd68;
    tx_valid <= 1;
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

    if (count_2 > 30'd8000000) //this state is used for 80ms
        next_state = reversing;
    else if (count > 30'd2000000)
        next_state = motor_off_2;
    else
        next_state = forward;
    end


    motor_off_2:
    begin

        tx_data <= 8'd0;
        tx_valid <= 0;

        next_state = forward;
        motor_l_reset <= 1;
        motor_r_reset <= 1;
        motor_l_direction <= 1;
        motor_r_direction <= 0;
        count_reset <= 1;
        motor_brake <= 0;
        done_or_no <= 0;
        count_reset_2 <= 0;

    end




    reversing: begin
        count_reset <= 0;
        done_or_no <= 0;
        motor_brake <= 0;
        tx_data <= 8'd0;
        tx_valid <= 0;
        count_reset_2 <= 1;
        // Reverse motion
        motor_l_direction <= 0;
        motor_r_direction <= 1;
        motor_l_reset <= 0;
        motor_r_reset <= 0;
        motor_brake <= 0;
        if (count > 27'd2000000) begin
            next_state = motor_off;
        end	
        else if (sensor_l == 1 && sensor_m == 1 && sensor_r == 1) begin
            next_state = done;
        end
        else begin   
            next_state = reversing;
        end
    end

    motor_off:
    begin

        tx_data <= 8'd0;
        tx_valid <= 0;
        count_reset_2 <= 1;
        next_state = reversing;
        motor_l_reset <= 1;
        motor_r_reset <= 1;
        motor_l_direction <= 1;
        motor_r_direction <= 0;
        count_reset <= 1;
        motor_brake <= 0;
        done_or_no <= 0;

    end

    done:
    begin

        tx_data <= 8'd0;
        tx_valid <= 0;
        count_reset_2 <= 1;
        next_state = done;
        motor_l_reset <= 1;
        motor_r_reset <= 1;
        motor_l_direction <= 1;
        motor_r_direction <= 0;
        motor_brake <= 1;
        done_or_no <= 1;
        count_reset <= 1;
    end

default: begin
        motor_l_direction <= 0;
        motor_r_direction <= 0;
        motor_l_reset <= 1;
        motor_r_reset <= 1;
        motor_brake <= 0;
        count_reset <= 1;
        done_or_no <= 0;
        next_state = sending;
        tx_data <= 8'd0;
        tx_valid <= 0;
        count_reset_2 <= 1;
   
    end


   endcase   
end

endmodule
