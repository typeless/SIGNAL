process NARROW =
  ( ! short S; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | S := N
   |)
  where
    integer ZN, N;
  end;
