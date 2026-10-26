process P =
  ( ? integer PAIR; ! boolean B, C; )
  (| X := PAIR / 10
   | Y := PAIR modulo 10
   | B := X == Y
   | C := X <<= Y
   |)
  where
    integer X, Y;
  end;
