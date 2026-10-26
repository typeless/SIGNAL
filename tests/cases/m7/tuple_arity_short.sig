process P =
  ( ! integer A, B, C; )
  (| N := ZN + 1 | ZN := N $ init 0
   | (A, B, C) := (N, N + 1)
   |)
  where integer ZN, N; end;
