process MINLINK =
  ( ! integer N, A; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | B := N when (N modulo 2 = 0)
   | C := N when (N modulo 3 = 0)
   | A := 7
   | D := 8
   | min_clock(A)
   | min_clock(D)
   | A ^> B
   | D ^> C
   | A ^= D
   |)
  where
    integer ZN, B, C, D;
  end;
