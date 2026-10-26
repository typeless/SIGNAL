process P =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | on when N = 3 :: (| (A, B) := PAIR(N) |)
   |)
  where
    integer ZN, A, B;
    process PAIR = ( ? integer X; ! integer U, V; ) (| U := X | V := X + 1 |);
  end;
