process GATHER =
  ( ! integer K, GK, I2; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | K := N modulo 4
   | G := A[ORDER]
   | I := indices(4)
   | GK := G[K]
   | I2 := I[K]
   |)
  where
    integer ZN, N;
    constant [4] integer A = [10, 20, 30, 40];
    constant [4] integer ORDER = [3, 0, 2, 1];
    [4] integer G, I;
  end;
