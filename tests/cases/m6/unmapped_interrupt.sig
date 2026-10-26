process TICKER =
  ( ? event START, TICK;
    ! integer TALLY; )
  pragmas
    Machine "mps2-an385"
    Boot {START}
    Interrupt {TICK} "15"
  end pragmas
  (| PRIORITY :: store{NVIC, uinteger}(pointer(SHPR3) when START, uinteger(2147483648))
   | ENABLE :: store{NVIC, uinteger}(pointer(NVIC_ISER0) when START, uinteger(32))
   | RAISE :: store{NVIC, uinteger}(pointer(NVIC_ISPR0) when START, uinteger(32))
   | PRIORITY --> ENABLE --> RAISE
   | RELOAD :: store{SYSTICK, uinteger}(pointer(SYST_RVR) when START, uinteger(PERIOD))
   | CURRENT :: store{SYSTICK, uinteger}(pointer(SYST_CVR) when START, uinteger(0))
   | CONTROL :: store{SYSTICK, uinteger}(pointer(SYST_CSR) when START, uinteger(7))
   | RAISE --> RELOAD --> CURRENT --> CONTROL
   | TALLY := ZCOUNT + 1
   | ZCOUNT := TALLY $ init 0
   | TALLY ^= TICK
   |)
  where
    type NVIC = external;
    type SYSTICK = external;
    constant ulong SHPR3 = ulong(3758157088);
    constant ulong NVIC_ISER0 = ulong(3758153984);
    constant ulong NVIC_ISPR0 = ulong(3758154240);
    constant ulong SYST_CSR = ulong(3758153744);
    constant ulong SYST_RVR = ulong(3758153748);
    constant ulong SYST_CVR = ulong(3758153752);
    constant integer PERIOD = 500000;
    integer ZCOUNT;
    label PRIORITY, ENABLE, RAISE, RELOAD, CURRENT, CONTROL;
  end;
