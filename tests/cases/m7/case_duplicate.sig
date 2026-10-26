process P =
  ( ! integer A, B; )
  (| N := ZN + 1 | ZN := N $ init 0
   | case N modulo 3 in {0}: A := 1 {1, 0}: B := 2 end
   |)
  where integer ZN, N; end;
