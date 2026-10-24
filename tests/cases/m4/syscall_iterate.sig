process WRITES =
  ( ! )
  (| I := indices(3)
   | iterate I of W := syscall{OS}(4, 1, 0, 0, 0, 0, 0) end
   |)
  where
    type OS = external;
    long W;
    [3] integer I;
  end;
