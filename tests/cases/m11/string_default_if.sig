process STRINGNEST =
  ( ? integer N; ! integer K; )
  (| K := N
   | C1 := N modulo 2 = 1
   | C2 := N > 2
   | S := ("a" when C1) default (if C2 then "b" else "c")
   | W :: writeString(S)
   |)
  where
    boolean C1, C2; string S; label W;
  end;
