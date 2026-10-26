process P =
  ( ! integer Y; )
  (| N := ZN + 1 | ZN := N $ init 0
   | M := N when (N > 2)
   | (Y) ^= M
   | Y := M + 1
   |)
  where integer ZN, N, M; end;
