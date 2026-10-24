process P =
  ( ! integer Y; )
  (| Y := SUM(T) |)
  where
    constant [3] integer T = [1, 2, 3];
    function SUM = ( ? [3] integer Q; ! integer R; ) (| R := Q[0] |);
  end;
