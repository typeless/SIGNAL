process P =
  ( ! integer N; )
  (| N := INNER(1)
   |)
  where
    process INNER =
      ( ? integer X;
        ! integer C; )
      pragmas
        Interrupt {X} "27"
      end pragmas
      (| C := ZC + X
       | ZC := C $ init 0
       |)
      where
        integer ZC;
      end;
  end;
