process RANGESTEP =
  ( ? integer I;
    ! integer A, B, C; )
  (| R := 1 .. 7 step 2
   | Q := 10 .. 1 step -3
   | A := R[I]
   | B := Q[I]
   | C := size(R) * 10 + size(Q) + I - I
   |)
  where
    [4] integer R, Q;
  end;
