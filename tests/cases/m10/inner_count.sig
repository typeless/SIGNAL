process INNERCOUNT =
  ( ? integer K; ! integer A; )
  (| I := indices(2)
   | J := 0 .. K
   | iterate I of
       iterate J of
         A := A[?] + 1
       end
     with A := 0
     end
   |)
  where
    [2] integer I;
    [4] integer J;
  end;
