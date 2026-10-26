process P =
  ( ! boolean C; )
  (| N := ZN + 1 | ZN := N $ init 0 | B := N modulo 2 = 0
   | C := left_tt(B, B, B) |)
  where integer ZN, N; boolean B; end;
