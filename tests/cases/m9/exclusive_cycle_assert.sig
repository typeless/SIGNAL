process EXCLASSERT =
  ( ! integer A, B; )
  (| C := ZC + 1
   | ZC := C $ init 0
   | P := (C modulo 2) = 0
   | Q := (C modulo 2) = 1
   | PS := C when P
   | QS := C when Q
   | assert (| PS ^# QS |)
   | A := ((B + 100) when P) default C
   | B := ((A + 10) when Q) default C
   | A ^= B ^= C
   |)
  where
    integer C, ZC, PS, QS;
    boolean P, Q;
  end;
