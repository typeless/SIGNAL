process EXTIN =
  ( ! [3] ulong C; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | C := ulong(K) + instruction{CPU, ADD_ONE}(ulong(N))
   |)
  where
    type CPU = external;
    constant long ADD_ONE = 2432697344;
    constant [3] integer K = [1, 2, 3];
    integer ZN, N;
  end;
