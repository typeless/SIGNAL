process SUBARRAYTARGET =
  ( ? integer I;
    ! integer A; )
  (| X := W next I : 5
   | A := X[0, 0]
   |)
  where
    [2, 2] integer X;
    constant [2, 2] integer W = [[0, 0], [0, 0]];
  end;
