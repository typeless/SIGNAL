process STRINGDEFAULT =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | S := if N modulo 2 = 0 then "even" else "odd"
   | D := S $ 1
   | SS := S when N > 1
   | V := var SS
   | V ^= N
   | E := D = ""
   | W :: write("d=", D)
   | X :: write("empty ", E)
   | Y :: write("v=", V)
   | W --> X --> Y
   |)
  where
    integer ZN;
    string S, D, V, SS;
    boolean E;
    label W, X, Y;
  end;
