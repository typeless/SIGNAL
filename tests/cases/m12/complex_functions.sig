process COMPLEXFUNCTIONS =
  ( ? complex A; dcomplex C;
    ! complex J; dcomplex JD; real R; dreal RD; real I; dreal ID; real M; dreal MD; dreal IW; )
  (| J := conj(A)
   | JD := conjd(C)
   | R := rpart(A)
   | RD := rpartd(C)
   | I := ipart(A)
   | ID := ipartd(C)
   | M := modu(A)
   | MD := modud(C)
   | IW := ipartd(A)
   | A ^= C
   |)
  where
  end;
