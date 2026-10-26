process P =
  ( ! integer A, B; )
  (| N := ZN + 1 | ZN := N $ init 0
   | (A, B) := (N, N + f(N, 1))
   |)
  where
    integer ZN, N;
    function f = ( ? integer X, Y; ! integer Z; ) (| Z := X - Y + 1 |);
  end;
