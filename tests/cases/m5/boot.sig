process BOOTED =
  ( ? event START;
    ! integer TOTAL; boolean ODD, SMALL; integer NEGATED; )
  pragmas
    Boot {START}
  end pragmas
  (| LAST := SIZE - 1 when START
   | I := 0 .. LAST
   | iterate I of
       (| R := R[?] + A[I]
        | P := P[?] next I : R
        |)
     with R := 0
     end
   | TOTAL := P[SIZE - 1]
   | ODD := TOTAL modulo 2 = 1
   | SMALL := TOTAL < 10
   | NEGATED := 0 - TOTAL
   |)
  where
    constant integer SIZE = 8;
    constant [SIZE] integer A = [3, 1, 4, 1, 5, 9, 2, 6];
    integer LAST, R;
    [SIZE] integer I, P;
  end;
