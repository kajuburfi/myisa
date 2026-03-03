#include <stdio.h>

short int mem[65536] = {0};
short int reg[16] = {0};

void load_pgm_into_mem(FILE *fp) {
  char buf[2];
  short int idx = 0xFFFF;
  while (fread(buf, sizeof(buf), 1, fp) == 1) {
    short val = (((short)buf[0]) << 8) | (0x00FF & buf[1]);
    mem[idx--] = val;
    // The below line prints the pgm in mem
    printf("%X %04X\n", idx & 0x0000FFFF, val & 0x0000FFFF);
  }
  printf("Bottom line of pgm is %x", idx);
}

void set_up_regs() { reg[0xA] = 0xFFFF; }

int main(int argc, char *argv[]) {
  if (argc != 2) {
    printf("Error: please provide machine code binary file.");
    return 1;
  }

  FILE *fp = fopen(argv[1], "rb");

  load_pgm_into_mem(fp);

  fclose(fp);

  return 0;
}

/*

========== SOURCES ===========
[1] https://stackoverflow.com/questions/17768625/2-chars-to-short-in-c


*/
