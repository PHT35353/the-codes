module uart (
    input  logic clk,
    input  logic reset,
    
    // UART interface with ZigBee module
    input  logic rx,
    output logic tx,
    
    // Ready-valid handshake interfaces with rest of robot
    input  logic [7:0] tx_data,
    input  logic tx_valid,
    output logic tx_ready,

    output logic [7:0] rx_data,
    output logic rx_valid,
    input  logic rx_ready
  );
  
  uart_tx txmod(.*);
  uart_rx rxmod(.*);
  
endmodule

// ------------------------------------
// UART TX
// ------------------------------------

module uart_tx (
    input  logic clk,
    input  logic reset,
    output logic tx,

    input  logic [7:0] tx_data,
    input  logic tx_valid,
    output logic tx_ready
  );
  
  // Declarations
  logic [7:0] tx_data_buf;
  logic       tx_start;
  logic       tx_pre;
  
  logic [13:0] count;
  logic        count_en, count_done;
  
  typedef enum logic [3:0] {
    IDLE, STA, D0, D1, D2, D3, D4, D5, D6, D7, STO
  } state_t;
  
  state_t fsm_state, fsm_state_next;
  logic   fsm_busy;
  
  // Handshake
  assign tx_ready = ~fsm_busy;
  assign tx_start = tx_valid & tx_ready;
  
  // Baud rate up-counter (10417 cycles <> 9600 baud @100 MHz clock)
  assign count_en = tx_start | fsm_busy;
  assign count_done = (count >= 10417 - 1); // 1-tick pulse when counter finishes
  
  always_ff @(posedge clk) begin
    if (reset)
      count <= 'd0;
    else
      if (count_en)
        if (count_done)
          count <= 'd0;
        else
          count <= count + 1;
      else
        count <= count;
  end
  
  // Control FSM
  always_ff @(posedge clk) begin
    if (reset)
      fsm_state <= IDLE;
    else
      fsm_state <= fsm_state_next;
  end
  
  always_comb begin
    if (tx_start | count_done)
      case (fsm_state)
        IDLE : fsm_state_next = STA;
        STA  : fsm_state_next = D0;
        D0   : fsm_state_next = D1;
        D1   : fsm_state_next = D2;
        D2   : fsm_state_next = D3;
        D3   : fsm_state_next = D4;
        D4   : fsm_state_next = D5;
        D5   : fsm_state_next = D6;
        D6   : fsm_state_next = D7;
        D7   : fsm_state_next = STO;
        STO  : fsm_state_next = IDLE;
        default : fsm_state_next = IDLE;
      endcase
    else
      fsm_state_next = fsm_state;
  end
  
  assign fsm_busy = (fsm_state != IDLE);

  // TX buffer
  always_ff @(posedge clk) begin
    if (reset)
      tx_data_buf <= 1'b0;
    else
      if (tx_start)
        tx_data_buf <= tx_data;
      else
        tx_data_buf <= tx_data_buf;
  end
  
  // Output logic
  always_comb begin
    case (fsm_state)
      IDLE : tx_pre = 1'b1;
      STA  : tx_pre = 1'b0;
      D0   : tx_pre = tx_data_buf[0];
      D1   : tx_pre = tx_data_buf[1];
      D2   : tx_pre = tx_data_buf[2];
      D3   : tx_pre = tx_data_buf[3];
      D4   : tx_pre = tx_data_buf[4];
      D5   : tx_pre = tx_data_buf[5];
      D6   : tx_pre = tx_data_buf[6];
      D7   : tx_pre = tx_data_buf[7];
      STO  : tx_pre = 1'b1;
      default : tx_pre = 1'b1;
    endcase
  end
  
  // Buffer output to minimize delays
  always_ff @(posedge clk) begin
    if (reset)
      tx <= 1'b1;
    else
      tx <= tx_pre;
  end
  
endmodule

// ------------------------------------
// UART RX
// ------------------------------------

module uart_rx (
    input  logic clk,
    input  logic reset,
    input  logic rx,
    
    output logic [7:0] rx_data,
    output logic rx_valid,
    input  logic rx_ready
  );
  
  logic rx_buf1, rx_buf2;
  logic [12:0] count;
  logic count_en, count_done;
  logic shift, shift_disable;
  
  typedef enum logic [3:0] {
    IDLE, STA, D0, D1, D2, D3, D4, D5, D6, D7, STO, VALID
  } state_t;
  
  state_t fsm_state, fsm_state_next;
  logic fsm_next, fsm_busy, fsm_shift_en;
  
  // Input buffer
  always_ff @(posedge clk) begin
    if (reset) begin
      rx_buf1 <= 1'b1; // rx line high by default
      rx_buf2 <= 1'b1;
    end else begin
      rx_buf1 <= rx;
      rx_buf2 <= rx_buf1;
    end
  end
  
  // Sampling counter (half baudrate <> 5208 cycles @100 MHz)
  assign count_done = (count >= 5208 - 1);
  assign count_en = fsm_busy;
  
  always_ff @(posedge clk) begin
    if (reset)
      count <= 'd0;
    else
      if (count_en)
        if(count_done)
          count <= 'd0;
        else
          count <= count + 1;
      else
        count <= count;
  end
  
  // Sampling TFF
  always_ff @(posedge clk) begin
    if (reset)
      shift_disable <= 1'b0;
    else
      if (count_done)
        shift_disable <= ~shift_disable;
      else
        shift_disable <= shift_disable;
  end
  
  // Demultiplexer
  always_comb begin
    if (shift_disable) begin
      shift    = 1'b0;
      fsm_next = count_done;
    end
    else begin
      shift    = count_done;
      fsm_next = 1'b0;
    end
  end
  
  // Control FSM
  always_ff @(posedge clk) begin
    if (reset)
      fsm_state <= IDLE;
    else
      fsm_state <= fsm_state_next;
  end
  
  always_comb begin
    fsm_state_next = fsm_state;
    
    case (fsm_state)
      IDLE: if (~rx_buf2) fsm_state_next = STA;
      STA : if (fsm_next) fsm_state_next = D0;
      D0  : if (fsm_next) fsm_state_next = D1;
      D1  : if (fsm_next) fsm_state_next = D2;
      D2  : if (fsm_next) fsm_state_next = D3;
      D3  : if (fsm_next) fsm_state_next = D4;
      D4  : if (fsm_next) fsm_state_next = D5;
      D5  : if (fsm_next) fsm_state_next = D6;
      D6  : if (fsm_next) fsm_state_next = D7;
      D7  : if (fsm_next) fsm_state_next = STO;
      STO : if (fsm_next) fsm_state_next = VALID;
      VALID  : if (rx_ready) fsm_state_next = IDLE;
      default: fsm_state_next = IDLE;
    endcase
  end
  
  assign fsm_busy     = (fsm_state != IDLE) & (fsm_state != VALID);
  assign fsm_shift_en = (fsm_state != STO)  & fsm_busy;
  assign rx_valid     = (fsm_state == VALID);
  
  // Output shift register
  always_ff @(posedge clk) begin
    if (reset)
      rx_data <= 1'b0;
    else
      if (shift & fsm_shift_en)
        rx_data <= {rx_buf2, rx_data[7:1]};
      else
        rx_data <= rx_data;
  end

endmodule
