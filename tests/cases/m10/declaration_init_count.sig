process DECLARATIONINITCOUNT =
  ( ! [3] integer C; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := [N, N, N]
   | C := A $
   |)
  where
    integer ZN, N;
    [3] integer A init [4, 5];
  end;
