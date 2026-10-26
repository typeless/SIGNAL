process P =
  ( ! integer N, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := INNER(N)
   |)
  where
    integer ZN;
    process INNER = ( ? integer X; ! integer R; )
      (| R := TWICE(X) + ZN |)
      where
        process TWICE = ( ? integer A; ! integer B; ) (| B := A * 2 |);
        ref ZN;
      end;
  end;
