process COMPLEXARITHMETIC =
  ( ? complex A, B; dcomplex C, E;
    ! complex S, D, P, Q, M; dcomplex SD, DD, PD, QD, MD, W, V; )
  (| S := A + B
   | D := A - B
   | P := A * B
   | Q := A / B
   | M := -A
   | SD := C + E
   | DD := C - E
   | PD := C * E
   | QD := C / E
   | MD := -C
   | W := A + C
   | V := +C * A
   |)
  where
  end;
