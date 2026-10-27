process PARTIALMINOVER =
  ( ! integer N, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | C := N modulo 2 = 0
   | D := N modulo 3 = 0
   | X ::= N when C
   | X ::= N * 10 when D
   | min_clock(X)
   | Y := X
   |)
  where
    integer ZN; boolean C, D; shared integer X;
  end;
