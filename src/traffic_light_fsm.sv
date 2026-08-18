module traffic_light_fsm (
    input logic clk,
    input logic rst_n,
    output logic [1:0] state
);

    typedef enum logic [1:0] {
        RED    = 2'b00,
        GREEN  = 2'b01,
        YELLOW = 2'b10,
        LEFT   = 2'b11
    } state_t;

    state_t current_state, next_state;

    // State transition logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= RED;
        else
            current_state <= next_state;
    end

    // Next state logic
    always_comb begin
        case (current_state)
            RED:    next_state = LEFT;
            GREEN:  next_state = YELLOW;
            YELLOW: next_state = RED;
            LEFT:   next_state = GREEN;
            default: next_state = RED;
        endcase
    end

    // Output assignment
    assign state = current_state;

endmodule
