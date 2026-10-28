process TABLEOUT =
  ( ? [3] integer V;
    ! [2] integer W; )
  (| W := V[K]
   |)
  where
    constant [2] integer K = [0, 5];
  end;
