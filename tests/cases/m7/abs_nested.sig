process P =
  ( ? integer X; ! integer Y, Z; )
  (| Y := abs(G(X, 5))
   | Z := abs(abs(X) - 5) |)
  where
    function G = ( ? integer A, B; ! integer C; ) (| C := A - B |);
  end;
