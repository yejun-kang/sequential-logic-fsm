#include <iostream>
#include <iomanip>
#include <cassert>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vvending_machine_fsm.h"

struct TestCase {
    int nickels;
    int dimes;
    int quarters;
    const char* description;
};

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);
    Vvending_machine_fsm* top = new Vvending_machine_fsm;
    VerilatedVcdC* tfp = new VerilatedVcdC;

    top->trace(tfp, 99);
    tfp->open("wave_vending.vcd");

    int sim_time = 0;

    auto tick = [&]() {
        top->eval();
        tfp->dump(sim_time);
        sim_time += 5;
    };

    TestCase test_suite[] = {
        {0, 0, 0, "TEST 1: Zero Money (Expect Stay IDLE)"},
        {1, 0, 0, "TEST 2: 5 Cents - Insufficient (Expect Refund/No Item)"},
        {0, 0, 1, "TEST 3: 25 Cents - Insufficient (Expect Refund/No Item)"},
        {1, 0, 1, "TEST 4: 30 Cents - Exact Amount (Expect Item, 0 Change)"},
        {2, 2, 0, "TEST 5: 30 Cents - Multi-coin (2 Nickels + 2 Dimes)"},
        {0, 0, 2, "TEST 6: 50 Cents - Overpaid (Expect Item, 20c Change)"},
        {1, 1, 1, "TEST 7: 40 Cents - Overpaid (1 Nickel + 1 Dime + 1 Quarter -> 10c Change)"},
        {3, 3, 3, "TEST 8: 120 Cents - Large Overpayment (Expect Item, 90c Change)"}
    };

    std::cout << "===============================================================" << std::endl;
    std::cout << "   RUNNING VENDING MACHINE FSM TEST SUITE (8 TEST CASES)       " << std::endl;
    std::cout << "===============================================================" << std::endl;

    top->clk = 0;
    top->rst_n = 0;
    top->nickel_count = 0;
    top->dime_count = 0;
    top->quarter_count = 0;
    tick();

    top->clk = 1; tick();
    top->clk = 0; top->rst_n = 1; tick();

    for (int i = 0; i < 8; i++) {
        const auto& test = test_suite[i];

        std::cout << "\n---------------------------------------------------------------" << std::endl;
        std::cout << test.description << std::endl;
        std::cout << "Inputs -> Nickels: " << test.nickels 
                  << " | Dimes: " << test.dimes 
                  << " | Quarters: " << test.quarters 
                  << " | Total: " << (test.nickels*5 + test.dimes*10 + test.quarters*25) << "c" 
                  << std::endl;

        top->clk = 0;
        top->nickel_count  = test.nickels;
        top->dime_count    = test.dimes;
        top->quarter_count = test.quarters;
        tick();

        for (int cycle = 0; cycle < 3; cycle++) {
            top->clk = 1; tick();

            std::cout << "  [Cycle " << cycle << "] State: " << (int)top->state
                      << " | Dispense: " << (int)top->dispense_item
                      << " | Change: " << (int)top->change << "c"
                      << std::endl;

            top->clk = 0; tick();
        }

        top->clk = 0;
        top->nickel_count  = 0;
        top->dime_count    = 0;
        top->quarter_count = 0;
        tick();
        
        top->clk = 1; tick();
        top->clk = 0; tick();
    }

    std::cout << "\n===============================================================" << std::endl;
    std::cout << "               ALL TEST CASES EXECUTED                         " << std::endl;
    std::cout << "===============================================================" << std::endl;

    // Cleanup
    tfp->close();
    delete tfp;
    delete top;
    return 0;
}
