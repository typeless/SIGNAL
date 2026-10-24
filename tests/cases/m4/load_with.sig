process LOADSEED =
  ( ! integer S; )
  (| I := indices(3)
   | iterate I of S := S[?] + 1 with S := integer(load{MEM, ubyte}(pointer(ulong(4096)))) end
   |)
  where
    type MEM = external;
    [3] integer I;
  end;
