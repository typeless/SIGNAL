process STRINGNEST =
  ( ? integer N; ! integer K; )
  (| K := N
   | C1 := N modulo 2 = 1
   | C2 := N > 2
   | S := ((if C1 then "a" else "b") when C1) default ((if C2 then "c" else "d") when ^N)
   | T := if C2 then (if C1 then "e" else "f") else (if C1 then "g" else "h")
   | U := (if C1 then S else T) when C2
   | W :: write(S, T)
   | V :: write("u=", U)
   | W --> V
   |)
  where
    boolean C1, C2; string S, T, U; label W, V;
  end;
