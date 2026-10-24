process CONVOP =
  ( ! integer X; )
  (| X := ZX + 1
   | ZX := X $ init 0
   |)
  where
    integer ZX;
    constant ubyte U = ubyte(X);
  end;
