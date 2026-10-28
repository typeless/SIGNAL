process STRUCTLE =
  ( ? integer N;
    ! boolean E; )
  (| S := (N, N > 1)
   | T := (1, true) when ^N
   | E := S <<= T
   |)
  where
    struct (integer A; boolean B;) S, T;
  end;
