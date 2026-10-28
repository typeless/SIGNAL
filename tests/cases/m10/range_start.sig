process RANGESTART =
  ( ! integer A; )
  (| I := 3 .. 5
   | iterate I of
       A := A[?] * 10 + I
     with A := 0
     end
   |)
  where
    [3] integer I;
  end;
