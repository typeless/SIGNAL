process TEXT =
  ( ! ubyte B; )
  (| B := S[0] |)
  where
    constant [1] ubyte S = "\400";
  end;
