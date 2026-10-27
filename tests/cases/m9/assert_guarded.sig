process ASSERTGUARDED =
  ( ! integer N, E, O; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | C := N modulo 2 = 0
   | D := N > 2
   | H := when D
   | on H :: (| assert(C) |)
   | E := N when not C
   | O := N when D
   | E ^# O
   |)
  where
    integer ZN; boolean C, D; event H;
  end;
