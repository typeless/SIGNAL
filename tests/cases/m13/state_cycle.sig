process STATECYCLE =
  ( )
  (| N := ZN + 1
   | ZN := N $ init 0
   | R :: A := read("" when N modulo 2 = 1)
   | X := A default (Y $ 1 init "y0")
   | Y := X $ 1 init "x0"
   | X ^= N
   | W :: write("x=", X)
   | V :: write("y=", Y)
   | R --> W --> V
   |)
  where
    integer N, ZN;
    string A, X, Y;
    label R, W, V;
  end;
