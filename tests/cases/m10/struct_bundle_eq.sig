process STRUCTBUNDLEEQ =
  ( ? integer N;
    ! boolean E; )
  (| S := (N, N)
   | B := (N, N)
   | E := S == B
   |)
  where
    struct (integer A; integer B;) S;
    bundle (integer A; integer B;) B;
  end;
