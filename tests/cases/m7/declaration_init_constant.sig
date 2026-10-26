process COUNTER =
  ( ! integer N; boolean B; )
  (| N := ZN + 1
   | ZN := N $
   | B := ZB
   | ZB := C $
   | C := not B
   | B ^= N
   |)
  where
    integer ZN init START;
    boolean ZB init true;
    boolean C;
    constant integer START = 10;
  end;
