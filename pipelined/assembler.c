/* Changes made compared to c_impl:
 - SystemVerilog Change Instruction storage format for cmp and branch instr to
   have flg register as rd
 */
// vim: set filetype=systemverilog:
#include <stdio.h>
#include <string.h>

// An enum for instructions
typedef enum Instruction Instr;
enum Instruction {
  lw,
  sw,
  nand,
  nandi,
  add,
  addi,
  sub,
  mul,
  div,
  cmp,
  b,
  beq,
  bgt,
  imm,
  nop = 15, // 1111 -> Does no operation
};

// An enum for registers. Easy to convert symbolic repr. and binary value
typedef enum Regs Reg;
enum Regs {
  r0,
  r1,
  r2,
  r3,
  r4,
  r5,
  r6,
  r7,
  r8,
  r9,
  pc,
  ibr,
  flg,
  hi,
  lo,
  zero, // Yes; zero is 15 or 0xF
};

// Smart stuff to split a short integers(16 bits) into 4 pieces of 4 bits each
// Picked up from [1]
typedef union {
  short int int_val;
  char char_vals[4];
} int_to_bytes;

// Converts the string in the code to a Reg
Reg str_to_reg(char *s) {
  if (strcmp(s, "r0") == 0)
    return r0;
  if (strcmp(s, "r1") == 0)
    return r1;
  if (strcmp(s, "r2") == 0)
    return r2;
  if (strcmp(s, "r3") == 0)
    return r3;
  if (strcmp(s, "r4") == 0)
    return r4;
  if (strcmp(s, "r5") == 0)
    return r5;
  if (strcmp(s, "r6") == 0)
    return r6;
  if (strcmp(s, "r7") == 0)
    return r7;
  if (strcmp(s, "r8") == 0)
    return r8;
  if (strcmp(s, "r9") == 0)
    return r9;
  if (strcmp(s, "pc") == 0)
    return pc;
  if (strcmp(s, "ibr") == 0)
    return ibr;
  if (strcmp(s, "hi") == 0)
    return hi;
  if (strcmp(s, "lo") == 0)
    return lo;
  if (strcmp(s, "flg") == 0)
    return flg;
  if (strcmp(s, "zero") == 0)
    return zero;
  return zero;
}

// Similarly, converts a read string into an Instr
Instr str_to_instr(char *s) {
  if (strcmp(s, "lw") == 0)
    return lw;
  if (strcmp(s, "sw") == 0)
    return sw;
  if (strcmp(s, "nand") == 0)
    return nand;
  if (strcmp(s, "nandi") == 0)
    return nandi;
  if (strcmp(s, "add") == 0)
    return add;
  if (strcmp(s, "addi") == 0)
    return addi;
  if (strcmp(s, "sub") == 0)
    return sub;
  if (strcmp(s, "mul") == 0)
    return mul;
  if (strcmp(s, "div") == 0)
    return div;
  if (strcmp(s, "cmp") == 0)
    return cmp;
  if (strcmp(s, "b") == 0)
    return b;
  if (strcmp(s, "beq") == 0)
    return beq;
  if (strcmp(s, "bgt") == 0)
    return bgt;
  if (strncmp(s, "0", 1) == 0)
    return imm;
  return nop;
}

// Takes in a string pointer and modifies it such that there are no "extra"
// spaces and no commas.
// This also removes newlines and comments.
void del_extra_spaces_n_commas(char *s) {
  char *d = s;
  // replace '\n' with '\0' ;)
  if (*d == '\n')
    *s = '\0';
  // Comments - Only single line comments, starting with `;` are allowed.
  if (strncmp(s, ";", 1) == 0) {
    *s = '\0';
    return;
  } // This takes care of the extra spaces and commas(and removes the newline at
  // the end of an instruction)
  do {
    while ((*d == ' ' && *(d + 1) == ' ') || *d == ',' || *d == '\n')
      d++;
  } while ((*s++ = *d++));
  // Yes; we are checking the return value of the assignment in the above stmt
}

int main(int argc, char *argv[]) {
  // Give only one argument(as of now)
  if (argc != 2) {
    printf("Error: Please provide the .asm file");
    return 1;
  }

  // Open both read and write files.
  FILE *fp = fopen(argv[1], "r");
  FILE *fop = fopen("output.bin", "wb");

  if (fp == NULL || fop == NULL) {
    printf("Error: Cannot open file.");
    return 1;
  }

  char buf[256]; // This is to read a line of not more than 256 characters
  // The condition in the while iterates over every line in the file
  while (fgets(buf, sizeof(buf), fp) != NULL) {
    del_extra_spaces_n_commas(buf); // Does exactly what it says it does
    // If it's an empty line, skip over.
    if (strcmp(buf, "\0") == 0)
      continue;

    // Adds `flg` as the register dest(rd) for each instr which requires that
    // Source: [6]
    if (strncmp(buf, "cmp", 3) == 0 || strncmp(buf, "b ", 2) == 0 ||
        strncmp(buf, "bgt", 3) == 0 || strncmp(buf, "beq", 3) == 0) {
      char temp[256];
      int x = (strncmp(buf, "b ", 2) == 0) ? 1 : 3;
      strncpy(temp, buf, x);
      temp[x] = '\0';
      strcat(temp, " flg");
      strcat(temp, buf + x);
      strcpy(buf, temp);
    }

    // The first word of a line in the asm is the instruction. Everything else
    // must be a register. Hence, the first time, you check for instr, after
    // that, you just check for regs
    short int is_instr = 1;
    // NOTE: Funnily enough, all `char` is, is just 1 byte of storage; we can
    // do whatever we want with that 1 byte. Here, I'm storing each byte of
    // the instruction as an array of "characters", but it stores integers.
    char instruction[4] = {0}; // Instruction to write in binary
    short int i = 0;           // Counter for instruction

    // Split the line into instruction and its arguments
    char *token = strtok(buf, " ");

    while (token != NULL) {
      if (is_instr) {
        Instr instr = str_to_instr(token); // Get the instruction as the enum

        // A bunch of stuff to do if it's an immediate type
        if (instr == imm) {
          // Cool stuff to convert str to int
          int_to_bytes temp;
          if (strncmp(token, "0d", 2) == 0)
            // Crazy hack(Unfortunately, it would depend of the endianness of
            // the system)
            sscanf(token + 2, "%hd", &temp.int_val);
          else if (strncmp(token, "0x", 2) == 0)
            sscanf(token + 2, "%hx", &temp.int_val);

          for (int j = 0; j < 4; j++)
            instruction[j] = temp.char_vals[j];

          // For immediates, the first and second bit are to be swapped
          char temp1;
          temp1 = instruction[0];
          instruction[0] = instruction[1];
          instruction[1] = temp1;

          break;
        }

        instruction[i++] = instr;
        is_instr = 0;

      } else {
        Reg reg = str_to_reg(token);
        instruction[i++] = reg;
      }

      // Move over to the next part of the line
      token = strtok(NULL, " ");
    }

    // NOTE: If it is an immediate value, then the value of `is_instr` will be
    // 1, since we change it after the imm portion. So, we use that to check
    // if the instruction[] contains an instruction or an immediate value.
    if (!is_instr) { // Sounds weird, but this is just because we count down for
                     // register vs instructions and all
      // Doing this because the minimum size of data is 1 byte, but I need 4
      // bits of info here.
      char final_instr[2];
      final_instr[0] = (instruction[0] << 4) + instruction[1];
      final_instr[1] = (instruction[2] << 4) + instruction[3];
      fwrite(final_instr, sizeof(char), 2, fop);
    } else {
      fwrite(instruction, sizeof(char), 2, fop);
    }
  }
  char halt_instr[2] = {0xFF, 0xFF};
  fwrite(halt_instr, sizeof(char), 2, fop);

  fclose(fp);
  fclose(fop);
  return 0;
}

/*

HEXDUMP command to get nice output as how it will be stored:
$ hexdump output.bin -e '"%08.8_ax " 2/1 " %02X""\n"'

========== SOURCES REFERRED ===========
[1]
https://stackoverflow.com/questions/51555676/how-to-divide-an-int-into-two-bytes-in-c
[2] https://www.geeksforgeeks.org/c/convert-string-to-int-in-c/
[3] https://www.w3schools.com/c/c_enums.php
[4] https://little-book-of.github.io/c/        REALLY GOOD RESOURCE
[5]
https://stackoverflow.com/questions/17598572/how-to-read-write-a-binary-file
[6]
https://stackoverflow.com/questions/2015901/inserting-char-string-into-another-char-string



*/
