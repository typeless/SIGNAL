process PARTIALDELAY =
  ( ! integer N, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | C := N modulo 2 = 0
   | X ::= N when C
   | X ::= defaultvalue 0
   | ZX := X $ init 0
   | ZX ^= N
   | Y := X
   |)
  where
    integer ZN, ZX; boolean C; shared integer X;
  end;
