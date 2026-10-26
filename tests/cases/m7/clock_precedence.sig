process P =
  ( ! event D, G; )
  (| N := ZN + 1 | ZN := N $ init 0 | A := when (N modulo 2 = 0) | B := when (N modulo 3 = 0)
   | C := when (N modulo 4 = 0)
   | D := A ^* B ^+ C
   | G := C ^+ A ^* B |)
  where integer ZN, N; event A, B, C; end;
