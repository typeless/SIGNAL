process RECOVERYINDICES =
  ( ? integer I;
    ! integer A; )
  (| A := M[I, I] \\ 0 |)
  where
    constant [2, 2] integer M = [[1, 2], [3, 4]];
  end;
