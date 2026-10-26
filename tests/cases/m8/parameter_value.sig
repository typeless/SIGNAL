process P =
  ( ! integer A, B; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := SCALE{3}(N)
   | B := SCALE{KK}(N)
   |)
  where
    integer ZN, N;
    constant integer KK = 5;
    process SCALE = { integer K; } ( ? integer X; ! integer Y; ) (| Y := X * K |);
  end;
