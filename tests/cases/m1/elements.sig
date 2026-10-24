process ELEMENTS =
  ( ! integer K, X, Y; long Z; integer F; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | K := (N - 1) modulo SIZE
   | X := A[K]
   | Y := B[K]
   | Z := C[K]
   | F := A[3] + N
   |)
  where
    constant integer SIZE = 4;
    constant [SIZE] integer A = [10, 20, 30, 40];
    constant [SIZE] short B = [-200, 100, -50, 25];
    constant [SIZE] long C = [-1, -2, -3, -4];
    integer ZN, N;
  end;
