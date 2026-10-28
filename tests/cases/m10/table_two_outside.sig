process TWOOUT =
  ( ? [2, 2] integer M;
    ! [2] integer W; )
  (| W := M[PA, PB]
   |)
  where
    constant [2] integer PA = [0, 1];
    constant [2] integer PB = [1, 7];
  end;
