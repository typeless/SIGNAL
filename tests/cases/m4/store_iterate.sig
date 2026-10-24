process LETTERS =
  ( ! )
  (| N := ZN + 1
   | ZN := N $ init 0
   | FIRST := N = 1
   | MAPPED := syscall{OS}(197, 0 when FIRST, 16384, 3, 4098, -1, 0)
   | P := pointer(ulong(MAPPED))
   | I := indices(5)
   | I ^= MAPPED
   | iterate I of
       (| store{BUFFER, ubyte}(P + I, ubyte(65 + I))
        | LAST := I
        |)
     end
   | NEWLINE :: store{BUFFER, ubyte}(P + 5, ubyte(10))
   | WRITTEN := syscall{OS}(4, 1, P, 6, 0, 0, 0)
   | DONE := syscall{OS}(1, 0 when N = 2, 0, 0, 0, 0, 0)
   | LAST --> NEWLINE
   | NEWLINE --> WRITTEN
   | WRITTEN --> DONE
   |)
  where
    type OS = external;
    type BUFFER = external;
    integer ZN, N, LAST;
    boolean FIRST;
    label NEWLINE;
    long MAPPED, WRITTEN, DONE;
    pointer P;
    [5] integer I;
  end;
