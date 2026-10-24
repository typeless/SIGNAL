process IFCOND =
  ( ! integer X; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | X := if N then 1 else 2
   |)
  where
    integer ZN, N;
  end;
