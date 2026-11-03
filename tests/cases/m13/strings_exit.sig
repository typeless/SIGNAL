process STRINGSEXIT =
  ( )
  (| N := ZN + 1
   | ZN := N $ init 0
   | R :: LINE := read("" when ^N)
   | PREVIOUS := LINE $ 1 init "none"
   | FIRST_LINE := LINE when N = 1
   | FIRST := FIRST_LINE cell ^N init ""
   | O :: FD := syscall{OS}(5, pointer(LINE), 0, 0, 0, 0, 0)
   | W1 :: write("line ", LINE)
   | W2 :: write("previous ", PREVIOUS)
   | W3 :: write("first ", FIRST)
   | W4 :: write("same as previous ", LINE = PREVIOUS)
   | W5 :: write("before previous ", LINE < PREVIOUS)
   | W6 :: write("same as first ", LINE = FIRST)
   | W7 :: write("before first ", LINE < FIRST)
   | W8 :: write("opens ", FD >= 0)
   | R --> W1 --> W2 --> W3 --> W4 --> W5 --> W6 --> W7 --> W8
   | O --> W8
   |)
  where
    type OS = external;
    integer N, ZN;
    string LINE, PREVIOUS, FIRST_LINE, FIRST;
    long FD;
    label R, O, W1, W2, W3, W4, W5, W6, W7, W8;
  end;
