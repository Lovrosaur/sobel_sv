module sobel_tb;
    sobel_test_runner test_runner ();

    initial begin
        $dumpfile("simulation.vcd");
        $dumpvars(0, sobel_tb);
    end
endmodule
