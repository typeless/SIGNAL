process TWOLEFT =
  ( ? [2, 2] integer M;
    ! [2] integer W; )
  (| W := M[PA, PB]
   |)
  where
    constant [2] integer PA = [-1, 1];
    constant [2] integer PB = [1, 0];
  end;
