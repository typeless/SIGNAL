process LOADCOMMANDS =
  ( ! uinteger CMD, SIZE; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | MAPPED := syscall{OS}(197, 0 when N = 1, 16384, 1, 2, 0, 0)
   | HEADER := pointer(ulong(MAPPED))
   | TALLY := load{FILE, uinteger}(HEADER + 16)
   | K := TALLY default ZK
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
    uinteger TALLY, K, ZK, STEP, ZSIZE;
    boolean MORE;
  end;
