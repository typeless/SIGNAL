process COUNTER =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init 0
   |) / Q
  where
    integer ZN;
  end;
