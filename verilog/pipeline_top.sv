module pipeline_top # (
    parameter QED_TRACE_FIFO_SIZE = 16
)
(   
    input        clock0,             // System clock
    input        reset0,             // System reset
    input [3:0]  mem2proc_response0, // Tag from memory about current request
    input [63:0] mem2proc_data0,     // Data coming back from memory
    input [3:0]  mem2proc_tag0,      // Tag from memory about current reply

    output logic [1:0]       proc2mem_command0, // Command sent to memory
    output logic [`XLEN-1:0] proc2mem_addr0,    // Address sent to memory
    output logic [63:0]      proc2mem_data0,    // Data sent to memory
    output MEM_SIZE          proc2mem_size0,    // Data size sent to memory

    // Note: these are assigned at the very bottom of the module
    output logic [3:0]       pipeline_completed_insts0,
    output EXCEPTION_CODE    pipeline_error_status0,
    output logic [4:0]       pipeline_commit_wr_idx0,
    output logic [`XLEN-1:0] pipeline_commit_wr_data0,
    output logic             pipeline_commit_wr_en0,
    output logic [`XLEN-1:0] pipeline_commit_NPC0,

    // Debug outputs: these signals are solely used for debugging in testbenches
    // Do not change for project 3
    // You should definitely change these for project 4
    output logic [`XLEN-1:0] if_NPC_dbg0,
    output logic [31:0]      if_inst_dbg0,
    output logic             if_valid_dbg0,
    output logic [`XLEN-1:0] if_id_NPC_dbg0,
    output logic [31:0]      if_id_inst_dbg0,
    output logic             if_id_valid_dbg0,
    output logic [`XLEN-1:0] id_ex_NPC_dbg0,
    output logic [31:0]      id_ex_inst_dbg0,
    output logic             id_ex_valid_dbg0,
    output logic [`XLEN-1:0] ex_mem_NPC_dbg0,
    output logic [31:0]      ex_mem_inst_dbg0,
    output logic             ex_mem_valid_dbg0,
    output logic [`XLEN-1:0] mem_wb_NPC_dbg0,
    output logic [31:0]      mem_wb_inst_dbg0,
    output logic             mem_wb_valid_dbg0,
    output EX_MEM_PACKET     ex_mem_packet_out0,
    output MEM_WB_PACKET     mem_wb_packet_out0,



    input        clock1,             // System clock
    input        reset1,             // System reset
    input [3:0]  mem2proc_response1, // Tag from memory about current request
    input [63:0] mem2proc_data1,     // Data coming back from memory
    input [3:0]  mem2proc_tag1,      // Tag from memory about current reply

    output logic [1:0]       proc2mem_command1, // Command sent to memory
    output logic [`XLEN-1:0] proc2mem_addr1,    // Address sent to memory
    output logic [63:0]      proc2mem_data1,    // Data sent to memory
    output MEM_SIZE          proc2mem_size1,    // Data size sent to memory

    // Note: these are assigned at the very bottom of the module
    output logic [3:0]       pipeline_completed_insts1,
    output EXCEPTION_CODE    pipeline_error_status1,
    output logic [4:0]       pipeline_commit_wr_idx1,
    output logic [`XLEN-1:0] pipeline_commit_wr_data1,
    output logic             pipeline_commit_wr_en1,
    output logic [`XLEN-1:0] pipeline_commit_NPC1,

    // Debug outputs: these signals are solely used for debugging in testbenches
    // Do not change for project 3
    // You should definitely change these for project 4
    output logic [`XLEN-1:0] if_NPC_dbg1,
    output logic [31:0]      if_inst_dbg1,
    output logic             if_valid_dbg1,
    output logic [`XLEN-1:0] if_id_NPC_dbg1,
    output logic [31:0]      if_id_inst_dbg1,
    output logic             if_id_valid_dbg1,
    output logic [`XLEN-1:0] id_ex_NPC_dbg1,
    output logic [31:0]      id_ex_inst_dbg1,
    output logic             id_ex_valid_dbg1,
    output logic [`XLEN-1:0] ex_mem_NPC_dbg1,
    output logic [31:0]      ex_mem_inst_dbg1,
    output logic             ex_mem_valid_dbg1,
    output logic [`XLEN-1:0] mem_wb_NPC_dbg1,
    output logic [31:0]      mem_wb_inst_dbg1,
    output logic             mem_wb_valid_dbg1,
    output EX_MEM_PACKET     ex_mem_packet_out1,
    output MEM_WB_PACKET     mem_wb_packet_out1,

    input logic clock,
    input logic reset,
    input MEM_WB_PACKET packet1,
    input MEM_WB_PACKET packet2,
    output  logic              fault_debug,           // Fault signal
    output MEM_WB_PACKET  [QED_TRACE_FIFO_SIZE-1:0]    trace1 , // FIFO1 contents
    output MEM_WB_PACKET  [QED_TRACE_FIFO_SIZE-1:0]    trace2,   // FIFO2 contents
    output [$clog2(QED_TRACE_FIFO_SIZE)-1:0] head1_out, head2_out,
    output logic has_fault_occured,
    output int faultCounterDebug


    
);

logic fault;
assign fault_debug = fault;

    // Instantiate the Pipeline
    pipeline core0 (
        // Inputs
        .clock             (clock0),
        .reset             (reset0),
        .mem2proc_response (mem2proc_response0),
        .mem2proc_data     (mem2proc_data0),
        .mem2proc_tag      (mem2proc_tag0),

        // Outputs
        .proc2mem_command (proc2mem_command0),
        .proc2mem_addr    (proc2mem_addr0),
        .proc2mem_data    (proc2mem_data0),
        .proc2mem_size    (proc2mem_size0),

        .pipeline_completed_insts (pipeline_completed_insts0),
        .pipeline_error_status    (pipeline_error_status0),
        .pipeline_commit_wr_data  (pipeline_commit_wr_data0),
        .pipeline_commit_wr_idx   (pipeline_commit_wr_idx0),
        .pipeline_commit_wr_en    (pipeline_commit_wr_en0),
        .pipeline_commit_NPC      (pipeline_commit_NPC0),

        .if_NPC_dbg       (if_NPC_dbg0),
        .if_inst_dbg      (if_inst_dbg0),
        .if_valid_dbg     (if_valid_dbg0),
        .if_id_NPC_dbg    (if_id_NPC_dbg0),
        .if_id_inst_dbg   (if_id_inst_dbg0),
        .if_id_valid_dbg  (if_id_valid_dbg0),
        .id_ex_NPC_dbg    (id_ex_NPC_dbg0),
        .id_ex_inst_dbg   (id_ex_inst_dbg0),
        .id_ex_valid_dbg  (id_ex_valid_dbg0),
        .ex_mem_NPC_dbg   (ex_mem_NPC_dbg0),
        .ex_mem_inst_dbg  (ex_mem_inst_dbg0),
        .ex_mem_valid_dbg (ex_mem_valid_dbg0),
        .mem_wb_NPC_dbg   (mem_wb_NPC_dbg0),
        .mem_wb_inst_dbg  (mem_wb_inst_dbg0),
        .mem_wb_valid_dbg (mem_wb_valid_dbg0),
        .ex_mem_packet_out(ex_mem_packet_out0),
        .mem_wb_packet_out(mem_wb_packet_out0)
    );

    pipeline_buggy core1 (
        // Inputs
        .clock             (clock1),
        .reset             (reset1),
        .mem2proc_response (mem2proc_response1),
        .mem2proc_data     (mem2proc_data1),
        .mem2proc_tag      (mem2proc_tag1),

        // Outputs
        .proc2mem_command (proc2mem_command1),
        .proc2mem_addr    (proc2mem_addr1),
        .proc2mem_data    (proc2mem_data1),
        .proc2mem_size    (proc2mem_size1),

        .pipeline_completed_insts (pipeline_completed_insts1),
        .pipeline_error_status    (pipeline_error_status1),
        .pipeline_commit_wr_data  (pipeline_commit_wr_data1),
        .pipeline_commit_wr_idx   (pipeline_commit_wr_idx1),
        .pipeline_commit_wr_en    (pipeline_commit_wr_en1),
        .pipeline_commit_NPC      (pipeline_commit_NPC1),

        .if_NPC_dbg       (if_NPC_dbg1),
        .if_inst_dbg      (if_inst_dbg1),
        .if_valid_dbg     (if_valid_dbg1),
        .if_id_NPC_dbg    (if_id_NPC_dbg1),
        .if_id_inst_dbg   (if_id_inst_dbg1),
        .if_id_valid_dbg  (if_id_valid_dbg1),
        .id_ex_NPC_dbg    (id_ex_NPC_dbg1),
        .id_ex_inst_dbg   (id_ex_inst_dbg1),
        .id_ex_valid_dbg  (id_ex_valid_dbg1),
        .ex_mem_NPC_dbg   (ex_mem_NPC_dbg1),
        .ex_mem_inst_dbg  (ex_mem_inst_dbg1),
        .ex_mem_valid_dbg (ex_mem_valid_dbg1),
        .mem_wb_NPC_dbg   (mem_wb_NPC_dbg1),
        .mem_wb_inst_dbg  (mem_wb_inst_dbg1),
        .mem_wb_valid_dbg (mem_wb_valid_dbg1),
        .ex_mem_packet_out(ex_mem_packet_out1),
        .mem_wb_packet_out(mem_wb_packet_out1)
    );



        QEDV2 #(.N(10)) qed (
        .clk(clock),
        .reset(reset),
        .packet1(mem_wb_packet_out0),
        .packet2(mem_wb_packet_out1),
        .fault(fault)
    );


        QEDTrace
    #(.FIFO_SIZE(QED_TRACE_FIFO_SIZE))
    qedtrace (
        .clk(clock),
        .reset(reset),
        .packet1(mem_wb_packet_out0),
        .packet2(mem_wb_packet_out1),
        .fault(fault),
        .trace1(trace1),
        .trace2(trace2),
        .head1_out(head1_out),
        .head2_out(head2_out),
        .has_fault_occured(has_fault_occured),
        .faultCounterDebug(faultCounterDebug)
        

    );

endmodule

