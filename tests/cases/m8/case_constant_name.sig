process P =
  ( ! integer A; )
  (| N := ZN + 1 | ZN := N $ init 0
   | case N modulo 3 in {K}: A := 1 end
   |)
  where integer ZN, N; constant integer K = 2; end;
