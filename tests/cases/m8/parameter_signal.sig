process P =
  ( ! integer A; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := SCALE{ZN}(N)
   |)
  where
    integer ZN, N;
    process SCALE = { integer K; } ( ? integer X; ! integer Y; ) (| Y := X * K |);
  end;
