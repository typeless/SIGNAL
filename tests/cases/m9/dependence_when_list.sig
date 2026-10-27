process DEPLIST =
  ( ! integer X, Y, Z; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | X := N * 2
   | Y := N * 3
   | Z := N * 4
   | C := (N modulo 2) = 0
   | {X, Y --> Z} when C
   |)
  where
    integer ZN, N; boolean C;
  end;
