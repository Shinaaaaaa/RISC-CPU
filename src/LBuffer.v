`include "define.vh"

module LBuffer(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,

    input wire rob_flush_in,

    output wire lsqueue_rdy_out,

    input wire addressUnit_en_in,
    input wire[`INSTRUCTION_WIDTH] addressUnit_A_in,
    input wire[`ROB_WIDTH] addressUnit_dest_in,
    input wire[`INST_TYPE_WIDTH] addressUnit_inst_type_in,

    output reg cdb_lbuffer_en_out,
    output reg[`ROB_WIDTH] cdb_lbuffer_dest_out,
    output reg[`INSTRUCTION_WIDTH] cdb_lbuffer_value_out,

    output wire rob_load_check_en_out,
    output wire[`ROB_WIDTH] rob_load_check_dest_out,
    output wire[`ADDRESS_WIDTH] rob_load_check_address_out,
    input wire rob_load_check_sameaddress_in,
    input wire rob_load_check_forwarding_en_in,
    input wire[`INSTRUCTION_WIDTH] rob_load_check_forwarding_data_in,

    input wire ram_bus_rdy_in,
    input wire ram_bus_data_en_in,
    input wire[`INSTRUCTION_WIDTH] ram_bus_data_in,
    output reg ram_bus_en_out,
    output reg[`INSTRUCTION_WIDTH] ram_bus_A_out,
    output reg[`ROB_WIDTH] ram_bus_dest_out,
    output reg[`INST_TYPE_WIDTH] ram_bus_inst_type_out
);

localparam lbufferlength = 16;

reg status;
reg[`INSTRUCTION_WIDTH] lbuffer_A[lbufferlength - 1 : 0];
reg[`ROB_WIDTH] lbuffer_dest[lbufferlength - 1 : 0];
reg[`INST_TYPE_WIDTH] lbuffer_inst_type[lbufferlength - 1 : 0];
reg[`LBUFFER_WIDTH] head , tail;
integer i;


always @(posedge clk_in) begin
    cdb_lbuffer_en_out <= `DISABLE;
    ram_bus_en_out <= `DISABLE;
    if (rst_in) begin
        head <= `NULL;
        tail <= `NULL;
        status <= `IDLE;
        cdb_lbuffer_en_out <= `DISABLE;
        ram_bus_en_out <= `DISABLE;
    end
    else if (rdy_in) begin
        if (rob_flush_in) begin
            head <= `NULL;
            tail <= `NULL;
            status <= `IDLE;
            cdb_lbuffer_en_out <= `DISABLE;
            ram_bus_en_out <= `DISABLE;
        end
        else begin
            if (head != tail + 1 && addressUnit_en_in) begin
                lbuffer_A[tail] <= addressUnit_A_in;
                lbuffer_dest[tail] <= addressUnit_dest_in;
                lbuffer_inst_type[tail] <= addressUnit_inst_type_in;
                tail <= (tail + 1) % lbufferlength;
            end
            if (head != tail) begin
                if (!rob_load_check_sameaddress_in) begin
                    if (ram_bus_rdy_in && !ram_bus_data_en_in) begin
                        status <= `BUSY;
                        if (status == `IDLE) ram_bus_en_out <= `ENABLE;
                        ram_bus_A_out <= lbuffer_A[head];
                        ram_bus_dest_out <= lbuffer_dest[head];
                        ram_bus_inst_type_out <= lbuffer_inst_type[head];
                    end
                    else if (ram_bus_data_en_in) begin
                        status <= `IDLE;
                        cdb_lbuffer_en_out <= `ENABLE;
                        cdb_lbuffer_dest_out <= lbuffer_dest[head];
                        cdb_lbuffer_value_out <= ram_bus_data_en_in;
                        head <= (head + 1) % lbufferlength;
                        status <= `IDLE;
                    end  
                end
                else begin
                    if (rob_load_check_forwarding_en_in) begin
                        cdb_lbuffer_en_out <= `ENABLE;
                        case (lbuffer_inst_type[head])
                            `LB: cdb_lbuffer_value_out <= $signed(rob_load_check_forwarding_data_in[7 : 0]);
                            `LH: cdb_lbuffer_value_out <= $signed(rob_load_check_forwarding_data_in[15 : 0]);
                            `LW: cdb_lbuffer_value_out <= rob_load_check_forwarding_data_in[31 : 0];
                            `LBU: cdb_lbuffer_value_out <= rob_load_check_forwarding_data_in[7 : 0];
                            `LHU: cdb_lbuffer_value_out <= rob_load_check_forwarding_data_in[15 : 0];
                        endcase
                        cdb_lbuffer_dest_out <= lbuffer_dest[head];
                        head <= (head + 1) % lbufferlength;
                        status <= `IDLE;
                    end
                end
            end
        end     
    end
end

assign lsqueue_rdy_out = (head != (tail + 1) % lbufferlength);
assign rob_load_check_en_out = (head != tail);
assign rob_load_check_dest_out = lbuffer_dest[head];
assign rob_load_check_address_out = lbuffer_A[head];

endmodule