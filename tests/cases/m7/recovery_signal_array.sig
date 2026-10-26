process P =
  ( ! integer Y; )
  (| N := ZN + 1 | ZN := N $ init 0
   | K := (N modulo 5) - 1
   | I := indices(3)
   | iterate I of S := S[?] next I : N + I end
   | Y := S[K] \\ -1
   |)
  where
    integer ZN, N, K;
    [3] integer I, S;
  end;
