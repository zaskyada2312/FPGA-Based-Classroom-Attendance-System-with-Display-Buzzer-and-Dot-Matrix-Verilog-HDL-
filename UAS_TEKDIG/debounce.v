// ============================================================
// File   : debounce.v
// Fungsi : Menghilangkan bouncing pada push button
// ============================================================

module debounce #(
    parameter CLK_FREQ = 50000000,
    parameter DEBOUNCE_MS = 20
)(
    input  wire clk,
    input  wire rst_n,
    input  wire button_in,
    output reg  button_out
);

    localparam integer COUNT_MAX = (CLK_FREQ / 1000) * DEBOUNCE_MS;

    reg [31:0] counter;
    reg sync_0;
    reg sync_1;
    reg stable_state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_0 <= 1'b0;
            sync_1 <= 1'b0;
        end else begin
            sync_0 <= button_in;
            sync_1 <= sync_0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 32'd0;
            stable_state <= 1'b0;
            button_out <= 1'b0;
        end else begin
            if (sync_1 != stable_state) begin
                if (counter < COUNT_MAX) begin
                    counter <= counter + 1'b1;
                end else begin
                    stable_state <= sync_1;
                    button_out <= sync_1;
                    counter <= 32'd0;
                end
            end else begin
                counter <= 32'd0;
            end
        end
    end

endmodule
