process P =
  ( ! integer A; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | (A, B, C) := PAIR(N)
   |)
  where
    integer ZN, N, B, C;
    process PAIR = ( ? integer X; ! integer U, V; ) (| U := X | V := X + 1 |);
  end;
