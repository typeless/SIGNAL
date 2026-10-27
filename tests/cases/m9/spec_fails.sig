process SPECFAILS =
  ( ! integer X, Y; )
  spec (| Y ^= X |)
  (| X := ZX + 1
   | ZX := X $ init 0
   | C := X modulo 2 = 0
   | Y := X when C
   |)
  where
    integer ZX; boolean C;
  end;
