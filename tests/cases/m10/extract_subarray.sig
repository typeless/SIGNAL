process EXTRACTSUBARRAY =
  ( ? [2] integer P;
    ! [2, 2] integer R; )
  (| R := M[P]
   |)
  where
    constant [3, 2] integer M = [[1, 2], [3, 4], [5, 6]];
  end;
