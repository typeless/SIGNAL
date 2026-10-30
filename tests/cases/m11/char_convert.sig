process CHARCONVERT =
  ( ? integer N; char C; boolean F;
    ! char X, Y; integer I; ubyte U; long L; ushort S; char Z; )
  (| X := char(N)
   | Y := char(F)
   | I := integer(C)
   | U := ubyte(C)
   | L := long(C)
   | S := ushort(C)
   | Z := char(C)
   |)
  where
  end;
