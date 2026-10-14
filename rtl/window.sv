module sliding_window #(MAX_IMG_WIDTH = 4096) (
    input logic clock, rst_n,
    input logic [7:0] in_pixel,
    input logic input_valid,
    input logic[31:0] img_width,
    output logic output_valid,
    output logic [7:0] window [2:0][2:0]
);
    logic [7:0] buffer [MAX_IMG_WIDTH-4:0][1:0];
    logic [31:0] ptr, counter;

    always_ff @(posedge clock) begin
        if (!rst_n) begin
            ptr <= 0;
            counter <= 0;
            output_valid <= 0;
            foreach (window[i, j]) window[i][j] <= 0;
        end
        else begin 
            if (input_valid) begin
                window[0][0] <= window[0][1];
                window[0][1] <= window[0][2];
                window[0][2] <= buffer[ptr][1];
                window[1][0] <= window[1][1];
                window[1][1] <= window[1][2];
                window[1][2] <= buffer[ptr][0];
                window[2][0] <= window[2][1];
                window[2][1] <= window[2][2];
                window[2][2] <= in_pixel;

                buffer[ptr][0] <= window[2][0];
                buffer[ptr][1] <= window[1][0];

                if (ptr < img_width - 4) ptr <= ptr + 1;
                else ptr <= 0;

                if (counter < 2) output_valid <= 0;
                else output_valid <= 1;

                if (counter < img_width - 1) counter <= counter + 1;
                else counter <= 0;
            end
            else output_valid <= 0;
        end
        
    end

    logic [23:0] tmp;
    always_comb tmp = {window[0][0],window[0][1],window[0][2]};

endmodule