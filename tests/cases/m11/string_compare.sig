process STRINGCOMPARE =
  ( ? integer N, M;
    ! boolean EQ, SAME, NE, LT, LE, GT, GE, PO; )
  (| A := if N = 0 then "" else if N = 1 then "ab" else if N = 2 then "abc" else "ab\xFF"
   | B := if M = 0 then "" else if M = 1 then "ab" else if M = 2 then "abc" else "ab\xFF"
   | EQ := A = B
   | SAME := A == B
   | NE := A /= B
   | LT := A < B
   | LE := A <= B
   | GT := A > B
   | GE := A >= B
   | PO := A <<= B
   |)
  where
    string A, B;
  end;
