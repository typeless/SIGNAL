process READCHARMALFORMED =
  ( )
  (| N := ZN + 1
   | ZN := N $ init 0
   | R :: C := read("" when ^N)
   | W :: write("", C)
   | R --> W
   |)
  where
    integer N, ZN;
    char C;
    label R, W;
  end;
