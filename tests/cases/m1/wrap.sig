process WRAP =
  ( ! short S; integer I; long L; ubyte B; ushort H; uinteger W; ulong Q; )
  (| S := ZS + 16384
   | ZS := S $ init 0
   | I := ZI + 1073741824
   | ZI := I $ init 0
   | L := ZL + 4611686018427387904
   | ZL := L $ init 0
   | B := ZB + ubyte(128)
   | ZB := B $
   | H := ZH + ushort(32768)
   | ZH := H $
   | W := ZW + uinteger(2147483648)
   | ZW := W $
   | Q := ZQ + ulong(9223372036854775807)
   | ZQ := Q $
   | S ^= I ^= L ^= B ^= H ^= W ^= Q
   |)
  where
    short ZS; integer ZI; long ZL; ubyte ZB; ushort ZH; uinteger ZW; ulong ZQ;
  end;
