process CONVERT =
  ( ? integer N; ulong U; boolean F; char C; real X; dreal Y;
    ! real RN; dreal DN, DU; real RU, RF; dreal DC; integer IX; long LY; ubyte BX; dreal DX; real RY; ushort SY; char CX; )
  (| RN := real(N)
   | DN := dreal(N)
   | DU := dreal(U)
   | RU := real(U)
   | RF := real(F)
   | DC := dreal(C)
   | IX := integer(X)
   | LY := long(Y)
   | BX := ubyte(X)
   | DX := dreal(X)
   | RY := real(Y)
   | SY := ushort(Y)
   | CX := char(X)
   |)
  where
  end;
