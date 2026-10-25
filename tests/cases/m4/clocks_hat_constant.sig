process HC =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := N
   | E := ^3
   |)
  where
    integer ZN, N;
    event E;
  end;
