process OUTERCOUNT =
  ( ? integer K; ! integer S, C; )
  (| I := 0 .. K
   | J := indices(3)
   | iterate I of
       iterate J of
         (| S := S[?] + I * 3 + J
          | C := C[?] + 1
          |)
       end
     with (| S := 0 | C := 0 |)
     end
   |)
  where
    [4] integer I;
    [3] integer J;
  end;
