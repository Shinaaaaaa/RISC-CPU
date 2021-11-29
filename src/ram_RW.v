`include "define.vh"

module ram_RW(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,

    input wire[`RAM_RW_WIDTH] ram_rdata_in,
    output reg[`RAM_RW_WIDTH] ram_wdata_out,
    output reg[`ADDRESS_WIDTH] ram_addr_out,
    output reg ram_rw_out,

    output wire ifetch_bus_rdy_out,
    output reg ifetch_en_out,
    output reg[`INSTRUCTION_WIDTH] ifetch_inst_out,
    input wire ifetch_en_in,
    input wire[`ADDRESS_WIDTH] ifetch_pc_in,

    output wire lbuffer_rdy_out,
    output reg lbuffer_data_en_out,
    output reg[`INSTRUCTION_WIDTH] lbuffer_data_out,
    input wire lbuffer_en_in,
    input wire[`INSTRUCTION_WIDTH] lbuffer_A_in,
    input wire[`ROB_WIDTH] lbuffer_dest_in,
    input wire[`INST_TYPE_WIDTH] lbuffer_inst_type_in,
    
    input wire rob_flush_in,
    output wire rob_rdy_out,
    output reg rob_finish_out,
    input wire rob_en_in,
    input wire[`ADDRESS_WIDTH] rob_addr_in,
    input wire[`INSTRUCTION_WIDTH] rob_wdata_in,
    input wire[`INST_TYPE_WIDTH] rob_inst_type_in
);

localparam IF = 0;
localparam LB = 1;
localparam ROB = 2;

localparam Stage_0 = 3'b000;
localparam Stage_1 = 3'b001;
localparam Stage_2 = 3'b010;
localparam Stage_3 = 3'b011;
localparam Stage_4 = 3'b100;


localparam read = 0;
localparam write = 1;

reg[1 : 0] owner;
reg status;
reg[2 : 0] current_stage;
reg[`INSTRUCTION_WIDTH] inst_tmp;


always @(posedge clk_in) begin
    if (rst_in) begin
        owner <= IF;
        status <= `IDLE;
        current_stage <= Stage_0;
        inst_tmp <= `NULL;
    end
    else if (rdy_in) begin
        if (rob_flush_in) begin
            owner <= IF;
            status <= `IDLE;
            current_stage <= Stage_0;
            inst_tmp <= `NULL;
        end
        else begin
            if (status == `IDLE) begin
                case (owner)
                    IF: begin
                        if (ifetch_en_in) begin
                            status <= `BUSY;
                            owner <= IF;
                        end 
                        else if (lbuffer_en_in) begin
                            status <= `BUSY;
                            owner <= LB;
                        end 
                        else if (rob_en_in) begin
                            status <= `BUSY;
                            owner <= ROB;
                        end 
                    end
                    LB: begin
                        if (lbuffer_en_in) begin
                            status <= `BUSY;
                            owner <= LB;
                        end 
                        else if (rob_en_in) begin
                            status <= `BUSY;
                            owner <= ROB;
                        end 
                        else if (ifetch_en_in) begin
                            status <= `BUSY;
                            owner <= IF;
                        end 
                    end
                    ROB: begin
                        if (rob_en_in) begin
                            status <= `BUSY;
                            owner <= ROB;
                        end 
                        else if (ifetch_en_in) begin
                            status <= `BUSY;
                            owner <= IF;
                        end 
                        else if (lbuffer_en_in) begin
                            status <= `BUSY;
                            owner <= LB;
                        end 
                    end 
                endcase
            end
        end
    end
end

always @(posedge clk_in) begin
    if (rst_in) begin
        owner <= IF;
        status <= `IDLE;
        current_stage <= Stage_0;
        inst_tmp <= `NULL;
    end
    else if (rdy_in) begin
        if (rob_flush_in) begin
            owner <= IF;
            status <= `IDLE;
            current_stage <= Stage_0;
            inst_tmp <= `NULL;  
        end
        else begin
            if (status == `BUSY) begin
                if (owner == IF && ifetch_en_in) begin
                    case (current_stage)
                        Stage_0: current_stage <= Stage_1;
                        Stage_1: begin
                            inst_tmp[7 : 0] <= ram_rdata_in;
                            current_stage <= Stage_2;
                            ifetch_en_out <= `DISABLE;
                        end
                        Stage_2: begin
                            inst_tmp[15 : 8] <= ram_rdata_in;
                            current_stage <= Stage_3;
                            ifetch_en_out <= `DISABLE;
                        end
                        Stage_3: begin
                            inst_tmp[23 : 16] <= ram_rdata_in;
                            current_stage <= Stage_4;
                            ifetch_en_out <= `DISABLE;
                        end
                        Stage_4: begin
                            ifetch_inst_out <= {ram_rdata_in , inst_tmp[23 : 0]};
                            current_stage <= Stage_0;
                            ifetch_en_out <= `ENABLE;
                            inst_tmp <= `NULL;
                            status <= `IDLE;
                        end
                        default: ifetch_en_out <= `DISABLE;
                    endcase 
                end
                else if (owner == LB && lbuffer_en_in) begin
                    case (lbuffer_inst_type_in)
                        `LB: begin
                            case (current_stage)
                                Stage_0: current_stage <= Stage_1; 
                                Stage_1: begin
                                    lbuffer_data_out <= $signed(ram_rdata_in);
                                    lbuffer_data_en_out <= `ENABLE; 
                                    inst_tmp <= `NULL;
                                    status <= `IDLE;
                                    current_stage <= Stage_0;
                                end 
                            endcase
                        end
                        `LH: begin
                            case (current_stage)
                                Stage_0: current_stage <= Stage_1;
                                Stage_1: begin
                                    inst_tmp[7 : 0] <= ram_rdata_in;
                                    current_stage <= Stage_2;
                                end 
                                Stage_2: begin
                                    lbuffer_data_out <= $signed({ram_rdata_in , inst_tmp[7 : 0]});
                                    lbuffer_data_en_out <= `ENABLE; 
                                    inst_tmp <= `NULL;
                                    status <= `IDLE;
                                    current_stage <= Stage_0;
                                end
                            endcase
                        end
                        `LW: begin
                            case (current_stage)
                                Stage_0: current_stage <= Stage_1;
                                Stage_1: begin
                                    inst_tmp[7 : 0] <= ram_rdata_in;
                                    current_stage <= Stage_2;
                                end 
                                Stage_2: begin
                                    inst_tmp[15 : 8] <= ram_rdata_in;
                                    current_stage <= Stage_3;
                                end
                                Stage_3: begin
                                    inst_tmp[23 : 16] <= ram_rdata_in;
                                    current_stage <= Stage_4;  
                                end
                                Stage_4: begin
                                    lbuffer_data_out <= $signed({ram_rdata_in , inst_tmp[23 : 0]});
                                    lbuffer_data_en_out <= `ENABLE; 
                                    inst_tmp <= `NULL;
                                    status <= `IDLE;
                                    current_stage <= Stage_0;                           
                                end
                            endcase
                        end
                        `LBU: begin
                            case (current_stage)
                                Stage_0: current_stage <= Stage_1; 
                                Stage_1: begin
                                    lbuffer_data_out <= ram_rdata_in;
                                    lbuffer_data_en_out <= `ENABLE; 
                                    inst_tmp <= `NULL;
                                    status <= `IDLE; 
                                    current_stage <= Stage_0;
                                end
                            endcase
                        end
                        `LHU: begin
                            case (current_stage)
                                Stage_0: current_stage <= Stage_1;
                                Stage_1: begin
                                    inst_tmp[7 : 0] <= ram_rdata_in;
                                    current_stage <= Stage_2;
                                end 
                                Stage_2: begin
                                    lbuffer_data_out <= {ram_rdata_in , inst_tmp[7 : 0]};
                                    lbuffer_data_en_out <= `ENABLE; 
                                    inst_tmp <= `NULL;
                                    status <= `IDLE;
                                    current_stage <= Stage_0;
                                end
                            endcase
                        end
                    endcase
                end
                else if (owner == ROB && rob_en_in) begin
                    case (rob_inst_type_in)
                        `SB: begin
                            case (current_stage)
                                Stage_0: current_stage <= Stage_1; 
                                Stage_1: begin
                                    rob_finish_out <= 1'b1;
                                    inst_tmp <= `NULL;
                                    status <= `IDLE;
                                    current_stage <= Stage_0;
                                end 
                            endcase
                        end
                        `SH: begin
                            case (current_stage)
                                Stage_0: current_stage <= Stage_1;
                                Stage_1: current_stage <= Stage_2; 
                                Stage_2: begin
                                    rob_finish_out <= 1'b1;
                                    inst_tmp <= `NULL;
                                    status <= `IDLE;
                                    current_stage <= Stage_0; 
                                end
                            endcase
                        end
                        `SW: begin
                            case (current_stage)
                                Stage_0: current_stage <= Stage_1;
                                Stage_1: current_stage <= Stage_2;
                                Stage_2: current_stage <= Stage_3;
                                Stage_3: current_stage <= Stage_4;
                                Stage_4: begin
                                    rob_finish_out <= 1'b1;
                                    inst_tmp <= `NULL;
                                    status <= `IDLE;
                                    current_stage <= Stage_0; 
                                end
                            endcase
                        end
                    endcase
                end
            end
        end
    end
end

always @(*) begin
    if (!rst_in) begin
        case (current_stage)
            Stage_1: begin
                case (owner)
                    IF: begin
                        ram_rw_out <= read;
                        ram_addr_out <= ifetch_pc_in;
                        ram_wdata_out <= `NULL;
                    end
                    LB: begin
                        ram_rw_out <= read;
                        ram_addr_out <= lbuffer_A_in;
                        ram_wdata_out <= `NULL;
                    end
                    ROB: begin
                        ram_rw_out <= write;
                        ram_addr_out <= rob_addr_in;
                        ram_wdata_out <= rob_wdata_in[7 : 0];
                    end
                endcase
            end
            Stage_2: begin
                case (owner)
                    IF: begin
                        ram_rw_out <= read;
                        ram_addr_out <= ifetch_pc_in + 32'h1;
                        ram_wdata_out <= `NULL;
                    end
                    LB: begin
                        ram_rw_out <= read;
                        ram_addr_out <= lbuffer_A_in + 32'h1;
                        ram_wdata_out <= `NULL;
                    end
                    ROB: begin
                        ram_rw_out <= write;
                        ram_addr_out <= rob_addr_in + 32'h1;
                        ram_wdata_out <= rob_wdata_in[15 : 8];
                    end
                endcase
            end
            Stage_3: begin
                case (owner)
                    IF: begin
                        ram_rw_out <= read;
                        ram_addr_out <= ifetch_pc_in + 32'h2;
                        ram_wdata_out <= `NULL;
                    end
                    LB: begin
                        ram_rw_out <= read;
                        ram_addr_out <= lbuffer_A_in + 32'h2;
                        ram_wdata_out <= `NULL;
                    end
                    ROB: begin
                        ram_rw_out <= write;
                        ram_addr_out <= rob_addr_in + 32'h2;
                        ram_wdata_out <= rob_wdata_in[23 : 16];
                    end
                endcase
            end
            Stage_4: begin
                case (owner)
                    IF: begin
                        ram_rw_out <= read;
                        ram_addr_out <= ifetch_pc_in + 32'h3;
                        ram_wdata_out <= `NULL;
                    end
                    LB: begin
                        ram_rw_out <= read;
                        ram_addr_out <= lbuffer_A_in + 32'h3;
                        ram_wdata_out <= `NULL;
                    end
                    ROB: begin
                        ram_rw_out <= write;
                        ram_addr_out <= rob_addr_in + 32'h3;
                        ram_wdata_out <= rob_wdata_in[31 : 24];
                    end
                endcase
            end
        endcase    
    end
end

assign ifetch_bus_rdy_out = (owner == IF || status == `IDLE) ? `ENABLE : `DISABLE;
assign lbuffer_rdy_out = (owner == LB || status == `IDLE) ? `ENABLE : `DISABLE;
assign rob_rdy_out = (owner == ROB || status == `IDLE) ? `ENABLE : `DISABLE;

endmodule