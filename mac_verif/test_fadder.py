import os
import random
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

@cocotb.test()
async def test_fadder(dut):
    dut.EN_intmac_result.value = 0
    clock = Clock(dut.CLK, 10, units="us")
    cocotb.start_soon(clock.start(start_high=False))
    dut.RST_N.value = 0
    await RisingEdge(dut.CLK)
    dut.RST_N.value = 1
    dut.EN_intmac_result.value = 1
    dut.intmac_result_a.value = 0
    dut.intmac_result_b.value = 0
    dut.intmac_result_c.value = 0
    dut._log.info('all zeros')
    await RisingEdge(dut.CLK)
    dut._log.info( f'output{int(dut.intmac_result.value)}')
    
    dut.intmac_result_a.value = 1
    dut.intmac_result_b.value = 0
    dut.intmac_result_c.value = 5
    dut._log.info('a = 1, b = 0, c = 5')
    await RisingEdge(dut.CLK)
    dut._log.info( f'output{int(dut.intmac_result.value)}')
    
    dut.intmac_result_a.value = 1
    dut.intmac_result_b.value = 1
    dut.intmac_result_c.value = 5
    dut._log.info('a = 1, b = 1, c = 5')
    await RisingEdge(dut.CLK)
    dut._log.info( f'output{int(dut.intmac_result.value)}')

    dut.intmac_result_a.value = 5
    dut.intmac_result_b.value = 8
    dut.intmac_result_c.value = 40
    dut._log.info('a = 5, b = 8, c = 40')
    await RisingEdge(dut.CLK)
    dut._log.info( f'output{int(dut.intmac_result.value)}')
    
    dut.intmac_result_a.value = 5
    dut.intmac_result_b.value = -8
    dut.intmac_result_c.value = 40
    dut._log.info('a = 5, b = -8, c = 40')
    await RisingEdge(dut.CLK)
    dut._log.info( f'output{int(dut.intmac_result.value)}')

    dut.intmac_result_a.value = -5
    dut.intmac_result_b.value = 8
    dut.intmac_result_c.value = 80
    dut._log.info('a = -5, b = 8, c = 80')
    await RisingEdge(dut.CLK)
    dut._log.info( f'output{int(dut.intmac_result.value)}')
    
    dut.intmac_result_a.value = -5
    dut.intmac_result_b.value = -8
    dut.intmac_result_c.value = -80
    dut._log.info('a = -5, b = -8, c = -80')
    await RisingEdge(dut.CLK)
    dut._log.info( f'output{int(dut.intmac_result.value)}')
    
    dut.intmac_result_a.value = -5
    dut.intmac_result_b.value = -8
    dut.intmac_result_c.value = -40
    dut._log.info('a = -5, b = -8, c = -40')
    await RisingEdge(dut.CLK)
    dut._log.info( f'output{int(dut.intmac_result.value)}')

