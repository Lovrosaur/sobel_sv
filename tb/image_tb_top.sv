module image_tb_top;
    sobel_test_runner #(
        .DEFAULT_WIDTH(512),
        .DEFAULT_HEIGHT(512),
        .DEFAULT_IMG_FILE("vectors/image/rgb_image.mem"),
        .DEFAULT_EXPECTED_FILE("vectors/image/expected_gradient.mem"),
        .DEFAULT_OUTPUT_FILE("actual_gradients.mem")
    ) test_runner ();
endmodule
