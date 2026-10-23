process RESET =
  ( ! integer N; boolean R; )
  (| T := ZT + 1
   | ZT := T $ init 0
   | R := T modulo 4 = 0
   | N := (0 when R) default (ZN + 1)
   | ZN := N $ init 0
   | N ^= T
   |)
  where
    integer T, ZT, ZN;
  end;
