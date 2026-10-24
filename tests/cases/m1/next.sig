process NEXTCOPY =
  ( ! integer T0, T1, T2, T3; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | K := N modulo 5
   | V := N * 10
   | G := A[ORDER]
   | T := G next K : V
   | T0 := T[0]
   | T1 := T[1]
   | T2 := T[2]
   | T3 := T[3]
   |)
  where
    integer ZN, N, K, V;
    constant [4] integer A = [1, 2, 3, 4];
    constant [4] integer ORDER = [3, 2, 1, 0];
    [4] integer G, T;
  end;
