process CONSTANTWIDENING =
  ( ! integer N; dreal X; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | X := C when ^N
   |)
  where
    integer ZN;
    constant dreal C = 0.1;
  end;
