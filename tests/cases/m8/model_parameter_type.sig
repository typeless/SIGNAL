process P =
  ( ! integer A; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := APPLY{WIDE}(N)
   |)
  where
    integer ZN, N;
    type process STEP = ( ? integer X; ! integer Y; );
    process APPLY = { process STEP F; } ( ? integer X; ! integer Y; ) (| Y := F(X) |);
    process WIDE = ( ? integer X; ! long Y; ) (| Y := long(X) |);
  end;
