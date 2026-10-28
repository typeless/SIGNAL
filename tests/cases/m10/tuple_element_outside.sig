process TUPLEELEMENTOUTSIDE =
  ( ? integer A;
    ! [2] integer Q; integer R; )
  (| (Q[0], R) := divide(A, 3)
   | Q[1] := 0
   |)
  where
    function divide =
      ( ? integer n, d;
        ! integer q, r; )
      (| q := n / d
       | r := n modulo d
       |);
  end;
