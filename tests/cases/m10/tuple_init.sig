process TUPLEINIT =
  ( ? integer N; ! integer T; )
  (| S := (N, N)
   | T := S.A
   |)
  where
    struct (integer A; integer B;) S init (0, 0);
  end;
