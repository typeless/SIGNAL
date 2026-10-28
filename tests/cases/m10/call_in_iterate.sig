process CALLINITERATE =
  ( ? [4] integer T;
    ! integer R; [4] integer D; )
  (| array I to 3 of
       R := op(T[I], R[?])
     with R := 0
     end
   | array J to 3 of
       D[J] := twice(T[J])
     end
   |)
  where
    function op =
      ( ? integer a, b;
        ! integer c; )
      (| c := a + 2 * b |);
    function twice =
      ( ? integer x;
        ! integer y; )
      (| y := x + x |);
  end;
