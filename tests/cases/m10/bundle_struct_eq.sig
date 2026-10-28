process BUNDLESTRUCTEQ =
  ( ? integer N;
    ! bundle (boolean A; boolean B;) E; )
  (| S := (N, N + 1)
   | B := (N, N)
   | E := B == S
   |)
  where
    struct (integer A; integer B;) S;
    bundle (integer A; integer B;) B;
  end;
