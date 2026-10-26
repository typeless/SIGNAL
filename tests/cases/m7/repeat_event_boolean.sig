process P =
  ( ! integer Y; )
  (| N := ZN + 1 | ZN := N $ init 0
   | B := N modulo 2 = 0
   | A := B |* 3
   | Y := N when A[1]
   |)
  where integer ZN, N; boolean B; [3] event A; end;
