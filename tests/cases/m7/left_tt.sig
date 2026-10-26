process P =
  ( ! boolean C, D; )
  (| N := ZN + 1 | ZN := N $ init 0
   | B1 := (N modulo 4 = 2) when (N modulo 2 = 0)
   | B2 := (N modulo 3 = 0) when (N modulo 3 = 0)
   | B3 := (N modulo 9 /= 0) when (N modulo 3 = 0)
   | C := left_tt(B1, B2)
   | D := left_tt(B1, B3) |)
  where integer ZN, N; boolean B1, B2, B3; end;
