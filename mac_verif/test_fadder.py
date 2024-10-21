import os
import random
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

@cocotb.test()
async def test_fadder(dut):
    dut.EN_fulladder_result.value = 0
    clock = Clock(dut.CLK, 10, units="us")
    cocotb.start_soon(clock.start(start_high=False))
    dut.RST_N.value = 0
    await RisingEdge(dut.CLK)
    dut.RST_N.value = 1
    dut.EN_fulladder_result.value = 1
    dut.fulladder_result_a.value = 0
    dut.fulladder_result_b.value = 0
    dut.fulladder_result_c.value = 0
    dut._log.info('all zeros')
    await RisingEdge(dut.CLK)
    dut._log.info( f'output{int(dut.fulladder_result.value)}')
    
    dut.fulladder_result_a.value = 0
    dut.fulladder_result_b.value = 0
    dut.fulladder_result_c.value = 1
    dut._log.info('one one')
    await RisingEdge(dut.CLK)
    dut._log.info( f'output{int(dut.fulladder_result.value)}')
    
    dut.fulladder_result_a.value = 1
    dut.fulladder_result_b.value = 0
    dut.fulladder_result_c.value = 1
    dut._log.info('two ones')
    await RisingEdge(dut.CLK)
    dut._log.info( f'output{int(dut.fulladder_result.value)}')

    dut.fulladder_result_a.value = 1
    dut.fulladder_result_b.value = 1
    dut.fulladder_result_c.value = 1
    dut._log.info('all ones')
    await RisingEdge(dut.CLK)
    dut._log.info( f'output{int(dut.fulladder_result.value)}')

    dut.fulladder_result_a.value = 125
    dut.fulladder_result_b.value = 17
    dut.fulladder_result_c.value = 1
    dut._log.info('125 + 17 + 1')
    await RisingEdge(dut.CLK)
    dut._log.info( f'output{int(dut.fulladder_result.value)}')

