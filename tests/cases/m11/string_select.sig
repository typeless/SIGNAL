process STRINGSELECT =
  ( ? integer N; ! integer K; )
  (| K := N
   | S := if N modulo 2 = 0 then "even" else "odd"
   | Z := S $ init "start"
   | W := S when N > 1
   | D := W default ("small" when ^N)
   | C := S cell (N > 3) init "none"
   | A :: writeString(Z)
   | B :: write("d=", D)
   | E :: write("c=", C when ^N)
   | A --> B --> E
   |)
  where
    string S, Z, W, D, C;
    label A, B, E;
  end;
