process RANGE =
  ( ! integer M, S; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | M := (N - 1) modulo 4
   | X := 0 .. M - 1
   | iterate X of S := S[?] + X + 1 with S := 0 end
   |)
  where
    integer ZN, N;
    [8] integer X;
  end;
