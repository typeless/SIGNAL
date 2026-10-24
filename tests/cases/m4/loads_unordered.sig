process TWICE =
  ( ! integer S; )
  (| P := pointer(ulong(4096))
   | I := indices(3)
   | iterate I of
       (| A := load{MEM, ubyte}(P + I)
        | B := load{MEM, ubyte}(P + I + 1)
        | S := integer(A) + integer(B)
        |)
     end
   |)
  where
    type MEM = external;
    pointer P;
    ubyte A, B;
    [3] integer I;
  end;
