process P =
  ( ? integer X; ! integer Y; )
  (| Y := F(X, X > 0) |)
  where
    function F = ( ? integer A; boolean B; ! integer C; ) (| C := A cell B |);
  end;
