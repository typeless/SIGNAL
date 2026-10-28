process STRUCTALIASCALL =
  ( ? integer N;
    ! integer A, B, C; )
  (| P := (N, N + 1)
   | Q := SWAP(P)
   | A := Q.X
   | B := Q.Y
   | C := SUM(Q)
   |)
  where
    type POINT = struct (integer X; integer Y;);
    POINT P, Q;
    function SWAP = ( ? POINT U; ! POINT V; ) (| V := (U.Y, U.X) |);
    function SUM = ( ? POINT U; ! integer S; ) (| S := U.X + U.Y |);
  end;
