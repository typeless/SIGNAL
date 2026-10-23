process CLOCKLOOP =
  ( ! integer N, X; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | X := N when C
   | C := (X default 0) > 2
   | C ^= N
   |)
  where
    integer ZN;
    boolean C;
  end;
