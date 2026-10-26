process P =
  ( ! integer A; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := DOUBLE(N)
   |)
  where
    integer ZN, N;
    process DOUBLE = ( ? integer X; ! integer Y; ) safe (| Y := X * 2 |);
  end;
