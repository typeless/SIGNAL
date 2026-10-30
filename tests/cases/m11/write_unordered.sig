process WRITEUNORDERED =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | writeString("a" when ^N)
   | write("b", N)
   |)
  where
    integer ZN;
  end;
