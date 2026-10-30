process STRINGLIST =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | writeString("ab" "cd" % a comment % "e\x66"
                 "g" when ^N)
   |)
  where
    integer ZN;
  end;
