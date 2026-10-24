process COPY =
  ( ! )
  (| N := ZN + 1
   | ZN := N $ init 0
   | MAPPED := syscall{OS}(197, 0 when N = 1, 16, 3, 4098, -1, 0)
   | BUFFER := pointer(ulong(MAPPED)) default ZBUFFER
   | ZBUFFER := BUFFER $
   | BUFFER ^= N
   | COUNT := syscall{OS}(3, 0, BUFFER, 16, 0, 0, 0)
   | MORE := when COUNT > 0
   | on MORE :: (| WRITTEN := syscall{OS}(4, 1, BUFFER, COUNT, 0, 0, 0) |)
   | DONE := syscall{OS}(1, 0 when COUNT <= 0, 0, 0, 0, 0, 0)
   | WRITTEN --> DONE
   |)
  where
    type OS = external;
    integer ZN, N;
    long MAPPED, COUNT, WRITTEN, DONE;
    pointer BUFFER, ZBUFFER;
    event MORE;
  end;
