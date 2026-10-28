process TUPLECALLINITERATE =
  ( ? [4] integer A;
    ! [4] integer Q, R; integer LARGEST; )
  (| array I to 3 of
       (Q[I], R[I], LARGEST) := divide(A[I], 3, LARGEST[?])
     with LARGEST := -1
     end
   |)
  where
    function divide =
      ( ? integer n, d, m;
        ! integer q, r, k; )
      (| q := n / d
       | r := n modulo d
       | k := if n > m then n else m
       |);
  end;
