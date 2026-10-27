process IDLONG =
  ( ! integer N; long X, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | X :=: N + 1
   | Y := X * long(4294967296)
   |)
  where
    integer ZN;
  end;
