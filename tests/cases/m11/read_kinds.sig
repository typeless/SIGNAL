process READKINDS =
  ( )
  (| N := ZN + 1
   | ZN := N $ init 0
   | R1 :: I := read("" when ^N)
   | R2 :: B := read("")
   | R3 :: C := read("")
   | R4 :: U := read("")
   | W :: write("", I)
   | X :: write("", B)
   | Y :: write("", C)
   | Z :: write("", U)
   | I ^= B
   | B ^= C
   | C ^= U
   | R1 --> R2 --> R3 --> R4 --> W --> X --> Y --> Z
   |)
  where
    integer N, ZN;
    integer I;
    boolean B;
    char C;
    ulong U;
    label R1, R2, R3, R4, W, X, Y, Z;
  end;
