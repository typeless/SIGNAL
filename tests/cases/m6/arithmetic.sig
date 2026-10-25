process WIDE =
  ( ? event START;
    ! long MIN_LONG, MIN_DIV, DIV_ZERO, MOD_ZERO, NEG_DIV, NEG_MOD, BOTH_NEG_MOD, PRODUCT, CROSS;
      ulong BIG_DIV, BIG_MOD, TOP_BIT, SHIFT_64, SHIFT_32, SHIFT_63, SHIFT_LEFT_31, SHIFT_LEFT_33, SHIFT_ZERO;
      boolean UNSIGNED_GT, SIGNED_LT, EQUAL_HIGH;
      ubyte NARROW_BYTE; short NARROW_SHORT; integer NARROW_INT; long WIDE_INT; ulong WIDE_UINT; )
  pragmas
    Machine "mps2-an385"
    Boot {START}
  end pragmas
  (| ONE := long(1) when START
   | UONE := ulong(ONE)
   | ALL := ulong(ONE - 2)
   | TOP_BIT := UONE shl ulong(63)
   | MIN_LONG := long(TOP_BIT)
   | MIN_DIV := MIN_LONG / long(-1)
   | DIV_ZERO := long(7) / (ONE - 1)
   | MOD_ZERO := long(7) modulo (ONE - 1)
   | NEG_DIV := long(-7) / (ONE + 2)
   | NEG_MOD := long(-7) modulo (ONE + 2)
   | BOTH_NEG_MOD := long(-7) modulo (ONE - 4)
   | PRODUCT := long(UONE shl ulong(32)) * long(4294967295) + ONE
   | CROSS := long(UONE shl ulong(33) + ulong(3)) * long(UONE shl ulong(31) + ulong(5))
   | BIG_DIV := ALL / ulong(10)
   | BIG_MOD := ALL modulo ulong(10)
   | SHIFT_64 := ALL shl (UONE + ulong(63))
   | SHIFT_32 := ALL shr (UONE + ulong(31))
   | SHIFT_63 := ALL shr (UONE + ulong(62))
   | SHIFT_LEFT_31 := (ALL shr ulong(4)) shl (UONE + ulong(30))
   | SHIFT_LEFT_33 := (ALL shr ulong(4)) shl (UONE + ulong(32))
   | SHIFT_ZERO := ALL shr (UONE - UONE)
   | UNSIGNED_GT := TOP_BIT > UONE
   | SIGNED_LT := MIN_LONG < ONE
   | EQUAL_HIGH := UONE shl ulong(40) = UONE shl ulong(41)
   | NARROW_BYTE := ubyte(ONE + 299)
   | NARROW_SHORT := short(ONE + 69999)
   | NARROW_INT := integer(long(UONE shl ulong(32)) + 4)
   | WIDE_INT := long(integer(ONE - 6))
   | WIDE_UINT := ulong(uinteger(ONE - 2))
   |)
  where
    long ONE;
    ulong UONE, ALL;
  end;
