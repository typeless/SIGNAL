process SCATOUT =
  ( ? [2] integer A;
    ! [3] integer W; )
  (| W := K : A
   |)
  where
    constant [2] integer K = [0, 5];
  end;
