process TICKER =
  ( ? event START, TICK;
    ! integer TALLY; )
  pragmas
    Boot {START}
    Interrupt {TICK} "27"
  end pragmas
  (| DISTRIBUTOR :: store{GIC, uinteger}(pointer(GICD_CTLR) when START, uinteger(1))
   | ENABLE :: store{GIC, uinteger}(pointer(GICD_ISENABLER0) when START, uinteger(134217728))
   | PRIORITY :: store{GIC, ubyte}(pointer(GICD_IPRIORITY27) when START, ubyte(0))
   | MASK :: store{GIC, uinteger}(pointer(GICC_PMR) when START, uinteger(255))
   | INTERFACE :: store{GIC, uinteger}(pointer(GICC_CTLR) when START, uinteger(1))
   | DISTRIBUTOR --> ENABLE --> PRIORITY --> MASK --> INTERFACE
   | BOOT_ARMED := instruction{TIMER, MSR_CNTV_TVAL}(PERIOD when START)
   | TIMER_ON := instruction{TIMER, MSR_CNTV_CTL}(ulong(1) when START)
   | TICK_ARMED := instruction{TIMER, MSR_CNTV_TVAL}(PERIOD when TICK)
   | INTERFACE --> BOOT_ARMED --> TIMER_ON --> TICK_ARMED
   | TALLY := ZCOUNT + 1
   | ZCOUNT := TALLY $ init 0
   | TALLY ^= TICK
   |)
  where
    type GIC = external;
    type TIMER = external;
    constant ulong GICD_CTLR = ulong(134217728);
    constant ulong GICD_ISENABLER0 = ulong(134217984);
    constant ulong GICD_IPRIORITY27 = ulong(134218779);
    constant ulong GICC_CTLR = ulong(134283264);
    constant ulong GICC_PMR = ulong(134283268);
    constant ulong MSR_CNTV_TVAL = ulong(3575374592);
    constant ulong MSR_CNTV_CTL = ulong(3575374624);
    constant ulong PERIOD = ulong(625000);
    integer ZCOUNT;
    ulong BOOT_ARMED, TIMER_ON, TICK_ARMED;
    label DISTRIBUTOR, ENABLE, PRIORITY, MASK, INTERFACE;
  end;
