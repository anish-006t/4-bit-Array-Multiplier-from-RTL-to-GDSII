// Exhaustive, self-checking testbench for mult_array.
// Applies all 256 (a, b) combinations, waits the 2-cycle latency for each,
// and compares p against a * b.
`timescale 1ns / 1ps

module tb_mult;

    reg        clk;
    reg        rst_n;
    reg  [3:0] a;
    reg  [3:0] b;
    wire [7:0] p;

    reg  [7:0] expected;
    integer    i, j;
    integer    vectors;
    integer    errors;

    mult_array dut (
        .clk  (clk),
        .rst_n(rst_n),
        .a    (a),
        .b    (b),
        .p    (p)
    );

    // 10 ns clock period
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Waveform dump
    initial begin
        $dumpfile("mult.vcd");
        $dumpvars(0, tb_mult);
    end

    initial begin
        vectors = 0;
        errors  = 0;
        a       = 4'd0;
        b       = 4'd0;

        // Hold reset low for the first 2 clock cycles (0 ns to 20 ns)
        rst_n = 1'b0;
        repeat (2) @(negedge clk);
        rst_n = 1'b1;

        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                // Apply inputs on the falling edge so they are stable before the rising edge
                a = i;
                b = j;
                expected = i * j;

                // Edge 1: inputs captured; edge 2: product captured
                repeat (2) @(posedge clk);
                // Check half a cycle later, after the output register has settled
                @(negedge clk);

                vectors = vectors + 1;
                if (p !== expected) begin
                    errors = errors + 1;
                    $display("MISMATCH at %0d ns: a=%0d b=%0d  expected p=%0d  got p=%0d",
                             $time, a, b, expected, p);
                end
            end
        end

        if (errors == 0)
            $display("PASS: %0d vectors checked, %0d errors", vectors, errors);
        else
            $display("FAIL: %0d vectors checked, %0d errors", vectors, errors);

        $finish;
    end

endmodule
