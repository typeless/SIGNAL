process EXCL =
  ( ! integer A; )
  (| C := ZC + 1
   | ZC := C $ init 0
   | P := (C modulo 2) = 0
   | A := (B when P) default C
   | B := (A when not P) default C
   | A ^= B ^= C
   |)
  where
    integer B, C, ZC;
    boolean P;
  end;
