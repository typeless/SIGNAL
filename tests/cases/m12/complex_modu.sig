process COMPLEXMODU =
  ( ? complex A; dcomplex C;
    ! real M; dreal MD; )
  (| M := modu(A)
   | MD := modud(C)
   | A ^= C
   |)
  where
  end;
