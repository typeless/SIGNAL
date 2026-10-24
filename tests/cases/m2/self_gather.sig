process SELFGATHER =
  ( ! integer Z0, Z1, Z2, Z3; )
  (| I := indices(1)
   | iterate I of Z := Z[?][R] with Z := SRC end
   | Z0 := Z[0]
   | Z1 := Z[1]
   | Z2 := Z[2]
   | Z3 := Z[3]
   |)
  where
    constant [4] integer SRC = [10, 11, 12, 13];
    constant [4] integer R = [3, 0, 1, 2];
    [1] integer I;
    [4] integer Z;
  end;
