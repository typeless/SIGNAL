process CHARCOMPARE =
  ( ? char A, B;
    ! boolean LT, LE, GT, GE, EQ, NE, PO, SAME; )
  (| LT := A < B
   | LE := A <= B
   | GT := A > B
   | GE := A >= B
   | EQ := A = B
   | NE := A /= B
   | PO := A <<= B
   | SAME := A == 'a'
   |)
  where
  end;
