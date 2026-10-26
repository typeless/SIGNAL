process COUNTER =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | (| |)
   |)
  where
    integer ZN;
  end;
