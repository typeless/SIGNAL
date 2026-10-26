process P =
  ( ! integer Y, Z; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := CK + N * 0
   | Z := CL + N * 0
   |)
  where
    integer ZN, N;
    constant integer CK = (2 * 2 + 1) ** 2, CL = - (2 ** 3) ** 1;
  end;
