process COMPLEXCOMPARE =
  ( ? complex A, B; dcomplex C, E;
    ! boolean EQ, NE, EE, EQD, NED, EED, MIXED; )
  (| EQ := A = B
   | NE := A /= B
   | EE := A == B
   | EQD := C = E
   | NED := C /= E
   | EED := C == E
   | MIXED := A = E
   | A ^= C
   |)
  where
  end;
