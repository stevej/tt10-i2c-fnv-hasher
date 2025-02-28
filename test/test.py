# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

#STATUS_ADDRESS = [0,1,1,1,0,0,1,0] # 0x72
STATUS_ADDRESS = [0,1,0,1,0,1,0,1] # Zero One periph
@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst_n.value = 1

    dut._log.info("Test project behavior")

    # SCL is bidir bit 2
    # SDA is bidir bit 3
    dut.uio_in.value = 0b0000_0100
    await ClockCycles(dut.clk, 1)
    dut.uio_in.value = 0b0000_0000
    await ClockCycles(dut.clk, 1)
    assert dut.uio_out.value == 0b0000_0000

    # Address is 0x72 to read how many entries are in the fifo
    for bit in STATUS_ADDRESS:
        dut.uio_in.value = (0b0000_0100 | (bit << 3))
        await ClockCycles(dut.clk, 1)
        dut.uio_in.value = 0b0000_0000
        await ClockCycles(dut.clk, 1)

    dut.uio_in.value = 0b0000_0100 # drive SCL high
    await ClockCycles(dut.clk, 1)
    dut.uio_in.value = 0b0000_0000 # drive SCL low

    assert dut.uio_out.value == 0b0000_1000


@cocotb.test()
async def test_start_condition(dut):
    dut._log.info("Start Condition")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1

    dut._log.info("Test project behavior")

    # One SCK clock cycle, two start changes
    dut.uio_out.value = 0b0000_0000
    dut.uio_in.value = 0b0000_1100
    await ClockCycles(dut.clk, 8)
    dut.uio_in.value = 0b0000_0100
    await ClockCycles(dut.clk, 8)
    dut.uio_in.value = 0b0000_1000
    await ClockCycles(dut.clk, 8)
    dut.uio_in.value = 0b0000_0000
    await ClockCycles(dut.clk, 8)

    # assert that the state machine is in start
    #assert dut.uo_out.value == 0b1000_000

    # Address is 0x72 to read how many entries are in the fifo
    for bit in STATUS_ADDRESS:
        dut.uio_in.value = (0b0000_0100 | (bit << 3))
        await ClockCycles(dut.clk, 1)
        dut.uio_in.value = 0b0000_0000
        await ClockCycles(dut.clk, 1)

    dut.uio_in.value = 0b0000_0100 # drive SCL high
    await ClockCycles(dut.clk, 1)
    dut.uio_in.value = 0b0000_0000 # drive SCL low





