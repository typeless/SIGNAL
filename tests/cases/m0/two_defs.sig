process TWODEF =
  ( ! integer Y; )
  (| T := ZT + 1
   | ZT := T $ init 0
   | C := T > 2
   | D := T > 4
   | Y := T when C
   | Y ^= T when D
   |)
  where
    integer T, ZT;
    boolean C, D;
  end;
