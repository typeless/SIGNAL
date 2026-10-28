process TUPLEVALUEARGUMENT =
  ( ? integer N;
    ! integer O; )
  (| O := SUM((N, N + 1))
   |)
  where
    type POINT = struct (integer X; integer Y;);
    function SUM = ( ? POINT U; ! integer S; ) (| S := U.X + U.Y |);
  end;
