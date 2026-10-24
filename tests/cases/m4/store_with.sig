process SEED =
  ( ! integer S; )
  (| I := indices(3)
   | iterate I of S := S[?] + 1 with store{MEM, ubyte}(pointer(ulong(0)), ubyte(0)) end
   |)
  where
    type MEM = external;
    [3] integer I;
  end;
