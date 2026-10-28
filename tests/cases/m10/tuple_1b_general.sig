process TUPLE1BGENERAL =
  ( ? integer N;
    ! integer W, X, U; boolean V; )
  (| (W, X) := (N + 1, TWICE(N))
   | S := (N * 3, N > 2)
   | (U, V) := S
   |)
  where
    struct (integer A; boolean B;) S;
    function TWICE = ( ? integer I; ! integer O; ) (| O := I * 2 |);
  end;
