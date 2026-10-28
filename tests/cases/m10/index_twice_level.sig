process TWICE =
  ( ! integer A; )
  (| I := indices(2)
   | iterate I of
       iterate I of
         A := A[?] + I
       end
     with A := 0
     end
   |)
  where
    [2] integer I;
  end;
