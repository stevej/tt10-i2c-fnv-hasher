#!/bin/bash

set -oex

iverilog -g2012 -I ../src/async_fifo -I ../src -o tt08_top_tb -s tb_i2c tb_i2c.sv ../src/*.sv ../src/*.v ../src/async_fifo/*.v
vvp tt08_top_tb
