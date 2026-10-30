process STRINGIFCHAIN =
  ( ? integer N; ! integer K; )
  (| K := N
   | C1 := N modulo 2 = 1
   | C2 := N > 2
   | S := if C1 and C2 then "a" else if C1 then "b" else if C2 then "c" else "d"
   | T := if C1 then (if C2 then "e" else "f") else "g"
   | U := if C1 then "h" else (("i" when C2) default "j")
   | A :: writeString(S)
   | B :: write("t=", T)
   | D :: write("u=", U)
   | A --> B --> D
   |)
  where
    boolean C1, C2; string S, T, U; label A, B, D;
  end;
