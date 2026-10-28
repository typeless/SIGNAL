process DELAYZEROCONSTANT =
  ( ! integer N; integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := N $ K
   |)
  where
    integer ZN;
    constant integer K = 0;
  end;
