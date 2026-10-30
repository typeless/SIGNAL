process STRINGCASECONSTANT =
  ( ? integer N; ! integer K; )
  (| K := N
   | S := if N > 2 then "ab" else "cd"
   | case S in {AB}: K2 ::= 1 else K2 ::= 2 end
   | K2 ^= N
   | W :: write("", K2)
   |)
  where
    constant string AB = "ab";
    string S; label W; shared integer K2;
  end;
