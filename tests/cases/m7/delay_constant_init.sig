process COUNTER =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init START
   |)
  where
    constant integer START = 5;
    integer ZN;
  end;
