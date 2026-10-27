process ASSERTTWODEFINITIONS =
  ( ! integer N, X; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | C := N modulo 2 = 0
   | D := N > 2
   | X := N when C
   | X ^= N when D
   | assert (| when C ^= when D |)
   |)
  where
    integer ZN; boolean C, D;
  end;
