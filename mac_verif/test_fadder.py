import os
import random
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

@cocotb.test()
async def test_fadder(dut):
    dut.EN_mul_result.value = 0
    clock = Clock(dut.CLK, 10, units="us")
    cocotb.start_soon(clock.start(start_high=False))
    dut.RST_N.value = 0
    await RisingEdge(dut.CLK)
    dut.RST_N.value = 1
    dut.EN_mul_result.value = 1
    dut.mul_result_a.value = 0
    dut.mul_result_b.value = 0
    dut._log.info('all zeros')
    await RisingEdge(dut.CLK)
    dut._log.info( f'output{int(dut.mul_result.value)}')
    
    dut.mul_result_a.value = 1
    dut.mul_result_b.value = 0
    dut._log.info('one one')
    await RisingEdge(dut.CLK)
    dut._log.info( f'output{int(dut.mul_result.value)}')
    
    dut.mul_result_a.value = 1
    dut.mul_result_b.value = 1
    dut._log.info('two ones')
    await RisingEdge(dut.CLK)
    dut._log.info( f'output{int(dut.mul_result.value)}')

    dut.mul_result_a.value = 5
    dut.mul_result_b.value = 8
    dut._log.info('5 * 8')
    await RisingEdge(dut.CLK)
    dut._log.info( f'output{int(dut.mul_result.value)}')
    
    dut.mul_result_a.value = -5
    dut.mul_result_b.value = 8
    dut._log.info('- 5 * 8')
    await RisingEdge(dut.CLK)
    dut._log.info( f'output{int(dut.mul_result.value)}')

    dut.mul_result_a.value = 32767 
    dut.mul_result_b.value = 32767 
    dut._log.info('highest edge case - both = 32767')
    await RisingEdge(dut.CLK)
    dut._log.info( f'output{int(dut.mul_result.value)}')

