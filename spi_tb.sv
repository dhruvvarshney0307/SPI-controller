// Code your testbench here
// or browse Examples
//======================
module tb_spi;
  logic clk = 0, rst = 1;
  logic start = 0;
  logic [7:0] master_data = 8'hA5;
  logic [7:0] slave_data = 8'h3C;
  logic [7:0] master_rcv, slave_rcv;
  logic done;

  spi_if spi(clk);

  spi_master u_master (
    .clk(clk), .rst(rst), .start(start),
    .data_in(master_data), .done(done), .data_out(master_rcv),
    .spi(spi)
  );

  spi_slave u_slave (
    .clk(clk), .rst(rst),
    .spi(spi), .slave_data(slave_data),
    .received_data(slave_rcv)
  );

  always #5 clk = ~clk; // 100 MHz

  initial begin
    $dumpfile("spi.vcd");
    $dumpvars(0, tb_spi);

    #10 rst = 0;
    #10 start = 1;
    #10 start = 0;

    wait (done);
    #20;
    $display("Master sent: %h, received: %h", master_data, master_rcv);
    $display("Slave sent: %h, received: %h", slave_data, slave_rcv);
    $finish;
  end
endmodule
