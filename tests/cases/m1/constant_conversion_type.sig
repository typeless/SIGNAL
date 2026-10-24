process CONVTYPE =
  ( ! integer X; )
  (| X := ZX + 1
   | ZX := X $ init 0
   |)
  where
    integer ZX;
    constant pointer P = pointer(1);
  end;
