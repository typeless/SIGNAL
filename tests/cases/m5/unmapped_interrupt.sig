process TICKER =
  ( ? event START, TICK;
    ! integer TALLY; )
  pragmas
    Boot {START}
    Interrupt {TICK} "30"
  end pragmas
  (| DISTRIBUTOR :: store{GIC, uinteger}(pointer(GICD_CTLR) when START, uinteger(1))
   | ENABLE :: store{GIC, uinteger}(pointer(GICD_ISENABLER0) when START, uinteger(1073741826))
   | MASK :: store{GIC, uinteger}(pointer(GICC_PMR) when START, uinteger(255))
   | INTERFACE :: store{GIC, uinteger}(pointer(GICC_CTLR) when START, uinteger(1))
   | DISTRIBUTOR --> ENABLE --> MASK --> INTERFACE
   | RAISE :: store{GIC, uinteger}(pointer(GICD_SGIR) when START, uinteger(33554433))
   | P_ARMED := instruction{TIMER, MSR_CNTP_TVAL}(PERIOD when START)
   | P_ON := instruction{TIMER, MSR_CNTP_CTL}(ulong(1) when START)
   | TICK_ARMED := instruction{TIMER, MSR_CNTP_TVAL}(PERIOD when TICK)
   | INTERFACE --> RAISE --> P_ARMED --> P_ON --> TICK_ARMED
   | TALLY := ZCOUNT + 1
   | ZCOUNT := TALLY $ init 0
   | TALLY ^= TICK
   |)
  where
    type GIC = external;
    type TIMER = external;
    constant ulong GICD_CTLR = ulong(134217728);
    constant ulong GICD_ISENABLER0 = ulong(134217984);
    constant ulong GICD_SGIR = ulong(134221568);
    constant ulong GICC_CTLR = ulong(134283264);
    constant ulong GICC_PMR = ulong(134283268);
    constant ulong MSR_CNTP_TVAL = ulong(3575374336);
    constant ulong MSR_CNTP_CTL = ulong(3575374368);
    constant ulong PERIOD = ulong(1250000);
    integer ZCOUNT;
    ulong P_ARMED, P_ON, TICK_ARMED;
    label DISTRIBUTOR, ENABLE, MASK, INTERFACE, RAISE;
  end;
