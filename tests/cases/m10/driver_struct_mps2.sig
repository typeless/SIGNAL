process DRIVERSTRUCTMPS2 =
  ( ? event START, TICK;
    ! integer TALLY;
      bundle (boolean TX_READY; boolean RX_VALID;) spec (| TX_READY ^# RX_VALID |) STATUS;
      boolean TX_ENABLED; )
  pragmas
    Machine "mps2-an385"
    Boot {START}
    Interrupt {TICK} "15"
  end pragmas
  (| RELOAD :: store{SYSTICK, uinteger}(pointer(SYST_RVR) when START, uinteger(PERIOD))
   | CURRENT :: store{SYSTICK, uinteger}(pointer(SYST_CVR) when START, uinteger(0))
   | CONTROL :: store{SYSTICK, uinteger}(pointer(SYST_CSR) when START, uinteger(7))
   | RELOAD --> CURRENT --> CONTROL
   | TALLY := ZCOUNT + 1
   | ZCOUNT := TALLY $ init 0
   | TALLY ^= TICK
   | REG.STATE := load{UART, uinteger}(pointer(UART_BASE) + 4 when TICK)
   | REG.CTRL := load{UART, uinteger}(pointer(UART_BASE) + 8 when TICK)
   | REG.STATE --> REG.CTRL
   | RX_EMPTY := (REG.STATE and uinteger(2)) = uinteger(0)
   | STATUS.TX_READY := (REG.STATE and uinteger(1)) = uinteger(0) when RX_EMPTY
   | STATUS.RX_VALID := true when not RX_EMPTY
   | TX_ENABLED := (REG.CTRL and uinteger(1)) /= uinteger(0)
   |)
  where
    type SYSTICK = external;
    type UART = external;
    constant ulong SYST_CSR = ulong(3758153744);
    constant ulong SYST_RVR = ulong(3758153748);
    constant ulong SYST_CVR = ulong(3758153752);
    constant integer PERIOD = 250000;
    constant ulong UART_BASE = ulong(1073758208);
    integer ZCOUNT;
    struct (uinteger STATE; uinteger CTRL;) REG;
    boolean RX_EMPTY;
    label RELOAD, CURRENT, CONTROL;
  end;
