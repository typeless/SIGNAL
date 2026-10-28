process STRUCTIDENTITY =
  ( ? integer N;
    ! integer O, P; )
  (| S := (N, N + 1)
   | T :=: S
   | O := T.B
   | P := T.A * 10
   |)
  where
    struct (integer A; integer B;) S, T;
  end;
