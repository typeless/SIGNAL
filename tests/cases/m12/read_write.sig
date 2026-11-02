process READWRITE =
  ( )
  (| N := ZN + 1
   | ZN := N $ init 0
   | R1 :: X := read("x? " when ^N)
   | R2 :: Y := read("y? ")
   | W1 :: write("x=", X)
   | W2 :: write("y=", Y * 2.0d0)
   | X ^= Y
   | R1 --> R2 --> W1 --> W2
   |)
  where
    integer N, ZN;
    real X;
    dreal Y;
    label R1, R2, W1, W2;
  end;
