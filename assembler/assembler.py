import sys

def get_symbol_array(filename: str):
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

    keywords = ["left", "right", "load", "store", "copy", "exch",
                "add", "sub", "and", "or", "neg", "halt", "jump",
                "jumplg", "jumprg", "jumpeq", "push", "pop", "call",
                "ret", "feed", "seed"]   

    tag_references = {}
    tag_declarations = {}

    machine_code = []

    offset = 0
    while offset < len(program):
        word = program[offset]

        if word not in keywords and word[0] != "$" and word[-1] != ":": # parse tag references
            pass
        
        if word[0] == "$": # parse literals: convert to hex, crop "0x" at beginning
            machine_word = ""
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
        ...
    
        # Error cases
        if word[0] == "$" and word[-1] == ":":
            raise RuntimeError("FATAL: ambiguous statement: " + word)

        offset += 1
    return machine_code

if __name__ == "__main__":
    print(get_symbol_array("code.txt"))

    
