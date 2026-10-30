process WRITEKINDS =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A :: write("n=", N)
   | B :: write("b=", N > 1)
   | C :: write("c=", 'é' when ^N)
   | D :: write("s=", "x y" when ^N)
   | E :: writeString("end" when ^N)
   | F :: write("u=", (ulong(0) - ulong(1)) when ^N)
   | G :: write("a=", 'A' when ^N)
   | A --> B --> C --> D --> E --> F --> G
   |)
  where
    integer ZN;
    label A, B, C, D, E, F, G;
  end;
