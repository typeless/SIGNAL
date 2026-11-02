process COMPLEXDIVIDE =
  ( ? complex A, B; dcomplex C, E;
    ! complex Q; dcomplex QD; )
  (| Q := A / B
   | QD := C / E
   | A ^= C
   |)
  where
  end;
