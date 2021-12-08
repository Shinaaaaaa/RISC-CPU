`include "define.vh"

module ICache(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,

    input wire[`INSTRUCTION_WIDTH] ifetch_pc_in,
    output wire[`ADDRESS_WIDTH] ifetch_inst_out,
    output wire ifetch_miss_out,

    input wire ram_bus_en_in,
    input wire[`ADDRESS_WIDTH] ram_bus_pc_in,
    input wire[`INSTRUCTION_WIDTH] ram_bus_inst_in
);

localparam cachelength = 256;
localparam indexlength = 8;
localparam taglength = 24;

reg valid[cachelength - 1 : 0];
reg[taglength - 1 : 0] tag[cachelength - 1 : 0];
reg[`INSTRUCTION_WIDTH] inst[cachelength - 1 : 0];
integer i;

always @(posedge clk_in) begin
    if (rst_in) begin
        for (i = 0 ; i < cachelength ; i = i + 1) begin
            valid[i] <= `NULL;
            tag[i] <= `NULL;
            inst[i] <= `NULL;
        end
    end
    else if (rdy_in) begin
        if (ram_bus_en_in) begin
            valid[ram_bus_pc_in[7 : 0]] <= `ENABLE;
            tag[ram_bus_pc_in[7 : 0]] <= ram_bus_pc_in[31 : 8];
            inst[ram_bus_pc_in[7 : 0]] <= ram_bus_inst_in; 
        end
    end
end

assign ifetch_miss_out = ifetch_pc_in[31 : 8] != tag[ifetch_pc_in[7 : 0]] || !valid[ifetch_pc_in[7 : 0]];
assign ifetch_inst_out = inst[ifetch_pc_in[7 : 0]];

endmodule