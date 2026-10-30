process WRITEMESSAGE =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | writeString(N)
   |)
  where
    integer ZN;
  end;
