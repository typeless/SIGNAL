process RUNMAX =
  ( ! integer K, S; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | K := (N - 1) modulo SIZE
   | I := indices(SIZE)
   | iterate I of
       (| M := if A[I] > M[?] then A[I] else M[?]
        | P := P[?] next I : M
        |)
     with M := 0
     end
   | S := P[K]
   |)
  where
    constant integer SIZE = 8;
    constant [SIZE] integer A = [3, 1, 4, 1, 5, 9, 2, 6];
    integer ZN, N, M;
    [SIZE] integer I, P;
  end;
