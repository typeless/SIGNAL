process DECLARATIONINITNESTING =
  ( ! [2, 2] integer C; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | C := A $
   |)
  where
    integer ZN, N;
    [2, 2] integer A init [1, 2, 3, 4];
  end;
