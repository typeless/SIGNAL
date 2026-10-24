process P =
  ( ? integer X; event T; ! integer Y, C; )
  (| Y := X + 1
   | C := ZC + 1
   | ZC := C $ init 0
   | C ^= T
   |)
  where
    integer ZC;
  end;
