process P =
  ( ! integer A, B; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := OUTER{3, 1}(N)
   | B := OUTER{KK, 2}(N)
   |)
  where
    integer ZN, N;
    constant integer KK = 5;
    process OUTER = { integer K; short D; } ( ? integer X; ! integer Y; ) (| Y := SCALE{K}(X) + D |);
    process SCALE = { integer K; } ( ? integer X; ! integer Y; ) (| Y := X * K |);
  end;
