process STRINGLONGPATHS =
  ( ? integer N; ! integer K; )
  (| K := N
   | S := if N modulo 3 = 0 then LA else if N modulo 3 = 1 then LB else LC
   | Z := S $ init LD
   | W := S when N modulo 2 = 1
   | C := W cell (N > 1) init LD
   | V := var W
   | V ^= N
   | E := N modulo 2 = 0
   | P ::= LA when E
   | P ::= "ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc3" when not E
   | P ^= N
   | (T, U) := INNER(S)
   | A :: writeString(Z)
   | B :: write("c=", C)
   | D :: write("v=", V)
   | F :: writeString(P)
   | G :: write("t=", T)
   | H :: write("u=", U)
   | A --> B --> D --> F --> G --> H
   |)
  where
    constant string LA = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1";
    constant string LB = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb2";
    constant string LC = "ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc3";
    constant string LD = "ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd4";
    string S, Z, W, C, V, T, U;
    boolean E;
    shared string P;
    label A, B, D, F, G, H;
    process INNER =
      ( ? string INS; ! string OUT, OUT2; )
      (| OUT := INS
       | OUT2 := if INS = LA then "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb2" else INS
       |)
      where
      end;
  end;
