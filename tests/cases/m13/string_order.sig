process STRINGORDER =
  ( ? integer I, J;
    ! boolean EQ, NE, LT, LE, GT, GE; )
  (| A := if I = 0 then "" else if I = 1 then "ab" else if I = 2 then "ab\0" else if I = 3 then "ab\0c" else if I = 4 then "a\0" else "ab\xFF"
   | B := if J = 0 then "" else if J = 1 then "ab" else if J = 2 then "ab\0" else if J = 3 then "ab\0c" else if J = 4 then "a\0" else "ab\xFF"
   | EQ := A = B
   | NE := A /= B
   | LT := A < B
   | LE := A <= B
   | GT := A > B
   | GE := A >= B
   |)
  where
    string A, B;
  end;
