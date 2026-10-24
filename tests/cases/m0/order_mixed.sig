process ORDERMIXED =
  ( ! boolean B; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | B := N < (N > 2)
   |)
  where
    integer N, ZN;
  end;
