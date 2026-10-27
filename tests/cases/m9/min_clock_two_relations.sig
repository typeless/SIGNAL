process MINTWO =
  ( ! integer N, A; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | B := N when (N modulo 2 = 0)
   | C := N when (N modulo 3 = 0)
   | A := 7
   | min_clock(A)
   | A ^> B
   | A ^> C
   |)
  where
    integer ZN, B, C;
  end;
