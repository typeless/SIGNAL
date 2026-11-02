process CONSTANTEXPRESSION =
  ( ! real X; )
  (| X := C
   |)
  where
    constant real C = 1.0 + 2.0;
  end;
