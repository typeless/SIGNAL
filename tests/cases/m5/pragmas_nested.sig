process P =
  ( ? event TICK;
    ! integer COUNT; )
  pragmas
    Interrupt {TICK} "27"
  end pragmas
  (| COUNT := INNER(TICK)
   |)
  where
    process INNER =
      ( ? event T;
        ! integer C; )
      pragmas
        Interrupt {T} "28"
      end pragmas
      (| C := ZC + 1
       | ZC := C $ init 0
       | C ^= T
       |)
      where
        integer ZC;
      end;
  end;
