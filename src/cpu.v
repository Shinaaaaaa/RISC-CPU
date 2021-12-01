// RISCV32I CPU top module
// port modification allowed for debugging purposes
`include "define.vh"
`include "addressUnit.v"
`include "ALU.v"
`include "decoder.v"
`include "dispatcher.v"
`include "IFetch.v"
`include "InstQueue.v"
`include "LBuffer.v"
`include "LSQueue.v"
`include "ram_RW.v"
`include "register.v"
`include "rob.v"
`include "RS.v"

module cpu(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
	input  wire					rdy_in,			// ready signal, pause cpu when low

    input  wire [ 7:0]          mem_din,		// data input bus
    output wire [ 7:0]          mem_dout,		// data output bus
    output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
    output wire                 mem_wr,			// write/read signal (1 for write)
	
	input  wire                 io_buffer_full, // 1 if uart buffer is full
	
	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

wire rob_flush;

wire ram_bus_ifetch_rdy;
wire ram_bus_ifetch_en;
wire[`INSTRUCTION_WIDTH] ram_bus_ifetch_inst;
wire ifetch_ram_bus_en;
wire[`ADDRESS_WIDTH] ifetch_ram_bus_pc;

wire instqueue_ifetch_rdy;
wire ifetch_instqueue_en;
wire[`INSTRUCTION_WIDTH] ifetch_instqueue_inst;
wire[`ADDRESS_WIDTH] ifetch_instqueue_pc;

wire rob_ifetch_en;
wire[`ADDRESS_WIDTH] rob_ifetch_pc;

wire rob_instqueue_rdy;

wire lsqueue_instqueue_rdy;

wire rs_instqueue_rdy;

wire instqueue_decoder_en;
wire[`INSTRUCTION_WIDTH] instqueue_decoder_inst;
wire[`ADDRESS_WIDTH] instqueue_decoder_pc;

wire decoder_dispatcher_en;
wire[`INST_TYPE_WIDTH] decoder_dispatcher_inst_type;
wire[`REGISTER_WIDTH] decoder_dispatcher_rs1;
wire[`REGISTER_WIDTH] decoder_dispatcher_rs2;
wire[`REGISTER_WIDTH] decoder_dispatcher_rd;
wire[`INSTRUCTION_WIDTH] decoder_dispatcher_imm;
wire[`ADDRESS_WIDTH] decoder_dispatcher_pc;

wire dispatcher_register_en;
wire[`REGISTER_WIDTH] dispatcher_register_rs1;
wire[`REGISTER_WIDTH] dispatcher_register_rs2;
wire[`REGISTER_WIDTH] dispatcher_register_rd;
wire[`ROB_WIDTH] dispatcher_register_rd_dest;
wire[`INSTRUCTION_WIDTH] register_dispatcher_rs1_data;
wire register_dispatcher_rs1_busy;
wire[`ROB_WIDTH] register_dispatcher_rs1_dest;
wire[`INSTRUCTION_WIDTH] register_dispatcher_rs2_data;
wire register_dispatcher_rs2_busy;
wire[`ROB_WIDTH] register_dispatcher_rs2_dest;

wire dispatcher_rob_en;
wire[`INST_TYPE_WIDTH] dispatcher_rob_inst_type;
wire[`REGISTER_WIDTH] dispatcher_rob_reg_pos;
wire[`ROB_WIDTH] dispatcher_rob_rs1;
wire[`ROB_WIDTH] dispatcher_rob_rs2;
wire[`ROB_WIDTH] rob_dispatcher_idle_pos;
wire rob_dispatcher_rs1_rdy;
wire[`INSTRUCTION_WIDTH] rob_dispatcher_rs1_data;
wire rob_dispatcher_rs2_rdy;
wire[`INSTRUCTION_WIDTH] rob_dispatcher_rs2_data;

wire dispatcher_rs_en;
wire dispatcher_lsqueue_en;

wire[`INSTRUCTION_WIDTH] dispatcher_vj;
wire[`ROB_WIDTH] dispatcher_qj;
wire[`INSTRUCTION_WIDTH] dispatcher_vk;
wire[`ROB_WIDTH] dispatcher_qk;
wire[`INST_TYPE_WIDTH] dispatcher_inst_type;
wire[`INSTRUCTION_WIDTH] dispatcher_A;
wire[`ROB_WIDTH] dispatcher_dest;
wire[`INSTRUCTION_WIDTH] dispatcher_pc;

wire rs_alu_en;
wire[`INSTRUCTION_WIDTH] rs_alu_vj;
wire[`INSTRUCTION_WIDTH] rs_alu_vk;
wire[`INSTRUCTION_WIDTH] rs_alu_A;
wire[`ROB_WIDTH] rs_alu_dest;
wire[`ADDRESS_WIDTH] rs_alu_pc;
wire[`INST_TYPE_WIDTH] rs_alu_inst_type;

wire cdb_alu_en;
wire[`ROB_WIDTH] cdb_alu_dest;
wire[`INSTRUCTION_WIDTH] cdb_alu_value;
wire[`ADDRESS_WIDTH] cdb_alu_addr;

wire lbuffer_lsqueue_rdy;

wire lsqueue_rob_en;
wire[`ROB_WIDTH] lsqueue_rob_dest;
wire[`INSTRUCTION_WIDTH] lsqueue_rob_value;

wire lsqueue_addressUnit_en;
wire[`INSTRUCTION_WIDTH] lsqueue_addressUnit_A;
wire[`INSTRUCTION_WIDTH] lsqueue_addressUnit_vj;
wire[`ROB_WIDTH] lsqueue_addressUnit_dest;
wire[`INST_TYPE_WIDTH] lsqueue_addressUnit_inst_type;

wire addressUnit_lbuffer_en;
wire[`INSTRUCTION_WIDTH] addressUnit_lbuffer_A;
wire[`ROB_WIDTH] addressUnit_lbuffer_dest;
wire[`INST_TYPE_WIDTH] addressUnit_lbuffer_inst_type;

wire addressUnit_rob_en;
wire[`ROB_WIDTH] addressUnit_rob_dest;
wire[`ADDRESS_WIDTH] addressUnit_rob_address;

wire cdb_lbuffer_en;
wire[`ROB_WIDTH] cdb_lbuffer_dest;
wire[`INSTRUCTION_WIDTH] cdb_lbuffer_value;

wire lbuffer_rob_load_check_en;
wire[`ROB_WIDTH] lbuffer_rob_load_check_dest;
wire[`ADDRESS_WIDTH] lbuffer_rob_load_check_address;
wire rob_lbuffer_load_check_sameaddress;
wire rob_lbuffer_load_check_forwarding_en;
wire[`INSTRUCTION_WIDTH] rob_lbuffer_load_check_forwarding_data;

wire ram_bus_lbuffer_rdy;
wire ram_bus_lbuffer_data_en;
wire[`INSTRUCTION_WIDTH] ram_bus_lbuffer_data;
wire lbuffer_ram_bus_en;
wire[`INSTRUCTION_WIDTH] lbuffer_ram_bus_A;
wire[`ROB_WIDTH] lbuffer_ram_bus_dest;
wire[`INST_TYPE_WIDTH] lbuffer_ram_bus_inst_type;

wire ram_bus_rob_rdy;
wire ram_bus_rob_finish;
wire rob_ram_bus_en;
wire[`ADDRESS_WIDTH] rob_ram_bus_address;
wire[`INSTRUCTION_WIDTH] rob_ram_bus_wdata;
wire[`INST_TYPE_WIDTH] rob_ram_bus_inst_type;

wire rob_register_en;
wire[`REGISTER_WIDTH] rob_register_reg_pos;
wire[`ROB_WIDTH] rob_register_dest;
wire[`INSTRUCTION_WIDTH] rob_register_value;

IFetch IFetch(
    .clk_in (clk_in),
    .rst_in (rst_in),
    .rdy_in (rdy_in),

    .ram_bus_rdy_in (ram_bus_ifetch_rdy),
    .ram_bus_en_in (ram_bus_ifetch_en),
    .ram_bus_inst_in (ram_bus_ifetch_inst),
    .ram_bus_en_out (ifetch_ram_bus_en),
    .ram_bus_pc_out (ifetch_ram_bus_pc),

    .instqueue_rdy_in (instqueue_ifetch_rdy),
    .instqueue_inst_en_out (ifetch_instqueue_en),
    .instqueue_inst_out (ifetch_instqueue_inst),
    .instqueue_pc_out (ifetch_instqueue_pc),

    .rob_en_in (rob_ifetch_en),
    .rob_pc_in (rob_ifetch_pc)
);

InstQueue InstQueue(
    .clk_in (clk_in),
    .rst_in (rst_in),
    .rdy_in (rdy_in),

    .rob_flush_in (flush),

    .rob_rdy_in (rob_instqueue_rdy),

    .lsqueue_rdy_in (lsqueue_instqueue_rdy),

    .rs_rdy_in (rs_instqueue_rdy),

    .ifetch_rdy_out (instqueue_ifetch_rdy),
    .ifetch_en_in (ifetch_instqueue_en),
    .ifetch_inst_in (ifetch_instqueue_inst),
    .ifetch_pc_in (ifetch_instqueue_pc),

    .decoder_en_out (instqueue_decoder_en),
    .decoder_inst_out (instqueue_decoder_inst),
    .decoder_pc_out (instqueue_decoder_pc)
);

decoder decoder(
    .clk_in (clk_in),    
    .rst_in (rst_in),
    .rdy_in (rdy_in),
    
    .rob_flush_in (rob_flush),

    .instqueue_inst_en (instqueue_decoder_en),
    .instqueue_inst_in (instqueue_decoder_inst),
    .instqueue_pc_in (instqueue_decoder_pc),

    .dispatcher_en_out (decoder_dispatcher_en),
    .dispatcher_inst_type_out (decoder_dispatcher_inst_type),
    .dispatcher_rs1_out (decoder_dispatcher_rs1),
    .dispatcher_rs2_out (decoder_dispatcher_rs2),
    .dispatcher_rd_out (decoder_dispatcher_rd), 
    .dispatcher_imm_out (decoder_dispatcher_imm),
    .dispatcher_pc_out (decoder_dispatcher_pc)
);

dispatcher dispatcher(
    .clk_in (clk_in),
    .rst_in (rst_in),
    .rdy_in (rdy_in),
    
    .decoder_en_in (decoder_dispatcher_en),
    .decoder_inst_type_in (decoder_dispatcher_inst_type),
    .decoder_rs1_in (decoder_dispatcher_rs1),
    .decoder_rs2_in (decoder_dispatcher_rs2),
    .decoder_rd_in (decoder_dispatcher_rd), 
    .decoder_imm_in (decoder_dispatcher_imm),
    .decoder_pc_in (decoder_dispatcher_pc),

    .register_en_out (dispatcher_register_en),
    .register_rs1_out (dispatcher_register_rs1),
    .register_rs2_out (dispatcher_register_rs2),
    .register_rd_out (dispatcher_register_rd),
    .register_rd_robnum_out (dispatcher_register_rd_dest),
    .register_rs1_data_in (register_dispatcher_rs1_data),
    .register_rs1_busy_in (register_dispatcher_rs2_busy),
    .register_rs1_robnum_in (register_dispatcher_rs1_dest),
    .register_rs2_data_in (register_dispatcher_rs2_data),
    .register_rs2_busy_in (register_dispatcher_rs2_busy),
    .register_rs2_robnum_in (register_dispatcher_rs2_dest),
    
    .rob_en_out (dispatcher_rob_en),
    .rob_inst_type_out (dispatcher_rob_inst_type),
    .rob_reg_pos_out (dispatcher_rob_reg_pos),
    .rob_rs1_out (dispatcher_rob_rs1),
    .rob_rs2_out (dispatcher_rob_rs2),
    .rob_idle_pos_in (rob_dispatcher_idle_pos),
    .rob_rs1_rdy_in (rob_dispatcher_rs1_rdy),
    .rob_rs1_data_in (rob_dispatcher_rs1_data),
    .rob_rs2_rdy_in (rob_dispatcher_rs2_rdy),
    .rob_rs2_data_in (rob_dispatcher_rs2_data),

    .rs_en_out (dispatcher_rs_en),
    .lsqueue_en_out (dispatcher_lsqueue_en),

    .vj_out (dispatcher_vj),
    .qj_out (dispatcher_qj),
    .vk_out (dispatcher_vk),
    .qk_out (dispatcher_qk),
    .inst_type_out (dispatcher_inst_type),
    .A_out (dispatcher_A),
    .dest_out (dispatcher_dest),
    .pc_out (dispatcher_pc)
);

RS RS(
    .clk_in (clk_in),
    .rst_in (rst_in),
    .rdy_in (rdy_in),

    .rob_flush_in (rob_flush),

    .instqueue_rdy_out (rs_instqueue_rdy),

    .dispatcher_en_in (dispatcher_rs_en),
    .dispatcher_vj_in (dispatcher_vj),
    .dispatcher_qj_in (dispatcher_qj),
    .dispatcher_vk_in (dispatcher_vk),
    .dispatcher_qk_in (dispatcher_qk),
    .dispatcher_inst_type_in (dispatcher_inst_type),
    .dispatcher_A_in (dispatcher_A),
    .dispatcher_dest_in (dispatcher_dest),
    .dispatcher_pc_in (dispatcher_pc),

    .alu_en_out (rs_alu_en),
    .alu_vj_out (rs_alu_vj),
    .alu_vk_out (rs_alu_vk),
    .alu_A_out (rs_alu_A),
    .alu_dest_out (rs_alu_dest),
    .alu_pc_out (rs_alu_pc),
    .alu_inst_type_out (rs_alu_inst_type),

    .cdb_alu_en_in (cdb_alu_en),
    .cdb_alu_dest_in (cdb_alu_dest),
    .cdb_alu_value_in (cdb_alu_value),

    .cdb_lbuffer_en_in (cdb_lbuffer_en),
    .cdb_lbuffer_dest_in (cdb_lbuffer_dest),
    .cdb_lbuffer_value_in (cdb_lbuffer_value)
);

ALU ALU(
    .clk_in (clk_in),
    .rst_in (rst_in),
    .rdy_in (rdy_in),

    .rs_en_in (rs_alu_en),
    .rs_vj_in (rs_alu_vj),
    .rs_vk_in (rs_alu_vk),
    .rs_A_in (rs_alu_A),
    .rs_dest_in (rs_alu_dest),
    .rs_pc_in (rs_alu_pc),
    .rs_inst_type_in (rs_alu_inst_type),

    .rob_flush_in (rob_flush),
    
    .cdb_alu_en_out (cdb_alu_en),
    .cdb_alu_dest_out (cdb_alu_dest),
    .cdb_alu_value_out (cdb_alu_value),
    .cdb_alu_addr_out (cdb_alu_addr)
);

rob rob(
    .clk_in (clk_in),
    .rst_in (rst_in),
    .rdy_in (rdy_in),

    .flush (rob_flush),

    .if_en_out (rob_ifetch_en),
    .if_pc_out (rob_ifetch_pc),

    .instqueue_rdy_out (rob_instqueue_rdy),

    .dispatcher_en_in (dispatcher_rob_en),
    .dispatcher_inst_type_in (dispatcher_rob_inst_type),
    .dispatcher_reg_pos_in (dispatcher_rob_reg_pos),
    .dispatcher_rs1_in (dispatcher_rob_rs1),
    .dispatcher_rs2_in (dispatcher_rob_rs2),
    .dispatcher_idle_pos_out (rob_dispatcher_idle_pos),
    .dispatcher_rs1_rdy_out (rob_dispatcher_rs1_rdy),
    .dispatcher_rs1_data_out (rob_dispatcher_rs1_data),
    .dispatcher_rs2_rdy_out (rob_dispatcher_rs2_rdy),
    .dispatcher_rs2_data_out (rob_dispatcher_rs2_data),

    .cdb_alu_en_in (cdb_alu_en),
    .cdb_alu_dest_in (cdb_alu_dest),
    .cdb_alu_value_in (cdb_alu_value),
    .cdb_alu_addr_in (cdb_alu_addr),

    .addressUnit_en_in (addressUnit_rob_en),
    .addressUnit_dest_in (addressUnit_rob_dest),
    .addressUnit_address_in (addressUnit_rob_address),

    .cdb_lbuffer_en_in (cdb_lbuffer_en),
    .cdb_lbuffer_dest_in (cdb_lbuffer_dest),
    .cdb_lbuffer_value_in (cdb_lbuffer_value),

    .lbuffer_load_check_en (lbuffer_rob_load_check_en),
    .lbuffer_load_check_dest_in (lbuffer_rob_load_check_dest),
    .lbuffer_load_check_address_in (lbuffer_rob_load_check_address),
    .lbuffer_load_check_sameaddress_out (rob_lbuffer_load_check_sameaddress),
    .lbuffer_load_check_forwarding_en_out (rob_lbuffer_load_check_forwarding_en),
    .lbuffer_load_check_forwarding_data_out (rob_lbuffer_load_check_forwarding_data),

    .ram_bus_rdy_in (ram_bus_rob_rdy),
    .ram_bus_finish_in (ram_bus_rob_finish),
    .ram_bus_en_out (rob_ram_bus_en),
    .ram_bus_address_out (rob_ram_bus_address),
    .ram_bus_wdata_out (rob_ram_bus_wdata),
    .ram_bus_inst_type_out (rob_ram_bus_inst_type),

    .register_en_out (rob_register_en),
    .register_reg_pos_out (rob_register_reg_pos),
    .register_dest_out (rob_register_dest),
    .register_value_out (rob_register_value)
);

LSQueue LSQueue(
    .clk_in (clk_in),
    .rst_in (rst_in),
    .rdy_in (rdy_in),

    .lbuffer_rdy_in (lbuffer_lsqueue_rdy),

    .instqueue_rdy_out (lsqueue_instqueue_rdy),

    .dispatcher_en_in (dispatcher_lsqueue_en),
    .dispatcher_vj_in (dispatcher_vj),
    .dispatcher_qj_in (dispatcher_qj),
    .dispatcher_vk_in (dispatcher_vk),
    .dispatcher_qk_in (dispatcher_qk),
    .dispatcher_inst_type_in (dispatcher_inst_type),
    .dispatcher_A_in (dispatcher_A),
    .dispatcher_dest_in (dispatcher_dest),

    .cdb_alu_en_in (cdb_alu_en),
    .cdb_alu_dest_in (cdb_alu_dest),
    .cdb_alu_value_in (cdb_alu_value),

    .cdb_lbuffer_en_in (cdb_lbuffer_en),
    .cdb_lbuffer_dest_in (cdb_lbuffer_dest),
    .cdb_lbuffer_value_in (cdb_lbuffer_value),

    .rob_flush_in (rob_flush),
    .rob_en_out (lsqueue_rob_en),
    .rob_dest_out (lsqueue_rob_dest),
    .rob_value_out (lsqueue_rob_value),

    .addressUnit_en_out (lsqueue_addressUnit_en),
    .addressUnit_A_out (lsqueue_addressUnit_A),
    .addressUnit_vj_out (lsqueue_addressUnit_vj),
    .addressUnit_dest_out (lsqueue_addressUnit_dest),
    .addressUnit_inst_type_out (lsqueue_addressUnit_inst_type)
);

addressUnit addressUnit(
    .clk_in (clk_in),
    .rst_in (rst_in),
    .rdy_in (rdy_in),

    .lsqueue_en_in (lsqueue_addressUnit_en),
    .lsqueue_A_in (lsqueue_addressUnit_A),
    .lsqueue_vj_in (lsqueue_addressUnit_vj),
    .lsqueue_dest_in (lsqueue_addressUnit_dest),
    .lsqueue_inst_type_in (lsqueue_addressUnit_inst_type),

    .lbuffer_en_out (addressUnit_lbuffer_en),
    .lbuffer_A_out (addressUnit_lbuffer_A),
    .lbuffer_dest_out (addressUnit_lbuffer_dest),
    .lbuffer_inst_type_out (addressUnit_lbuffer_inst_type),

    .rob_en_out (addressUnit_rob_en),
    .rob_dest_out (addressUnit_rob_dest),
    .rob_address_out (addressUnit_rob_address)
);

LBuffer LBuffer(
    .clk_in (clk_in),
    .rst_in (rst_in),
    .rdy_in (rdy_in),

    .rob_flush_in (rob_flush),

    .lsqueue_rdy_out (lbuffer_lsqueue_rdy),

    .addressUnit_en_in (addressUnit_lbuffer_en),
    .addressUnit_A_in (addressUnit_lbuffer_A),
    .addressUnit_dest_in (addressUnit_lbuffer_dest),
    .addressUnit_inst_type_in (addressUnit_lbuffer_inst_type),

    .cdb_lbuffer_en_out (cdb_lbuffer_en),
    .cdb_lbuffer_dest_out (cdb_lbuffer_dest),
    .cdb_lbuffer_value_out (cdb_lbuffer_value),

    .rob_load_check_en_out (lbuffer_rob_load_check_en),
    .rob_load_check_dest_out (lbuffer_rob_load_check_dest),
    .rob_load_check_address_out (lbuffer_rob_load_check_address),
    .rob_load_check_sameaddress_in (rob_lbuffer_load_check_sameaddress),
    .rob_load_check_forwarding_en_in (rob_lbuffer_load_check_forwarding_en),
    .rob_load_check_forwarding_data_in (rob_lbuffer_load_check_forwarding_data),

    .ram_bus_rdy_in (ram_bus_lbuffer_rdy),
    .ram_bus_data_en_in (ram_bus_lbuffer_data_en),
    .ram_bus_data_in (ram_bus_lbuffer_data),
    .ram_bus_en_out (lbuffer_ram_bus_en),
    .ram_bus_A_out (lbuffer_ram_bus_A),
    .ram_bus_dest_out (lbuffer_ram_bus_dest),
    .ram_bus_inst_type_out (lbuffer_ram_bus_inst_type)
);

ram_RW ram_RW(
    .clk_in (clk_in),
    .rst_in (rst_in),
    .rdy_in (rdy_in),

    .ram_rdata_in (mem_din),
    .ram_wdata_out (mem_dout),
    .ram_addr_out (mem_a),
    .ram_rw_out (mem_wr),

    .ifetch_rdy_out (ram_bus_ifetch_rdy),
    .ifetch_en_out (ram_bus_ifetch_en),
    .ifetch_inst_out (ram_bus_ifetch_inst),
    .ifetch_en_in (ifetch_ram_bus_en),
    .ifetch_pc_in (ifetch_ram_bus_pc),

    .lbuffer_rdy_out (ram_bus_lbuffer_rdy),
    .lbuffer_data_en_out (ram_bus_lbuffer_data_en),
    .lbuffer_data_out (ram_bus_lbuffer_data),
    .lbuffer_en_in (lbuffer_ram_bus_en),
    .lbuffer_A_in (lbuffer_ram_bus_A),
    .lbuffer_dest_in (lbuffer_ram_bus_dest),
    .lbuffer_inst_type_in (lbuffer_ram_bus_inst_type),
    
    .rob_flush_in (rob_flush),
    .rob_rdy_out (ram_bus_rob_rdy),
    .rob_finish_out (ram_bus_rob_finish),
    .rob_en_in (rob_ram_bus_en),
    .rob_addr_in (rob_ram_bus_address),
    .rob_wdata_in (rob_ram_bus_wdata),
    .rob_inst_type_in (rob_ram_bus_inst_type)
);

register register(
    .clk_in (clk_in),
    .rst_in (rst_in),
    .rdy_in (rdy_in),

    .dispatcher_en_in (dispatcher_register_en),
    .dispatcher_rs1_in (dispatcher_register_rs1),
    .dispatcher_rs2_in (dispatcher_register_rs2),
    .dispatcher_rd_in (dispatcher_register_rd),
    .dispatcher_rd_dest_in (dispatcher_register_rd_dest),
    .dispatcher_rs1_data_out (register_dispatcher_rs1_data),
    .dispatcher_rs1_busy_out (register_dispatcher_rs1_busy),
    .dispatcher_rs1_dest_out (register_dispatcher_rs1_dest), 
    .dispatcher_rs2_data_out (register_dispatcher_rs2_data), 
    .dispatcher_rs2_busy_out (register_dispatcher_rs2_busy),
    .dispatcher_rs2_dest_out (register_dispatcher_rs2_dest),
    
    .rob_en_in (rob_register_en),
    .rob_reg_pos_in (rob_register_reg_pos),
    .rob_dest_in (rob_register_dest),
    .rob_value_in (rob_register_value)
);

endmodule