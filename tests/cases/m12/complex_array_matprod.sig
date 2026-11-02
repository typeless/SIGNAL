process COMPLEXARRAYMATPROD =
  ( ? [2] complex X, Y;
    ! complex D; )
  (| D := X *. Y
   | X ^= Y
   |)
  where
  end;
