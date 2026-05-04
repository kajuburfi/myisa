module mainMemory (
  input logic clk, mwe,
  input logic [15:0] waddr, wdata,
  input logic [15:0] a1, a2,
  output logic [15:0]  d1, d2, d3
);
  // File parameters
  localparam FNAME = "mem.hex";
  localparam LINE_BYTES = 5; // 4 hex chars + '\n'
  integer fh;
  integer ok;
  integer i;

  // open existing mem.hex (must be pre-created with 65536 lines of 4 hex chars + newline)
  initial begin
    fh = $fopen(FNAME, "r+");
    if (fh == 0) begin
      $display("[%0t] ERROR: %s not found or cannot open. Ensure file exists and has 65536 lines of 4 hex digits.", FNAME, $time);
      $finish;
    end
  end

  // helper: hex nibble (0..15) -> ASCII code
  function [7:0] nibble_to_ascii(input [3:0] n);
    begin
      if (n < 10) nibble_to_ascii = 8'h30 + n; // '0'..'9'
      else nibble_to_ascii = 8'h41 + (n - 10); // 'A'..'F'
    end
  endfunction

  // helper: ASCII hex char -> nibble (0..15), returns 0 on invalid
  function [3:0] ascii_to_nibble(input [7:0] c);
    begin
      if (c >= "0" && c <= "9") ascii_to_nibble = c - "0";
      else if (c >= "A" && c <= "F") ascii_to_nibble = c - "A" + 4'd10;
      else if (c >= "a" && c <= "f") ascii_to_nibble = c - "a" + 4'd10;
      else ascii_to_nibble = 4'd0;
    end
  endfunction

  // seek to start of line for word address 'a'
  function integer seek_line(input integer a);
    integer byte_off;
    begin
      byte_off = a * LINE_BYTES;
      seek_line = $fseek(fh, byte_off, 0); // returns 0 on success in iverilog
    end
  endfunction

  // read 16-bit word from hex file at address a
  function [15:0] file_read_hex_word(input integer a);
    integer okseek;
    integer c0, c1, c2, c3, nl;
    logic [3:0] n0, n1, n2, n3;
    begin
      file_read_hex_word = 16'h0000;
      okseek = seek_line(a);
      if (okseek != 0) begin
        $display("[%0t] fseek read error at addr %0d", a, $time);
      end else begin
        c0 = $fgetc(fh); c1 = $fgetc(fh); c2 = $fgetc(fh); c3 = $fgetc(fh); nl = $fgetc(fh);
        if (c0 == -1 || c1 == -1 || c2 == -1 || c3 == -1) begin
          file_read_hex_word = 16'h0000;
        end else begin
          n0 = ascii_to_nibble(c0[7:0]);
          n1 = ascii_to_nibble(c1[7:0]);
          n2 = ascii_to_nibble(c2[7:0]);
          n3 = ascii_to_nibble(c3[7:0]);
          file_read_hex_word = {n0, n1, n2, n3}; // concatenates nibbles -> 16 bits
        end
      end
    end
  endfunction

  // write 16-bit word as 4 hex chars + newline in-place at address a
  task file_write_hex_word(input integer a, input [15:0] v);
    integer okseek;
    logic [7:0] c0, c1, c2, c3;
    integer temp0, temp1, temp2, temp3, temp4; // for the return values of fputc
    begin
      okseek = seek_line(a);
      if (okseek != 0) begin
        $display("[%0t] fseek write error at addr %0d", a, $time);
      end else begin
        c0 = nibble_to_ascii(v[15:12]);
        c1 = nibble_to_ascii(v[11:8]);
        c2 = nibble_to_ascii(v[7:4]);
        c3 = nibble_to_ascii(v[3:0]);
        // overwrite 4 chars + newline (keep newline as '\n')
        temp0 = $fputc(c0, fh);
        temp1 = $fputc(c1, fh);
        temp2 = $fputc(c2, fh);
        temp3 = $fputc(c3, fh);
        temp4 = $fputc(8'h0A, fh);
        $fflush(fh);
      end
    end
  endtask

  // Sync write
  always @(posedge clk) begin
    if (mwe) file_write_hex_word(waddr, wdata);
  end
  // Async read 
  assign d1 = file_read_hex_word(a1);
  assign d2 = file_read_hex_word(a2);
  assign d3 = file_read_hex_word(waddr); //Use this IFF ~mwe

  final begin
    if (fh != 0) $fclose(fh);
  end
endmodule
