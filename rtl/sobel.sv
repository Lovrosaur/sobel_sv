module sobel #(parameter MAX_IMG_WIDTH = 4096)(
    input logic clock, rst_n,
    input logic input_valid,
    input logic [7:0] in_pixel,
    input logic [31:0] img_width,
    output logic [7:0] grad,
    output logic out_valid
);
    logic output_valid;
    logic [7:0] window [2:0][2:0];
    
    sliding_window #(.MAX_IMG_WIDTH(MAX_IMG_WIDTH)) sobel_window (
        .clock        (clock),
        .rst_n        (rst_n),
        .input_valid  (input_valid),
        .in_pixel     (in_pixel),
        .img_width    (img_width),
        .output_valid (output_valid),
        .window       (window)
    );
    logic [23:0] tmp;
    always_comb tmp = {window[0][0],window[0][1],window[0][2]};

    logic [9:0] gx1,gx2,gy1,gy2, gx, gy;
    logic [10:0] g;
    logic [32:0] cnt;
    always_ff @(posedge clock) begin
        if (!rst_n) begin
            out_valid <= 0;
            grad <= 0;
            cnt <= (img_width << 1) - 4;
        end
        else begin
            if (!output_valid) out_valid <= 0;
            else begin
                if (cnt > 0) begin
                    cnt <= cnt - 1;
                    out_valid <= 0;
                end
                else begin
                    out_valid <= output_valid;
                    if (g[10]) grad <= '1;
                    else grad <= g[9:2];
                end
            end
        end
    end
    always_comb begin
        gx1 = window[0][0] + (window[1][0]<<1) + window[2][0];
        gx2 = window[0][2] + (window[1][2]<<1) + window[2][2];
        gy1 = window[0][0] + (window[0][1]<<1) + window[0][2];
        gy2 = window[2][0] + (window[2][1]<<1) + window[2][2];
        if (gx2 > gx1) gx = gx2 - gx1;
        else gx = gx1 - gx2;
        if (gy2 > gy1) gy = gy2 - gy1;
        else gy = gy1 - gy2;
    end
    always_comb g = gx + gy;

endmodule
