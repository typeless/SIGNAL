process SIZEAXIS =
  ( ? integer I;
    ! integer A; )
  (| A := size(M, 3) + I |)
  where
    constant [2, 2] integer M = [[1, 2], [3, 4]];
  end;
