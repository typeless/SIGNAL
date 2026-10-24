process P =
  ( ? integer X; ! integer Y; )
  (| Y := X + 1
   | B := (N modulo 2 = 0)
   | N := ZN + 1
   | ZN := N $ init 0
   | X ^= when B
   |)
  where
    integer ZN, N;
    boolean B;
  end;
