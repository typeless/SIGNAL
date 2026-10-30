process STRINGVAR =
  ( ? integer N; ! integer K; boolean E; )
  (| K := N
   | S := if N > 2 then "big" else "small"
   | V := var S
   | P ::= "even" when C
   | P ::= "odd" when not C
   | C := N modulo 2 = 0
   | E := V = P
   | V ^= N
   | A :: write("v=", V when ^N)
   | B :: write("p=", P)
   | W := S when C
   | Q := W cell C init "none"
   | D :: writeString(Q)
   | A --> B --> D
   |)
  where
    string S, V, Q, W;
    boolean C;
    shared string P;
    label A, B, D;
  end;
