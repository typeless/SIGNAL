process CONTAIN =
  ( ! integer Y; )
  (| C := ZC + 1
   | ZC := C $ init 0
   | P := (C modulo 2) = 0
   | Y := C default ZC
   | Y ^= C when P
   |)
  where
    integer C, ZC;
    boolean P;
  end;
