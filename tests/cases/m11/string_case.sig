process STRINGCASE =
  ( ? integer N; ! integer K; )
  (| K := N
   | S := "ab" when ^N
   | case S in {"ab"}: K2 ::= 1 else K2 ::= 2 end
   | W :: write("", K2)
   |)
  where
    string S; label W; shared integer K2;
  end;
