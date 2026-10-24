process INSIDE =
  ( ! integer S; )
  (| I := indices(2)
   | iterate I of
       (| X := 0 .. I
        | S := S[?] + I
        |)
     with S := 0
     end
   |)
  where
    [2] integer I;
    [8] integer X;
  end;
