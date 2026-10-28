process RANGEEND =
  ( ? integer K; ! integer A; )
  (| I := 1 .. K
   | iterate I of
       A := A[?] + I
     with A := 0
     end
   |)
  where
    [4] integer I;
  end;
