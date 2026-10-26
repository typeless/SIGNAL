process P =
  ( ! integer A; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := APPLY{DOUBLE}(N)
   |)
  where
    integer ZN, N;
    type process STEP = ( ? integer X; ! integer Y; );
    process APPLY = { process STEP F; } ( ? integer X; ! integer Y; ) (| Y := F(X) |);
    function DOUBLE = STEP (| Y := X * 2 |);
  end;
