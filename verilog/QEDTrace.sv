module QEDTrace
#(
    parameter int FIFO_SIZE = 16 // Size of each FIFO
)(
    input  logic              clk,             // Clock signal
    input  logic              reset,           // Reset signal
    input  MEM_WB_PACKET      packet1,         // Input to FIFO1
    input  MEM_WB_PACKET      packet2,         // Input to FIFO2
    input  logic              fault,           // Fault signal
    output MEM_WB_PACKET  [FIFO_SIZE-1:0]    trace1 , // FIFO1 contents
    output MEM_WB_PACKET  [FIFO_SIZE-1:0]    trace2,   // FIFO2 contents
    output [$clog2(FIFO_SIZE)-1:0] head1_out, head2_out,
    output logic has_fault_occured,
    output int faultCounterDebug

);

    // FIFO1 signals
    logic [$clog2(FIFO_SIZE)-1:0] head1;
    MEM_WB_PACKET   [FIFO_SIZE-1:0]             fifo1 ; // Storage array for FIFO1

    int faultCounter;
    assign faultCounterDebug = faultCounter;
    

    // FIFO2 signals
    logic [$clog2(FIFO_SIZE)-1:0] head2;
    MEM_WB_PACKET    [FIFO_SIZE-1:0]            fifo2 ; // Storage array for FIFO2

    assign head1_out = head1;
    assign head2_out = head2;

    // Reset or initialize head/tail pointers and FIFOs
    always_ff @(posedge clk) begin
        if (reset) begin
            head1 <= 0;
            head2 <= 0;
            fifo1 <= 0;
            fifo2 <= 0;
            has_fault_occured <= 0;
            faultCounter <= 0;
        end
        else begin

            if (has_fault_occured) begin
                faultCounter <= faultCounter;
            end
            else begin
                faultCounter <= faultCounter + 1;
            end
            
            // FIFO1 Operation
            if(fault) begin
                has_fault_occured <= 1;
            end else begin
                has_fault_occured <= has_fault_occured;
            end

            if (!has_fault_occured) begin
                fifo1[head1] <= packet1;
                head1 <= (head1 == FIFO_SIZE-1) ? 0 : head1 + 1;
            end else begin
                head1 <= head1;
            end

            // FIFO2 Operation
            if (!has_fault_occured) begin
                fifo2[head2] <= packet2;
                head2 <= (head2 == FIFO_SIZE-1) ? 0 : head2 + 1;
            end else begin
                head2 <= head2;
            end

            // if (fault) begin
            //     // $display("Fault Detected!\n");
            //     // $display("FIFO1 contents:");
            //     // for (int i = 0; i < FIFO_SIZE; i++) begin
            //     //     $display("FIFO1[%0d] = %0h", i, fifo1[i]);
            //     // end

            //     // $display("\nFIFO2 contents:");
            //     // for (int i = 0; i < FIFO_SIZE; i++) begin
            //     //     $display("FIFO2[%0d] = %0h", i, fifo2[i]);
            //     // end
               
            // end

        end
    end

    // Assign full contents of FIFO to outputs
    assign trace1 = fifo1;
    assign trace2 = fifo2;

endmodule
