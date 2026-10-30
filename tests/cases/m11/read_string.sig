process READSTRING =
  ( )
  (| N := ZN + 1
   | ZN := N $ init 0
   | R :: S := read("" when ^N)
   | W :: write("got ", S)
   | R --> W
   |)
  where
    integer N, ZN;
    string S;
    label R, W;
  end;
