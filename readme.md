# MEGACALC 5000
## About
this is a primitive 16 bit microprocessor model with following features:
- two equivalent general-purpose registers: ```LEFT``` and ```RIGHT```
- independent memory interface
- stack and subroutine call support
- half-assed pointer logic support

## Assembling and running programs
You can translate assembly code to binary using ```assembler.py```. Build the simulation with ```iverilog``` by
running ```build.sh```, move the assembled program to the same directory as the binary and make sure the filename is set to ```program.txt```.
Then run the binary and inspect the dump file by running ```gtkwave dump.vcd```.

There are two helper modules: ```rom_loader``` is the first to start when simulation begins; it copies the contents of ```program.txt``` to
RAM and sets unused words to zero. ```ram_reader``` scans all memory cells when the CPU has finished working so they can be viewed in the dump file.

Display the flags ```loader_done``` and ```cpu_done``` in GTKWave to find when each of components was working, to see how memory has changed after
running the program and what steps did CPU take.

## Assembler overview
The assembler's first step is copying the program and removing the comments from it; When it encounters ```//```, this combination
and any other characters until the end of the line are ignored.

After this, the program is split into words; it is not substantial that only one instruction is written per line. 
Every **non-keyword** that ends with a ```:``` is considered a **tag**: it is not represented in the final binary, but
it associates the next word's memory location with a textual identifier that can be referenced in other parts of the program.
It can be used to implement variables, flow control, and functions.

The following program excerpt adds a number to one register and subtracts it from the other, until the the former is greater than the latter:
```
loop:	add left number		// overwrite LEFT register with LEFT + *number
	sub right number	// overwrite RIGHT register with RIGHT - *number
	jumplg end		// continue executing from "end:" if LEFT > RIGHT
	jump loop		// continue executing from "loop:" regardless of condition
end: // ...
```
A word that starts with ```$``` and signifies a number is a **constant** that is represented verbatim in the assembled program.
Normally, it is treated as a decimal number; use ```$h``` for hexadecimal and ```$b``` for binary numbers.

**Tag names** must not begin with an ```$```, end with ```:```, contain spaces, tabs, or newlines, or match mnemonic keywords.
Any other names, including numbers, are legal: you can use it to declare constants.

Here is an implementation of modulo 5:
```
load left 37	// set LEFT to 37
load right 5	// set RIGHT to 5 to compare against
jump mod5_loop	// skip data section

// data section
37:	$37
5:	$5
result:	$hFFFF

mod5_loop:	sub left 5
		jumplg mod5_loop	// Start loop again if LEFT > RIGHT=5
		jumpeq mod5_loop	// Start loop again if LEFT == RIGHT=5
end:		store left result	// Store the result in memory cell marked as "result:"
```

You can make functions using tags and the ```ret``` instruction. Make sure that the last item on stack --
which is the address from what the function was called -- stays the same!

## Mnemonics
...

## Binary Instruction set
### Overview
The instructions and data are stored in common memory space, which is loaded
with contents of  **program.txt** on startup. 
The first hex word in .txt is metadata, and it denotes the length of program section that follows; 
everything with an address greater than it will be filled with 0000's by _rom\_loader_. There's a total of 
_65536_ 16-bit memory cells at user's disposal. 

Most commands consist of two words - a command identifier and an argument.
For example, ```ADD0 0064``` adds the value stored at memory address
```0x0064``` to register ```LEFT```, replacing it with the result. Both words are treated as parts of a single
command and retrieved from memory sequentially. Therefore, the command pointer
is normally advanced 2 cells forward.

Other commands, especially those that do not require accessing memory, 
use only one word. For example, the ```1110``` overwrites all bits of ```LEFT```
with their inverses and does not require an argument. After execution of
a single-word command, the _instruction pointer_ is increased by 1 - the word
that comes next is not skipped and is treated as the beginning of next command,
so instructions are not always aligned by parity.

### Loading/Storing
  
- ```F000``` - move from LEFT to given addr
- ```F001``` - move from RIGHT to given addr

- ```2000``` - move from given addr to LEFT
- ```2001``` - move from given addr to RIGHT

- ```C021``` - copy value from LEFT to RIGHT
- ```C120``` - copy value from RIGHT to LEFT

 To access something using a 

- ```EC6E``` - exchange registers

 all constants are presumed to be stored in memory
 commands that add const to register or load const into it
 are omitted because they are redundant.

### Arithmetics
 
- ```ADD0``` - add value from given addr to LEFT
- ```ADD1``` - add value from given addr to RIGHT

- ```AD10``` - add LEFT and RIGHT, save to LEFT
- ```AD01``` - add LEFT and RIGHT, save to RIGHT
 
- ```5B70``` - sub value from given addr from LEFT
- ```5B71``` - sub value from given addr from RIGHT

- ```5A10``` - sub RIGHT from LEFT, save to LEFT
- ```5A01``` - sub LEFT from RIGHT, save to RIGHT

### Binary

- ```AAA0``` - place LEFT AND RIGHT to LEFT
- ```AAA1``` - place LEFT AND RIGHT to RIGTH

- ```CCC0``` - place LEFT OR RIGHT to LEFT
- ```CCC1``` - place LEFT OR RIGHT to RIGHT

- ```1110``` - bitwise invert LEFT
- ```1111``` - bitwise invert RIGHT

### Flow Control

- ```FFFF``` - shutdown
- ```BBBB``` - unconditional jump

- ```B061``` - jump if LEFT > RIGHT
- ```B051``` - jump if LEFT < RIGHT
- ```B0E1``` - jump if LEFT == RIGHT

### Stack and functions

- ```5AD0``` - push LEFT
- ```5AD1``` - push RIGHT

- ```5670``` - pop to LEFT
- ```5671``` - pop to RIGHT
- ```567E``` - pop to nowhere

- ```CA11``` - call function (push RIP, then set it to arg)
- ```EEFF``` - exit function (pop to RIP)

- ```C500``` - call peripheral (not implemented, this can be anything)
	- write something to indicators
    	- button input

### Mystery Commands (DO NOT TRY)

- ```FEED```
- ```5EED```

## Memory Interface

The command processor is decoupled from memory so they can run at different
clock speeds. There is a semaphore consisting of two registers (RESPONSE inside memory and
REQUEST inside the requesting device) that regulates memory requests.

The CPU and other devices react to positive clock edge while memory reacts to negative
clock edge. The process of accessing memory takes two clock periods:

* CLK POSEDGE 1: DEVICE sets ```REQUEST``` to ```1```; it no longer responds to ```clk``` in this state.
* CLK NEGEDGE 1: MEMORY sees that ```REQUEST``` is ```1``` while ```RESPONSE``` is ```0```; it sets
```RESPONSE``` to ```1``` and begins to process the operation according to bus values and mode flag.
an internal semaphore prevents it from processing multiple requests at once.
* CLK POSEDGE 2..N: DEVICE still has ```REQUEST``` set to ```1``` and does not do anything.
* CLK NEGEDGE 2..N: MEMORY displays or finishes writing values and sets  ```RESPONSE``` to ```0```.
* RESPONSE NEGEDGE: DEVICE sets ```REQUEST``` back to ```0``` and continues operating at next CLK POSEDGE.
