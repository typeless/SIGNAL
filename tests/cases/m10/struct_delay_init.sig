process STRUCTDELAYINIT =
  ( ? integer N;
    ! struct (integer A; integer B;) D; )
  (| S := (N, N * 10)
   | D := S $ 2 init (0, 0)
   |)
  where
    struct (integer A; integer B;) S;
  end;
