PROCESS KEYWORDS =
  ( ! INTEGER Process, processX, UBYTE; )
  (| N := ZN + 1
   | ZN := N $ INIT 0
   | Process := N
   | processX := N * 2
   | UBYTE := N * 3
   |)
  WHERE
    INTEGER ZN, N;
  END;
