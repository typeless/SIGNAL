process LOOPS =
  ( ? event START, TICK;
    ! integer A, B, C, D, E, F, G; )
  pragmas
    Machine "mps2-an385"
    Boot {START}
    Interrupt {TICK} "15"
  end pragmas
  (| N := ZN + 1
   | ZN := N $ init 0
   | N ^= TICK
   | EA := N - 3
   | XA := 0 .. EA
   | iterate XA of SA := SA[?] + 1 with SA := 0 end
   | A := SA
   | EB := short(N) - short(6)
   | XB := 0 .. EB
   | iterate XB of SB := SB[?] + 1 with SB := 0 end
   | B := SB
   | EC := ulong(N) shl ulong(60)
   | XC := 0 .. EC
   | iterate XC of SC := SC[?] + 1 with SC := 0 end
   | C := SC
   | ED := ubyte(N) + ubyte(250)
   | XD := 0 .. ED
   | iterate XD of SD := SD[?] + 1 with SD := 0 end
   | D := SD
   | EE := long(N) - 5
   | XE := 0 .. EE
   | iterate XE of SE := SE[?] + 1 with SE := 0 end
   | E := SE
   | EF := uinteger(0) - uinteger(N)
   | XF := 0 .. EF
   | iterate XF of SF := SF[?] + 1 with SF := 0 end
   | F := SF
   | EG := long(N) - 4 + long(-9223372036854775807) - long(1)
   | XG := 0 .. EG
   | iterate XG of SG := SG[?] + XG with SG := 0 end
   | G := SG
   | RELOAD :: store{SYSTICK, uinteger}(pointer(SYST_RVR) when START, uinteger(250000))
   | CURRENT :: store{SYSTICK, uinteger}(pointer(SYST_CVR) when START, uinteger(0))
   | CONTROL :: store{SYSTICK, uinteger}(pointer(SYST_CSR) when START, uinteger(7))
   | RELOAD --> CURRENT --> CONTROL
   |)
  where
    integer ZN, N, EA, SA, SB, SC, SD, SE, SF, SG;
    short EB;
    ulong EC;
    ubyte ED;
    long EE, EG;
    uinteger EF;
    [4] integer XA, XB, XC, XD, XE, XF, XG;
    type SYSTICK = external;
    constant ulong SYST_CSR = ulong(3758153744);
    constant ulong SYST_RVR = ulong(3758153748);
    constant ulong SYST_CVR = ulong(3758153752);
    label RELOAD, CURRENT, CONTROL;
  end;
