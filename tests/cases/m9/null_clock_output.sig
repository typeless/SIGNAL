process NULLOUTPUT =
  ( ! integer X, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | C := N modulo 2 = 0
   | X := (N when C) when not C
   | Y := X default N
   |)
  where
    integer N, ZN;
    boolean C;
  end;
