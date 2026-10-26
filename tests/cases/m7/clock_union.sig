process P =
  ( ! event D; )
  (| N := ZN + 1 | ZN := N $ init 0 | A := when (N modulo 2 = 0) | B := when (N modulo 3 = 0)
   | D := A ^+ B |)
  where integer ZN, N; event A, B; end;
