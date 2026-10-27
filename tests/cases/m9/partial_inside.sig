process PARTIALINSIDE =
  ( ! integer N, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | C := N modulo 2 = 0
   | D := N modulo 3 = 0
   | M := N when D
   | X ::= N when C
   | X ^= M
   | Y := X
   |)
  where
    integer ZN, M; boolean C, D; shared integer X;
  end;
