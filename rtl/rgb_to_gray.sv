module rgb_to_gray (
    input logic clock, rst_n,
    input logic input_valid,
    input logic [2:0][7:0] rgb,
    output logic [7:0] gray,
    output logic output_valid
);
    logic [15:0] sum;

    assign sum = (77 * rgb[2]) + (150 * rgb[1]) + (29 * rgb[0]);

    always_ff @(posedge clock ) begin
        if (!rst_n) begin
            output_valid <= 0;
            gray <= 0;
        end
        else begin
            output_valid <= input_valid;
            gray <= sum[15:8];
        end
    end
endmodule