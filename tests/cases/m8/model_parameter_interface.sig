process P =
  ( ! integer A; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := APPLY{TWOIN}(N)
   |)
  where
    integer ZN, N;
    type process STEP = ( ? integer X; ! integer Y; );
    process APPLY = { process STEP F; } ( ? integer X; ! integer Y; ) (| Y := F(X) |);
    process TWOIN = ( ? integer X1, X2; ! integer Y; ) (| Y := X1 + X2 |);
  end;
