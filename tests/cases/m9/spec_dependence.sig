process SPECDEPENDENCE =
  ( ! integer X, Y; )
  spec (| X --> Y |)
  (| X := ZX + 1
   | ZX := X $ init 0
   | Y := ZX * 2
   | Y --> X
   |)
  where
    integer ZX;
  end;
