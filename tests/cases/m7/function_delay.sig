process P =
  ( ? integer X; ! integer Y; )
  (| Y := F(X) |)
  where
    function F = ( ? integer A; ! integer B; ) (| B := A $ init 0 |);
  end;
