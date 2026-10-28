process WINDOWZERO =
  ( ! integer N; [1] integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := N window 0
   |)
  where
    integer ZN;
    constant integer K = 0;
  end;
