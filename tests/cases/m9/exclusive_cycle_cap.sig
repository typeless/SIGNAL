process EXCLCAP =
  ( ! integer A0; )
  (| C := ZC + 1
   | ZC := C $ init 0
   | P1 := (C modulo 2) = 0
   | P2 := (C modulo 3) = 0
   | P3 := (C modulo 5) = 0
   | P4 := (C modulo 7) = 0
   | P5 := (C modulo 11) = 0
   | A0 := (A1 when P1) default C
   | A1 := (A0 when not P1) default (A2 when P2) default C
   | A2 := (A1 when not P2) default (A3 when P3) default C
   | A3 := (A2 when not P3) default (A4 when P4) default C
   | A4 := (A3 when not P4) default (A5 when P5) default C
   | A5 := (A4 when not P5) default C
   | A0 ^= A1 ^= A2 ^= A3 ^= A4 ^= A5 ^= C
   |)
  where
    integer A1, A2, A3, A4, A5, C, ZC;
    boolean P1, P2, P3, P4, P5;
  end;
