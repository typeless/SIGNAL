process BUNDLESPECNONFIELD =
  ( ? integer N;
    ! integer O; )
  (| E := N modulo 2 = 0
   | B.EVEN := N when E
   | B.ODD := N when not E
   | FOO := N when not E
   | O := (B.EVEN default B.ODD) + 1
   |)
  where
    boolean E;
    integer FOO;
    bundle (integer EVEN; integer ODD;) spec (| EVEN ^# FOO |) B;
  end;
