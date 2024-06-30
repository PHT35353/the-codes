module ultrasensor_stopstate
   (input logic clk,
    input logic reset,
    output logic [2:0]done_or_no,
// uart bit
    output logic [7:0]tx_data,
    output logic tx_valid,
    input logic tx_ready,

// the inputs/outputs below have to be linked to the main module and then defined in the xdc file to connect to the correct ports.
    input logic echo, 
    output logic trigger
);
typedef enum logic [3:0]{sensoring, sending, done, idle, done_2}           
    motor_controller_state;
    motor_controller_state state, next_state;

logic count_reset;
logic [29:0]count;
logic sensor_on;
logic [2:0] distance;
ultrasonic_sensor ultrasonic_sensor1(.clk(clk),.ctrl(sensor_on),.echo(echo),.distance_output(distance),.trigger(trigger)); //calling the ultrasonic sensor module, the output we care about is the distance. Echo has to be sent all the way up to the robot module so we can assign the correct value in the robot.xdc file
timebase timebase2(.clk(clk),.reset(count_reset),.count(count));


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
    count_reset <= 1;
    done_or_no <= 0;
    next_state = sensoring;
    tx_data <= 0;
    tx_valid <= 0;
    sensor_on <= 0;
    end

    sensoring: begin //sensor state
    
    done_or_no <= 0;
    tx_data <= 8'b0;
    tx_valid <= 0;
    if (count > 27'd7000000) begin
        next_state = sending;
        sensor_on <= 1;
        count_reset <= 1;
    end
    else begin 
        next_state = sensoring;
        sensor_on <= 1;
        count_reset <= 0;
    end
    end
    
    

    sending: begin
    count_reset <= 1;
    done_or_no <= 0;
    sensor_on <= 1;
    if (distance == 3'd1) begin
        tx_data <= 8'd49; 
        if (tx_ready == 1) begin // checks if the uart-module is ready for inputs.
            next_state = done;
            tx_valid <= 1; // sends a signal to the uart to start sending the tx_data that it received.
        end
        else begin
            next_state = sending;
            tx_valid <= 0;
        end
    end
    else if (distance == 3'd2) begin
        tx_data <= 8'd50; 
        if (tx_ready == 1) begin // checks if the uart-module is ready for inputs.
            next_state = done;
            tx_valid <= 1; // sends a signal to the uart to start sending the tx_data that it received.
        end
        else begin
            next_state = sending;
            tx_valid <= 0;
        end
    end
    else if (distance == 3'd3) begin
        tx_data <= 8'd51; 
        if (tx_ready == 1) begin // checks if the uart-module is ready for inputs.
            next_state = done;
            tx_valid <= 1; // sends a signal to the uart to start sending the tx_data that it received.
        end
        else begin
            next_state = sending;
            tx_valid <= 0;
        end
    end
    else if (distance == 3'd4) begin
        tx_data <= 8'd52; 
        if (tx_ready == 1) begin // checks if the uart-module is ready for inputs.
            next_state = done;
            tx_valid <= 1; // sends a signal to the uart to start sending the tx_data that it received.
        end
        else begin
            next_state = sending;
            tx_valid <= 0;
        end
    end
    else begin
        tx_data <= 8'd48;
        if (tx_ready == 1) begin // checks if the uart-module is ready for inputs.
            next_state = done_2;
            tx_valid <= 1; // sends a signal to the uart to start sending the tx_data that it received.
        end
        else begin
            next_state = sending;
            tx_valid <= 0;
        end
    end
    end

  

    done: //done state where it sends a signal to the actualcontroller to go to the next state
    begin
    done_or_no <= 3'd1;
    next_state = done;
    count_reset <= 1;
    tx_data <= 8'b0;
    tx_valid <= 0;
    sensor_on <= 0;
    end
    
    done_2: //done state where it sends a signal to the actualcontroller to go to the next state
    begin
    done_or_no <= 3'd2;
    next_state = done_2;
    count_reset <= 1;
    tx_data <= 8'b0;
    tx_valid <= 0;
    sensor_on <= 0;
    end

    default: begin
    tx_data <= 8'b0;
    tx_valid <= 0;
    done_or_no <= 3'd1;
    next_state =  idle;
    count_reset <= 1;
    sensor_on <= 0;
    end
endcase
    end
endmodule
