process MINCLOCKRELATION =
  ( ! integer N, B, A; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | B := N when (N modulo 2 = 0)
   | A := ZA + 1
   | ZA := A $ init 0
   | min_clock(A)
   | A ^> B
   |)
  where
    integer ZN, ZA;
  end;
