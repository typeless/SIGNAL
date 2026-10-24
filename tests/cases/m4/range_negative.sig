process NEG =
  ( ! integer OUT; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | E := if N = 1 then -5 else if N = 2 then -1 else if N = 3 then -2147483647 - 1 else 2
   | X := 0 .. E
   | iterate X of S := S[?] + 1 with S := 0 end
   | OUT := S
   |)
  where
    integer ZN, N, E, S;
    [4] integer X;
  end;
