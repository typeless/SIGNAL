process PARTIALOUTPUT =
  ( ! integer N, X; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | C := N modulo 2 = 0
   | X ::= N when C
   | X ::= defaultvalue 0
   | X ^= N
   |)
  where
    integer ZN; boolean C;
  end;
