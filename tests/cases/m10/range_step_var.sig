process RANGESTEPVAR =
  ( ? integer I;
    ! integer A; )
  (| R := 1 .. I step 2
   | A := R[0]
   |)
  where
    [4] integer R;
  end;
