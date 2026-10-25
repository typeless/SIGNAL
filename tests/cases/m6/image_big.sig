process BIG =
  ( ? event START;
    ! integer TOTAL; )
  pragmas
    Machine "mps2-an385"
    Boot {START}
  end pragmas
  (| LAST := SIZE - 1 when START
   | I := 0 .. LAST
   | iterate I of
       (| R := R[?] + 1
        | P := P[?] next I : R
        |)
     with R := 0
     end
   | TOTAL := P[SIZE - 1]
   |)
  where
    constant integer SIZE = 1100000;
    integer LAST, R;
    [SIZE] integer I, P;
  end;
