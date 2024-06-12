import sys
import argparse

def assembly(filename: str, outname: str):
    with open(filename, "r") as file:
        program = '\0' + file.read()

    # remove comments
    in_comment = False
    offset = 1;
    
    while offset < len(program):
        if in_comment:
            comment_to += 1
        # comment start detected
        if program[offset-1:offset+1] == "//" and not in_comment:
            in_comment = True
            comment_from = offset - 1
            comment_to = offset
        # comment end detected, cut it
        if program[offset] == '\n' and in_comment:
            program = program[:comment_from] + program[comment_to:]
            offset -= comment_to - comment_from
            in_comment = False
            
        offset += 1

    program = program.lower()
    program = program[1:].split() # remove \0 from start and split

    keywords = ["left", "right", "load", "store", "copy",
                "add", "sub", "and", "or", "not", "halt", "jump",
                "jumplg", "jumprg", "jumpeq", "push", "pop", "call",
                "ret", "feed", "seed"]   

    tag_declarations = {}

    machine_code = []

    offset = 0
    while offset < len(program):
        word = program[offset]

        if word not in keywords and word[0] != "$" and word[-1] != ":": # parse tag references
            machine_code.append("%" + word)
        
        if word[0] == "$": # parse literals: convert to hex, crop "0x" at beginning
            if word[1] == "b":
                machine_code.append(hex(int(word[2:], 2))[2:].zfill(4).upper())
            elif word[1] == "h":
                machine_code.append(word[2:].zfill(4).upper())
            else:
                machine_code.append(hex(int(word[1:]))[2:].zfill(4).upper())
                 
            
        if word[-1] == ":": # parse tag declarations
            tag = word[:-1]
            if tag in tag_declarations.keys():
                raise RuntimeError("FATAL: " + tag + " declared twice")

            tag_declarations[tag] = len(machine_code)

        # parse instructions
        if word in keywords:
            if word == "halt":
                machine_code.append("FFFF")

            if word == "jump":
                machine_code.append("BBBB")

            if word == "jumplg":
                machine_code.append("B061")

            if word == "jumprg":
                machine_code.append("B051")

            if word == "jumpeq":
                machine_code.append("B0E1")

            if word == "call":
                machine_code.append("CA11")

            if word == "ret":
                machine_code.append("EEFF")

            if word == "int":
                machine_code.append("C500")
                            
            if word == "load":
                if program[offset+1] == "left":
                    machine_code.append("2000")
                elif program[offset+1] == "right":
                    machine_code.append("2001")
                else:
                    raise RuntimeError("Malformed statement: " + word + " " + program[offset+1])
                offset += 1

            if word == "store":
                if program[offset+1] == "left":
                    machine_code.append("F000")
                elif program[offset+1] == "right":
                    machine_code.append("F001")
                else:
                    raise RuntimeError("Malformed statement: " + word + " " + program[offset+1]) 
                offset += 1 

            if word == "push":
                if program[offset+1] == "left":
                    machine_code.append("5AD0")
                    offset += 1
                elif program[offset+1] == "right":
                    machine_code.append("5AD1")
                    offset += 1
                else:
                    raise RuntimeError("Malformed statement: " + word + " " + program[offset+1]) 
    
            if word == "pop":
                if program[offset+1] == "left":
                    machine_code.append("5670")
                    offset += 1
                elif program[offset+1] == "right":
                    machine_code.append("5671")
                    offset += 1
                else:
                    machine_code.append("567E") 

            if word == "copy":
                if program[offset+1] == "left" and program[offset+2] == "right":
                    machine_code.append("C120")
                elif program[offset+1] == "right" and program[offset+2] == "left":
                    machine_code.append("C021")
                else:
                    raise RuntimeError("Malformed statement: " + word + " " + program[offset+1] + " " + program[offset+2])
                offset += 2 
                       
            if word == "add":
            
                if program[offset+1] == "left":
                    if program[offset+2] == "right":
                        machine_code.append("AD10")
                        offset += 2
                    if program[offset+2] == "left":
                        raise RuntimeError("Malformed statement: " + word + " " + program[offset+1] + " " + program[offset+2])
                    else:
                        machine_code.append("ADD0")
                        offset += 1
                        
                elif program[offset+1] == "right":
                    if program[offset+2] == "left":
                        machine_code.append("AD01")
                        offset += 2
                    if program[offset+2] == "right":
                        raise RuntimeError("Malformed statement: " + word + " " + program[offset+1] + " " + program[offset+2])
                    else:
                        machine_code.append("ADD1")
                        offset += 1
                        
                else:
                    raise RuntimeError("Malformed statement: " + word + " " + program[offset+1])

            if word == "sub":
            
                if program[offset+1] == "left":
                    if program[offset+2] == "right":
                        machine_code.append("5B10")
                        offset += 2
                    if program[offset+2] == "left":
                        raise RuntimeError("Malformed statement: " + word + " " + program[offset+1] + " " + program[offset+2])
                    else:
                        machine_code.append("5B70")
                        offset += 1
                        
                elif program[offset+1] == "right":
                    if program[offset+2] == "left":
                        machine_code.append("5B01")
                        offset += 2
                    if program[offset+2] == "right":
                        raise RuntimeError("Malformed statement: " + word + " " + program[offset+1] + " " + program[offset+2])
                    else:
                        machine_code.append("5B71")
                        offset += 1
                        
                else:
                    raise RuntimeError("Malformed statement: " + word + " " + program[offset+1])

            if word == "and":
                if program[offset+1] == "left" and program[offset+2] == "right":
                    machine_code.append("AAA0")
                elif program[offset+1] == "right" and program[offset+2] == "left":
                    machine_code.append("AAA1")
                else:
                    raise RuntimeError("Malformed statement: " + word + " " + program[offset+1] + " " + program[offset+2])
                offset += 2

            if word == "or":
                if program[offset+1] == "left" and program[offset+2] == "right":
                    machine_code.append("CCC0")
                elif program[offset+1] == "right" and program[offset+2] == "left":
                    machine_code.append("CCC1")
                else:
                    raise RuntimeError("Malformed statement: " + word + " " + program[offset+1] + " " + program[offset+2])
                offset += 2

            if word == "not":
                if program[offset+1] == "left":
                    machine_code.append("1110")
                elif program[offset+1] == "right":
                    machine_code.append("1111")
                else:
                    raise RuntimeError("Malformed statement: " + word + " " + program[offset+1])
                offset += 1
    
        # Error cases
        if word[0] == "$" and word[-1] == ":":
            raise RuntimeError("FATAL: ambiguous statement: " + word)

        offset += 1

    output = "" # resolve tags
    for word in machine_code:
        if word[0] == "%":
            output += hex(tag_declarations[word[1:]])[2:].zfill(4).upper()
        else:
            output += word

        output += "\n"

    output = hex(len(machine_code))[2:].zfill(4).upper() + "\n" + output
    with open(outname, "w") as outfile:
        outfile.write(output)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Convert MEGACALC-5000 assembly code to binary.')
    parser.add_argument('source', type=str, help='The file containing assembly program')
    parser.add_argument('-o', '--output', type=str, default="program.txt", help='The file to write binary to')
    
    args = parser.parse_args()
    
    assembly(args.source, args.output)
