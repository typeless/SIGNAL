process BOOLS =
  ( ! integer N, R; boolean EVEN, B, F, G, P; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | R := (N - 8) modulo 3
   | EVEN := N modulo 2 = 0
   | B := (EVEN and not (N > 4)) or (N = 5)
   | F := (N <= 2) xor (N /= 1)
   | G := (N < 3) = (N >= 2)
   | P := EVEN $ init true
   |)
  where
    integer ZN;
  end;
