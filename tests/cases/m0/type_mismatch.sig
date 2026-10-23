process TY =
  ( ! integer X; )
  (| X := ZX > 0
   | ZX := X $ init 0
   |)
  where
    integer ZX;
  end;
