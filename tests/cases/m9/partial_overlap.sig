process PARTIALOVERLAP =
  ( ! integer N, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | C := N modulo 2 = 0
   | D := N modulo 3 = 0
   | X ::= N when C
   | X ::= N when D
   | X ^= N
   | Y := X
   |)
  where
    integer ZN; boolean C, D; shared integer X;
  end;
