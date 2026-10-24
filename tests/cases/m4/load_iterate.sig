process SUM =
  ( ! integer S; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | FIRST := N = 1
   | MAPPED := syscall{OS}(197, 0 when FIRST, 16384, 1, 2, 0, 0)
   | P := pointer(ulong(MAPPED))
   | I := indices(6)
   | I ^= MAPPED
   | iterate I of
       (| B := load{FILE, ubyte}(P + I)
        | S := S[?] + integer(B)
        |)
     with S := 0
     end
   | DONE := syscall{OS}(1, 0 when N = 2, 0, 0, 0, 0, 0)
   | MAPPED --> DONE
   |)
  where
    type OS = external;
    type FILE = external;
    integer ZN, N;
    boolean FIRST;
    long MAPPED, DONE;
    pointer P;
    ubyte B;
    [6] integer I;
  end;
