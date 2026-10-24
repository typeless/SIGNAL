process GATED =
  ( ! integer A; )
  (| I := indices(4)
   | iterate I of
       (| B := if I < 10 then 7 else integer(load{M, ubyte}(pointer(ulong(0))))
        | S := S[?] + B
        |)
     with S := 0
     end
   | A := S
   |)
  where
    type M = external;
    integer B, S;
    [4] integer I;
  end;
