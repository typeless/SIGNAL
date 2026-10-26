process P =
  ( ! integer A; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := LOOPER{BACK}(N)
   |)
  where
    integer ZN, N;
    type process STEP = ( ? integer X; ! integer Y; );
    process LOOPER = { process STEP F; } ( ? integer X; ! integer Y; ) (| Y := F(X) |);
    process BACK = ( ? integer X; ! integer Y; ) (| Y := LOOPER{BACK}(X) |);
  end;
