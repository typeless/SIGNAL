process FIELDUNKNOWN =
  ( ? integer N; ! integer T; )
  (| S := (N, N + 1)
   | T := S.C
   |)
  where
    struct (integer A; integer B;) S;
  end;
