process ARRAYEQ =
  ( ? [3] integer V, W;
    ! boolean A, B; )
  (| A := V == W
   | B := V == C
   | V ^= W
   |)
  where
    constant [3] integer C = [1, 2, 3];
  end;
