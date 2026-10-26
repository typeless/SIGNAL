process P =
  ( ! integer A, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | (A, B) := PAIR(N)
   | Y := B * 10
   |)
  where
    integer ZN, N, B;
    process PAIR = ( ? integer X; ! integer U, V; ) (| U := X | V := X + 1 |);
  end;
