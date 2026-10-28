process TYPERANKTWO =
  ( ! [2, 3] integer C; )
  (| C := Z
   |)
  where
    constant [3, 2] integer Z = [[1, 2], [3, 4], [5, 6]];
  end;
