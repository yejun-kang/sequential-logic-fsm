#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vtraffic_light_fsm.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);
    Vtraffic_light_fsm* top = new Vtraffic_light_fsm;
    VerilatedVcdC* tfp = new VerilatedVcdC;

    top->trace(tfp, 99);
    tfp->open("wave_traffic.vcd");

    top->clk = 0;
    top->rst_n = 0;

    int sim_time = 0;

    for (int sim_step = 0; sim_step < 20; sim_step++) {
        top->clk = !top->clk;

        if(sim_step > 4) {
            top->rst_n = 1;
        }

        top->eval();

        tfp->dump(sim_time);
        sim_time += 5;

        std::cout << "Step: " << sim_step
                  << " | rst_n: " << (int)top->rst_n
                  << " | state: " << (int)top->state << std::endl;
    }

    tfp->close();
    top->final();

    delete top;
    return 0;
}
