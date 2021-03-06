`include "define.vh"

module IFetch(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,

    input wire ram_bus_rdy_in,
    input wire ram_bus_en_in,
    input wire[`INSTRUCTION_WIDTH] ram_bus_inst_in,
    output wire ram_bus_en_out,
    output reg[`ADDRESS_WIDTH] ram_bus_pc_out,

    input wire instqueue_rdy_in,
    output reg instqueue_inst_en_out,
    output reg[`INSTRUCTION_WIDTH] instqueue_inst_out,
    output reg[`ADDRESS_WIDTH] instqueue_pc_out,

    output wire[`INSTRUCTION_WIDTH] icache_pc_out,
    input wire[`ADDRESS_WIDTH] icache_inst_in,
    input wire icache_miss_in,

    input wire rob_en_in,
    input wire[`ADDRESS_WIDTH] rob_pc_in
);
    
reg status;
reg[`ADDRESS_WIDTH] pc_value;

always @(posedge clk_in) begin
    instqueue_inst_en_out <= `DISABLE;
    ram_bus_pc_out <= `NULL;
    instqueue_inst_out <= `NULL;
    instqueue_pc_out <= `NULL;
    if (rst_in) begin
        status <= `IDLE;
        pc_value <= 1'b0;
        instqueue_inst_en_out <= `DISABLE;
    end
    else if (rdy_in) begin
        if (rob_en_in) begin
            status <= `IDLE;
            pc_value <= rob_pc_in;
        end
        else if (instqueue_rdy_in) begin
            if (!icache_miss_in) begin
                instqueue_inst_en_out <= `ENABLE;
                instqueue_inst_out <= icache_inst_in;
                instqueue_pc_out <= pc_value;
                pc_value <= pc_value + 4;
            end
            else begin
                if (ram_bus_rdy_in && !ram_bus_en_in) begin
                    status <= `BUSY;
                    ram_bus_pc_out <= pc_value;
                end
                else if (ram_bus_en_in) begin
                    status <= `IDLE;
                    instqueue_inst_en_out <= `ENABLE;
                    instqueue_inst_out <= ram_bus_inst_in;
                    instqueue_pc_out <= pc_value;
                    pc_value <= pc_value + 4;
                end   
            end
        end
    end
end

assign icache_pc_out = pc_value;
assign ram_bus_en_out = !rob_en_in && !status && instqueue_rdy_in && icache_miss_in;

endmodule