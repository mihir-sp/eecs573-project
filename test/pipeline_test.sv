/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  testbench.sv                                        //
//                                                                     //
//  Description :  Testbench module for the verisimple pipeline;       //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`include "verilog/sys_defs.svh"

// these link to the pipe_print.c file in this directory, and are used below to print
// detailed output to the pipeline_output_file, initialized by open_pipeline_output_file()
import "DPI-C" function void open_pipeline_output_file(string file_name0, string file_name1);
import "DPI-C" function void print_header(string str, bit toFile0);
import "DPI-C" function void print_cycles(bit toFile0);
import "DPI-C" function void print_stage(string div, int inst, int npc, int valid_inst, bit toFile0);
import "DPI-C" function void print_reg(int wb_reg_wr_data_out_hi, int wb_reg_wr_data_out_lo,
                                       int wb_reg_wr_idx_out, int wb_reg_wr_en_out, bit toFile0);
import "DPI-C" function void print_membus(int proc2mem_command, int mem2proc_response,
                                          int proc2mem_addr_hi, int proc2mem_addr_lo,
                                          int proc2mem_data_hi, int proc2mem_data_lo, bit toFile0);
import "DPI-C" function void print_close();
import "DPI-C" function void testPrint();

interface pipeline_interface;
    logic        clock;
    logic        reset;

    logic [31:0] clock_count;
    logic [31:0] instr_count;
    logic [63:0] debug_counter; // counter used for when pipeline infinite loops, forces termination

    logic [1:0]       proc2mem_command;
    logic [`XLEN-1:0] proc2mem_addr;
    logic [63:0]      proc2mem_data;
    logic [3:0]       mem2proc_response;
    logic [63:0]      mem2proc_data;
    logic [3:0]       mem2proc_tag;
`ifndef CACHE_MODE
    MEM_SIZE          proc2mem_size;
`endif

    logic [3:0]       pipeline_completed_insts;
    EXCEPTION_CODE    pipeline_error_status;
    logic [4:0]       pipeline_commit_wr_idx;
    logic [`XLEN-1:0] pipeline_commit_wr_data;
    logic             pipeline_commit_wr_en;
    logic [`XLEN-1:0] pipeline_commit_NPC;

    logic [`XLEN-1:0] if_NPC_dbg;
    logic [31:0]      if_inst_dbg;
    logic             if_valid_dbg;
    logic [`XLEN-1:0] if_id_NPC_dbg;
    logic [31:0]      if_id_inst_dbg;
    logic             if_id_valid_dbg;
    logic [`XLEN-1:0] id_ex_NPC_dbg;
    logic [31:0]      id_ex_inst_dbg;
    logic             id_ex_valid_dbg;
    logic [`XLEN-1:0] ex_mem_NPC_dbg;
    logic [31:0]      ex_mem_inst_dbg;
    logic             ex_mem_valid_dbg;
    logic [`XLEN-1:0] mem_wb_NPC_dbg;
    logic [31:0]      mem_wb_inst_dbg;
    logic             mem_wb_valid_dbg;
    EX_MEM_PACKET     ex_mem_packet_out;
    MEM_WB_PACKET     mem_wb_packet_out;
    
endinterface //pipeline_interface


module testbench;
    // used to parameterize which files are used for memory and writeback/pipeline outputs
    // "./simv" uses program.mem, writeback.out, and pipeline.out
    // but now "./simv +MEMORY=<my_program>.mem" loads <my_program>.mem instead
    // use +WRITEBACK=<my_program>.wb and +PIPELINE=<my_program>.ppln for those outputs as well
    string program_memory_file;
    string writeback_output_file0;
    string pipeline_output_file0;
    
    string writeback_output_file1;
    string pipeline_output_file1;

    // variables used in the testbench
    logic        clock;
    logic        reset;
    logic [31:0] clock_count;
    logic [31:0] instr_count;
    int          wb_fileno0;
    int          wb_fileno1;
    logic [63:0] debug_counter; // counter used for when pipeline infinite loops, forces termination

    logic [1:0]       proc2mem_command;
    logic [`XLEN-1:0] proc2mem_addr;
    logic [63:0]      proc2mem_data;
    logic [3:0]       mem2proc_response;
    logic [63:0]      mem2proc_data;
    logic [3:0]       mem2proc_tag;
`ifndef CACHE_MODE
    MEM_SIZE          proc2mem_size;
`endif

    logic [3:0]       pipeline_completed_insts;
    EXCEPTION_CODE    pipeline_error_status;
    logic [4:0]       pipeline_commit_wr_idx;
    logic [`XLEN-1:0] pipeline_commit_wr_data;
    logic             pipeline_commit_wr_en;
    logic [`XLEN-1:0] pipeline_commit_NPC;

    logic [`XLEN-1:0] if_NPC_dbg;
    logic [31:0]      if_inst_dbg;
    logic             if_valid_dbg;
    logic [`XLEN-1:0] if_id_NPC_dbg;
    logic [31:0]      if_id_inst_dbg;
    logic             if_id_valid_dbg;
    logic [`XLEN-1:0] id_ex_NPC_dbg;
    logic [31:0]      id_ex_inst_dbg;
    logic             id_ex_valid_dbg;
    logic [`XLEN-1:0] ex_mem_NPC_dbg;
    logic [31:0]      ex_mem_inst_dbg;
    logic             ex_mem_valid_dbg;
    logic [`XLEN-1:0] mem_wb_NPC_dbg;
    logic [31:0]      mem_wb_inst_dbg;
    logic             mem_wb_valid_dbg;
    string format_str;
    logic QED_fault;
    parameter QED_TRACE_FIFO_SIZE = 16;

    MEM_WB_PACKET    [QED_TRACE_FIFO_SIZE-1:0]  trace1; // FIFO1 contents
    MEM_WB_PACKET     [QED_TRACE_FIFO_SIZE-1:0] trace2;
    logic has_fault_occured;

    pipeline_interface pif0();
    pipeline_interface pif1();


    // Instantiate the Pipeline
    pipeline core0 (
        // Inputs
        .clock             (pif0.clock),
        .reset             (pif0.reset),
        .mem2proc_response (pif0.mem2proc_response),
        .mem2proc_data     (pif0.mem2proc_data),
        .mem2proc_tag      (pif0.mem2proc_tag),

        // Outputs
        .proc2mem_command (pif0.proc2mem_command),
        .proc2mem_addr    (pif0.proc2mem_addr),
        .proc2mem_data    (pif0.proc2mem_data),
        .proc2mem_size    (pif0.proc2mem_size),

        .pipeline_completed_insts (pif0.pipeline_completed_insts),
        .pipeline_error_status    (pif0.pipeline_error_status),
        .pipeline_commit_wr_data  (pif0.pipeline_commit_wr_data),
        .pipeline_commit_wr_idx   (pif0.pipeline_commit_wr_idx),
        .pipeline_commit_wr_en    (pif0.pipeline_commit_wr_en),
        .pipeline_commit_NPC      (pif0.pipeline_commit_NPC),

        .if_NPC_dbg       (pif0.if_NPC_dbg),
        .if_inst_dbg      (pif0.if_inst_dbg),
        .if_valid_dbg     (pif0.if_valid_dbg),
        .if_id_NPC_dbg    (pif0.if_id_NPC_dbg),
        .if_id_inst_dbg   (pif0.if_id_inst_dbg),
        .if_id_valid_dbg  (pif0.if_id_valid_dbg),
        .id_ex_NPC_dbg    (pif0.id_ex_NPC_dbg),
        .id_ex_inst_dbg   (pif0.id_ex_inst_dbg),
        .id_ex_valid_dbg  (pif0.id_ex_valid_dbg),
        .ex_mem_NPC_dbg   (pif0.ex_mem_NPC_dbg),
        .ex_mem_inst_dbg  (pif0.ex_mem_inst_dbg),
        .ex_mem_valid_dbg (pif0.ex_mem_valid_dbg),
        .mem_wb_NPC_dbg   (pif0.mem_wb_NPC_dbg),
        .mem_wb_inst_dbg  (pif0.mem_wb_inst_dbg),
        .mem_wb_valid_dbg (pif0.mem_wb_valid_dbg),
        .ex_mem_packet_out(pif0.ex_mem_packet_out),
        .mem_wb_packet_out(pif0.mem_wb_packet_out)
    );

    pipeline_buggy core1 (
        // Inputs
        .clock             (pif1.clock),
        .reset             (pif1.reset),
        .mem2proc_response (pif1.mem2proc_response),
        .mem2proc_data     (pif1.mem2proc_data),
        .mem2proc_tag      (pif1.mem2proc_tag),

        // Outputs
        .proc2mem_command (pif1.proc2mem_command),
        .proc2mem_addr    (pif1.proc2mem_addr),
        .proc2mem_data    (pif1.proc2mem_data),
        .proc2mem_size    (pif1.proc2mem_size),

        .pipeline_completed_insts (pif1.pipeline_completed_insts),
        .pipeline_error_status    (pif1.pipeline_error_status),
        .pipeline_commit_wr_data  (pif1.pipeline_commit_wr_data),
        .pipeline_commit_wr_idx   (pif1.pipeline_commit_wr_idx),
        .pipeline_commit_wr_en    (pif1.pipeline_commit_wr_en),
        .pipeline_commit_NPC      (pif1.pipeline_commit_NPC),

        .if_NPC_dbg       (pif1.if_NPC_dbg),
        .if_inst_dbg      (pif1.if_inst_dbg),
        .if_valid_dbg     (pif1.if_valid_dbg),
        .if_id_NPC_dbg    (pif1.if_id_NPC_dbg),
        .if_id_inst_dbg   (pif1.if_id_inst_dbg),
        .if_id_valid_dbg  (pif1.if_id_valid_dbg),
        .id_ex_NPC_dbg    (pif1.id_ex_NPC_dbg),
        .id_ex_inst_dbg   (pif1.id_ex_inst_dbg),
        .id_ex_valid_dbg  (pif1.id_ex_valid_dbg),
        .ex_mem_NPC_dbg   (pif1.ex_mem_NPC_dbg),
        .ex_mem_inst_dbg  (pif1.ex_mem_inst_dbg),
        .ex_mem_valid_dbg (pif1.ex_mem_valid_dbg),
        .mem_wb_NPC_dbg   (pif1.mem_wb_NPC_dbg),
        .mem_wb_inst_dbg  (pif1.mem_wb_inst_dbg),
        .mem_wb_valid_dbg (pif1.mem_wb_valid_dbg),
        .ex_mem_packet_out(pif1.ex_mem_packet_out),
        .mem_wb_packet_out(pif1.mem_wb_packet_out)
    );


    // Instantiate the Data Memory
    mem memory0(
        // Inputs
        .clk              (pif0.clock),
        .proc2mem_command (pif0.proc2mem_command),
        .proc2mem_addr    (pif0.proc2mem_addr),
        .proc2mem_data    (pif0.proc2mem_data),
`ifndef CACHE_MODE
        .proc2mem_size    (pif0.proc2mem_size),
`endif

        // Outputs
        .mem2proc_response (pif0.mem2proc_response),
        .mem2proc_data     (pif0.mem2proc_data),
        .mem2proc_tag      (pif0.mem2proc_tag)
    );

     mem memory1(
        // Inputs
        .clk              (pif1.clock),
        .proc2mem_command (pif1.proc2mem_command),
        .proc2mem_addr    (pif1.proc2mem_addr),
        .proc2mem_data    (pif1.proc2mem_data),
`ifndef CACHE_MODE
        .proc2mem_size    (pif1.proc2mem_size),
`endif

        // Outputs
        .mem2proc_response (pif1.mem2proc_response),
        .mem2proc_data     (pif1.mem2proc_data),
        .mem2proc_tag      (pif1.mem2proc_tag)
    );

    QEDV2 #(.N(1)) qed (
        .clk(clock),
        .reset(reset),
        .packet1(pif0.mem_wb_packet_out),
        .packet2(pif1.mem_wb_packet_out),
        .fault(QED_fault)
    );


    logic [$clog2(QED_TRACE_FIFO_SIZE)-1:0] head1, head2;
    QEDTrace
    #(.FIFO_SIZE(QED_TRACE_FIFO_SIZE))
    qedtrace (
        .clk(clock),
        .reset(reset),
        .packet1(pif0.mem_wb_packet_out),
        .packet2(pif1.mem_wb_packet_out),
        .fault(QED_fault),
        .trace1(trace1),
        .trace2(trace2),
        .head1_out(head1),
        .head2_out(head2),
        .has_fault_occured(has_fault_occured)
        

    );


    // Generate System Clock
    always begin
        #(`CLOCK_PERIOD/2.0);
        clock = ~clock;
    end

    assign pif0.clock = clock;
    assign pif1.clock = clock;
    assign pif0.reset = reset;
    assign pif1.reset = reset;

    // Task to display # of elapsed clock edges
    task show_clk_count0;
        real cpi;
        begin
            
            cpi = (pif0.clock_count + 1.0) / pif0.instr_count;
            format_str = $sformatf("@@  %0d cycles / %0d instrs = %f CPI\n@@",
                      pif0.clock_count+1, pif0.instr_count, cpi);
            print_header(format_str, 0);

            format_str = $sformatf("@@  %4.2f ns total time to execute\n@@\n",
                      pif0.clock_count * `CLOCK_PERIOD);
            print_header(format_str, 0);
        end
    endtask // task show_clk_count

    task show_clk_count1;
        real cpi;
        begin
            
            cpi = (pif1.clock_count + 1.0) / pif1.instr_count;
            format_str = $sformatf("@@  %0d cycles / %0d instrs = %f CPI\n@@",
                      pif1.clock_count+1, pif1.instr_count, cpi);
            print_header(format_str, 1);

            format_str = $sformatf("@@  %4.2f ns total time to execute\n@@\n",
                      pif1.clock_count * `CLOCK_PERIOD);
            print_header(format_str, 1);
        end
    endtask // task show_clk_count


    // Show contents of a range of Unified Memory, in both hex and decimal
    task show_mem_with_decimal0;
        input [31:0] start_addr;
        input [31:0] end_addr;
        int showing_data;
        begin
            print_header("@@@", 0);
            showing_data=0;
            for(int k=start_addr;k<=end_addr; k=k+1)
                if (memory0.unified_memory[k] != 0) begin
                    format_str = $sformatf("@@@ mem[%5d] = %x : %0d", k*8, memory0.unified_memory[k],
                                                             memory0.unified_memory[k]);
                    print_header(format_str, 0);
                    showing_data=1;
                end else if(showing_data!=0) begin
                    print_header("@@@", 0);
                    showing_data=0;
                end
            print_header("@@@", 0);
        end
    endtask // task show_mem_with_decimal

     // Show contents of a range of Unified Memory, in both hex and decimal
    task show_mem_with_decimal1;
        input [31:0] start_addr;
        input [31:0] end_addr;
        int showing_data;
        begin
            print_header("@@@", 1);
            showing_data=0;
            for(int k=start_addr;k<=end_addr; k=k+1)
                if (memory1.unified_memory[k] != 0) begin
                    format_str = $sformatf("@@@ mem[%5d] = %x : %0d", k*8, memory1.unified_memory[k],
                                                            memory1.unified_memory[k]);
                    print_header(format_str, 1);
                    
                    showing_data=1;
                end else if(showing_data!=0) begin
                    print_header("@@@", 1);
                    showing_data=0;
                end
            print_header("@@@", 1);
        end
    endtask // task show_mem_with_decimal


    initial begin
        $assertoff;
        testPrint;
        //$dumpvars;
        // set paramterized strings, see comment at start of module
        if ($value$plusargs("MEMORY=%s", program_memory_file)) begin
            $display("Loading memory file: %s", program_memory_file);
        end else begin
            $display("Loading default memory file: program.mem");
            program_memory_file = "program.mem";
        end

        $display("Using default writeback output file: writeback.out");
        writeback_output_file0 = "output/writeback0.out";
        writeback_output_file1 = "output/writeback1.out";

        $display("Using default pipeline output file: pipeline.out");
        pipeline_output_file0 = "output/pipeline0.out";
        pipeline_output_file1= "output/pipeline1.out";

        clock = 1'b0;
        reset = 1'b0;

        // Pulse the reset signal
        $display("@@\n@@\n@@  %t  Asserting System reset......", $realtime);
        reset = 1'b1;
        @(posedge clock);
        @(posedge clock);

        // store the compiled program's hex data into memory
        $readmemh(program_memory_file, memory0.unified_memory);
        $readmemh(program_memory_file, memory1.unified_memory);

        @(posedge clock);
        @(posedge clock);
        #1;
        // This reset is at an odd time to avoid the pos & neg clock edges

        reset = 1'b0;
        $display("@@  %t  Deasserting System reset......\n@@\n@@", $realtime);

        wb_fileno0 = $fopen(writeback_output_file0);
        wb_fileno1 = $fopen(writeback_output_file1);

        // Open pipeline output file AFTER throwing the reset otherwise the reset state is displayed
        open_pipeline_output_file(pipeline_output_file0, pipeline_output_file1);
        print_header("                                                                            D-MEM Bus &\n", 1);
        print_header("Cycle:      IF      |     ID      |     EX      |     MEM     |     WB      Reg Result", 1);

        print_header("                                                                            D-MEM Bus &\n", 0);
        print_header("Cycle:      IF      |     ID      |     EX      |     MEM     |     WB      Reg Result", 0);
    end

    function string alu_func_to_string(INST inst);
            case (inst.r.opcode)
                ALU_ADD:     alu_func_to_string = "ALU_ADD";
                ALU_SUB:     alu_func_to_string = "ALU_SUB";
                ALU_SLT:     alu_func_to_string = "ALU_SLT";
                ALU_SLTU:    alu_func_to_string = "ALU_SLTU";
                ALU_AND:     alu_func_to_string = "ALU_AND";
                ALU_OR:      alu_func_to_string = "ALU_OR";
                ALU_XOR:     alu_func_to_string = "ALU_XOR";
                ALU_SLL:     alu_func_to_string = "ALU_SLL";
                ALU_SRL:     alu_func_to_string = "ALU_SRL";
                ALU_SRA:     alu_func_to_string = "ALU_SRA";
                ALU_MUL:     alu_func_to_string = "ALU_MUL";
                ALU_MULH:    alu_func_to_string = "ALU_MULH";
                ALU_MULHSU:  alu_func_to_string = "ALU_MULHSU";
                ALU_MULHU:   alu_func_to_string = "ALU_MULHU";
                ALU_DIV:     alu_func_to_string = "ALU_DIV";
                ALU_DIVU:    alu_func_to_string = "ALU_DIVU";
                ALU_REM:     alu_func_to_string = "ALU_REM";
                ALU_REMU:    alu_func_to_string = "ALU_REMU";
                default:     alu_func_to_string = "UNKNOWN";
            endcase
        endfunction
        logic [$clog2(QED_TRACE_FIFO_SIZE)-1:0] modHead1, modHead2;

        function print_trace;
            if(has_fault_occured) $display("Fault Detected!");
            else $display("Fault not detected!");

                //             int head1cast; 
                // int head2cast;
            // $display("%-50s %s", "FIFO1 contents:", "FIFO2 contents:");
            
            // logic [$clog2(QED_TRACE_FIFO_SIZE)-1:0] temp; 
            
            for (int i = 0; i < QED_TRACE_FIFO_SIZE; i++) begin


                // $cast(head1cast, head1);
                // $cast(head2cast, head2);
                // // temp = head2+i;
                // int modHead1;
                // modHead1 = (head1cast + i) % QED_TRACE_FIFO_SIZE;
                // int modHead2;
                // modHead2 = (head2cast + i) % QED_TRACE_FIFO_SIZE;
                modHead1 = head1+i;
                modHead2 = head2 +i;
                $display("FIFO1[%0d] = result:%h  %s FIFO2[%0d] = result:%h %s", modHead1, trace1[modHead1].result, alu_func_to_string(trace1[modHead1].inst), modHead2, trace2[modHead2].result , alu_func_to_string(trace1[modHead2].inst));
            end
        endfunction
        

    // Count the number of posedges and number of instructions completed
    // till simulation ends
    always @(posedge clock) begin
        if(reset) begin
            clock_count <= 0;
            instr_count <= 0;
        end else begin
            clock_count <= (clock_count + 1);
            instr_count <= (instr_count + pipeline_completed_insts);
        end
    end


    always @(negedge clock) begin
        if(reset) begin
            $display("@@\n@@  %t : System STILL at reset, can't show anything\n@@",
                     $realtime);
            pif0.debug_counter <= 0;
        end else begin
            #2;

            // print the pipeline debug outputs via c code to the pipeline output file
            // print_cycles();
            // print_stage(" ", if_inst_dbg,     if_NPC_dbg    [31:0], {31'b0,if_valid_dbg});
            // print_stage("|", if_id_inst_dbg,  if_id_NPC_dbg [31:0], {31'b0,if_id_valid_dbg});
            // print_stage("|", id_ex_inst_dbg,  id_ex_NPC_dbg [31:0], {31'b0,id_ex_valid_dbg});
            // print_stage("|", ex_mem_inst_dbg, ex_mem_NPC_dbg[31:0], {31'b0,ex_mem_valid_dbg});
            // print_stage("|", mem_wb_inst_dbg, mem_wb_NPC_dbg[31:0], {31'b0,mem_wb_valid_dbg});
            // print_reg(32'b0, pipeline_commit_wr_data[31:0],
            //     {27'b0,pipeline_commit_wr_idx}, {31'b0,pipeline_commit_wr_en});
            // print_membus({30'b0,proc2mem_command}, {28'b0,mem2proc_response},
            //     32'b0, proc2mem_addr[31:0],
            //     proc2mem_data[63:32], proc2mem_data[31:0]);

            // print register write information to the writeback output file
            if (pif0.pipeline_completed_insts > 0) begin
                if(pif0.pipeline_commit_wr_en)
                    $fdisplay(wb_fileno0, "PC=%x, REG[%d]=%x",
                              pif0.pipeline_commit_NPC - 4,
                              pif0.pipeline_commit_wr_idx,
                              pif0.pipeline_commit_wr_data);
                else
                    $fdisplay(wb_fileno0, "PC=%x, ---", pif0.pipeline_commit_NPC - 4);
            end


            // deal with any halting conditions
            if(pif0.pipeline_error_status != NO_ERROR || pif0.debug_counter >160000)begin
                $display("@@@ Unified Memory contents hex on left, decimal on right: ");
                show_mem_with_decimal0(0,`MEM_64BIT_LINES - 1);
                // 8Bytes per line, 16kB total

                $display("@@  %t : System halted\n@@", $realtime);

                case(pif0.pipeline_error_status)
                    LOAD_ACCESS_FAULT:
                        $display("@@@ System halted on memory error");
                    HALTED_ON_WFI:
                        $display("@@@ System halted on WFI instruction");
                    ILLEGAL_INST:
                        $display("@@@ System halted on illegal instruction");
                    default:
                        $display("@@@ System halted on unknown error code %x",
                            pif0.pipeline_error_status);
                endcase
                $display("@@@\n@@");
                show_clk_count0;
                print_close(); // close the pipe_print output file
                $fclose(wb_fileno0);
                #100 
                print_trace;
                $finish;
            end
            pif0.debug_counter <= pif0.debug_counter + 1;
        end // if(reset)
    end


    always @(negedge clock) begin
        if(reset) begin
            $display("@@\n@@  %t : System STILL at reset, can't show anything\n@@",
                     $realtime);
            pif1.debug_counter <= 0;
        end else begin
            #2;

            // print the pipeline debug outputs via c code to the pipeline output file
            // print_cycles();
            // print_stage(" ", if_inst_dbg,     if_NPC_dbg    [31:0], {31'b0,if_valid_dbg});
            // print_stage("|", if_id_inst_dbg,  if_id_NPC_dbg [31:0], {31'b0,if_id_valid_dbg});
            // print_stage("|", id_ex_inst_dbg,  id_ex_NPC_dbg [31:0], {31'b0,id_ex_valid_dbg});
            // print_stage("|", ex_mem_inst_dbg, ex_mem_NPC_dbg[31:0], {31'b0,ex_mem_valid_dbg});
            // print_stage("|", mem_wb_inst_dbg, mem_wb_NPC_dbg[31:0], {31'b0,mem_wb_valid_dbg});
            // print_reg(32'b0, pipeline_commit_wr_data[31:0],
            //     {27'b0,pipeline_commit_wr_idx}, {31'b0,pipeline_commit_wr_en});
            // print_membus({30'b0,proc2mem_command}, {28'b0,mem2proc_response},
            //     32'b0, proc2mem_addr[31:0],
            //     proc2mem_data[63:32], proc2mem_data[31:0]);

            // print register write information to the writeback output file
    

            if (pif1.pipeline_completed_insts > 0) begin
                if(pif1.pipeline_commit_wr_en)
                    $fdisplay(wb_fileno1, "PC=%x, REG[%d]=%x",
                              pif1.pipeline_commit_NPC - 4,
                              pif1.pipeline_commit_wr_idx,
                              pif1.pipeline_commit_wr_data);
                else
                    $fdisplay(wb_fileno1, "PC=%x, ---", pif1.pipeline_commit_NPC - 4);
            end

            // deal with any halting conditions
            if(pif1.pipeline_error_status != NO_ERROR || pif1.debug_counter >160000)begin
                $display("@@@ Unified Memory contents hex on left, decimal on right: ");
                show_mem_with_decimal1(0,`MEM_64BIT_LINES - 1);
                // 8Bytes per line, 16kB total

                $display("@@  %t : System halted\n@@", $realtime);

                case(pif1.pipeline_error_status)
                    LOAD_ACCESS_FAULT:
                        $display("@@@ System halted on memory error");
                    HALTED_ON_WFI:
                        $display("@@@ System halted on WFI instruction");
                    ILLEGAL_INST:
                        $display("@@@ System halted on illegal instruction");
                    default:
                        $display("@@@ System halted on unknown error code %x",
                            pif1.pipeline_error_status);
                endcase
                $display("@@@\n@@");
                show_clk_count1;
                print_close(); // close the pipe_print output file
                $fclose(wb_fileno1);
                #100 
                print_trace;
                $finish;
            end
            pif0.debug_counter <= pif1.debug_counter + 1;
        end // if(reset)
    end

endmodule // module testbench
