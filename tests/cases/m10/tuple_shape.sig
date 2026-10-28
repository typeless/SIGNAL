process TUPLESHAPE =
  ( ? integer N; ! integer T; )
  (| S := (N, N + 1, N + 2)
   | T := S.A
   |)
  where
    struct (integer A; integer B;) S;
  end;
