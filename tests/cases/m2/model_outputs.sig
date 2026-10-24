process P =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := PAIR(N)
   |)
  where
    integer ZN, N;
    process PAIR = ( ? integer X; ! integer A, B; ) (| A := X | B := X |);
  end;
