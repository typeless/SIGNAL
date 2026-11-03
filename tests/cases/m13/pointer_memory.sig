process POINTERMEMORY =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | L1 :: FIRST := load{MEM, ubyte}(pointer(GREETING) when N < 2)
   | W :: write("first ", integer(FIRST))
   | R :: S := read("" when N < 2)
   | P := pointer(S)
   | T :: store{MEM, ubyte}(P + 1, ubyte(90))
   | L2 :: B := load{MEM, ubyte}(P + 1)
   | L3 :: Z := load{MEM, ubyte}(P + 3)
   | V :: write("back ", S)
   | X :: write("bytes ", integer(B) * 1000 + integer(Z))
   | W --> R --> V --> X
   | L1 --> T --> L2 --> L3 --> V
   |)
  where
    type MEM = external;
    constant string GREETING = "hello";
    integer ZN;
    ubyte FIRST, B, Z;
    string S;
    pointer P;
    label L1, W, R, T, L2, L3, V, X;
  end;
