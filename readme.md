# MEGACALC 5000
## About
this is a primitive 16 bit microprocessor model with following features:
- two equivalent general-purpose registers: ```LEFT``` and ```RIGHT```
- pointer logic support
- stack and subroutine call support (TBA)

## Programming
Instructions and data are stored in common memory space, which is loaded
with contents of  ```program.txt``` on startup. 
The first hex word in .txt denotes the length of program section; 
everything past it will be filled with 0000's. There's a total of 
_65536_ 16-bit memory cells at user's disposal. 

Most commands consist of two words - command identifier and argument.

For example, ```ADD0 0064``` adds the value stored at memory address
```0x0064``` to ```LEFT``` register. Both words are treated as a single
command.

On the other hand, the ```FA01``` command writes the value from ```LEFT```
to the address stored in ```RIGHT``` and is therefore treated as single-word 
command. The exectution continues from the word that comes after it, 
so it is neither read as argument nor skipped.

## Instruction set

### Loading/Storing
  
- ```F000``` - move from LEFT to given addr
- ```F001``` - move from RIGHT to given addr

- ```2000``` - move from given addr to LEFT
- ```2001``` - move from given addr to RIGHT

- ```C021``` - copy value from LEFT to RIGHT
- ```C120``` - copy value from RIGHT to LEFT

 To use pointers, modify the arg word
 corresponding to the command

- ```EC6E``` - exchange registers

 all constants are presumed to be stored in memory
 commands that add const to register or load const into it
 are omitted because they are redundant.

### Arithmetics
 
- ```ADD0``` - add value from given addr to LEFT
- ```ADD1``` - add value from given addr to RIGHT

- ```0A10``` - add LEFT and RIGHT, save to LEFT
- ```0A11``` - add LEFT and RIGHT, save to LEFT
 
- ```5B70``` - sub value from given addr from LEFT
- ```5B71``` - sub value from given addr from RIGHT

- ```5A10``` - sub *RIGHT from LEFT
- ```5A01``` - sub *LEFT from RIGHT

- ```0510``` - sub RIGHT from LEFT, save to LEFT
- ```1500``` - sub LEFT from RIGHT, save to LEFT

### Binary

_TBA_

### Flow Control

- ```FFFF``` - shutdown
- ```BBBB``` - unconditional jump

- ```B061``` - jump if LEFT > RIGHT
- ```B051``` - jump if LEFT < RIGHT
- ```B0E1``` - jump if LEFT == RIGHT

### Stack and functions (TBA)

- ```5AD0``` - push LEFT
- ```5AD1``` - push RIGHT

- ```5670``` - pop to LEFT
- ```5671``` - pop to RIGHT
- ```567E``` - pop to nowhere

- ```CF00``` - call function (lowest implementation priority)
- ```EF00``` - exit function ("ret")

- ```C500``` - call peripheral (probably going to be button input or indicators)
	- write something to indicators
    - button input

## Memory Interface

The command processor is decoupled from memory so they can still run at different
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
