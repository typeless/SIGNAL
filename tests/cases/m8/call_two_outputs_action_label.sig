process P =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | L :: (A, B) := PAIR(N)
   | M :: Y := A + B
   | L --> M
   |)
  where
    integer ZN, N, A, B;
    label L, M;
    process PAIR = ( ? integer X; ! integer U, V; ) (| U := X | V := X + 1 |);
  end;
