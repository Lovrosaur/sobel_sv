// Partially created using LLM ai
`timescale 1ns/1ps

module sobel_test_runner #(
    parameter int unsigned MAX_IMG_WIDTH = 4096,
    parameter int unsigned MAX_PIXELS = 4_194_304,
    parameter int unsigned DEFAULT_WIDTH = 4,
    parameter int unsigned DEFAULT_HEIGHT = 4,
    parameter string DEFAULT_IMG_FILE = "vectors/dummy/rgb_image.mem",
    parameter string DEFAULT_EXPECTED_FILE = "vectors/dummy/expected_gradient.mem",
    parameter string DEFAULT_OUTPUT_FILE = "actual_gradients.mem"
);
    logic clock = 1'b0;
    logic rst_n;
    logic input_valid;
    logic [2:0][7:0] rgb_in;
    logic [31:0] img_width;
    logic [7:0] grad_out;
    logic out_valid;

    logic [23:0] rgb_mem [0:MAX_PIXELS-1];
    logic [7:0] expected_mem [0:MAX_PIXELS-1];

    string image_file;
    string expected_file;
    string output_file;
    int unsigned image_width;
    int unsigned image_height;
    int unsigned pixel_count;
    int unsigned expected_count;

    integer output_handle;
    integer cycle_count;
    integer frame_start_cycle;
    integer observed_input_count;
    integer observed_gradient_count;
    bit frame_started;

    always #5 clock = ~clock;

    top #(.MAX_IMG_WIDTH(MAX_IMG_WIDTH)) dut (
        .clock       (clock),
        .rst_n       (rst_n),
        .input_valid (input_valid),
        .rgb_in      (rgb_in),
        .img_width   (img_width),
        .grad_out    (grad_out),
        .out_valid   (out_valid)
    );

    always @(posedge clock) begin
        #1ps;

        if (rst_n !== 1) begin
            cycle_count             = 0;
            frame_start_cycle       = 0;
            frame_started           = 0;
            observed_input_count    = 0;
            observed_gradient_count = 0;
        end else begin
            if (input_valid) begin
                if (!frame_started) begin
                    frame_started     = 1;
                    frame_start_cycle = cycle_count;
                end
                observed_input_count = observed_input_count + 1;
            end

            begin : check_this_cycle
                bit expected_valid;
                integer pixel_index;
                integer pixel_row;
                integer pixel_column;

                expected_valid = 1'b0;
                pixel_index = -1;
                pixel_row = 0;
                pixel_column = 0;

                if (frame_started && (cycle_count >= frame_start_cycle + 2)) begin
                    pixel_index = cycle_count - frame_start_cycle - 2;
                    if (pixel_index < pixel_count) begin
                        pixel_row = pixel_index / image_width;
                        pixel_column = pixel_index % image_width;
                        if ((pixel_row >= 2) && (pixel_column >= 2))
                            expected_valid = 1'b1;
                    end
                end

                if (out_valid === 1) begin
                    $fdisplay(output_handle, "%02h", grad_out);
                    $fflush(output_handle);
                end

                if (out_valid !== expected_valid) begin
                    $fatal(1,
                        "out_valid mismatch at cycle %0d: got %b, expected %b",
                        cycle_count, out_valid, expected_valid);
                end

                if (expected_valid) begin
                    if (observed_gradient_count >= expected_count) begin
                        $fatal(1, "Unexpected extra valid gradient at cycle %0d", cycle_count);
                    end

                    if (grad_out !== expected_mem[observed_gradient_count]) begin
                        $fatal(1,
                            "Gradient %0d mismatch: got 0x%02h, expected 0x%02h, grad count:%05h",
                            observed_gradient_count, grad_out,
                            expected_mem[observed_gradient_count], observed_gradient_count);
                    end
                    observed_gradient_count = observed_gradient_count + 1;
                end
            end

            cycle_count = cycle_count + 1;
        end
    end

    initial begin
        image_file = DEFAULT_IMG_FILE;
        expected_file = DEFAULT_EXPECTED_FILE;
        output_file = DEFAULT_OUTPUT_FILE;
        image_width = DEFAULT_WIDTH;
        image_height = DEFAULT_HEIGHT;

        if ((image_width == 0) || (image_height == 0))
            $fatal(1, "Image width and height must be greater than zero");

        if ((image_width > MAX_IMG_WIDTH) || (image_width > MAX_PIXELS) ||
            (image_height > MAX_PIXELS / image_width)) begin
            $fatal(1, "Image dimensions %0dx%0d exceed the testbench limits",
                   image_width, image_height);
        end

        pixel_count = image_width * image_height;
        if ((image_width >= 3) && (image_height >= 3))
            expected_count = (image_width - 2) * (image_height - 2);
        else
            expected_count = 0;

        output_handle = $fopen(output_file, "w");
        if (output_handle == 0)
            $fatal(1, "Could not open gradient output file: %s", output_file);

        $readmemh(image_file, rgb_mem, 0, pixel_count - 1);
        if (expected_count > 0)
            $readmemh(expected_file, expected_mem, 0, expected_count - 1);

        img_width = image_width;
        rst_n = 0;
        input_valid = 0;
        rgb_in = 0;
        cycle_count = 0;
        frame_start_cycle = 0;
        frame_started = 0;
        observed_input_count = 0;
        observed_gradient_count = 0;

        repeat (5) @(negedge clock);
        rst_n = 1;

        for (integer pixel = 0; pixel < pixel_count; pixel = pixel + 1) begin
            @(negedge clock);
            rgb_in = rgb_mem[pixel];
            input_valid = 1;
        end

        @(negedge clock);
        input_valid = 0;
        rgb_in = 0;

        repeat (6) @(negedge clock);
        #2ps;

        if (observed_input_count != pixel_count) begin
            $fatal(1, "Saw %0d input pixels, expected %0d",
                   observed_input_count, pixel_count);
        end

        if (observed_gradient_count != expected_count) begin
            $fatal(1, "Saw %0d gradients, expected %0d",
                   observed_gradient_count, expected_count);
        end

        $fclose(output_handle);
        $display("PASS: %0dx%0d image, %0d gradients checked.",
                 image_width, image_height, observed_gradient_count);
        $finish;
    end
endmodule
