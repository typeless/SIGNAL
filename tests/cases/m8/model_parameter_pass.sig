process P =
  ( ! integer A, B; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := OUTER{TRIPLE}(N)
   | B := OUTER{INCREMENT}(N)
   |)
  where
    integer ZN, N;
    type process STEP = ( ? integer X; ! integer Y; );
    type process SAME = STEP;
    process APPLY = { process STEP F; } ( ? integer X; ! integer Y; ) (| Y := F(X) + 100 |);
    process OUTER = { process SAME G; } ( ? integer X; ! integer Y; ) (| Y := APPLY{G}(X) |);
    function TRIPLE = ( ? integer X; ! integer Y; ) (| Y := X * 3 |);
    node INCREMENT = SAME (| Y := X + 1 |);
  end;
