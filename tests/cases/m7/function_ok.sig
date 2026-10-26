process P =
  ( ? integer X; ! integer Y, Z; )
  (| Y := MAG(X)
   | Z := if X < 0 then -X else X
   |)
  where
    function MAG = ( ? integer A; ! integer B; ) (| B := if A < 0 then -A else A |);
  end;
