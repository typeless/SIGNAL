process STRINGNEST =
  ( ? integer N; ! integer K; )
  (| K := N
   | C1 := N modulo 2 = 1
   | C2 := N > 2
   | S := (if C1 then "a" else "b") default ("c" when ^N)
   | W :: writeString(S)
   |)
  where
    boolean C1, C2; string S; label W;
  end;
