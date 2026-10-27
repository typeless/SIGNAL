process RELMIXED =
  ( ! integer N, Y, X; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | C1 := N modulo 2 = 0
   | C2 := N modulo 4 = 0
   | Y := N when C1
   | X := Y when C2
   | X ^< Y ^# N
   |)
  where
    integer ZN;
    boolean C1, C2;
  end;
