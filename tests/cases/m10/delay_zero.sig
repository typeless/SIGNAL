process DELAYZERO =
  ( ! integer N; integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := N $ 0
   |)
  where
    integer ZN;
    constant integer K = 0;
  end;
