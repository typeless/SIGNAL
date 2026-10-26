process P =
  ( ? integer X; ! integer Y; )
  (| Y := T[X] \\ (U[X] \\ 0) |)
  where
    constant [2] integer T = [1, 2];
    constant [3] integer U = [5, 6, 7];
  end;
