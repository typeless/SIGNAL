process P =
  ( ! integer Y; )
  (| Y := SUM(1) |)
  where
    function SUM = ( ? integer P; ! integer R; ) (| R := P |);
  end;
