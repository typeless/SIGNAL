process PRODUCT =
  ( ! integer A; )
  (| I := indices(65536)
   | J := indices(65536)
   | iterate I of
       iterate J of
         A := A[?] + 1
       end
     with A := 0
     end
   |)
  where
    [65536] integer I, J;
  end;
