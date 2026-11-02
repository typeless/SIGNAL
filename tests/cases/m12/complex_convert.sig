process COMPLEXCONVERT =
  ( ? complex A; dcomplex C;
    ! real RA; dreal DA; real RC; dreal DC; long LC; integer IA; char HC; ubyte BA; complex NC; dcomplex WA; )
  (| RA := real(A)
   | DA := dreal(A)
   | RC := real(C)
   | DC := dreal(C)
   | LC := long(C)
   | IA := integer(A)
   | HC := char(C)
   | BA := ubyte(A)
   | NC := complex(C)
   | WA := dcomplex(A)
   | A ^= C
   |)
  where
  end;
