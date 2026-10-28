process BYTEADDER =
  ( ? [8] boolean X, Y;
    ! [8] boolean S; boolean OVERFLOW; )
  (| (S, OVERFLOW) := byte_adder(X, Y)
   | X ^= Y
   |)
  where
    function byte_adder =
      ( ? [8] boolean X, Y;
        ! [8] boolean S; boolean overflow; )
      (| array i to 7 of
           (overflow, S[i]) := fulladd(overflow[?], X[i], Y[i])
         with overflow := false
         end
       |)
      where
        function fulladd =
          ( ? boolean cin, x, y;
            ! boolean cout, s; )
          (| s := x xor y xor cin
           | cout := (x and y) or (y and cin) or (cin and x)
           |);
      end;
  end;
