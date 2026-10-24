process SAMEWIDTH =
  ( ! uinteger U; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | U := N
   |)
  where
    integer ZN, N;
  end;
