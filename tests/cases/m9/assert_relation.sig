process ASSERTRELATION =
  ( ! integer N, E, O; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | E := N when C
   | O := N when D
   | C := N modulo 2 = 0
   | D := N > 2
   | assert (| E ^# O |)
   | E ^# O
   |)
  where
    integer ZN; boolean C, D;
  end;
