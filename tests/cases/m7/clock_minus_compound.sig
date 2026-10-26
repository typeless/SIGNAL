process P =
  ( ! event D, F; )
  (| N := ZN + 1 | ZN := N $ init 0 | B := when (N modulo 4 = 0) | E := when (N modulo 5 = 0)
   | A := when (N modulo 2 = 0)
   | D := when (N modulo 2 = 0) ^- B
   | F := E default A ^- B |)
  where integer ZN, N; event A, B, E; end;
