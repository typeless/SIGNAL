process ARRAYINPUTMALFORMED =
  ( ? [2, 2] boolean B; [2] short H;
    ! [2, 2] boolean C; short S; boolean D; )
  (| C := B
   | S := H[0] + H[1]
   | D := B[1, 0]
   |);
