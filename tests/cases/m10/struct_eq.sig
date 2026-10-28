process STRUCTEQ =
  ( ? integer N;
    ! boolean E, F; )
  (| S := (N modulo 2, N > 1)
   | T := (1, true) when ^N
   | E := S == T
   | F := (S == T) or (N = 0)
   |)
  where
    struct (integer A; boolean B;) S, T;
  end;
