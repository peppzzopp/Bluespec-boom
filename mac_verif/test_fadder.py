import os
import random
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

@cocotb.test()
async def test_fadder(dut):
    dut.EN_fpmac_result.value = 0
    clock = Clock(dut.CLK, 10, units="us")
    cocotb.start_soon(clock.start(start_high=False))
    dut.RST_N.value = 0
    await RisingEdge(dut.CLK)
    dut.RST_N.value = 1
    dut.EN_fpmac_result.value = 1
    dut.fpmac_result_a.value = 17280 
    dut.fpmac_result_b.value = 49856
    dut.fpmac_result_c.value = 0
    dut._log.info('output should be 3334471680')
    await RisingEdge(dut.CLK)
    dut._log.info( f'output{int(dut.fpmac_result.value)}')

    #11000110110000000000000000000000
    #11000101110000000000000000000000
    #11000101010000000000000000000000
