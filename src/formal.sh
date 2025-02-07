#!/bin/bash

set -ex

sby -f formal.sby -t bmc
sby -f formal.sby -t prove
sby -f formal.sby -t cover
