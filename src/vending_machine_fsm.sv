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

    logic [7:0] total;
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
        total = (nickel_count)*5 + (dime_count)*10 + (quarter_count)*25;
        case (current_state)
            IDLE: begin
                if (nickel_count > 0 || dime_count > 0 || quarter_count > 0)
                    next_state = COIN;
                else
                    next_state = IDLE;
            end
            COIN: begin
                if (total >= 30)
                    next_state = ITEM;
                else
                    next_state = CHANGE;
            end
            ITEM: begin
                sufficient = 1;
                next_state = CHANGE;
            end
            CHANGE: begin
                if (total >= 30)
                    change = total - 8'd30;
                else
                    change = total;
                next_state = IDLE;
                total = 0;
            end
            default: next_state = IDLE;
        endcase
    end

    assign dispense_item = (sufficient == 1);
    assign state = current_state;

    // =========================================================================
    // SYSTEMVERILOG ASSERTIONS (SVA)
    // =========================================================================
    
    always_comb begin
        assert final (state == current_state)
            else $error("SVA Violation: Output state signal does not match internal current_state!");
    end

    property p_item_dispense_check;
        @(posedge clk) disable iff (!rst_n)
        (current_state == ITEM) |-> (dispense_item == 1'b1);
    endproperty
    a_item_dispense_check: assert property (p_item_dispense_check)
        else $error("SVA Violation: Item was not dispensed during ITEM state!");

    property p_idle_no_dispense;
        @(posedge clk) disable iff (!rst_n)
        (current_state == IDLE) |-> (dispense_item == 1'b0);
    endproperty
    a_idle_no_dispense: assert property (p_idle_no_dispense)
        else $error("SVA Violation: Item dispensed while in IDLE state!");

    property p_reset_to_idle;
        @(posedge clk) !rst_n |-> (current_state == IDLE);
    endproperty
    a_reset_to_idle: assert property (p_reset_to_idle)
        else $error("SVA Violation: FSM failed to enter IDLE on reset!");

    property p_coin_to_item_sufficient;
        @(posedge clk) disable iff (!rst_n)
        (current_state == COIN && ((nickel_count * 5 + dime_count * 10 + quarter_count * 25) >= 30)) 
        |=> (current_state == ITEM);
    endproperty
    a_coin_to_item_sufficient: assert property (p_coin_to_item_sufficient)
        else $error("SVA Violation: FSM failed to transition COIN -> ITEM with >= 30 cents!");

    property p_coin_to_change_insufficient;
        @(posedge clk) disable iff (!rst_n)
        (current_state == COIN && ((nickel_count * 5 + dime_count * 10 + quarter_count * 25) < 30)) 
        |=> (current_state == CHANGE);
    endproperty
    a_coin_to_change_insufficient: assert property (p_coin_to_change_insufficient)
        else $error("SVA Violation: FSM failed to transition COIN -> CHANGE on insufficient funds!");

    property p_item_to_change;
        @(posedge clk) disable iff (!rst_n)
        (current_state == ITEM) |=> (current_state == CHANGE);
    endproperty
    a_item_to_change: assert property (p_item_to_change)
        else $error("SVA Violation: FSM did not transition ITEM -> CHANGE!");

    property p_change_to_idle;
        @(posedge clk) disable iff (!rst_n)
        (current_state == CHANGE) |=> (current_state == IDLE);
    endproperty
    a_change_to_idle: assert property (p_change_to_idle)
        else $error("SVA Violation: FSM did not transition CHANGE -> IDLE!");

endmodule

