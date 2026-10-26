process LAST =
  ( ? integer INP; ! integer O, Q; )
  (| O := INP + 1
   | iterate X of S := S[?] + 1 with S := 0 end
   | Q := S
   | X := 0 .. 2
   |)
  where
    integer S;
    [4] integer X;
  end;
