process STRUCTIDENTITYKIND =
  ( ? integer N;
    ! integer O; )
  (| S := (N, N + 1)
   | T :=: S
   | O := T.B
   |)
  where
    struct (integer A; integer B;) S;
    bundle (integer A; integer B;) T;
  end;
