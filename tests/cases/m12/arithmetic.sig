process ARITHMETIC =
  ( ? real A, B; dreal C, E;
    ! real S, D, P, Q, M, K; dreal SD, DD, PD, QD, MD, KD, W, V; )
  (| S := A + B
   | D := A - B
   | P := A * B
   | Q := A / B
   | M := -A
   | K := A ** 3
   | SD := C + E
   | DD := C - E
   | PD := C * E
   | QD := C / E
   | MD := -C
   | KD := C ** 2
   | W := A + C
   | V := C * A
   |)
  where
  end;
