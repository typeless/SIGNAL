process LAST =
  ( ? integer IN; ! integer O, Q; )
  (| O := IN + 1
   | iterate X of S := S[?] + 1 with S := 0 end
   | Q := S
   | X := 0 .. 2
   |)
  where
    integer S;
    [4] integer X;
  end;
