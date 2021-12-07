`include "define.vh"

module rob(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,

    output reg flush,

    output reg if_en_out,
    output reg[`ADDRESS_WIDTH] if_pc_out,

    output wire instqueue_rdy_out,

    input wire dispatcher_en_in,
    input wire[`INST_TYPE_WIDTH] dispatcher_inst_type_in,
    input wire[`INSTRUCTION_WIDTH] dispatcher_pc_in,
    input wire[`REGISTER_WIDTH] dispatcher_reg_pos_in,
    input wire[`ROB_WIDTH] dispatcher_rs1_in,
    input wire[`ROB_WIDTH] dispatcher_rs2_in,
    output wire[`ROB_WIDTH] dispatcher_idle_pos_out,
    output wire dispatcher_rs1_rdy_out,
    output wire[`INSTRUCTION_WIDTH] dispatcher_rs1_data_out,
    output wire dispatcher_rs2_rdy_out,
    output wire[`INSTRUCTION_WIDTH] dispatcher_rs2_data_out,

    input wire cdb_alu_en_in,
    input wire[`ROB_WIDTH] cdb_alu_dest_in,
    input wire[`INSTRUCTION_WIDTH] cdb_alu_value_in,
    input wire[`ADDRESS_WIDTH] cdb_alu_addr_in,

    input wire lsqueue_en_in,
    input wire[`ROB_WIDTH] lsqueue_dest_in,
    input wire[`INSTRUCTION_WIDTH] lsqueue_value_in,

    input wire addressUnit_en_in,
    input wire[`ROB_WIDTH] addressUnit_dest_in,
    input wire[`ADDRESS_WIDTH] addressUnit_address_in,

    input wire cdb_lbuffer_en_in,
    input wire[`ROB_WIDTH] cdb_lbuffer_dest_in,
    input wire[`INSTRUCTION_WIDTH] cdb_lbuffer_value_in,

    input wire lbuffer_load_check_en,
    input wire[`ROB_WIDTH] lbuffer_load_check_dest_in,
    input wire[`ADDRESS_WIDTH] lbuffer_load_check_address_in,
    output reg lbuffer_load_check_sameaddress_out,
    output reg lbuffer_load_check_forwarding_en_out,
    output reg[`INSTRUCTION_WIDTH] lbuffer_load_check_forwarding_data_out,

    input wire ram_bus_rdy_in,
    input wire ram_bus_finish_in,
    output wire ram_bus_en_out,
    output reg[`ADDRESS_WIDTH] ram_bus_address_out,
    output reg[`INSTRUCTION_WIDTH] ram_bus_wdata_out,
    output reg[`INST_TYPE_WIDTH] ram_bus_inst_type_out,

    output reg register_en_out,
    output reg[`REGISTER_WIDTH] register_reg_pos_out,
    output reg[`ROB_WIDTH] register_dest_out,
    output reg[`INSTRUCTION_WIDTH] register_value_out
);

    localparam ready = 1;
    localparam roblength = 32;

    reg busy[roblength - 1 : 0];
    reg[`INST_TYPE_WIDTH] inst_type[roblength - 1 : 0];
    reg[`REGISTER_WIDTH] reg_pos[roblength - 1 : 0];
    reg[`INSTRUCTION_WIDTH] value[roblength - 1 : 0];
    reg[`INSTRUCTION_WIDTH] addr[roblength - 1 : 0];
    reg[`INSTRUCTION_WIDTH] pc[roblength - 1 : 0];
    reg rdy[roblength - 1 : 0];

    reg status;
    reg[`ROB_WIDTH] head;
    reg[`ROB_WIDTH] tail;
    integer i;

    always @(posedge clk_in) begin
        if_en_out <= `DISABLE;
        if_pc_out <= `NULL;
        flush <= `DISABLE;
        ram_bus_address_out <= `NULL;
        ram_bus_wdata_out <= `NULL;
        ram_bus_inst_type_out <= `NULL;
        register_en_out <= `DISABLE;
        register_reg_pos_out <= `NULL;
        register_dest_out <= `NULL;
        register_value_out <= `NULL;
        if (rst_in) begin
            head <= 1'b1;
            tail <= 1'b1;
            if_en_out <= `DISABLE;
            flush <= `DISABLE;
            register_en_out <= `DISABLE;
            status <= `IDLE;
            for (i = 0 ; i <= roblength - 1; i = i + 1) begin
                busy[i] <= `NULL;
                rdy[i] <= `NULL;
            end
        end
        else if (rdy_in) begin
            if (dispatcher_en_in) begin
                busy[tail] <= `BUSY;
                inst_type[tail] <= dispatcher_inst_type_in;
                pc[tail] <= dispatcher_pc_in;
                reg_pos[tail] <= dispatcher_reg_pos_in;
                rdy[tail] <= 1'b0;
                tail <= tail % (roblength - 1) + 1;
            end

            if (cdb_alu_en_in) begin
                value[cdb_alu_dest_in] <= cdb_alu_value_in;
                addr[cdb_alu_dest_in] <= cdb_alu_addr_in;
                rdy[cdb_alu_dest_in] <= 1'b1;
            end

            if (lsqueue_en_in) begin
                value[lsqueue_dest_in] <= lsqueue_value_in;
            end

            if (addressUnit_en_in) begin
                addr[addressUnit_dest_in] <= addressUnit_address_in;
                rdy[addressUnit_dest_in] <= 1'b1;
            end

            if (cdb_lbuffer_en_in) begin
                value[cdb_lbuffer_dest_in] <= cdb_lbuffer_value_in;
                rdy[cdb_lbuffer_dest_in] <= 1'b1;
            end

            if (status == `BUSY) begin
                if (ram_bus_finish_in) begin
                    status <= `IDLE;
                    head <= head % (roblength - 1) + 1;
                    busy[head] <= `NULL;
                    rdy[head] <= `NULL;
                end
            end

            if (head != tail && rdy[head]) begin
                if (`BEQ <= inst_type[head] && inst_type[head] <= `BGEU) begin
                    if (value[head]) begin
                        if_en_out <= `ENABLE;
                        if_pc_out <= addr[head];
                        flush <= `ENABLE;
                        register_en_out <= `DISABLE;
                        status <= `IDLE;
                        head <= 1'b1;
                        tail <= 1'b1;
                        for (i = 0 ; i <= roblength - 1 ; i = i + 1) begin
                            busy[i] <= `IDLE;
                            rdy[i] <= `NULL;
                        end
                    end
                    else begin
                        head <= head % (roblength - 1) + 1;
                        busy[head] <= `IDLE;
                        rdy[head] <= `NULL;
                    end
                end
                else if (`SB <= inst_type[head] && inst_type[head] <= `SW) begin
                    if (ram_bus_rdy_in && !ram_bus_finish_in) begin
                        ram_bus_address_out <= addr[head];
                        ram_bus_wdata_out <= value[head];
                        ram_bus_inst_type_out <= inst_type[head];
                        status <= `BUSY;
                    end
                end
                else begin
                    register_en_out <= `ENABLE;
                    register_reg_pos_out <= reg_pos[head];
                    register_dest_out <= head;
                    register_value_out <= value[head];
                    head <= head % (roblength - 1) + 1;
                    busy[head] <= `NULL;
                    if (inst_type[head] == `JAL || inst_type[head] == `JALR) begin
                        if_en_out <= `ENABLE;
                        if_pc_out <= addr[head];
                        flush <= `ENABLE;
                        status <= `IDLE;
                        head <= 1'b1;
                        tail <= 1'b1;
                        for (i = 0 ; i <= roblength - 1 ; i = i + 1) begin
                            busy[i] <= `IDLE;
                            rdy[i] <= `NULL;
                        end
                    end
                end
            end
        end
    end

    always @(*) begin
        lbuffer_load_check_forwarding_en_out <= `DISABLE;
        lbuffer_load_check_sameaddress_out <= `NULL;
        lbuffer_load_check_forwarding_data_out <= `NULL;
        if (lbuffer_load_check_en) begin
            if (lbuffer_load_check_dest_in >= head) begin
                for (i = 1 ; i <= roblength - 1 ; i = i + 1) begin
                    if (head <= i && i < lbuffer_load_check_dest_in && `SB <= inst_type[i] && inst_type[i] <= `SW) begin
                        if (lbuffer_load_check_address_in == addr[i]) begin
                            lbuffer_load_check_sameaddress_out <= 1'b1;
                            if (rdy[i]) begin
                                lbuffer_load_check_forwarding_en_out <= `ENABLE;
                                lbuffer_load_check_forwarding_data_out <= value[i];
                            end
                        end
                    end
                end
            end
            else if (lbuffer_load_check_address_in < head) begin
                for (i = 1 ; i <= roblength - 1 ; i = i + 1) begin
                    if (head <= i && i <= roblength - 1 && `SB <= inst_type[i] && inst_type[i] <= `SW) begin
                        if (lbuffer_load_check_address_in == addr[i]) begin
                            lbuffer_load_check_sameaddress_out <= 1'b1;
                            if (rdy[i]) begin
                                lbuffer_load_check_forwarding_en_out <= `ENABLE;
                                lbuffer_load_check_forwarding_data_out <= value[i];
                            end
                        end
                    end
                end
                for (i = 1 ; i <= roblength - 1 ; i = i + 1) begin
                    if (1 <= i && i < lbuffer_load_check_address_in && `SB <= inst_type[i] && inst_type[i] <= `SW) begin
                        if (lbuffer_load_check_address_in == addr[i]) begin
                            lbuffer_load_check_sameaddress_out <= 1'b1;
                            if (rdy[i]) begin
                                lbuffer_load_check_forwarding_en_out <= `ENABLE;
                                lbuffer_load_check_forwarding_data_out <= value[i];
                            end
                        end
                    end
                end
            end
        end
    end

    assign ram_bus_en_out = (!rst_in && head != tail && rdy[head] && `SB <= inst_type[head] && inst_type[head] <= `SW && status == `IDLE);
    assign instqueue_rdy_out = (head != tail % (roblength - 1) + 1) && (head != (tail + 1) % (roblength - 1) + 1);
    assign dispatcher_rs1_rdy_out = rdy[dispatcher_rs1_in] || (cdb_alu_en_in && cdb_alu_dest_in == dispatcher_rs1_in) || (cdb_lbuffer_en_in && cdb_lbuffer_dest_in == dispatcher_rs1_in);
    assign dispatcher_rs1_data_out = rdy[dispatcher_rs1_in] ? value[dispatcher_rs1_in] : cdb_alu_en_in ? cdb_alu_value_in : cdb_lbuffer_en_in ? cdb_lbuffer_value_in : `NULL;
    assign dispatcher_rs2_rdy_out = rdy[dispatcher_rs2_in] || (cdb_alu_en_in && cdb_alu_dest_in == dispatcher_rs2_in) || (cdb_lbuffer_en_in && cdb_lbuffer_dest_in == dispatcher_rs2_in);
    assign dispatcher_rs2_data_out = rdy[dispatcher_rs2_in] ? value[dispatcher_rs2_in] : cdb_alu_en_in ? cdb_alu_value_in : cdb_lbuffer_en_in ? cdb_lbuffer_value_in : `NULL;
    assign dispatcher_idle_pos_out = tail;

endmodule