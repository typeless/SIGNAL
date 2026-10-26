process TEXT =
  ( ! ubyte B; )
  (| B := S[0] |)
  where
    constant [2] ubyte S = "a\qb";
  end;
