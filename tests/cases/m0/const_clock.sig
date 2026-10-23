process CONSTCLOCK =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | N ^= 1
   |)
  where
    integer ZN;
  end;
