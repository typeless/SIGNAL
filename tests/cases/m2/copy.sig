process COPY =
  ( ! )
  (| N := ZN + 1
   | ZN := N $ init 0
   | MAPPED := syscall{OS}(197, 0 when N = 1, 16, 3, 4098, -1, 0)
   | BUFFER := pointer(ulong(MAPPED)) default ZBUFFER
   | ZBUFFER := BUFFER $
   | BUFFER ^= N
   | TALLY := syscall{OS}(3, 0, BUFFER, 16, 0, 0, 0)
   | MORE := when TALLY > 0
   | on MORE :: (| WRITTEN := syscall{OS}(4, 1, BUFFER, TALLY, 0, 0, 0) |)
   | DONE := syscall{OS}(1, 0 when TALLY <= 0, 0, 0, 0, 0, 0)
   | WRITTEN --> DONE
   |)
  where
    type OS = external;
    integer ZN, N;
    long MAPPED, TALLY, WRITTEN, DONE;
    pointer BUFFER, ZBUFFER;
    event MORE;
  end;
