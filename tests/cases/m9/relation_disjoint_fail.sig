process RELDISJOINTFAIL =
  ( ! integer N, E, O; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | C := N modulo 2 = 0
   | D := N > 2
   | E := N when C
   | O := N when D
   | E ^# O
   |)
  where
    integer ZN;
    boolean C, D;
  end;
