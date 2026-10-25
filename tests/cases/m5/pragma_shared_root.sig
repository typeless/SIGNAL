process SHARED =
  ( ? event A, B, S;
    ! integer N; )
  pragmas
    Boot {S}
    Interrupt {A} "27"
    Interrupt {B} "26"
  end pragmas
  (| N := 1 when A
   | A ^= B
   |);
