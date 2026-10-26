process P =
  ( ! integer A; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := SCALE{300}(N)
   |)
  where
    integer ZN, N;
    process SCALE = { ubyte K; } ( ? integer X; ! integer Y; ) (| Y := X * integer(K) |);
  end;
