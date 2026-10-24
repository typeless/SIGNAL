process BOUND =
  ( ! integer S; )
  (| X := 0 .. true
   | iterate X of S := S[?] + X with S := 0 end
   |)
  where
    [8] integer X;
  end;
