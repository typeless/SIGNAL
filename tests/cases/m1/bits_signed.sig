process BITSSIGNED =
  ( ! integer A; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := N and 3
   |)
  where
    integer ZN, N;
  end;
