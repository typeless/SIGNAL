process DIVISION =
  ( ! integer N, A, M, K, E, F; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | D := N - 2
   | A := (0 - 7) / D
   | M := (0 - 7) modulo D
   | K := (N - N - 2147483647 - 1) / (N - N - 1)
   | E := (N - N - 7) modulo (N - N - 3)
   | F := (N - N + 7) modulo (N - N - 3)
   |)
  where
    integer ZN, D;
  end;
