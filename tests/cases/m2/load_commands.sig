process LOADCOMMANDS =
  ( ! uinteger CMD, SIZE; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | MAPPED := syscall{OS}(197, 0 when N = 1, 16384, 1, 2, 0, 0)
   | HEADER := pointer(ulong(MAPPED))
   | COUNT := load{FILE, uinteger}(HEADER + 16)
   | K := COUNT default ZK
   | ZK := K $
   | K ^= N
   | MORE := uinteger(N) <= K
   | P := (HEADER + 32) default (ZP + ZSIZE)
   | ZP := P $
   | P ^= N
   | CMD := load{FILE, uinteger}(P when MORE)
   | SIZE := load{FILE, uinteger}((P + 4) when MORE)
   | CMD --> SIZE
   | STEP := SIZE default uinteger(0)
   | STEP ^= N
   | ZSIZE := STEP $
   | DONE := syscall{OS}(1, 0 when not MORE, 0, 0, 0, 0, 0)
   |)
  where
    type OS = external;
    type FILE = external;
    integer ZN, N;
    long MAPPED, DONE;
    pointer HEADER, P, ZP;
    uinteger COUNT, K, ZK, STEP, ZSIZE;
    boolean MORE;
  end;
