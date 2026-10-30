process READLONG =
  ( )
  (| N := ZN + 1
   | ZN := N $ init 0
   | R :: S := read("" when ^N)
   | W :: write("", S)
   | R --> W
   |)
  where
    integer N, ZN;
    string S;
    label R, W;
  end;
