process STOPPER =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | STOP_AFTER(N, 3)
   |)
  where
    type OS = external;
    integer ZN;
    process STOP_AFTER =
      ( ? integer K, LIMIT; ! )
      (| DONE := syscall{OS}(1, 7 when K > LIMIT, 0, 0, 0, 0, 0) |)
      where
        long DONE;
      end;
  end;
