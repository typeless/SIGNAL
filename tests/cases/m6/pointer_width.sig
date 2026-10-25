process WIDTH =
  ( ? event START;
    ! ulong FILLED, AFTER_POINTER, CONVERTED; )
  pragmas
    Machine "mps2-an385"
    Boot {START}
  end pragmas
  (| PLACE := pointer(SCRATCH) when START
   | FILL :: store{RAM, ulong}(PLACE, ulong(1229782938247303441))
   | FILLED := load{RAM, ulong}(PLACE)
   | NARROW :: store{RAM, pointer}(PLACE, pointer(ulong(4294967301)))
   | AFTER_POINTER := load{RAM, ulong}(PLACE)
   | FILL --> FILLED --> NARROW --> AFTER_POINTER
   | CONVERTED := ulong(pointer(ulong(4294967301) when START))
   |)
  where
    type RAM = external;
    constant ulong SCRATCH = ulong(536870912);
    pointer PLACE;
    label FILL, NARROW;
  end;
