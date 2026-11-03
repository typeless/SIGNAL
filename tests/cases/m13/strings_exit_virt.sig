process STRINGSEXITVIRT =
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
   | LINE := if TALLY = 1 then "/dev/null" else if TALLY = 2 then "/" else if TALLY = 3 then "/dev/null" else "abc\0d"
   | PREVIOUS := LINE $ 1 init "none"
   | FIRST_LINE := LINE when TALLY = 1
   | FIRST := FIRST_LINE cell ^TALLY init ""
   | L :: BYTE := load{MEM, ubyte}(pointer(LINE))
   | W1 :: write("line ", LINE)
   | W2 :: write("previous ", PREVIOUS)
   | W3 :: write("first ", FIRST)
   | W4 :: write("same as previous ", LINE = PREVIOUS)
   | W5 :: write("before previous ", LINE < PREVIOUS)
   | W6 :: write("same as first ", LINE = FIRST)
   | W7 :: write("before first ", LINE < FIRST)
   | W8 :: write("first byte ", integer(BYTE))
   | W1 --> W2 --> W3 --> W4 --> W5 --> W6 --> W7 --> W8
   | L --> W8
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
    type MEM = external;
    string LINE, PREVIOUS, FIRST_LINE, FIRST;
    ubyte BYTE;
    label DISTRIBUTOR, ENABLE, PRIORITY, MASK, INTERFACE, L, W1, W2, W3, W4, W5, W6, W7, W8;
  end;
