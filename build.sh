#!/bin/bash
iverilog top.v cpu.v memory.v peripheral.v static_loader.v rom_reader.v -o build
