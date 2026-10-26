process P =
  ( ! integer A; )
  (| N := ZN + 1 | ZN := N $ init 0
   | case N modulo 3 in {[.0, 1]}: A := 1 end
   |)
  where integer ZN, N; end;
