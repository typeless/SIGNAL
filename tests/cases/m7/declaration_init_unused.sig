process COUNTER =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | M := N + 1
   |)
  where
    integer ZN, M init 3;
  end;
