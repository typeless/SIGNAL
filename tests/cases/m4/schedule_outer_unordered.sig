process OUTER =
  ( ! integer S; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | FIRST := N = 1
   | MAPPED := syscall{OS}(197, 0 when FIRST, 16384, 1, 2, 0, 0)
   | P := pointer(ulong(MAPPED))
   | I := indices(3)
   | I ^= MAPPED
   | J := indices(3)
   | J ^= MAPPED
   | iterate I of
       (| A := load{FILE, ubyte}(P + I)
        | T := T[?] + integer(A)
        |)
     with T := 0
     end
   | iterate J of
       (| B := load{FILE, ubyte}(P + J + 3)
        | C := J
        | S := S[?] + integer(B) + C
        |)
     with S := 0
     end
   | DONE := syscall{OS}(1, 0 when N = 2, 0, 0, 0, 0, 0)
   | MAPPED --> DONE
   |)
  where
    type OS = external;
    type FILE = external;
    integer ZN, N, T, C;
    boolean FIRST;
    long MAPPED, DONE;
    pointer P;
    ubyte A, B;
    [3] integer I, J;
  end;
