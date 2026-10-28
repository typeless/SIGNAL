process STRUCTENUMALIASTWICE =
  ( ? integer N;
    ! integer O; )
  (| P := (N, N + 1)
   | O := P.X
   |)
  where
    type POINT = struct (integer X; integer Y;);
    type POINT = enum (RED, GREEN);
    POINT P;
  end;
