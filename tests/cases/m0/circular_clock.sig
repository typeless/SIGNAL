process CIRC =
  ( ! integer A; )
  (| C := ZC + 1
   | ZC := C $ init 0
   | P := (C modulo 2) = 0
   | A := B when P
   | B := A when P
   |)
  where
    integer B, C, ZC;
    boolean P;
  end;
