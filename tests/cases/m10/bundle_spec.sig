process BUNDLESPEC =
  ( ? integer N;
    ! bundle (integer EVEN; integer ODD;) spec (| EVEN ^# ODD |) B; integer C; )
  (| E := N modulo 2 = 0
   | B.EVEN := N when E
   | B.ODD := N * 10 when not E
   | C := (B.EVEN default B.ODD) + 1
   |)
  where
    boolean E;
  end;
