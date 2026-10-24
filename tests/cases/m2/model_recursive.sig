process P =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := AGAIN(N)
   |)
  where
    integer ZN, N;
    process AGAIN = ( ? integer X; ! integer Z; ) (| Z := AGAIN(X) |);
  end;
