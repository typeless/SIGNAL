process ELEMENTRANGE =
  ( ? integer I;
    ! integer A; )
  (| X := V next I : I
   | Y := V next I : I
   | A := X[0]
   | A --> Y[0..2]
   |)
  where
    [3] integer X, Y;
    constant [3] integer V = [5, 6, 7];
  end;
