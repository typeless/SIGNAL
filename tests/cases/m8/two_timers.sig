module TIMERS =
  process CMSDK_TIMER =
    { type RES; ulong BASE; integer RELOAD; }
    ( ? event START, IRQ;
      ! integer N; )
    (| R :: store{RES, uinteger}(pointer(BASE + ulong(8)) when START, uinteger(RELOAD))
     | V :: store{RES, uinteger}(pointer(BASE + ulong(4)) when START, uinteger(RELOAD))
     | C :: store{RES, uinteger}(pointer(BASE) when START, uinteger(9))
     | K :: store{RES, uinteger}(pointer(BASE + ulong(12)) when IRQ, uinteger(1))
     | R --> V --> C --> K
     | N := Z + 1
     | Z := N $ init 0
     | N ^= IRQ
     |)
    where
      integer Z;
      label R, V, C, K;
    end;
end;
process TWO =
  ( ? event START, T0, T1;
    ! integer N0, N1; )
  pragmas
    Machine "mps2-an385"
    Boot {START}
    Interrupt {T0} "24"
    Interrupt {T1} "25"
  end pragmas
  (| ENABLE :: store{NVIC, uinteger}(pointer(NVIC_ISER0) when START, uinteger(768))
   | N0 := CMSDK_TIMER{TIM0, TIMER0_BASE, RELOAD0}(START, T0)
   | N1 := CMSDK_TIMER{TIM1, TIMER1_BASE, RELOAD1}(START, T1)
   |)
  where
    use TIMERS;
    type NVIC = external;
    type TIM0 = external;
    type TIM1 = external;
    constant ulong NVIC_ISER0 = ulong(3758153984);
    constant ulong TIMER0_BASE = ulong(1073741824);
    constant ulong TIMER1_BASE = TIMER0_BASE + ulong(4096);
    constant integer RELOAD0 = 100000;
    constant integer RELOAD1 = 300000;
    label ENABLE;
  end;
