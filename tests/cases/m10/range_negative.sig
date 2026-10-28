process RANGENEGATIVE =
  ( ! integer A; )
  (| I := -2 .. -1
   | iterate I of
       A := A[?] * 10 + I + 5
     with A := 0
     end
   |)
  where
    [2] integer I;
  end;
