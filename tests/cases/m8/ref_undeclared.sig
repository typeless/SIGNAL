process P =
  ( ! integer N, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := INNER(N)
   |)
  where
    integer ZN;
    process INNER = ( ? integer X; ! integer R; )
      (| R := X + Z |)
      where
        ref Z;
      end;
  end;
