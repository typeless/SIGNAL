process SHIFTSIGNED =
  ( ! integer A; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := N shl 1
   |)
  where
    integer ZN, N;
  end;
