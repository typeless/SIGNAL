process STRUCTWINDOWINIT =
  ( ? integer N;
    ! [2] struct (integer A; integer B;) W; )
  (| S := (N, N * 10)
   | W := S window 2 init [(0, 0), (-1, -1)]
   |)
  where
    struct (integer A; integer B;) S;
  end;
