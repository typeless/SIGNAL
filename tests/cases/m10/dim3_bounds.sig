process DIM3BOUNDS =
  ( ? integer I, J, K;
    ! integer A; )
  (| I ^= J ^= K
   | A := M[I, J, K]
   |)
  where
    constant [2, 3, 4] integer M = [[[1, 2, 3, 4], [11, 12, 13, 14], [21, 22, 23, 24]],
                                    [[101, 102, 103, 104], [111, 112, 113, 114], [121, 122, 123, 124]]];
  end;
