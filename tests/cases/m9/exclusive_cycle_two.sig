process EXCLTWO =
  ( ! integer A, B, D; )
  (| C := ZC + 1
   | ZC := C $ init 0
   | P := (C modulo 2) = 0
   | Q := (C modulo 3) = 0
   | A := ((B + 100) when P) default C
   | B := ((A + 10) when not P) default ((D + 1000) when Q) default C
   | D := ((B + 1) when not Q) default C
   | A ^= B ^= D ^= C
   |)
  where
    integer C, ZC;
    boolean P, Q;
  end;
