process PARTIALCONST =
  ( ! integer N, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | C := N modulo 2 = 0
   | X ::= N when C
   | X ::= 5
   | X ^= N
   | Y := X
   |)
  where
    integer ZN; boolean C; shared integer X;
  end;
