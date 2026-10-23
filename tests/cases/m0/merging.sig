process MERGE =
  ( ! integer C, M, D; )
  (| C := ZC + 1
   | ZC := C $ init 0
   | S := C when ((C modulo 3) = 0)
   | T := (-C) when ((C modulo 3) = 1)
   | M := S default T
   | D := S default 0
   | D ^= C
   |)
  where
    integer ZC, S, T;
  end;
