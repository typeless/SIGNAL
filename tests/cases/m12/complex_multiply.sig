process COMPLEXMULTIPLY =
  ( ? complex A, B; dcomplex C, E;
    ! complex P; dcomplex Q; )
  (| P := A * B
   | Q := C * E
   | A ^= C
   |)
  where
  end;
