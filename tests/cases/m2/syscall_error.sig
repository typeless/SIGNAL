process BADFD =
  ( ! long R; )
  (| R := syscall{OS}(6, 99, 0, 0, 0, 0, 0) |)
  where
    type OS = external;
  end;
