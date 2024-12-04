`include "verilog/sys_defs.svh"

module QEDV2 #(
    parameter int FIFO_DEPTH = 16,      // Depth of the FIFO
    parameter int N = 2               // Add to FIFO every Nth clock cycle
)(
    input logic clk,
    input logic reset,
    input MEM_WB_PACKET packet1,
    input MEM_WB_PACKET packet2,
    output logic fault
);


    MEM_WB_PACKET fifo_mem1 [FIFO_DEPTH-1:0];
    MEM_WB_PACKET fifo_mem2 [FIFO_DEPTH-1:0];


    logic [$clog2(FIFO_DEPTH)-1:0] head1, tail1, head2, tail2;
    logic [$clog2(FIFO_DEPTH):0] count1, count2;
    logic [$clog2(N)-1:0] cycle_count1, cycle_count2;
    
    MEM_WB_PACKET head_packet1;
    MEM_WB_PACKET head_packet2;

    

    // File descriptor for logging
    int log_file;
    
    // Open the debug file during initialization
    initial begin
        log_file = $fopen("output/QED_log.txt", "w");
        $display("QED Debug File Opened");
        if (log_file == 0) begin
            $fatal(1, "Error: Unable to open QED_log.txt for writing!");
        end
        $fdisplay(log_file, "===== QED Debug =====");
    end
    
    assign head_packet1 = fifo_mem1[head1];
    assign head_packet2 = fifo_mem2[head2];

    // always_ff @(posedge clk) begin
    //     if(reset) begin
    //         cycle_count <= 0;
    //     end else begin
    //         cycle_count <= cycle_count +1;
    //     end
    // end


    always_ff @(posedge clk) begin
        if(reset)begin
            // Reset FIFO pointers and counts
            head1 <= 0; tail1 <= 0; count1 <= 0;
            head2 <= 0; tail2 <= 0; count2 <= 0;
            fault <= 0;

            cycle_count1 <= 0;
            cycle_count2 <= 0;
            $fdisplay(log_file, "Reset triggered at time %0t", $time);
        end
        else begin
            
            // if (packet1.valid && count1 < FIFO_DEPTH && cycle_count==N-1) begin
            if (packet1.valid && count1 < FIFO_DEPTH) begin
                if(cycle_count1 == N-1) begin
                    fifo_mem1[tail1] <= packet1;
                    $fdisplay(log_file, "Time %0t: Enqueued packet1 to FIFO1 at index %0d", $time, tail1);
                    $fdisplay(log_file, "  packet1: result=%h, NPC=%h, valid=%b", 
                                packet1.result, packet1.NPC, packet1.valid);
                    tail1 <= (tail1 + 1);
                    count1 <= count1 + 1;
                end
                if (N==1) begin
                    cycle_count1 <= 0;
                end
                else begin
                    cycle_count1 <= cycle_count1 + 1;
                end
            end else if (!packet1.valid) begin
                $fdisplay(log_file, "Time %0t: packet1 is invalid. Not enqueued to FIFO1.", $time);
            end else begin
                $fdisplay(log_file, "Time %0t: FIFO1 is full. packet1 not enqueued.", $time);
            end

            // if (packet2.valid && count2 < FIFO_DEPTH && cycle_count==N-1) begin
            if (packet2.valid && count2 < FIFO_DEPTH) begin         
                if(cycle_count2 == N-1) begin       
                    fifo_mem2[tail2] <= packet2;
                    $fdisplay(log_file, "Time %0t: Enqueued packet1 to FIFO2 at index %0d", $time, tail2);
                    $fdisplay(log_file, "  packet2: result=%h, NPC=%h, valid=%b", 
                                packet2.result, packet2.NPC, packet2.valid);
                    tail2 <= (tail2 + 1);
                    count2 <= count2 + 1;
                end
                if (N==1) begin
                    cycle_count2 <= 0;
                end
                else begin
                    cycle_count2 <= cycle_count2 + 1;
                end
            end else if (!packet2.valid) begin
                $fdisplay(log_file, "Time %0t: packet2 is invalid. Not enqueued to FIFO2.", $time);
            end else begin
                $fdisplay(log_file, "Time %0t: FIFO2 is full. packet1 not enqueued.", $time);
            end

            if (count1 > 0 && count2 > 0) begin

                $fdisplay(log_file, "Time %0t: Comparing FIFO1 head with FIFO2 head", $time);
                $fdisplay(log_file, "  FIFO1 head: result=%h, NPC=%h, valid=%b", 
                            head_packet1.result, head_packet1.NPC, head_packet1.valid);
                $fdisplay(log_file, "  FIFO2 head: result=%h, NPC=%h, valid=%b", 
                            head_packet2.result, head_packet2.NPC, head_packet2.valid);

                if (head_packet1.result != head_packet2.result) begin
                    fault <= 1; // Fault if packets differ
                    $fdisplay(log_file, "  Fault detected at time %0t: Packets differ!", $time);
                end else begin
                    fault <= 0; // Clear fault
                    $fdisplay(log_file, "  Packets match at time %0t", $time);
                end
                
                // Dequeue from both FIFOs
                head1 <= (head1 + 1);
                count1 <= count1 - 1;
                
                head2 <= (head2 + 1);
                count2 <= count2 - 1;
            end
            
        end
    end


    


endmodule