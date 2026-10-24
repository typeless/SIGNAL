process P =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | on when N = 3 :: (| BYE() |)
   |)
  where
    type OS = external;
    integer ZN;
    procedure BYE = ( ) (| X := syscall{OS}(1, 9, 0, 0, 0, 0, 0) |) where long X; end;
  end;
