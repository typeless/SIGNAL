process P =
  ( ! integer A; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := SCALE{1}(N)
   |)
  where
    integer ZN, N;
    process SCALE = { integer K; } ( ? integer X; ! integer Y; ) (| Y := X * K | K := 1 |);
  end;
