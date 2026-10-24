process CLAMP =
  ( ! integer S; )
  (| X := 0 .. 10
   | iterate X of S := S[?] + X + 1 with S := 0 end
   |)
  where
    [3] integer X;
  end;
