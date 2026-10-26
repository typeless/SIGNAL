process COUNTER =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init M
   | M := 5
   |)
  where
    integer ZN, M;
  end;
