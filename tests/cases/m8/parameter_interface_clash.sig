process P =
  ( ! integer A; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := SCALE{1}(N)
   |)
  where
    integer ZN, N;
    process SCALE = { integer K; } ( ? integer K; ! integer Y; ) (| Y := K * K |);
  end;
