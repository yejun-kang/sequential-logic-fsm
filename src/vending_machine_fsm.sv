module vending_machine_fsm (
    input logic clk,
    input logic rst_n,
    input logic [2:0] nickel_count,
    input logic [2:0] dime_count,
    input logic [2:0] quarter_count,
    output logic dispense_item,
    output logic [7:0] change,
    output logic [1:0] state
);

    typedef enum logic [1:0] {
        IDLE      = 2'b00,
        COIN      = 2'b01,
        ITEM      = 2'b10,
        CHANGE    = 2'b11
    } state_t;

    state_t current_state, next_state;

    logic sufficient;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    always_comb begin
        sufficient = 0;
        change = 0;
        case (current_state)
            IDLE: begin
                if (nickel_count > 0 || dime_count > 0 || quarter_count > 0)
                    next_state = COIN;
                else
                    next_state = IDLE;
            end
            COIN: begin
                if ((nickel_count)*5 + (dime_count)*10 + (quarter_count)*25 >= 30)
                    next_state = ITEM;
                else
                    next_state = CHANGE;
            end
            ITEM: begin
                sufficient = 1;
                next_state = CHANGE;
            end
            CHANGE: begin
                if (sufficient)
                    change = (nickel_count)*5 + (dime_count)*10 + (quarter_count)*25 - 30;
                else
                    change = (nickel_count)*5 + (dime_count)*10 + (quarter_count)*25;
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    assign dispense_item = (sufficient == 1);
    assign state = current_state;

endmodule
