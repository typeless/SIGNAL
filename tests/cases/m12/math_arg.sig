process MATHARG =
  ( ? complex A; dcomplex C;
    ! real T; dreal TD; )
  (| T := arg(A)
   | TD := argd(C)
   | A ^= C
   |)
  where
  end;
