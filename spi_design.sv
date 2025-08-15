// Code your design here
// SPI Interface
interface spi_if(input bit clk);
  logic mosi, miso, sclk, cs;
endinterface
// SPI Master Module
module spi_master(
  input logic clk, rst, start,
  input logic [7:0] data_in,
  output logic done,
  output logic [7:0] data_out,
  spi_if spi);
  typedef enum logic [1:0] {IDLE, TRANSFER, DONE} state_t;
  state_t state, next_state;
  logic [2:0] bit_cnt;
  logic [7:0] shift_reg;
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      state <= IDLE;
      shift_reg <= 8'b0;
      bit_cnt <= 3'd0;
      spi.sclk <= 0;
      spi.cs <= 1;
      spi.mosi <= 0;
      done <= 0;
    end else begin
      state <= next_state;
      case (state)
        IDLE: begin
          done <= 0;
          if (start) begin
            spi.cs <= 0;
            shift_reg <= data_in;
            bit_cnt <= 3'd7;
            spi.sclk <= 0;
            spi.mosi <= data_in[7];
          end
        end
        TRANSFER: begin
          spi.sclk <= ~spi.sclk;
          if (spi.sclk) begin
            data_out[bit_cnt] <= spi.miso;
            bit_cnt <= bit_cnt - 1;
            shift_reg <= {shift_reg[6:0], 1'b0};
            spi.mosi <= shift_reg[6];
          end
        end
        DONE: begin
          spi.cs <= 1;
          done <= 1;
        end
      endcase
    end
  end
  always_comb begin
    case (state)
      IDLE:    next_state = start ? TRANSFER : IDLE;
      TRANSFER:next_state = (bit_cnt == 0 && spi.sclk) ? DONE : TRANSFER;
      DONE:    next_state = IDLE;
      default: next_state = IDLE;
    endcase
  end
endmodule
// SPI Slave Module
module spi_slave(
  input logic clk, rst,
  spi_if spi,
  input logic [7:0] slave_data,
  output logic [7:0] received_data);
  logic [2:0] bit_cnt;
  logic [7:0] shift_reg;
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      bit_cnt <= 0;
      shift_reg <= slave_data;
      spi.miso <= slave_data[7];
    end else if (~spi.cs && spi.sclk) begin
      shift_reg <= {shift_reg[6:0], 1'b0};
      spi.miso <= shift_reg[6];
      received_data[bit_cnt] <= spi.mosi;
      bit_cnt <= bit_cnt + 1;
    end
  end
endmodule

// Top-level module to connect the SPI Master and Slave

module spi_top (
    input  logic        clk,
    input  logic        rst,

    // Inputs for the Master
    input  logic        start_transfer,
    input  logic [7:0]  master_data_in,

    // Data to be pre-loaded into the Slave
    input  logic [7:0]  slave_preload_data,
    
    // Outputs from the system
    output logic        transfer_complete,
    output logic [7:0]  master_data_out,
    output logic [7:0]  slave_received_data
);

    // 1. Instantiate the SPI interface that will connect the master and slave
    spi_if spi_bus(.*); // Connects the 'clk' from the top module to the interface's clk

    // 2. Instantiate the SPI Master
    spi_master master_inst (
        .clk        (clk),
        .rst        (rst),
        .start      (start_transfer),
        .data_in    (master_data_in),
        .done       (transfer_complete),
        .data_out   (master_data_out),
        .spi        (spi_bus) // Connect to the shared SPI bus
    );

    // 3. Instantiate the SPI Slave
    spi_slave slave_inst (
        .clk           (clk),
        .rst           (rst),
        .spi           (spi_bus), // Connect to the same shared SPI bus
        .slave_data    (slave_preload_data),
        .received_data (slave_received_data)
    );

endmodule

