process P =
  ( ! integer A, B; )
  (| N := ZN + 1 | ZN := N $ init 0
   | K := (N modulo 4) - 2
   | case K in
       {-1, 1}: A := K
       {0}: B := N
     end
   |)
  where integer ZN, N, K; end;
