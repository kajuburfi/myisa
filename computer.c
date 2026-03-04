#include <stdio.h>

// Global memory and registers
int mem[65536] = {0};
int reg[16] = {0};

void print_regs() {
  printf("REGS: ");
  for (int i = 0; i < 16; i++)
    printf("%X ", reg[i] & 0x0000FFFF);
  printf("\n");
}

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

typedef union {
  int int_val;
  char char_vals[4];
} int_to_bytes;

// Reads through the file pointer, and loads the pgm into the memory
// Returns the end of the program portion.
int load_pgm_into_mem(char *name) {
  FILE *fp = fopen(name, "rb");
  if (!fp)
    return 0; // The program shouldn't be 65535 instructions long.(Otherwise you
              // get this error)

  char buf[2];      // We read as chars
  int idx = 0xFFFF; // Index to store into
  // Reading loop
  while (fread(buf, sizeof(buf), 1, fp) == 1) {
    // I want to store it as int int(16 bits)
    int val = (((int)buf[0]) << 8) | (0x00FF & buf[1]);
    mem[idx] = val;
    // The below line prints the pgm in mem
    printf("%X %04X\n", idx & 0x0000FFFF, val & 0x0000FFFF);
    idx--;
  }
  // printf("Bottom line of pgm is %x", idx);
  fclose(fp);

  return idx;
}

char *get_split_instr(char *split_instr) {
  int_to_bytes temp;
  temp.int_val = mem[reg[pc]];
  split_instr[0] = (temp.char_vals[1] & 0xF0) >> 4;
  split_instr[1] = temp.char_vals[1] & 0x0F;
  split_instr[2] = (temp.char_vals[0] & 0xF0) >> 4;
  split_instr[3] = temp.char_vals[0] & 0x0F;
  // The below code prints the split for a particular mem
  // for (int i = 0; i < 4; i++)
  //   printf("%x ", split_instr[i]);
  // printf("\n");
  return split_instr;
}

void do_instr(char *split_instr) {
  Instr instr = split_instr[0];
  Reg rd = split_instr[1];
  Reg rs = split_instr[2];
  Reg rt = split_instr[3];

  if (instr == lw) { // 0000
    int imm = mem[--reg[pc]];
    reg[rd] = mem[reg[rs] + imm];
  } else if (instr == sw) { // 0001
    int imm = mem[--reg[pc]];
    mem[reg[rs] + imm] = reg[rd];
  } else if (instr == nand) { // 0010
    reg[rd] = !(reg[rs] & reg[rt]);
  } else if (instr == nandi) { // 0011
    int imm = mem[--reg[pc]];
    reg[rd] = !(reg[rs] & imm);
  } else if (instr == add) { // 0100
    reg[rd] = reg[rs] + reg[rt];
  } else if (instr == addi) { // 0101
    int imm = mem[--reg[pc]];
    reg[rd] = reg[rs] + imm;
  } else if (instr == sub) { // 0110
    reg[rd] = reg[rs] - reg[rt];
  } else if (instr == mul) { // 0111
    int sol = reg[rd] * reg[rs];
    reg[hi] = (sol >> 16) & 0x0000FFFF;
    reg[lo] = sol & 0x0000FFFF;
  } else if (instr == div) { // 1000
    reg[hi] = reg[rd] / reg[rs];
    reg[lo] = reg[rd] % reg[rs];
  } else if (instr == cmp) { // 1001
    if (reg[rd] > reg[rs])
      reg[flg] = reg[flg] | 0b0000000000000010;
    if (reg[rd] == reg[rs])
      reg[flg] = reg[flg] | 0b0000000000000001;
  } else if (instr == b) { // 1010
    // Plus one because we are subtracting at the end of this function
    reg[pc] = reg[rd] + 1;
  } else if (instr == beq) {
    if ((reg[flg] & 0x0001) == 1)
      reg[pc] = reg[rd];
  } else if (instr == bgt) {
    if ((reg[flg] & 0x0002) == 2)
      reg[pc] = reg[rd];
  }
  print_regs();
  for (int i = 0; i < 20; i++)
    printf("%x ", mem[i]);
  printf("\n\n");
  reg[pc]--;
}

void set_up_regs() { reg[pc] = 0xFFFF; }

int compare_arrays(char arr1[], char arr2[], int size) {
  for (int i = 0; i < size; i++)
    if (arr1[i] != arr2[i])
      return 0; // Arrays are not equal

  return 1; // Arrays are equal
}

int main(int argc, char *argv[]) {
  if (argc != 2) {
    printf("Error: please provide machine code binary file.\n");
    return 1;
  }

  set_up_regs();
  int pgm_end = load_pgm_into_mem(argv[1]);
  if (pgm_end == 0) {
    printf("Error: Couldn't open binary provided\n");
    return 1;
  }

  char split_instr[4]; // This contains the bits of the instruction
  char instruction_halt[4] = {0x0F, 0x0F, 0x0F, 0x0F};
  do {
    get_split_instr(split_instr);

    for (int j = 0; j < 4; j++)
      printf("%x ", split_instr[j]);
    printf("\n");
    do_instr(split_instr);
  } while (!compare_arrays(split_instr, instruction_halt, 4));
  return 0;
}

/*

========== SOURCES ===========
[1] https://stackoverflow.com/questions/17768625/2-chars-to-int-in-c
[2] https://stackoverflow.com/questions/11656532/returning-an-array-using-c

*/
