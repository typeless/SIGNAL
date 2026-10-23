process RESETFREE =
  ( ! integer T, N; )
  (| T := ZT + 1
   | ZT := T $ init 0
   | R := T modulo 4 = 0
   | N := (0 when R) default (ZN + 1)
   | ZN := N $ init 0
   |)
  where
    integer ZT, ZN;
    boolean R;
  end;
