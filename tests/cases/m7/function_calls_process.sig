process P =
  ( ? integer X; ! integer Y; )
  (| Y := F(X) |)
  where
    process G = ( ? integer A; ! integer B; ) (| B := A + 1 |);
    function F = ( ? integer A; ! integer B; ) (| B := G(A) |);
  end;
