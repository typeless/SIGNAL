process PCONV =
  ( ! pointer P; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | P := pointer(N)
   |)
  where
    integer ZN, N;
  end;
