process COMPLEXREADMALFORMED =
  ( )
  (| N := ZN + 1
   | ZN := N $ init 0
   | R :: X := read("" when ^N)
   | W :: write("", X)
   | R --> W
   |)
  where
    integer N, ZN;
    complex X;
    label R, W;
  end;
