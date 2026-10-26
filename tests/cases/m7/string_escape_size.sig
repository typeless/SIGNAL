process TEXT =
  ( ! ubyte B; )
  (| B := S[0] |)
  where
    constant [5] ubyte S = "a\nbc";
  end;
