process PARTSAMPLED =
  ( ! integer N, Z; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | P := N modulo 2 = 0
   | X := N when P
   | B := X modulo 3 = 0
   | Y := (N when B) default (N when not B)
   | Z := Y + X
   |)
  where
    integer ZN, X, Y;
    boolean P, B;
  end;
