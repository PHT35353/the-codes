`timescale 1 ns / 1 ps
module robot
   (input logic clk,
    input logic reset,

    input logic sensor_l_in,
    input logic sensor_m_in,
    input logic sensor_r_in,

   
    output logic motor_l_pwm,
    output logic motor_r_pwm,
    input logic echo,
    output logic trigger,
    output logic [7:0] rx_data,
    output logic tx,
    input logic rx
	
);
logic sensor_l, sensor_m, sensor_r, count_reset, motor_l_reset, motor_l_direction, motor_r_reset, motor_r_direction, motor_brake; 
logic [29:0]count;
logic[7:0]tx_data;
logic tx_valid, tx_ready, rx_valid, rx_ready;

inputbuffer inputbuffer1(.clk(clk),.sensor_l_in(sensor_l_in),.sensor_m_in(sensor_m_in),.sensor_r_in(sensor_r_in),.sensor_l_out(sensor_l),.sensor_m_out(sensor_m),.sensor_r_out(sensor_r));

timebase timebase1(.clk(clk),.reset(count_reset),.count(count));


actualcontroller actualcontroller1(.clk(clk), .reset(reset), .sensor_l(sensor_l), .sensor_m(sensor_m), .sensor_r(sensor_r), .count(count), .count_reset(count_reset), .motor_l_reset(motor_l_reset), .motor_l_direction(motor_l_direction), .motor_r_reset(motor_r_reset), .motor_r_direction(motor_r_direction),.tx_data(tx_data),.tx_valid(tx_valid),.tx_ready(tx_ready),.rx_data(rx_data),.rx_valid(rx_valid),.rx_ready(rx_ready),.motor_brake(motor_brake),.trigger(trigger),.echo(echo));

motorcontrol motorcontrol_l(.clk(clk),.reset(motor_l_reset),.direction(motor_l_direction),.count_in(count),.pwm(motor_l_pwm),.motor_brake(motor_brake));

motorcontrol motorcontrol_r(.clk(clk),.reset(motor_r_reset),.direction(motor_r_direction),.count_in(count),.pwm(motor_r_pwm),.motor_brake(motor_brake));

uart uart1(.clk(clk),.reset(reset),.rx(rx),.tx(tx),.tx_data(tx_data),.tx_valid(tx_valid),.tx_ready(tx_ready),.rx_data(rx_data),.rx_valid(rx_valid),.rx_ready(rx_ready));
endmodule
