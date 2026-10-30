process STRINGBRANCHES =
  ( ? integer N; ! integer K; )
  (| K := N
   | C1 := N modulo 2 = 1
   | C2 := N > 2
   | X := "x" when C2
   | Y := "y" when not C2
   | S := if C1 then (if C2 then "a" else "b") else (X default "q")
   | W :: writeString(S)
   |)
  where
    boolean C1, C2; string S, X, Y; label W;
  end;
