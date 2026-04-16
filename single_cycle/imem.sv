module imem(
  input logic [15:0] a1, a2,
  output logic [15:0] ri1, ri2
);
  // NOTE: Here, the book mentions that we need to use RAM[63:0], but this gives a warning/error.
  // Hence, we use RAM[0:17].
  // Reference: https://stackoverflow.com/questions/66824196/icarus-verilog-warning-readmemh-standard-inconsistency-following-1364-2005
  // 
  // logic [15:0] RAM[0:17];
  // initial begin 
  //   $readmemh("instr.dat", RAM);
  // end

  int fd, code;
  logic [15:0] RAM [0:255]; // Define memory array to store the data
  int start = 0; // Start index
  int count = 2; // Maximum memory index to read

  initial begin
    fd = $fopen("output.bin", "r");
    if (fd == 0) begin
      $display("Error: Could not open file.");
      $finish;
    end

    // Read data from the file into memory array
    code = $fread(RAM, fd, start, count);
    if (code == 0) begin
      $display("Error: Could not read data.");
    end else begin
      $display("imem.sv: Read %0d bytes of data.", code);
    end
    
    // Display the contents of the first few memory locations
    // for (int i = 0; i < 20; i++) begin
    //   $display("mem[%0d] = %h", i, mem[i]);
    // end
    
    $fclose(fd);
  end

  assign ri1 = RAM[a1]; // word aligned
  assign ri2 = RAM[a2];
endmodule

