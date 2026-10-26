process P =
  ( ! integer A, B, C; )
  (| N := ZN + 1 | ZN := N $ init 0
   | case N modulo 3 in
       {0}: (| A := 1 |)
       {1}: (| B := 2 |)
       else (| C := 3 |)
     end
   |)
  where integer ZN, N; end;
