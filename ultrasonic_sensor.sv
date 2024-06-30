module ultrasonic_sensor(
    input logic clk,
    input logic ctrl,
    input logic echo,
    output logic trigger,
    output logic [2:0] distance_output //this is the output of linefollower
    /*output logic led0,  
    output logic led1,
    output logic led2,
    output logic led3,
    output logic led4,
    output logic led5,
    output logic led6*/
);
    logic[22:0] count, echo_data;
    logic reset;
    logic buff_ctrl;
    logic buff_echo;
    
    //logic sensor_output;
    logic [2:0] distance;

    inputbuffer inputbuffer1(.clk(clk), .input_1(ctrl), .input_2(echo), .input_3(), .output_1(buff_ctrl), .output_2(buff_echo),.output_3());
    timebase_ultra timebase(.clk(clk), .reset(reset), .count(count));
    ultrasensor_controller2 controller(.clk(clk), .control(buff_ctrl), .count(count), .echo(buff_echo), .trigger(trigger), .reset(reset), .s_echo(echo_data));
    data_comparator comparator(.data_input(echo_data), .blockade_output(distance));

    always_comb
   /* begin
        if(echo_data > 0) begin
        led0 = 1;
        led1 = 1;
        led2 = 1;
        led3 = 1;
        led4 = 1;
        led5 = 1;
        led6 = 1;
        end else
        begin
        led0 = 0;
        led1 = 0;
        led2 = 0;
        led3 = 0;
        led4 = 0;
        led5 = 1;
        led6 = 1;
        end
    end */ // this outputs is not in use

    distance_output = distance; // output for line follower!! 

    
   /* begin   this outputs must be ignored for linefollower. This outputs are only for testing
    if(distance == 0 && ctrl) begin
    led0 = 1;
    led1 = 0;
    led2 = 0;
    led3 = 0;
    led4 = 0;
    led5 = 1;
    led6 = 0;
    end else if(distance == 1 && ctrl) begin
    led0 = 0;
    led1 = 1;
    led2 = 0;
    led3 = 0;
    led4 = 0;
    led5 = 1;
    led6 = 0;
    end else if(distance == 2 && ctrl) begin
    led0 = 0;
    led1 = 0;
    led2 = 1;
    led3 = 0;
    led4 = 0;
    led5 = 1;
    led6 = 0;
    end else if(distance == 3 && ctrl) begin
    led0 = 0;
    led1 = 0;
    led2 = 0;
    led3 = 1;
    led4 = 0;
    led5 = 1;
    led6 = 0;
    end else if(distance == 4 && ctrl) begin
    led0 = 0;
    led1 = 0;
    led2 = 0;
    led3 = 0;
    led4 = 1;
    led5 = 1;
    led6 = 0;
    end else if(distance == 7 && ctrl) begin
    led0 = 0;
    led1 = 0;
    led2 = 0;
    led3 = 0;
    led4 = 0;
    led5 = 1;
    led6 = 1;
    end else if(!ctrl) begin
    led0 = 0;
    led1 = 0;
    led2 = 0;
    led3 = 0;
    led4 = 0;
    led5 = 0;
    led6 = 0;
    end else begin
    led0 = 1;
    led1 = 1;
    led2 = 1;
    led3 = 1;
    led4 = 1;
    led5 = 1;
    led6 = 1;
    end*/

    end 
    
endmodule
