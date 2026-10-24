process CONSTRAINT =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := N
   | Y ^= 0 .. N
   |)
  where
    integer ZN, N;
  end;
