process P =
  ( ! integer A, B; )
  (| N := ZN + 1 | ZN := N $ init 0
   | (A, B) := (N, N + 1, N + 2)
   |)
  where integer ZN, N; end;
