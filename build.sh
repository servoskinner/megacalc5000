#!/bin/bash
iverilog top_sim1.v cpu.v memory.v peripheral.v rom_loader.v rom_reader.v -o build
