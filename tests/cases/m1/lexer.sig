process LEXER =
  ( ! integer J, KO, SO, LO, CNT; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | X := indices(LEN)
   | iterate X of
       (| C := CLASS[SRC[X]]
        | M := TRANS[S[?] * 9 + C]
        | E := M = 8
        | EI := integer(E)
        | S := M + EI * (TRANS[C] - M)
        | B := B[?] + integer(S[?] = 0 or E) * (X - B[?])
        | KINDS := KINDS[?] next T[?] : KIND_OF[S[?]]
        | STARTS := STARTS[?] next T[?] : B[?]
        | LENGTHS := LENGTHS[?] next T[?] : X - B[?]
        | T := T[?] + EI
        |)
     with (| S := 0 | B := 0 | T := 0 |)
     end
   | CNT := T
   | J := (N - 1) modulo CNT
   | KO := integer(KINDS[J])
   | SO := STARTS[J]
   | LO := LENGTHS[J]
   |)
  where
    constant integer LEN = 51;
    constant integer CAP = 32;
    constant [LEN] short SRC = [
        40, 124, 32, 78, 32, 58, 61, 32, 90, 78, 32, 43, 32, 49, 32, 124, 32,
        90, 78, 32, 58, 61, 32, 78, 32, 36, 32, 105, 110, 105, 116, 32, 48, 32,
        124, 32, 66, 32, 58, 61, 32, 78, 32, 60, 61, 32, 57, 32, 124, 41, 10];
    constant [128] short CLASS = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        1, 0, 0, 0, 0, 0, 0, 0, 4, 6, 0, 0, 0, 0, 0, 7,
        3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 7, 0, 7, 8, 7, 0,
        0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
        2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 7, 2,
        0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
        2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 5, 0, 0, 0];
    constant [72] short TRANS = [
        3, 0, 1, 2, 4, 5, 3, 6, 3,
        8, 8, 1, 1, 8, 8, 8, 8, 8,
        8, 8, 8, 2, 8, 8, 8, 8, 8,
        8, 8, 8, 8, 8, 8, 8, 8, 8,
        8, 8, 8, 8, 8, 7, 8, 8, 8,
        8, 8, 8, 8, 8, 8, 7, 8, 8,
        8, 8, 8, 8, 8, 8, 8, 8, 7,
        8, 8, 8, 8, 8, 8, 8, 8, 8];
    constant [8] short KIND_OF = [0, 1, 2, 3, 3, 3, 3, 3];
    integer ZN, N, C, M, EI, S, B, T;
    boolean E;
    [LEN] integer X;
    [CAP] short KINDS;
    [CAP] integer STARTS, LENGTHS;
  end;
