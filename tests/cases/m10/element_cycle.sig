process ELEMENTCYCLE =
  ( ? integer I;
    ! integer B; )
  (| X := V next I : I
   | B := X[0] + I
   | B --> X[2]
   |)
  where
    [3] integer X;
    constant [3] integer V = [5, 6, 7];
  end;
