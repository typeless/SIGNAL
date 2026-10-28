process STRUCTNAMEDTWICE =
  ( ? integer N;
    ! integer O; )
  (| P := (N, N)
   | O := P.A
   |)
  where
    type COLOR = enum (RED, GREEN);
    struct (integer A; integer B;) P;
    COLOR P;
  end;
