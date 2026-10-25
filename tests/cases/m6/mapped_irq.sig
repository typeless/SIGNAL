process RELAY =
  ( ? event START, TICK, SOFT;
    ! integer TICKS, SOFTS; )
  pragmas
    Machine "mps2-an385"
    Boot {START}
    Interrupt {TICK} "15"
    Interrupt {SOFT} "47"
  end pragmas
  (| ENABLE :: store{NVIC, uinteger}(pointer(NVIC_ISER0) when START, uinteger(2147483648))
   | RELOAD :: store{SYSTICK, uinteger}(pointer(SYST_RVR) when START, uinteger(PERIOD))
   | CURRENT :: store{SYSTICK, uinteger}(pointer(SYST_CVR) when START, uinteger(0))
   | CONTROL :: store{SYSTICK, uinteger}(pointer(SYST_CSR) when START, uinteger(7))
   | ENABLE --> RELOAD --> CURRENT --> CONTROL --> RAISE
   | RAISE :: store{NVIC, uinteger}(pointer(NVIC_ISPR0) when TICK, uinteger(2147483648))
   | TICKS := ZTICKS + 1
   | ZTICKS := TICKS $ init 0
   | TICKS ^= TICK
   | SOFTS := ZSOFTS + 1
   | ZSOFTS := SOFTS $ init 0
   | SOFTS ^= SOFT
   |)
  where
    type NVIC = external;
    type SYSTICK = external;
    constant ulong NVIC_ISER0 = ulong(3758153984);
    constant ulong NVIC_ISPR0 = ulong(3758154240);
    constant ulong SYST_CSR = ulong(3758153744);
    constant ulong SYST_RVR = ulong(3758153748);
    constant ulong SYST_CVR = ulong(3758153752);
    constant integer PERIOD = 250000;
    integer ZTICKS, ZSOFTS;
    label ENABLE, RELOAD, CURRENT, CONTROL, RAISE;
  end;
