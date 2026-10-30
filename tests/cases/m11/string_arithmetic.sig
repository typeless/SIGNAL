process STRINGARITHMETIC =
  ( ? integer N; ! boolean B; )
  (| S := "a" when N > 0
   | T := S + S
   | B := T = S
   |)
  where
    string S, T;
  end;
