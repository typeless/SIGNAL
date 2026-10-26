process COUNTER =
  ( ! integer N; )
  (| (| N := ZN + STEP
      | ZN := N $ init 0
      |)
     where
       constant integer STEP = 3;
       integer ZN;
       label L;
     end
   | (| |) where type unused = integer; end
   |);
