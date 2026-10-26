process P =
  ( ! integer M; )
  (| N := ZN + 1 | ZN := N $ init 0
   | case N modulo 2 in {0}: M := 1 else M := 2 end
   |)
  where integer ZN, N; end;
