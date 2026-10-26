process P =
  ( ! integer N; )
  (| N := INNER(1) |)
  where
    process INNER =
      ( ? integer X;
        ! integer C; )
      (| C := ZC + X
       | ZC := C $ init 0
       |) / X
      where
        integer ZC;
      end;
  end;
