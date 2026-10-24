process START =
  ( ! integer S; )
  (| X := 1 .. 4
   | iterate X of S := S[?] + X with S := 0 end
   |)
  where
    [8] integer X;
  end;
