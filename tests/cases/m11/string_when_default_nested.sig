process STRINGWHENDEFAULT =
  ( ? integer N; ! integer K; )
  (| K := N
   | C1 := N modulo 2 = 1
   | C2 := N > 2
   | X := "x" when C2
   | Y := "y" when not C2
   | S := (("a" when C1) default ("b" when C2)) default (("c" when C2) default ("d" when ^N))
   | T := (X when C1) default (Y default ("e" when ^N))
   | U := ("f" when C1) default (("g" default "h") when C2)
   | V := (X default Y) default ("i" when ^N)
   | A :: writeString(S)
   | B :: write("t=", T)
   | D :: write("u=", U)
   | E :: write("v=", V)
   | A --> B --> D --> E
   |)
  where
    boolean C1, C2; string S, T, U, V, X, Y; label A, B, D, E;
  end;
