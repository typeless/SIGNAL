process P =
  ( ? integer X; ! integer Y; )
  (| V := X when (X > 10)
   | Y := T[X] \\ V |)
  where
    integer V;
    constant [2] integer T = [1, 2];
  end;
