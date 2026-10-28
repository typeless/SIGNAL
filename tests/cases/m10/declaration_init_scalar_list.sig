process DECLARATIONINITSCALARLIST =
  ( ! integer C; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | C := S $
   |)
  where
    integer ZN, N;
    integer S init [1];
  end;
