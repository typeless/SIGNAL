process STEPOUT =
  ( ? [4] integer V;
    ! [2] integer W; )
  (| W := V[-1 .. 1 step 2]
   |)
  where
  end;
