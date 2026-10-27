process INDEXCOUNT =
  ( ? integer I;
    ! integer A; )
  (| A := M[I, I, I] |)
  where
    constant [2, 2] integer M = [[1, 2], [3, 4]];
  end;
