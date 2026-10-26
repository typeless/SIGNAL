process P =
  ( ! integer A, B, C; )
  (| N := ZN + 1 | ZN := N $ init 0
   | case N modulo 2 in
       {0}: case N modulo 3 in {1}: A := N else B := N end
       {1}: C := N
     end
   |)
  where integer ZN, N; end;
