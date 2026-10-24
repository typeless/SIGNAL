process MD =
  ( ! short X; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | X := (N * 40000) modulo 0
   |)
  where
    integer ZN, N;
  end;
