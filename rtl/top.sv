module top #(parameter MAX_IMG_WIDTH = 4096) (
    input  logic             clock,
    input  logic             rst_n,
    input  logic             input_valid,
    input  logic [2:0][7:0]  rgb_in,
    input  logic [31:0]      img_width,
    output logic [7:0]       grad_out,
    output logic             out_valid
);

    logic [7:0] gray_pixel;
    logic       gray_valid;

    rgb_to_gray u_rgb_to_gray (
        .clock(clock),
        .rst_n(rst_n),
        .input_valid(input_valid),
        .rgb(rgb_in),
        .gray(gray_pixel),
        .output_valid(gray_valid)
    );

    sobel #(.MAX_IMG_WIDTH(MAX_IMG_WIDTH)) u_sobel (
        .clock(clock),
        .rst_n(rst_n),
        .input_valid(gray_valid),
        .in_pixel(gray_pixel),
        .img_width(img_width),
        .grad(grad_out),
        .out_valid(out_valid)
    );

endmodule