process NI =
  ( ! integer Y; )
  (| Y := INNER() |)
  where
    process INNER =
      ( ! integer O; )
      (| C := ZC + 1
       | ZC := C $ init 0
       | P := (C modulo 2) = 0
       | O := C default ZC
       | O ^= C when P
       |)
      where integer C, ZC; boolean P; end;
  end;
