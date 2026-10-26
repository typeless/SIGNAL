process P =
  ( ? integer X; ! integer Y; )
  (| Y := T[X] \\ (X * 10) |)
  where
    constant [2] integer T = [1, 2];
  end;
