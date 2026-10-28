process DELAYCHAIN =
  ( ! integer Y, Z; [2] ubyte P; boolean Q; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := N $ 3 init Y0
   | Z := N $ 2
   | U := [ubyte(N), ubyte(N + 100)]
   | P := U $ 2 init P0
   | Q := (N modulo 2 = 0) $ 1 init true
   |)
  where
    integer ZN, N;
    [2] ubyte U;
    constant [3] integer Y0 = [-2, -1, 0];
    constant [2, 2] ubyte P0 = [[ubyte(1), ubyte(2)], [ubyte(3), ubyte(4)]];
  end;
