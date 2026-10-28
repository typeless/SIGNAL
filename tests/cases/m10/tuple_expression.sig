process TUPLEEXPRESSION =
  ( ? integer N; ! integer T; )
  (| S := (N, N + 1)
   | T := S + 1
   |)
  where
    struct (integer A; integer B;) S;
  end;
