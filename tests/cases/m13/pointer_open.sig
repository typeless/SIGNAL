process POINTEROPEN =
  ( )
  (| N := ZN + 1
   | ZN := N $ init 0
   | R :: PATH := read("" when ^N)
   | O :: FD := syscall{OS}(5, pointer(PATH), 0, 0, 0, 0, 0)
   | W :: write("opened ", FD >= 0)
   | R --> W
   | O --> W
   |)
  where
    type OS = external;
    integer N, ZN;
    string PATH;
    long FD;
    label R, O, W;
  end;
