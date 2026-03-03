#include <stdio.h>

// Global memory and registers
short int mem[65536] = {0};
short int reg[16] = {0};

// Reads through the file pointer, and loads the pgm into the memory
// Returns the end of the program portion.
short load_pgm_into_mem(char *name) {
  FILE *fp = fopen(name, "rb");
  if (!fp)
    return -1;

  char buf[2];            // We read as chars
  short int idx = 0xFFFF; // Index to store into
  // Reading loop
  while (fread(buf, sizeof(buf), 1, fp) == 1) {
    // I want to store it as short int(16 bits)
    short val = (((short)buf[0]) << 8) | (0x00FF & buf[1]);
    mem[idx--] = val;
    // The below line prints the pgm in mem
    printf("%X %04X\n", idx & 0x0000FFFF, val & 0x0000FFFF);
  }
  // printf("Bottom line of pgm is %x", idx);
  fclose(fp);

  return idx;
}

void set_up_regs() { reg[0xA] = 0xFFFF; }

int main(int argc, char *argv[]) {
  if (argc != 2) {
    printf("Error: please provide machine code binary file.\n");
    return 1;
  }

  set_up_regs();
  short pgm_end = load_pgm_into_mem(argv[1]);
  if (pgm_end < 0) {
    printf("Error: Couldn't open binary provided\n");
    return 1;
  }
  return 0;
}

/*

========== SOURCES ===========
[1] https://stackoverflow.com/questions/17768625/2-chars-to-short-in-c


*/
