process IDTYPEBOOL =
  ( ! integer N, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | B :=: N + 1
   | Y := N when B
   |)
  where
    integer ZN; boolean B;
  end;
