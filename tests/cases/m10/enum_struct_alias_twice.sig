process ENUMSTRUCTALIASTWICE =
  ( ? integer N;
    ! integer O; )
  (| P := (N, N + 1)
   | O := P.X
   |)
  where
    type POINT = enum (RED, GREEN);
    type POINT = struct (integer X; integer Y;);
    POINT P;
  end;
