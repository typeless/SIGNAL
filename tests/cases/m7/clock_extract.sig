process P =
  ( ! event E, F; )
  (| N := ZN + 1 | ZN := N $ init 0 | B := N modulo 2 = 0
   | E := [: B]
   | F := [/: B] |)
  where integer ZN, N; boolean B; end;
