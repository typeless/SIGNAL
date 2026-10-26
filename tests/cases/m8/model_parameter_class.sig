process P =
  ( ! integer A; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := APPLY{PLAIN}(N)
   |)
  where
    integer ZN, N;
    type function STEP = ( ? integer X; ! integer Y; );
    process APPLY = { function STEP F; } ( ? integer X; ! integer Y; ) (| Y := F(X) |);
    process PLAIN = ( ? integer X; ! integer Y; ) (| Y := X |);
  end;
