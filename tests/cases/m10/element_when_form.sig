process ELEMENTWHENFORM =
  ( ? integer I;
    ! integer A, B; )
  (| X := V next I : I
   | Y := V next I : I
   | A := X[0]
   | B := Y[0]
   | { A --> Y[0] } when I > 0
   |)
  where
    [3] integer X, Y;
    constant [3] integer V = [5, 6, 7];
  end;
