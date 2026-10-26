process P =
  ( ! integer N, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := MID(N)
   |)
  where
    integer ZN;
    process MID = ( ? integer X; ! integer R; ) (| R := INNER(X) * 10 |);
    process INNER = ( ? integer X; ! integer R; )
      (| R := X + ZN |)
      where
        ref ZN;
      end;
  end;
