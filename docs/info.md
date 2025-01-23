<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

Listening on address 0xFF is an i2c receiver that will take the incoming 32-bit value and add it to a running FNV-1a hash. async fifo queues are used for both the read and write sides.

## How to test

At address 0xFF, send a write request with a 32-bit value. For each 32-bit word you send, it'll be added to a running fnv-1a hash. When requesting a read from that address, you'll see the hashed value. If you want to reset the hash, reset the whole chip.

Attached is an arduino sketch that will send data and check that the correct value is returned. Tested on an Arduino Uno.

## External hardware

Something that speaks i2c is required to use this device.