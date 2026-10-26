process P =
  ( ? integer X; ! integer Y; )
  (| Y := F(X, X > 0) |)
  where
    function F = ( ? integer A; boolean C; ! integer B; ) (| B := A when C |);
  end;
