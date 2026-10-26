process P =
  ( ? integer X; ! integer Y; )
  (| Y := T[X] \\ T[X + 1] \\ 0 |)
  where
    constant [2] integer T = [1, 2];
  end;
