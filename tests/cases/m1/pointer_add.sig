process PADD =
  ( ! pointer Q; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | P := pointer(ulong(N))
   | Q := P + P
   |)
  where
    integer ZN, N;
    pointer P;
  end;
