process LEAFNEVERDEFINED =
  ( ? integer N; ! integer T; )
  (| S.A := N
   | T := S.A
   |)
  where
    struct (integer A; integer B;) S;
  end;
