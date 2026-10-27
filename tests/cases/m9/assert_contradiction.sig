process ASSERTCONTRADICTION =
  ( ! integer N, E, O; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | E := N when C
   | O := N when D
   | C := N modulo 2 = 0
   | D := C
   | assert(C)
   | assert(not C)
   | E ^# O
   |)
  where
    integer ZN; boolean C, D;
  end;
