process NOCOMMON =
  ( ! ulong Q; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | U := ulong(N)
   | Q := U + N
   |)
  where
    integer ZN, N;
    ulong U;
  end;
