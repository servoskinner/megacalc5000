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

- ```F000```: store ```LEFT``` to ```*ARG```
- ```F001```: store ```RIGHT``` to ```*ARG```

- ```2000```: load ```*ARG``` to ```LEFT```
- ```2001```: load ```*ARG``` to ```RIGHT```

*TBA*

