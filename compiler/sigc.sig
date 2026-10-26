process SIGC =
  ( ! )
  (| ARGC := integer(instruction{ARGS, 2853766112}(ulong(0)))
   | ARGV := pointer(instruction{ARGS, 2853831648}(ulong(ARGC)))
   | ARG1 := load{ARGS, pointer}(ARGV + 8)
   | ARG2 := load{ARGS, pointer}(ARGV + 16)
   | ARG3 := load{ARGS, pointer}(ARGV + 24)
   | ARG1 --> ARG2
   | ARG2 --> ARG3
   | ARGUMENT_COUNT_OK := ARGC = 4
   | DASH_INDEX := 0 .. (if ARGUMENT_COUNT_OK then 2 else -1)
   | iterate DASH_INDEX of
       (| DASH_BYTE := load{ARGS, ubyte}(ARG2 + DASH_INDEX)
        | DASH_MATCHES := DASH_MATCHES[?] and DASH_BYTE = OUTPUT_OPTION[DASH_INDEX]
        |)
     with DASH_MATCHES := true
     end
   | ARG3 --> DASH_BYTE
   | USAGE_OK := ARGUMENT_COUNT_OK and DASH_MATCHES
   | PATH_INDEX := 0 .. (if USAGE_OK then ARG_CAP - 1 else -1)
   | iterate PATH_INDEX of
       (| PATH_BYTE := load{ARGS, ubyte}(if PATH_ENDED[?] then ARG1 else ARG1 + PATH_INDEX)
        | PATH_ENDED := PATH_ENDED[?] or PATH_BYTE = ubyte(0)
        | PATH_LENGTH := if PATH_ENDED then PATH_LENGTH[?] else PATH_INDEX + 1
        | PATH_TEXT := PATH_TEXT[?] next PATH_INDEX : PATH_BYTE
        |)
     with (| PATH_ENDED := false | PATH_LENGTH := 0 |)
     end
   | OUT_PATH_INDEX := 0 .. (if USAGE_OK then ARG_CAP - 1 else -1)
   | iterate OUT_PATH_INDEX of
       (| OUT_PATH_BYTE := load{ARGS, ubyte}(if OUT_PATH_ENDED[?] then ARG3 else ARG3 + OUT_PATH_INDEX)
        | OUT_PATH_ENDED := OUT_PATH_ENDED[?] or OUT_PATH_BYTE = ubyte(0)
        | OUT_PATH_LENGTH := if OUT_PATH_ENDED then OUT_PATH_LENGTH[?] else OUT_PATH_INDEX + 1
        | OUT_PATH_TEXT := OUT_PATH_TEXT[?] next OUT_PATH_INDEX : OUT_PATH_BYTE
        |)
     with (| OUT_PATH_ENDED := false | OUT_PATH_LENGTH := 0 |)
     end
   | PATH_BYTE --> OUT_PATH_BYTE
   | SOURCE_ROOT := if PATH_LENGTH > 0 and PATH_TEXT[0] = ubyte(47) then (if PATH_LENGTH > 1 and PATH_TEXT[1] = ubyte(47) and not (PATH_LENGTH > 2 and PATH_TEXT[2] = ubyte(47)) then 2 else 1) else 0
   | OUT_ROOT := if OUT_PATH_LENGTH > 0 and OUT_PATH_TEXT[0] = ubyte(47) then (if OUT_PATH_LENGTH > 1 and OUT_PATH_TEXT[1] = ubyte(47) and not (OUT_PATH_LENGTH > 2 and OUT_PATH_TEXT[2] = ubyte(47)) then 2 else 1) else 0
   | SOURCE_SLOTS := 2 * PATH_LENGTH + 1
   | NP_INDEX := 0 .. (if USAGE_OK then SOURCE_SLOTS + 2 * OUT_PATH_LENGTH else -1)
   | iterate NP_INDEX of
       (| NP_OUT := NP_INDEX >= SOURCE_SLOTS
        | NP_K := if NP_OUT then NP_INDEX - SOURCE_SLOTS else NP_INDEX
        | NP_I := NP_K / 2
        | NP_SEPARATOR_SLOT := NP_K modulo 2 = 0
        | NP_L := if NP_OUT then OUT_PATH_LENGTH else PATH_LENGTH
        | NP_ROOT := if NP_OUT then OUT_ROOT else SOURCE_ROOT
        | NP_C := if NP_I >= NP_L then ubyte(0) else if NP_OUT then OUT_PATH_TEXT[NP_I] else PATH_TEXT[NP_I]
        | NP_P := if NP_I = 0 then ubyte(47) else if NP_OUT then OUT_PATH_TEXT[NP_I - 1] else PATH_TEXT[NP_I - 1]
        | NP_N := if NP_I + 1 >= NP_L then ubyte(47) else if NP_OUT then OUT_PATH_TEXT[NP_I + 1] else PATH_TEXT[NP_I + 1]
        | NP_DOT := NP_C = ubyte(46) and NP_P = ubyte(47) and NP_N = ubyte(47)
        | NP_IN_NAME := NP_I < NP_L and NP_C /= ubyte(47) and not NP_DOT
        | NP_STARTS := NP_IN_NAME and NP_P = ubyte(47)
        | NP_FIRST := NP_INDEX = 0 or NP_INDEX = SOURCE_SLOTS
        | NP_NAMES_IN := if NP_FIRST then 0 else NP_NAMES[?]
        | NP_LENGTH_IN := if NP_FIRST then 0 else NP_LENGTH[?]
        | NP_FINAL := NP_I = NP_L
        | NP_WRITES := if NP_FINAL then NP_LENGTH_IN = 0 else if NP_SEPARATOR_SLOT then NP_STARTS and NP_NAMES_IN > 0
                       else NP_IN_NAME or NP_I < NP_ROOT
        | NP_BYTE := if NP_FINAL then ubyte(46) else if NP_SEPARATOR_SLOT then ubyte(47) else NP_C
        | NP_NAMES := NP_NAMES_IN + integer(not NP_SEPARATOR_SLOT and NP_STARTS)
        | NP_LENGTH := NP_LENGTH_IN + integer(NP_WRITES)
        | SOURCE_NAME := SOURCE_NAME[?] next (if NP_WRITES and not NP_OUT then NP_LENGTH_IN else -1) : NP_BYTE
        | OUTPUT_NAME := OUTPUT_NAME[?] next (if NP_WRITES and NP_OUT then NP_LENGTH_IN else -1) : NP_BYTE
        | SOURCE_NAME_LENGTH := if NP_OUT then SOURCE_NAME_LENGTH[?] else NP_LENGTH
        | OUTPUT_NAME_LENGTH := if NP_OUT then NP_LENGTH else OUTPUT_NAME_LENGTH[?]
        | OUTPUT_NAME_SLASH := if NP_OUT and NP_WRITES and NP_BYTE = ubyte(47) then NP_LENGTH_IN else OUTPUT_NAME_SLASH[?]
        |)
     with (| NP_NAMES := 0 | NP_LENGTH := 0 | SOURCE_NAME_LENGTH := 0 | OUTPUT_NAME_LENGTH := 0 | OUTPUT_NAME_SLASH := -1 |)
     end
   | BUFFER_ADDRESS := syscall{OS}(if USAGE_OK then 197 else 20, 0, OUTPUT_CAP, 3, 4098, -1, 0)
   | BUFFER_OK := USAGE_OK and BUFFER_ADDRESS >= long(0)
   | OUTPUT_BASE := pointer(ulong(BUFFER_ADDRESS))
   | NAMES_AT := integer(OUTPUT_CAP) - 2 * (ARG_CAP + 16)
   | SOURCE_NAME_ADDRESS := OUTPUT_BASE + NAMES_AT
   | OUTPUT_NAME_ADDRESS := OUTPUT_BASE + (NAMES_AT + ARG_CAP + 16)
   | NC_INDEX := 0 .. (if BUFFER_OK then SOURCE_NAME_LENGTH + OUTPUT_NAME_LENGTH + 1 else -1)
   | iterate NC_INDEX of
       (| NC_OUT := NC_INDEX > SOURCE_NAME_LENGTH
        | NC_J := if NC_OUT then NC_INDEX - SOURCE_NAME_LENGTH - 1 else NC_INDEX
        | NC_LENGTH := if NC_OUT then OUTPUT_NAME_LENGTH else SOURCE_NAME_LENGTH
        | NC_BYTE := if NC_J >= NC_LENGTH then ubyte(0) else if NC_OUT then OUTPUT_NAME[NC_J] else SOURCE_NAME[NC_J]
        | store{NAMES, ubyte}(OUTPUT_BASE + (NAMES_AT + (if NC_OUT then ARG_CAP + 16 else 0) + NC_J), NC_BYTE)
        |)
     end
   | FALLBACK := syscall{OS}(if USAGE_OK and not BUFFER_OK then 197 else 20, 0, 16384, 3, 4098, -1, 0)
   | BUFFER_ADDRESS --> FALLBACK
   | FALLBACK_OK := USAGE_OK and not BUFFER_OK and FALLBACK >= long(0)
   | RS_INDEX := 0 .. (if FALLBACK_OK then FRAGMENT_LENGTH[F_RESERVATION_FAILED] else -1)
   | iterate RS_INDEX of
       (| RS_BYTE := if RS_INDEX < FRAGMENT_LENGTH[F_RESERVATION_FAILED] then FRAGMENTS[FRAGMENT_START[F_RESERVATION_FAILED] + RS_INDEX]
                     else ubyte(10)
        | store{RESERVE, ubyte}(pointer(ulong(FALLBACK)) + RS_INDEX, RS_BYTE)
        |)
     end
   | RESERVATION_WRITTEN := syscall{OS}(if FALLBACK_OK then 4 else 20, 2, FALLBACK, FRAGMENT_LENGTH[F_RESERVATION_FAILED] + 1, 0, 0, 0)
   | FALLBACK --> RS_BYTE
   | RS_BYTE --> RESERVATION_WRITTEN
   | SOURCE_FD := syscall{OS}(if BUFFER_OK and PATH_ENDED then 5 else 20, SOURCE_NAME_ADDRESS, 0, 0, 0, 0, 0)
   | RESERVATION_WRITTEN --> SOURCE_FD
   | NC_BYTE --> SOURCE_FD
   | OPEN_OK := BUFFER_OK and PATH_ENDED and SOURCE_FD >= 0
   | PROBE := syscall{OS}(if OPEN_OK then 3 else 20, SOURCE_FD, BUFFER_ADDRESS, 1, 0, 0, 0)
   | READ_OK := OPEN_OK and PROBE >= 0
   | SIZE := syscall{OS}(if READ_OK then 199 else 20, SOURCE_FD, 0, 2, 0, 0, 0)
   | SIZE_OK := READ_OK and SIZE >= 0
   | SOURCE_FITS := SIZE <= long(SRC_CAP - SEED_LENGTH - 4)
   | MAP_WANTED := SIZE_OK and SOURCE_FITS and SIZE > 0
   | MAPPED := syscall{OS}(if MAP_WANTED then 197 else 20, 0, SIZE, 1, 2, SOURCE_FD, 0)
   | MAP_OK := not MAP_WANTED or MAPPED >= 0
   | SOURCE_CLOSED := syscall{OS}(if OPEN_OK then 6 else 20, SOURCE_FD, 0, 0, 0, 0, 0)
   | MAPPED --> SOURCE_CLOSED
   | ERRNO := if not BUFFER_OK then 0 else if not PATH_ENDED then 63 else if not OPEN_OK then integer(-SOURCE_FD) else if not READ_OK then integer(-PROBE)
              else if not SIZE_OK then integer(-SIZE) else if not MAP_OK then integer(-MAPPED) else 0
   | SOURCE_OK := BUFFER_OK and ERRNO = 0 and SOURCE_FITS
   | LENGTH := integer(SIZE)
   | SOURCE_BASE := pointer(ulong(MAPPED))
   | COPY_INDEX := 0 .. (if SOURCE_OK then LENGTH - 1 else -1)
   | iterate COPY_INDEX of
       (| SOURCE_BYTE := load{FILE, ubyte}(SOURCE_BASE + COPY_INDEX)
        | SRC := SRC[?] next COPY_INDEX : SOURCE_BYTE
        |)
     end
   | UV_INDEX := 0 .. (if SOURCE_OK then LENGTH else -1)
   | iterate UV_INDEX of
       (| UV_AT_END := UV_INDEX = LENGTH
        | UV_BYTE := SRC[UV_INDEX]
        | UV_LIVE := UV_FAIL_AT[?] < 0
        | UV_NEED_IN := UV_NEED[?]
        | UV_SECOND := UV_NEED_IN > 0 and UV_INDEX = UV_START[?] + 1
        | UV_LEAD := SRC[UV_START[?]]
        | UV_LOW := if UV_SECOND and UV_LEAD = ubyte(224) then ubyte(160) else if UV_SECOND and UV_LEAD = ubyte(240) then ubyte(144)
                    else ubyte(128)
        | UV_HIGH := if UV_SECOND and UV_LEAD = ubyte(237) then ubyte(159) else if UV_SECOND and UV_LEAD = ubyte(244) then ubyte(143)
                     else ubyte(191)
        | UV_CONTINUES := UV_BYTE >= UV_LOW and UV_BYTE <= UV_HIGH
        | UV_BAD_START := UV_NEED_IN = 0 and not UV_AT_END and UV_BYTE >= ubyte(128) and (UV_BYTE < ubyte(194) or UV_BYTE >= ubyte(245))
        | UV_BAD_CONTINUATION := UV_NEED_IN > 0 and not UV_AT_END and not UV_CONTINUES
        | UV_TRUNCATED := UV_NEED_IN > 0 and UV_AT_END
        | UV_FAILS := UV_LIVE and (UV_BAD_START or UV_BAD_CONTINUATION or UV_TRUNCATED)
        | UV_FAIL_AT := if UV_FAILS then (if UV_BAD_START then UV_INDEX else UV_START[?]) else UV_FAIL_AT[?]
        | UV_FAIL_END := if UV_FAILS then (if UV_BAD_START then UV_INDEX + 1 else UV_INDEX) else UV_FAIL_END[?]
        | UV_FAIL_REASON := if not UV_FAILS then UV_FAIL_REASON[?] else if UV_BAD_START then UTF8_INVALID_START
                            else if UV_TRUNCATED then UTF8_UNEXPECTED_END else UTF8_INVALID_CONTINUATION
        | UV_NEED := if UV_NEED_IN > 0 then UV_NEED_IN - 1 else if UV_BYTE >= ubyte(240) then 3 else if UV_BYTE >= ubyte(224) then 2
                     else if UV_BYTE >= ubyte(194) then 1 else 0
        | UV_START := if UV_NEED_IN = 0 then UV_INDEX else UV_START[?]
        |)
     with (| UV_NEED := 0 | UV_START := 0 | UV_FAIL_AT := -1 | UV_FAIL_END := 0 | UV_FAIL_REASON := 0 |)
     end
   | UTF8_FAILED := SOURCE_OK and UV_FAIL_AT >= 0
   | TEXT_OK := SOURCE_OK and not UTF8_FAILED
   | LEX_INDEX := 0 .. (if TEXT_OK then LENGTH + 1 else -1)
   | iterate LEX_INDEX of
       (| AT_EOF := LEX_INDEX = LENGTH
        | AT_END := LEX_INDEX >= LENGTH
        | BYTE := SRC[LEX_INDEX]
        | NEXT_BYTE := SRC[LEX_INDEX + 1]
        | CLASS := if BYTE = ubyte(195) and (NEXT_BYTE = ubyte(151) or NEXT_BYTE = ubyte(183)) then CLASS_INVALID
                   else CHARACTER_CLASS[BYTE]
        | PREVIOUS_MODE := MODE[?]
        | CONTINUES := not AT_END
            and (PREVIOUS_MODE = MODE_NAME and (CLASS = CLASS_LETTER or CLASS = CLASS_DIGIT)
                 or PREVIOUS_MODE = MODE_NUMBER and CLASS = CLASS_DIGIT
                 or PREVIOUS_MODE = MODE_COMMENT or PREVIOUS_MODE = MODE_STRING or PREVIOUS_MODE = MODE_SYMBOL)
        | STARTS := not CONTINUES
        | SYMBOL_LENGTH := if TRIPLE_CODE[BYTE] /= 0 and TRIPLE_SECOND[BYTE] = integer(NEXT_BYTE)
                              and TRIPLE_THIRD[BYTE] = integer(SRC[LEX_INDEX + 2]) then 3
                           else if PAIR_CODE[PAIR_ROW[BYTE] * PAIR_WIDTH + PAIR_COLUMN[NEXT_BYTE]] /= 0 then 2
                           else if CLASS = CLASS_SYMBOL then 1 else 0
        | OPENED_KIND := if AT_EOF then KIND_EOF else if AT_END then KIND_NONE else OPENED_KIND_OF_CLASS[CLASS]
        | OPENS_TOKEN := STARTS and OPENED_KIND /= KIND_NONE
        | REMAINING := if STARTS then SYMBOL_LENGTH - 1 else REMAINING[?] - 1
        | MODE := if STARTS then (if AT_END then MODE_IDLE else if SYMBOL_LENGTH > 1 then MODE_SYMBOL else MODE_OF_CLASS[CLASS])
                  else if PREVIOUS_MODE = MODE_COMMENT and BYTE = ubyte(37) and not ESCAPED[?]
                       or STRING_CLOSES
                       or PREVIOUS_MODE = MODE_SYMBOL and REMAINING = 0 then MODE_IDLE
                  else PREVIOUS_MODE
        | IN_TEXT := CONTINUES and (PREVIOUS_MODE = MODE_STRING or PREVIOUS_MODE = MODE_COMMENT)
        | ESCAPED := IN_TEXT and BYTE = ubyte(92) and not ESCAPED[?]
        | IN_STRING := CONTINUES and PREVIOUS_MODE = MODE_STRING
        | STRING_CLOSES := IN_STRING and BYTE = ubyte(34) and not ESCAPED[?]
        | OCTAL := BYTE >= ubyte(48) and BYTE <= ubyte(55)
        | EXTENDS := IN_STRING and (SEQUENCE[?] = SEQUENCE_OCTAL and OCTAL and SEQUENCE_DIGITS[?] < 3
                                    or SEQUENCE[?] = SEQUENCE_HEX and HEX_DIGIT[BYTE] > 0 and SEQUENCE_DIGITS[?] < 2)
        | SEQUENCE_CLOSES := IN_STRING and not EXTENDS and (SEQUENCE[?] = SEQUENCE_OCTAL or SEQUENCE[?] = SEQUENCE_HEX)
        | STRING_BASE := STRING_FILL[?] + integer(SEQUENCE_CLOSES)
        | AFTER_BACKSLASH := IN_STRING and SEQUENCE[?] = SEQUENCE_BACKSLASH
        | OPENS_SEQUENCE := IN_STRING and not EXTENDS and not AFTER_BACKSLASH and BYTE = ubyte(92)
        | SEQUENCE := if not IN_STRING then SEQUENCE_NONE
                      else if EXTENDS then SEQUENCE[?]
                      else if OPENS_SEQUENCE then SEQUENCE_BACKSLASH
                      else if AFTER_BACKSLASH and OCTAL then SEQUENCE_OCTAL
                      else if AFTER_BACKSLASH and BYTE = ubyte(120) then SEQUENCE_HEX
                      else SEQUENCE_NONE
        | SEQUENCE_DIGITS := if EXTENDS then SEQUENCE_DIGITS[?] + 1 else integer(AFTER_BACKSLASH and OCTAL)
        | SEQUENCE_VALUE := if EXTENDS and SEQUENCE[?] = SEQUENCE_OCTAL then SEQUENCE_VALUE[?] * 8 + integer(BYTE) - 48
                            else if EXTENDS then SEQUENCE_VALUE[?] * 16 + HEX_DIGIT[BYTE] - 1
                            else if AFTER_BACKSLASH and OCTAL then integer(BYTE) - 48 else 0
        | SIMPLE_ESCAPE := AFTER_BACKSLASH and ESCAPE_VALUE[BYTE] > 0
        | PLAIN_BYTE := IN_STRING and not EXTENDS and not AFTER_BACKSLASH and BYTE /= ubyte(92) and not STRING_CLOSES
        | STRING_WRITES := EXTENDS or AFTER_BACKSLASH and (OCTAL or BYTE = ubyte(120)) or SIMPLE_ESCAPE or PLAIN_BYTE
        | STRING_AT := if EXTENDS then STRING_FILL[?] else STRING_BASE
        | STRING_TEXT := STRING_TEXT[?] next (if STRING_WRITES then STRING_AT else -1)
                         : (if SIMPLE_ESCAPE then ubyte(ESCAPE_VALUE[BYTE]) else if PLAIN_BYTE then BYTE else ubyte(SEQUENCE_VALUE))
        | STRING_FILL := STRING_BASE + integer(SIMPLE_ESCAPE or PLAIN_BYTE)
        | ESCAPE_AT := if OPENS_SEQUENCE then LEX_INDEX else ESCAPE_AT[?]
        | ESCAPE_LINE := if OPENS_SEQUENCE then LINE[?] else ESCAPE_LINE[?]
        | ESCAPE_COLUMN := if OPENS_SEQUENCE then COLUMN else ESCAPE_COLUMN[?]
        | ESCAPE_UNKNOWN := AFTER_BACKSLASH and not OCTAL and BYTE /= ubyte(120) and ESCAPE_VALUE[BYTE] = 0
                            or SEQUENCE_CLOSES and SEQUENCE[?] = SEQUENCE_HEX and SEQUENCE_DIGITS[?] = 0
        | ESCAPE_TOO_BIG := EXTENDS and SEQUENCE_VALUE > 255
        | COLUMN := CODE_POINTS[?] - LINE_START[?] + 1
        | ENDS_LINE := not AT_END and (BYTE = ubyte(10) or BYTE = ubyte(13) and NEXT_BYTE /= ubyte(10))
        | CODE_POINTS := CODE_POINTS[?]
                         + integer(not (BYTE = ubyte(13) and NEXT_BYTE = ubyte(10)) and (BYTE < ubyte(128) or BYTE >= ubyte(192)))
        | LINE_START := if ENDS_LINE then CODE_POINTS else LINE_START[?]
        | LINE := LINE[?] + integer(ENDS_LINE)
        | OPEN_AT := if STARTS then LEX_INDEX else OPEN_AT[?]
        | OPEN_LINE := if STARTS then LINE[?] else OPEN_LINE[?]
        | OPEN_COLUMN := if STARTS then COLUMN else OPEN_COLUMN[?]
        | OPEN_KIND := if STARTS then OPENED_KIND else OPEN_KIND[?]
        | PENDING := if STARTS then (if OPENS_TOKEN then TOKEN_COUNT[?] else -1) else PENDING[?]
        | LETTER := LETTER_VALUE[BYTE]
        | KEY := if STARTS then ulong(LETTER) else KEY[?] * ulong(32) + ulong(LETTER)
        | NOT_ALL_LETTERS := not STARTS and NOT_ALL_LETTERS[?] or LETTER = 0
        | HAS_LOWER := not STARTS and HAS_LOWER[?] or BYTE >= ubyte(97) and BYTE <= ubyte(122)
        | HAS_UPPER := not STARTS and HAS_UPPER[?] or BYTE >= ubyte(65) and BYTE <= ubyte(90)
        | FINISHED_LENGTH := if OPEN_KIND[?] = KIND_EOF then 0 else LEX_INDEX - OPEN_AT[?]
        | IS_KEYWORD := OPEN_KIND[?] = KIND_NAME and not NOT_ALL_LETTERS[?] and FINISHED_LENGTH <= KEYWORD_LENGTH_MAX
                        and KEYWORD_KEYS[integer(KEY[?] modulo ulong(KEYWORD_MODULUS))] = KEY[?]
                        and not (HAS_LOWER[?] and HAS_UPPER[?])
        | FINISHED_SLOT := if STARTS then PENDING[?] else -1
        | TOKEN_KIND := TOKEN_KIND[?] next FINISHED_SLOT : ubyte(if IS_KEYWORD then KIND_KEYWORD else OPEN_KIND[?])
        | TOKEN_LENGTH := TOKEN_LENGTH[?] next FINISHED_SLOT : FINISHED_LENGTH
        | OPENED_SLOT := if OPENS_TOKEN then TOKEN_COUNT[?] else -1
        | TOKEN_START := TOKEN_START[?] next OPENED_SLOT : LEX_INDEX
        | TOKEN_LINE := TOKEN_LINE[?] next OPENED_SLOT : LINE[?]
        | TOKEN_COLUMN := TOKEN_COLUMN[?] next OPENED_SLOT : COLUMN
        | TOKEN_COUNT := TOKEN_COUNT[?] + integer(OPENS_TOKEN)
        | UNCLOSED := AT_EOF and (PREVIOUS_MODE = MODE_COMMENT or PREVIOUS_MODE = MODE_STRING)
                      or CONTINUES and PREVIOUS_MODE = MODE_STRING and (BYTE = ubyte(10) or BYTE = ubyte(13))
        | UNEXPECTED := STARTS and not AT_END and (CLASS = CLASS_INVALID or CLASS = CLASS_DOT and SYMBOL_LENGTH < 2)
        | FOUND := if UNEXPECTED or UNCLOSED then ERROR_UNEXPECTED
                   else if ESCAPE_UNKNOWN then ERROR_ESCAPE else if ESCAPE_TOO_BIG then ERROR_ESCAPE_RANGE
                   else if OPENS_TOKEN and TOKEN_COUNT[?] >= TOKEN_CAP then ERROR_TOKENS else ERROR_NONE
        | FIRST_FOUND := LEX_ERROR[?] = ERROR_NONE and FOUND /= ERROR_NONE
        | LEX_ERROR := if FIRST_FOUND then FOUND else LEX_ERROR[?]
        | IN_ESCAPE := FOUND = ERROR_ESCAPE or FOUND = ERROR_ESCAPE_RANGE
        | LEX_ERROR_LINE := if not FIRST_FOUND then LEX_ERROR_LINE[?] else if UNCLOSED then OPEN_LINE[?]
                            else if IN_ESCAPE then ESCAPE_LINE else LINE[?]
        | LEX_ERROR_COLUMN := if not FIRST_FOUND then LEX_ERROR_COLUMN[?] else if UNCLOSED then OPEN_COLUMN[?]
                              else if IN_ESCAPE then ESCAPE_COLUMN else COLUMN
        | LEX_ERROR_AT := if not FIRST_FOUND then LEX_ERROR_AT[?] else if UNCLOSED then OPEN_AT[?]
                          else if IN_ESCAPE then ESCAPE_AT + 1 else LEX_INDEX
        | LEX_ERROR_VALUE := if FIRST_FOUND then SEQUENCE_VALUE else LEX_ERROR_VALUE[?]
        | TOKEN_TEXT := TOKEN_TEXT[?] next OPENED_SLOT : STRING_FILL[?]
        |)
     with (| MODE := MODE_IDLE | REMAINING := 0 | CODE_POINTS := 0 | LINE_START := 0 | LINE := 1
           | OPEN_AT := 0 | OPEN_LINE := 1 | OPEN_COLUMN := 1 | OPEN_KIND := KIND_NONE | PENDING := -1
           | KEY := ulong(0) | NOT_ALL_LETTERS := false | HAS_LOWER := false | HAS_UPPER := false | TOKEN_COUNT := 0
           | LEX_ERROR := ERROR_NONE | LEX_ERROR_LINE := 0 | LEX_ERROR_COLUMN := 0 | LEX_ERROR_AT := 0
           | ESCAPED := false | SEQUENCE := SEQUENCE_NONE | SEQUENCE_DIGITS := 0 | SEQUENCE_VALUE := 0 | STRING_FILL := 0
           | ESCAPE_AT := 0 | ESCAPE_LINE := 0 | ESCAPE_COLUMN := 0 | LEX_ERROR_VALUE := 0 |)
     end
   | LEXED := TEXT_OK and LEX_ERROR = ERROR_NONE and DUMP_PASS /= 1
   | INTERN_INDEX := 0 .. (if LEXED then SEED_LENGTH + LENGTH - 1 else -1)
   | iterate INTERN_INDEX of
       (| IN_SEED := INTERN_INDEX < SEED_LENGTH
        | SOURCE_AT := INTERN_INDEX - SEED_LENGTH
        | CURSOR_ENDED := not IN_SEED and SOURCE_AT >= TOKEN_START[CURSOR[?]] + TOKEN_LENGTH[CURSOR[?]] and CURSOR[?] < TOKEN_COUNT - 1
        | CURSOR := if CURSOR_ENDED then CURSOR[?] + 1 else CURSOR[?]
        | CURSOR_START := TOKEN_START[CURSOR]
        | CURSOR_LENGTH := TOKEN_LENGTH[CURSOR]
        | CURSOR_KIND := integer(TOKEN_KIND[CURSOR])
        | IN_TOKEN := not IN_SEED and SOURCE_AT >= CURSOR_START and SOURCE_AT < CURSOR_START + CURSOR_LENGTH
        | TOKEN_BEGINS := IN_TOKEN and SOURCE_AT = CURSOR_START
        | TOKEN_ENDS := IN_TOKEN and SOURCE_AT = CURSOR_START + CURSOR_LENGTH - 1
        | NAME_BYTE := if IN_SEED then SEED[INTERN_INDEX] else SRC[SOURCE_AT]
        | NAMEISH := IN_SEED and NAME_BYTE /= ubyte(32) or IN_TOKEN and (CURSOR_KIND = KIND_KEYWORD or CURSOR_KIND = KIND_NAME)
        | NAME_BEGINS := if IN_SEED then INTERN_INDEX = 0 or SEED[INTERN_INDEX - 1] = ubyte(32) else TOKEN_BEGINS
        | NAME_ENDS := NAMEISH and (if IN_SEED then INTERN_INDEX = SEED_LENGTH - 1 or SEED[INTERN_INDEX + 1] = ubyte(32) else TOKEN_ENDS)
        | FOLDED_BYTE := if IN_TOKEN and CURSOR_KIND = KIND_KEYWORD and NAME_BYTE >= ubyte(65) and NAME_BYTE <= ubyte(90)
                         then NAME_BYTE + ubyte(32) else NAME_BYTE
        | TRIE_PARENT := if NAME_BEGINS then 0 else TRIE_NODE[?]
        | TRIE_SLOT := TRIE_PARENT * NAME_FANOUT + NAME_CHAR[FOLDED_BYTE]
        | TRIE_EXISTING := TRIE_CHILD[?][TRIE_SLOT]
        | TRIE_SKIPS := NAME_BYTE = ubyte(195)
        | TRIE_CREATES := NAMEISH and not TRIE_SKIPS and TRIE_EXISTING = 0
        | TRIE_NODE := if not NAMEISH then TRIE_NODE[?] else if TRIE_SKIPS then TRIE_PARENT
                       else if TRIE_CREATES then TRIE_NODE_COUNT[?] else TRIE_EXISTING
        | TRIE_NODE_COUNT := TRIE_NODE_COUNT[?] + integer(TRIE_CREATES)
        | TRIE_CHILD := TRIE_CHILD[?] next (if TRIE_CREATES then TRIE_SLOT else -1) : TRIE_NODE_COUNT[?]
        | NAME_BEGIN := if NAME_BEGINS then INTERN_INDEX else NAME_BEGIN[?]
        | KNOWN_NAME := TRIE_NAME[?][TRIE_NODE]
        | NEW_NAME := NAME_ENDS and KNOWN_NAME = 0
        | NAME_ID := if KNOWN_NAME > 0 then KNOWN_NAME - 1 else NAME_COUNT[?]
        | TRIE_NAME := TRIE_NAME[?] next (if NEW_NAME then TRIE_NODE else -1) : NAME_COUNT[?] + 1
        | NAME_COUNT := NAME_COUNT[?] + integer(NEW_NAME)
        | NAME_AT := NAME_AT[?] next (if NEW_NAME then NAME_COUNT[?] else -1) : NAME_BEGIN
        | NAME_LENGTH := NAME_LENGTH[?] next (if NEW_NAME then NAME_COUNT[?] else -1) : INTERN_INDEX - NAME_BEGIN + 1
        | TOKEN_NAME := TOKEN_NAME[?] next (if NAME_ENDS and IN_TOKEN then CURSOR else -1) : NAME_ID + 1
        | SYMBOL_CODE := if CURSOR_LENGTH = 3 then TRIPLE_CODE[NAME_BYTE]
                         else if CURSOR_LENGTH = 2 then PAIR_CODE[PAIR_ROW[NAME_BYTE] * PAIR_WIDTH + PAIR_COLUMN[SRC[SOURCE_AT + 1]]]
                         else SINGLE_SYMBOL[NAME_BYTE]
        | CODE_VALUE := if CURSOR_KIND = KIND_KEYWORD then NAME_ID + 1 else if CURSOR_KIND = KIND_NAME then C_NAME
                        else if CURSOR_KIND = KIND_SYMBOL then SYMBOL_CODE else if CURSOR_KIND = KIND_NUMBER then C_NUMBER
                        else C_STRING
        | CODE_SLOT := if NAMEISH and TOKEN_ENDS or not NAMEISH and TOKEN_BEGINS then CURSOR else -1
        | TOKEN_CODE := TOKEN_CODE[?] next CODE_SLOT : ubyte(CODE_VALUE)
        | DIGIT_VALUE := ulong(NAME_BYTE) - ulong(48)
        | ACCUMULATED := if TOKEN_BEGINS then DIGIT_VALUE else ACCUMULATED[?] * ulong(10) + DIGIT_VALUE
        | TOO_BIG := not TOKEN_BEGINS and (TOO_BIG[?] or ACCUMULATED[?] > ulong(922337203685477580))
                     or ACCUMULATED > ulong(9223372036854775807)
        | VALUE_SLOT := if TOKEN_ENDS and CURSOR_KIND = KIND_NUMBER then CURSOR else -1
        | TOKEN_VALUE := TOKEN_VALUE[?] next VALUE_SLOT : long(ACCUMULATED)
        | TOKEN_BIG := TOKEN_BIG[?] next VALUE_SLOT : TOO_BIG or CURSOR_LENGTH > 20
        | INTERN_OVERFLOWS := TRIE_CREATES and TRIE_NODE_COUNT[?] >= TRIE_NODE_CAP or NEW_NAME and NAME_COUNT[?] >= NAME_CAP
        | INTERN_ERROR_TOKEN := if INTERN_ERROR_TOKEN[?] < 0 and INTERN_OVERFLOWS then CURSOR else INTERN_ERROR_TOKEN[?]
        |)
     with (| CURSOR := 0 | TRIE_NODE := 0 | TRIE_NODE_COUNT := 1 | NAME_BEGIN := 0 | NAME_COUNT := 0
           | ACCUMULATED := ulong(0) | TOO_BIG := false | INTERN_ERROR_TOKEN := -1 |)
     end
   | INTERNED := LEXED and INTERN_ERROR_TOKEN < 0
   | PRESCAN_INDEX := 0 .. (if INTERNED then TOKEN_COUNT - 1 else -1)
   | iterate PRESCAN_INDEX of
       (| SCAN_CODE := integer(TOKEN_CODE[PRESCAN_INDEX])
        | SCAN_NAME := TOKEN_NAME[PRESCAN_INDEX] - 1
        | SCAN_PREVIOUS := SCAN_STATE[?]
        | SCAN_IS_NAME := SCAN_CODE = C_NAME
        | SCAN_CLASHES := SCAN_NAME <= N_ISIN or NAME_TYPE[?][SCAN_NAME] > 0
        | SCAN_DUPLICATE := VALUE_STAMP[?][SCAN_NAME] = USER_TYPE_COUNT[?] + 1
        | SCAN_FULL := SCAN_PREVIOUS = PRE_SEMICOLON and USER_TYPE_COUNT[?] >= TYPE_CAP - BUILTIN_TYPE_COUNT
                       or SCAN_PREVIOUS = PRE_VALUE and VALUE_COUNT[?] >= VALUE_CAP
        | SCAN_MESSAGE := if SCAN_PREVIOUS = PRE_NAME then
                            (if not SCAN_IS_NAME then T_EXPECTED_NAME
                             else if SCAN_CLASHES then (if SCAN_NAME >= N_LOAD and SCAN_NAME <= N_ISIN then T_RESERVED else T_DECLARED_TWICE) else 0)
                          else if SCAN_PREVIOUS = PRE_EQUAL then (if SCAN_CODE /= C_EQUAL then T_EXPECTED_FOUND else 0)
                          else if SCAN_PREVIOUS = PRE_OPEN then (if SCAN_CODE /= C_OPEN then T_EXPECTED_FOUND else 0)
                          else if SCAN_PREVIOUS = PRE_VALUE then
                            (if not SCAN_IS_NAME then T_EXPECTED_NAME else if SCAN_DUPLICATE then T_ENUM_TWICE
                             else if SCAN_FULL then T_CAPACITY else 0)
                          else if SCAN_PREVIOUS = PRE_SEPARATOR then
                            (if SCAN_CODE /= C_COMMA and SCAN_CODE /= C_CLOSE then T_EXPECTED_FOUND else 0)
                          else if SCAN_PREVIOUS = PRE_SEMICOLON then
                            (if SCAN_CODE /= C_SEMICOLON then T_EXPECTED_FOUND else if SCAN_FULL then T_CAPACITY else 0)
                          else 0
        | SCAN_FAILS := SCAN_MESSAGE /= 0
        | SCAN_ARGUMENT0 := if SCAN_MESSAGE = T_EXPECTED_NAME then PRESCAN_INDEX
                            else if SCAN_MESSAGE = T_DECLARED_TWICE then F_ROLE_TYPE
                            else if SCAN_MESSAGE = T_CAPACITY then (if SCAN_PREVIOUS = PRE_VALUE then F_CAP_VALUES else F_CAP_TYPES)
                            else if SCAN_MESSAGE = T_EXPECTED_FOUND then
                              (if SCAN_PREVIOUS = PRE_EQUAL then C_EQUAL else if SCAN_PREVIOUS = PRE_KIND then C_ENUM
                               else if SCAN_PREVIOUS = PRE_OPEN then C_OPEN else if SCAN_PREVIOUS = PRE_SEPARATOR then C_CLOSE
                               else C_SEMICOLON)
                            else SCAN_NAME
        | SCAN_ARGUMENT1 := if SCAN_MESSAGE = T_EXPECTED_FOUND then PRESCAN_INDEX else SCAN_NAME
        | SCAN_STATE := if SCAN_PREVIOUS = PRE_FAILED or SCAN_FAILS then PRE_FAILED
                        else if SCAN_PREVIOUS = PRE_IDLE then (if SCAN_CODE = C_TYPE then PRE_NAME else PRE_IDLE)
                        else if SCAN_PREVIOUS = PRE_NAME then PRE_EQUAL
                        else if SCAN_PREVIOUS = PRE_EQUAL then PRE_KIND
                        else if SCAN_PREVIOUS = PRE_KIND then
                          (if SCAN_CODE = C_EXTERNAL then PRE_SEMICOLON else if SCAN_CODE = C_ENUM then PRE_OPEN else PRE_IDLE)
                        else if SCAN_PREVIOUS = PRE_OPEN then PRE_VALUE
                        else if SCAN_PREVIOUS = PRE_VALUE then PRE_SEPARATOR
                        else if SCAN_PREVIOUS = PRE_SEPARATOR then (if SCAN_CODE = C_COMMA then PRE_VALUE else PRE_SEMICOLON)
                        else PRE_IDLE
        | SCAN_TYPE_NAME := if SCAN_PREVIOUS = PRE_NAME then SCAN_NAME else SCAN_TYPE_NAME[?]
        | SCAN_TYPE_KIND := if SCAN_PREVIOUS = PRE_KIND then (if SCAN_CODE = C_EXTERNAL then TK_EXTERNAL else TK_ENUM) else SCAN_TYPE_KIND[?]
        | SCAN_VALUE_START := if SCAN_PREVIOUS = PRE_NAME then VALUE_COUNT[?] else SCAN_VALUE_START[?]
        | SCAN_APPENDS_VALUE := SCAN_PREVIOUS = PRE_VALUE and not SCAN_FAILS
        | VALUE_NAME := VALUE_NAME[?] next (if SCAN_APPENDS_VALUE then VALUE_COUNT[?] else -1) : SCAN_NAME
        | VALUE_STAMP := VALUE_STAMP[?] next (if SCAN_APPENDS_VALUE then SCAN_NAME else -1) : USER_TYPE_COUNT[?] + 1
        | VALUE_COUNT := VALUE_COUNT[?] + integer(SCAN_APPENDS_VALUE)
        | SCAN_REGISTERS := SCAN_PREVIOUS = PRE_SEMICOLON and not SCAN_FAILS
        | USER_TYPE_SLOT := if SCAN_REGISTERS then USER_TYPE_COUNT[?] else -1
        | USER_TYPE_NAME := USER_TYPE_NAME[?] next USER_TYPE_SLOT : SCAN_TYPE_NAME
        | USER_TYPE_KIND := USER_TYPE_KIND[?] next USER_TYPE_SLOT : SCAN_TYPE_KIND
        | USER_TYPE_VALUE_START := USER_TYPE_VALUE_START[?] next USER_TYPE_SLOT : SCAN_VALUE_START
        | USER_TYPE_VALUE_COUNT := USER_TYPE_VALUE_COUNT[?] next USER_TYPE_SLOT : VALUE_COUNT[?] - SCAN_VALUE_START
        | NAME_TYPE := NAME_TYPE[?] next (if SCAN_REGISTERS then SCAN_TYPE_NAME else -1) : BUILTIN_TYPE_COUNT + USER_TYPE_COUNT[?] + 1
        | USER_TYPE_COUNT := USER_TYPE_COUNT[?] + integer(SCAN_REGISTERS)
        | FIRST_SCAN_FAILURE := SCAN_FAILS and SCAN_PREVIOUS /= PRE_FAILED
        | PRESCAN_MESSAGE := if FIRST_SCAN_FAILURE then SCAN_MESSAGE else PRESCAN_MESSAGE[?]
        | PRESCAN_TOKEN := if FIRST_SCAN_FAILURE then PRESCAN_INDEX else PRESCAN_TOKEN[?]
        | PRESCAN_ARGUMENT0 := if FIRST_SCAN_FAILURE then SCAN_ARGUMENT0 else PRESCAN_ARGUMENT0[?]
        | PRESCAN_ARGUMENT1 := if FIRST_SCAN_FAILURE then SCAN_ARGUMENT1 else PRESCAN_ARGUMENT1[?]
        | BRACKET_COUNT := BRACKET_COUNT[?] + integer(SCAN_CODE = C_OPEN_BRACKET)
        | COLONS_COUNT := COLONS_COUNT[?] + integer(SCAN_CODE = C_COLONS)
        | SET_OPENS := SCAN_CODE = C_OPEN_BRACE and SCAN_LAST_CODE[?] /= C_NAME
        | IN_SET_SCAN := if SET_OPENS then true else if SCAN_CODE = C_CLOSE_BRACE then false else IN_SET_SCAN[?]
        | SET_NAMES := SET_NAMES[?] + integer(IN_SET_SCAN[?] and SCAN_IS_NAME)
        | SCAN_LAST_CODE := SCAN_CODE
        | COPY_COUNT := COPY_COUNT[?] + integer(SCAN_CODE = C_CLOCK_MINUS or SCAN_CODE = C_BACKSLASHES or SCAN_IS_NAME and SCAN_NAME = N_ABS
                                                or SCAN_CODE = C_BAR_STAR or SCAN_CODE = C_ARRAY)
        | IN_SELECTOR_SCAN := if SCAN_CODE = C_CASE then true else if SCAN_CODE = C_IN then false else IN_SELECTOR_SCAN[?]
        | SELECTOR_TOKENS := SELECTOR_TOKENS[?] + integer(IN_SELECTOR_SCAN[?])
        | BRACE_COMMAS := if SCAN_CODE = C_OPEN_BRACE then 0 else BRACE_COMMAS[?] + integer(SCAN_CODE = C_COMMA)
        | LAST_OPEN_BRACE := if SCAN_CODE = C_OPEN_BRACE then PRESCAN_INDEX else LAST_OPEN_BRACE[?]
        | CLOSES_VALUES := SCAN_CODE = C_CLOSE_BRACE and integer(TOKEN_CODE[PRESCAN_INDEX + 1]) = C_COLON
        | VALUE_BRACE := VALUE_BRACE[?] next (if CLOSES_VALUES then LAST_OPEN_BRACE[?] else -1) : true
        | CASE_VALUES := CASE_VALUES[?]
                         + (if CLOSES_VALUES then BRACE_COMMAS[?] + 1 else 0)
        |)
     with (| BRACKET_COUNT := 0 | COLONS_COUNT := 0 | SET_NAMES := 0 | COPY_COUNT := 0 | IN_SELECTOR_SCAN := false
           | SELECTOR_TOKENS := 0 | BRACE_COMMAS := 0 | CASE_VALUES := 0 | LAST_OPEN_BRACE := 0 | IN_SET_SCAN := false | SCAN_LAST_CODE := 0 | SCAN_STATE := PRE_IDLE | SCAN_TYPE_NAME := 0 | SCAN_TYPE_KIND := 0 | SCAN_VALUE_START := 0 | VALUE_COUNT := 0
           | USER_TYPE_COUNT := 0 | PRESCAN_MESSAGE := 0 | PRESCAN_TOKEN := 0 | PRESCAN_ARGUMENT0 := 0
           | PRESCAN_ARGUMENT1 := 0 |)
     end
   | PARSES := INTERNED and PRESCAN_MESSAGE = 0
   | PARSE_BOUND := long(BUILTIN_TYPE_COUNT + USER_TYPE_COUNT + 16) + long(8) * long(TOKEN_COUNT)
                    + long(BRACKET_COUNT) * long(BRACKET_COUNT) + long(COLONS_COUNT) * long(COLONS_COUNT)
                    + long(SET_NAMES) * long(SET_NAMES + 2) + long(32) * long(COPY_COUNT) * long(TOKEN_COUNT)
                    + long(CASE_VALUES) * long(4 * SELECTOR_TOKENS + CASE_VALUES + 16)
   | PARSE_INDEX := 0 .. (if PARSES then PARSE_BOUND else long(-1))
   | iterate PARSE_INDEX of
       (| HERE := AT[?]
        | STATE_BEFORE := PARSE_STATE[?]
        | CODE0 := integer(TOKEN_CODE[HERE])
        | CODE1 := integer(TOKEN_CODE[HERE + 1])
        | CODE2 := integer(TOKEN_CODE[HERE + 2])
        | CODE3 := integer(TOKEN_CODE[HERE + 3])
        | NAME0 := TOKEN_NAME[HERE] - 1
        | NAME1 := TOKEN_NAME[HERE + 1] - 1
        | NAME2 := TOKEN_NAME[HERE + 2] - 1
        | MODEL_NOW := CURRENT_MODEL[?]
        | INDEX_TOP := if INDEX_DEPTH[?] > 0 then INDEX_STACK[?][INDEX_DEPTH[?] - 1] else -1
        | DRAIN_ID := if INDEX_TOP >= 0 then INDEX_TOP else 0
        | DRAIN_ARRAY := INDEX_ID_ARRAY[?][DRAIN_ID]
        | DECLARES_INDEX := STATE_BEFORE = P_INDEX_DECLARE and DRAIN_ARRAY
        | LOOKUP_KEY := if DECLARES_INDEX then INDEX_ID_NAME[?][DRAIN_ID] else NAME0
        | LOOKS_UP := (STATE_BEFORE = P_TYPE_SIZE or STATE_BEFORE = P_DECLARE_NAME or STATE_BEFORE = P_CONSTANT_NAME
                       or STATE_BEFORE = P_LABEL_NAME) and CODE0 = C_NAME or DECLARES_INDEX
        | LOCAL_TOP := if LOOKS_UP then LOCAL_HEAD[?][LOOKUP_KEY] - 1 else -1
        | LOCAL_TOP_MODEL := LOCAL_MODEL[?][LOCAL_TOP]
        | STALE := LOCAL_TOP >= 0 and MODEL_CLOSED[?][LOCAL_TOP_MODEL]
        | DRAIN_DUE := (STATE_BEFORE = P_MODEL_AFTER or STATE_BEFORE = P_END_SEMICOLON) and CODE0 = C_SEMICOLON and INDEX_TOP >= 0
                       and INDEX_ID_MODEL[?][DRAIN_ID] = MODEL_NOW
        | REPEAT_DUE := STATE_BEFORE = P_EQUATION_END and TARGET[?] >= 0 and not TUPLE_ACTIVE and LAST_ENTRY >= EXPRESSION_START[?]
                        and integer(ENTRY_OP[?][LAST_ENTRY]) = OP_REPEAT
        | STATE := if STALE then P_STALL else if DRAIN_DUE then P_INDEX_TYPE else if REPEAT_DUE then P_REPEAT_START else STATE_BEFORE
        | DECLARED := LOCAL_TOP >= 0 and LOCAL_TOP_MODEL = MODEL_NOW or NAME_CONSTANT[?][LOOKUP_KEY] > 0 or NAME_TYPE[LOOKUP_KEY] > 0
                      or NAME_ALIAS[?][LOOKUP_KEY] > 0 or NAME_MODEL[?][LOOKUP_KEY] or LOOKUP_KEY >= N_LOAD and LOOKUP_KEY <= N_ISIN
        | GLOBALLY_USED := NAME_SIGNAL_EVER[?][NAME0] or NAME_LABEL_EVER[?][NAME0]
        | RESERVED := LOOKUP_KEY >= N_LOAD and LOOKUP_KEY <= N_ISIN
        | CLASH_MESSAGE := if RESERVED then T_RESERVED else if NAME_MODEL[?][LOOKUP_KEY] then T_NAME_OF_MODEL else T_DECLARED_TWICE
        | TOKEN_TYPE := if NAME0 >= 0 and NAME0 < BUILTIN_TYPE_COUNT then NAME0
                      else if NAME_TYPE[NAME0] > 0 then NAME_TYPE[NAME0] - 1 else NAME_ALIAS[?][NAME0] - 1
        | IN_COPY_TYPES := STATE = P_COPY_TYPES
        | IN_START := STATE = P_START
        | IN_MODEL_NAME := STATE = P_MODEL_NAME
        | IN_MODEL_EQUAL := STATE = P_MODEL_EQUAL
        | IN_MODEL_OPEN := STATE = P_MODEL_OPEN
        | IN_MODEL_QUESTION := STATE = P_MODEL_QUESTION
        | IN_INPUTS := STATE = P_INPUTS
        | IN_MODEL_BANG := STATE = P_MODEL_BANG
        | IN_OUTPUTS := STATE = P_OUTPUTS
        | IN_MODEL_CLOSE := STATE = P_MODEL_CLOSE
        | IN_MODEL_BODY := STATE = P_MODEL_BODY
        | IN_MODEL_AFTER := STATE = P_MODEL_AFTER
        | IN_PROGRAM := STATE = P_PROGRAM
        | IN_END_SEMICOLON := STATE = P_END_SEMICOLON
        | IN_END_CHECK := STATE = P_END_CHECK
        | IN_TYPE_STATEMENT := STATE = P_TYPE_STATEMENT
        | IN_TYPE_SKIP := STATE = P_TYPE_SKIP
        | IN_TYPE := STATE = P_TYPE
        | IN_TYPE_SIZE := STATE = P_TYPE_SIZE
        | IN_TYPE_CLOSE := STATE = P_TYPE_CLOSE
        | IN_TYPE_NAME := STATE = P_TYPE_NAME
        | IN_TYPE_INTERN := STATE = P_TYPE_INTERN
        | IN_DECLARE_NAME := STATE = P_DECLARE_NAME
        | IN_DECLARE_SEPARATOR := STATE = P_DECLARE_SEPARATOR
        | IN_CONSTANT_NAME := STATE = P_CONSTANT_NAME
        | IN_CONSTANT_EQUAL := STATE = P_CONSTANT_EQUAL
        | IN_CONSTANT_DEFINITION := STATE = P_CONSTANT_DEFINITION
        | IN_INTEGER_CONSTANT := STATE = P_INTEGER_CONSTANT
        | IN_CONSTANT_ELEMENT := STATE = P_CONSTANT_ELEMENT
        | IN_CONSTANT_SCALAR := STATE = P_CONSTANT_SCALAR
        | IN_CONSTANT_SEPARATOR := STATE = P_CONSTANT_SEPARATOR
        | IN_LABEL_NAME := STATE = P_LABEL_NAME
        | IN_LABEL_SEPARATOR := STATE = P_LABEL_SEPARATOR
        | IN_PROCESS := STATE = P_PROCESS
        | IN_PATH_COPY := STATE = P_PATH_COPY
        | IN_GUARD_COLONS := STATE = P_GUARD_COLONS
        | IN_ITERATE_NAME := STATE = P_ITERATE_NAME
        | IN_ITERATE_OF := STATE = P_ITERATE_OF
        | IN_EQUATION := STATE = P_EQUATION
        | IN_DEPENDENCE := STATE = P_DEPENDENCE
        | IN_EQUATION_END := STATE = P_EQUATION_END
        | IN_GROUP_MEMBER := STATE = P_GROUP_MEMBER
        | IN_POP := STATE = P_POP
        | IN_OPERAND := STATE = P_OPERAND
        | IN_PARAMETER := STATE = P_PARAMETER
        | IN_PARAMETER_CLOSE := STATE = P_PARAMETER_CLOSE
        | IN_OPERATOR := STATE = P_OPERATOR
        | IN_BRANCH := STATE = P_BRANCH
        | IN_PRAGMA_NAME := STATE = P_PRAGMA_NAME
        | IN_PRAGMA_OPEN := STATE = P_PRAGMA_OPEN
        | IN_PRAGMA_OBJECT := STATE = P_PRAGMA_OBJECT
        | IN_PRAGMA_CLOSE := STATE = P_PRAGMA_CLOSE
        | IN_PRAGMA_STATEMENT := STATE = P_PRAGMA_STATEMENT
        | IN_PRAGMA_OTHER := STATE = P_PRAGMA_OTHER
        | IN_PRAGMA_SKIP := STATE = P_PRAGMA_SKIP
        | IN_PRAGMA_TEXT := STATE = P_PRAGMA_TEXT
        | IN_SET_NAME := STATE = P_SET_NAME
        | IN_SET_SEPARATOR := STATE = P_SET_SEPARATOR
        | IN_SET_EMIT := STATE = P_SET_EMIT
        | IN_ALIAS_END := STATE = P_ALIAS_END
        | IN_HIDE_NAME := STATE = P_HIDE_NAME
        | IN_HIDE_SEPARATOR := STATE = P_HIDE_SEPARATOR
        | IN_DECLARE_INIT := STATE = P_DECLARE_INIT
        | IN_TUPLE_NAME := STATE = P_TUPLE_NAME
        | IN_TUPLE_SEPARATOR := STATE = P_TUPLE_SEPARATOR
        | IN_SYNC := STATE = P_SYNC
        | IN_REPEAT_START := STATE = P_REPEAT_START
        | IN_INDEX_EMIT := STATE = P_INDEX_EMIT
        | IN_REPEAT_EMIT := STATE = P_REPEAT_EMIT
        | IN_ARRAY_TO := STATE = P_ARRAY_TO
        | IN_INDEX_TYPE := STATE = P_INDEX_TYPE
        | IN_INDEX_DECLARE := STATE = P_INDEX_DECLARE
        | IN_STATE_SIGNAL := STATE = P_STATE_SIGNAL
        | IN_STATE_CALL := STATE = P_STATE_CALL
        | IN_STATE_WHEN := STATE = P_STATE_WHEN
        | IN_STATE_GUARD := STATE = P_STATE_GUARD
        | IN_CASE_IN := STATE = P_CASE_IN
        | IN_CASE_BRANCH := STATE = P_CASE_BRANCH
        | IN_CASE_COPY := STATE = P_CASE_COPY
        | IN_CASE_LITERAL := STATE = P_CASE_LITERAL
        | IN_CASE_SCAN := STATE = P_CASE_SCAN
        | IN_CASE_ELSE_VALUE := STATE = P_CASE_ELSE_VALUE
        | IN_CASE_COMPARE := STATE = P_CASE_COMPARE
        | IN_CASE_JOIN := STATE = P_CASE_JOIN
        | IN_CASE_SEPARATOR := STATE = P_CASE_SEPARATOR
        | IN_CASE_WHEN := STATE = P_CASE_WHEN
        | IN_CASE_GUARD := STATE = P_CASE_GUARD
        | PRAGMAS_HERE := IN_MODEL_BODY and CODE0 = C_NAME and NAME0 = N_PRAGMAS
        | PRAGMAS_OPEN := PRAGMAS_HERE and integer(TOKEN_CODE[HERE - 1]) = C_CLOSE
        | PRAGMAS_STARTED := PRAGMA_ITEMS[?] > 0
        | PRAGMAS_CLOSE := IN_PRAGMA_NAME and PRAGMAS_STARTED and CODE0 = C_END and CODE1 = C_NAME and NAME1 = N_PRAGMAS
        | PRAGMA_KNOWN := CODE0 = C_NAME and (NAME0 = N_INTERRUPT or NAME0 = N_BOOT or NAME0 = N_MACHINE)
        | PRAGMA_KIND := if IN_PRAGMA_NAME then NAME0 else PRAGMA_KIND[?]
        | PRAGMA_NAME_HELD := if IN_PRAGMA_OBJECT then NAME0 else PRAGMA_NAME_HELD[?]
        | PRAGMA_TOKEN_HELD := if IN_PRAGMA_OBJECT then HERE else PRAGMA_TOKEN_HELD[?]
        | INTERRUPT_HIGH := integer(SRC[TOKEN_START[HERE] + 1]) - 48
        | INTERRUPT_LOW := integer(SRC[TOKEN_START[HERE] + 2]) - 48
        | INTERRUPT_VALUE := 10 * INTERRUPT_HIGH + INTERRUPT_LOW
        | INTERRUPT_OK := TOKEN_LENGTH[HERE] = 4 and INTERRUPT_HIGH >= 0 and INTERRUPT_HIGH <= 9 and INTERRUPT_LOW >= 0
                          and INTERRUPT_LOW <= 9
        | INTERRUPT_BIT := if INTERRUPT_OK and INTERRUPT_VALUE < 64 then ulong(1) shl INTERRUPT_VALUE else ulong(0)
        | MACHINE_AT := TOKEN_START[HERE] + 1
        | MACHINE_OK := CODE0 = C_STRING and TOKEN_LENGTH[HERE] = MACHINE_TEXT_LENGTH + 2
                        and SRC[MACHINE_AT] = MACHINE_TEXT[0] and SRC[MACHINE_AT + 1] = MACHINE_TEXT[1]
                        and SRC[MACHINE_AT + 2] = MACHINE_TEXT[2] and SRC[MACHINE_AT + 3] = MACHINE_TEXT[3]
                        and SRC[MACHINE_AT + 4] = MACHINE_TEXT[4] and SRC[MACHINE_AT + 5] = MACHINE_TEXT[5]
                        and SRC[MACHINE_AT + 6] = MACHINE_TEXT[6] and SRC[MACHINE_AT + 7] = MACHINE_TEXT[7]
                        and SRC[MACHINE_AT + 8] = MACHINE_TEXT[8] and SRC[MACHINE_AT + 9] = MACHINE_TEXT[9]
        | MACHINE_STATEMENT := IN_PRAGMA_STATEMENT and PRAGMA_KIND = N_MACHINE
        | PRAGMA_MESSAGE_HERE := if IN_PRAGMA_NAME then
                                   (if PRAGMAS_CLOSE then 0
                                    else if PRAGMA_KNOWN then
                                      (if MODEL_NOW /= 0 then T_PRAGMA_TOP_ONLY
                                       else if NAME0 = N_BOOT and PRAGMA_HAS_BOOT[?] then T_BOOT_TWICE
                                       else if NAME0 = N_MACHINE and MACHINE_TOKEN[?] >= 0 then T_MACHINE_TWICE else 0)
                                    else if CODE0 = C_NAME then 0
                                    else if PRAGMAS_STARTED then T_PRAGMAS_END else T_EXPECTED_NAME)
                                 else if IN_PRAGMA_SKIP then (if CODE0 = C_EOF then T_EXPECTED_FOUND else 0)
                                 else if IN_PRAGMA_OPEN then (if CODE0 /= C_OPEN_BRACE then T_EXPECTED_FOUND else 0)
                                 else if IN_PRAGMA_OBJECT then (if CODE0 /= C_NAME then T_EXPECTED_NAME else 0)
                                 else if IN_PRAGMA_CLOSE then (if CODE0 /= C_CLOSE_BRACE then T_EXPECTED_FOUND else 0)
                                 else if MACHINE_STATEMENT then (if MACHINE_OK then 0 else T_MACHINE_UNKNOWN)
                                 else if IN_PRAGMA_STATEMENT then
                                   (if CODE0 /= C_STRING then T_INTERRUPT_STATEMENT
                                    else if not INTERRUPT_OK then (if MACHINE_TOKEN[?] >= 0 then T_INTERRUPT_NUMBER_MPS2 else T_INTERRUPT_NUMBER)
                                    else if (PRAGMA_USED[?] and INTERRUPT_BIT) /= ulong(0) then T_INTERRUPT_TWICE else 0)
                                 else 0
        | COPIED_TYPE := TYPE_COUNT[?]
        | COPIED_USER := COPIED_TYPE - BUILTIN_TYPE_COUNT
        | COPY_IS_BUILTIN := COPIED_TYPE < BUILTIN_TYPE_COUNT
        | COPY_DONE := COPIED_TYPE + 1 >= BUILTIN_TYPE_COUNT + USER_TYPE_COUNT
        | MODEL_NAME_OK := CODE0 = C_NAME
        | MODEL_NAME_CLASHES := NAME_MODEL[?][NAME0] or GLOBALLY_USED or NAME_CONSTANT[?][NAME0] > 0 or NAME_TYPE[NAME0] > 0
                                or NAME_ALIAS[?][NAME0] > 0 or NAME0 >= N_LOAD and NAME0 <= N_LEFT_TT
        | CREATES_MODEL := IN_MODEL_NAME and MODEL_NAME_OK and not MODEL_NAME_CLASHES
        | MODEL_KIND_NOW := MODEL_KIND[?][MODEL_NOW]
        | CLOSES_MODEL := (IN_MODEL_AFTER and CODE0 /= C_WHERE or IN_END_SEMICOLON) and CODE0 = C_SEMICOLON
        | MAKES_STATE_TYPE := CLOSES_MODEL and MODEL_KIND_NOW = C_AUTOMATON
        | INTERFACE_NOW := SIGNAL_COUNT[?] - MODEL_SIGNAL_START[?][MODEL_NOW]
        | NEEDS_OUTPUT := (MODEL_KIND_NOW = C_NODE or MODEL_KIND_NOW = C_FUNCTION) and INTERFACE_NOW = MODEL_INPUTS[?][MODEL_NOW]
        | IS_FUNCTION := MODEL_KIND_NOW = C_FUNCTION
        | BODY_CLOSING := IN_POP and FRAME_DEPTH[?] = 1 and FRAME_TOP_KIND = FRAME_COMPOSE and CODE0 = C_BAR_CLOSE
        | SYNC_PENDING := BODY_CLOSING and IS_FUNCTION and not SYNC_DONE[?] and INTERFACE_NOW >= 2
        | SYNC_LAST := SYNC_I[?] + 1 >= INTERFACE_NOW
        | SYNC_I := if IN_SYNC and not SYNC_LAST then SYNC_I[?] + 1 else 0
        | SYNC_DONE := if CREATES_MODEL then false else if IN_SYNC and SYNC_LAST then true else SYNC_DONE[?]
        | PARENT_NOW := MODEL_PARENT[?][MODEL_NOW]
        | ALIAS_STATEMENT := CODE2 /= C_EXTERNAL and CODE2 /= C_ENUM
        | TYPE_STATEMENT_CLASHES := GLOBALLY_USED or NAME_CONSTANT[?][NAME0] > 0 or NAME_MODEL[?][NAME0]
                                    or NAME_ALIAS[?][NAME0] > 0 or ALIAS_STATEMENT and NAME_TYPE[NAME0] > 0
        | SIZE_IS_NUMBER := CODE0 = C_NUMBER
        | SIZE_CONSTANT := NAME_CONSTANT[?][NAME0] - 1
        | SIZE_CONSTANT_TYPE := CONSTANT_TYPE[?][SIZE_CONSTANT]
        | SIZE_IS_CONSTANT := CODE0 = C_NAME and SIZE_CONSTANT >= 0 and TYPE_KIND[?][SIZE_CONSTANT_TYPE] = TK_INT
        | SIZE_VALUE := if SIZE_IS_NUMBER then TOKEN_VALUE[HERE] else CONSTANT_VALUE[?][SIZE_CONSTANT]
        | SIZE_POSITIVE := if SIZE_IS_CONSTANT and SIZE_CONSTANT_TYPE = BUILTIN_ULONG then SIZE_VALUE /= long(0) else SIZE_VALUE > long(0)
        | SIZE_MESSAGE := if SIZE_IS_NUMBER then (if TOKEN_BIG[HERE] then T_LITERAL_BIG else 0)
                          else if SIZE_IS_CONSTANT then 0
                          else if CODE0 = C_NAME and not DECLARED then T_CONSTANT_UNDECLARED
                          else T_EXPECTED_INTEGER_CONSTANT
        | INTERN_CANDIDATE := CANDIDATE[?]
        | INTERN_MATCHES := INTERN_CANDIDATE >= 0 and TYPE_SIZE[?][INTERN_CANDIDATE] = ARRAY_SIZE[?]
                            and TYPE_ELEMENT[?][INTERN_CANDIDATE] = ARRAY_ELEMENT[?] and TYPE_KIND[?][INTERN_CANDIDATE] = TK_ARRAY
        | ELEMENT_TYPE := TOKEN_TYPE
        | BUCKET_HERE := integer((ulong(ELEMENT_TYPE) * ulong(40503) + ARRAY_SIZE[?] * ulong(2654435761)) modulo ulong(BUCKET_CAP))
        | DRAIN_BOUND := INDEX_ID_BOUND[?][DRAIN_ID]
        | DRAIN_BOUND_OP := integer(ENTRY_OP[?][DRAIN_BOUND])
        | DRAIN_CONSTANT := if DRAIN_BOUND_OP = OP_SIGNAL then NAME_CONSTANT[?][ENTRY_NAME[?][DRAIN_BOUND]] - 1 else -1
        | DRAIN_TYPE := if DRAIN_BOUND_OP = OP_CONST then ENTRY_TYPE[?][DRAIN_BOUND]
                        else if DRAIN_CONSTANT >= 0 then CONSTANT_TYPE[?][DRAIN_CONSTANT] else -1
        | DRAIN_VALUE := if DRAIN_BOUND_OP = OP_CONST then ENTRY_VALUE[?][DRAIN_BOUND]
                         else if DRAIN_CONSTANT >= 0 then CONSTANT_VALUE[?][DRAIN_CONSTANT] else long(0)
        | DRAIN_OK := INDEX_ID_BOUND_END[?][DRAIN_ID] - DRAIN_BOUND = 1 and DRAIN_TYPE >= 0
                      and TYPE_KIND[?][if DRAIN_TYPE >= 0 then DRAIN_TYPE else 0] = TK_INT and DRAIN_VALUE >= long(1)
        | DRAIN_SIZE := ulong(DRAIN_VALUE + long(integer(DRAIN_ARRAY)))
        | DRAIN_BUCKET := integer((ulong(BUILTIN_INTEGER) * ulong(40503) + DRAIN_SIZE * ulong(2654435761)) modulo ulong(BUCKET_CAP))
        | CREATES_ARRAY_TYPE := IN_TYPE_INTERN and INTERN_CANDIDATE < 0
        | TYPE_FINISHED := IN_TYPE_NAME and ARRAY_SIZE[?] = ulong(0) or IN_TYPE_INTERN and (INTERN_CANDIDATE < 0 or INTERN_MATCHES)
        | FINISHED_TYPE := if IN_TYPE_NAME then TOKEN_TYPE else if INTERN_CANDIDATE < 0 then TYPE_COUNT[?] else INTERN_CANDIDATE
        | DECLARED_TYPE := PARSED_TYPE[?]
        | DECLARED_KIND := TYPE_KIND[?][DECLARED_TYPE]
        | DECLARED_ARRAY := DECLARED_KIND = TK_ARRAY
        | DECLARED_ELEMENT := TYPE_ELEMENT[?][DECLARED_TYPE]
        | DECLARED_BASE := if DECLARED_ARRAY then DECLARED_ELEMENT else DECLARED_TYPE
        | DECLARED_SIZE := TYPE_SIZE[?][DECLARED_TYPE]
        | DECLARE_MESSAGE := if CODE0 /= C_NAME then T_EXPECTED_NAME else if DECLARED then CLASH_MESSAGE
                             else if TYPE_KIND[?][DECLARED_BASE] = TK_EXTERNAL then T_EXTERNAL_SIGNAL
                             else if ROLE[?] = ROLE_INPUT and DECLARED_ARRAY and MODEL_NOW = 0 then T_INPUT_SCALAR
                             else if ROLE[?] = ROLE_INPUT and DECLARED_ARRAY then T_ARRAYS_TO_MODELS
                             else if ROLE[?] = ROLE_OUTPUT and DECLARED_ARRAY then T_OUTPUT_ARRAY
                             else 0
        | APPENDS_SIGNAL := IN_DECLARE_NAME and DECLARE_MESSAGE = 0
        | INDEX_DECLARE_MESSAGE := if DRAIN_ARRAY and DECLARED then CLASH_MESSAGE else 0
        | APPENDS_INDEX_SIGNAL := IN_INDEX_DECLARE and DRAIN_ARRAY and INDEX_DECLARE_MESSAGE = 0
        | APPENDS_LABEL := IN_LABEL_NAME and CODE0 = C_NAME and not DECLARED
        | PUSHES_LOCAL := APPENDS_SIGNAL or APPENDS_LABEL
        | CONSTANT_NAME_MESSAGE := if CODE0 /= C_NAME then T_EXPECTED_NAME
                                   else if DECLARED or GLOBALLY_USED then CLASH_MESSAGE else 0
        | DEFINITION_IS_STRING := CODE0 = C_STRING
        | STRING_BYTES := TOKEN_TEXT[HERE + 1] - TOKEN_TEXT[HERE]
        | DEFINITION_MESSAGE := if DEFINITION_IS_STRING then
                                  (if not DECLARED_ARRAY or DECLARED_ELEMENT /= BUILTIN_UBYTE then T_CONSTANT_STRING
                                   else if ulong(STRING_BYTES) /= DECLARED_SIZE then T_CONSTANT_COUNT else 0)
                                else if CODE0 = C_OPEN_BRACKET and not DECLARED_ARRAY then T_CONSTANT_LIST
                                else 0
        | CONVERTS := CODE1 = C_OPEN and CODE0 /= C_MINUS
        | CONVERSION_OK := TOKEN_TYPE >= 0 and TYPE_KIND[?][TOKEN_TYPE] = TK_INT
        | SIGN_AT := HERE + 2 * integer(CONVERTS)
        | NEGATES := integer(TOKEN_CODE[SIGN_AT]) = C_MINUS
        | NUMBER_AT := SIGN_AT + integer(NEGATES)
        | CONSTANT_LITERAL := TOKEN_VALUE[NUMBER_AT]
        | CONSTANT_LITERAL_TYPE := if CONSTANT_LITERAL < long(32768) then BUILTIN_SHORT
                                   else if CONSTANT_LITERAL < long(2147483648) then BUILTIN_INTEGER else BUILTIN_LONG
        | SIGNED_LITERAL := if NEGATES then -CONSTANT_LITERAL else CONSTANT_LITERAL
        | TARGET_BYTES := BUILTIN_BYTES[TOKEN_TYPE]
        | TARGET_MASK := if TARGET_BYTES = 1 then ulong(255) else if TARGET_BYTES = 2 then ulong(65535) else ulong(4294967295)
        | MASKED := long(ulong(SIGNED_LITERAL) and TARGET_MASK)
        | HALF_RANGE := long(TARGET_MASK / ulong(2)) + long(1)
        | WRAPPED := if TARGET_BYTES = 8 then SIGNED_LITERAL
                     else if BUILTIN_SIGNED[TOKEN_TYPE] = 1 and MASKED >= HALF_RANGE then MASKED - long(TARGET_MASK) - long(1)
                     else MASKED
        | INTEGER_CONSTANT_MESSAGE := if CONVERTS and not CONVERSION_OK then T_CONVERSION
                                      else if integer(TOKEN_CODE[NUMBER_AT]) /= C_NUMBER then T_CONSTANT_LITERAL
                                      else if TOKEN_BIG[NUMBER_AT] then T_LITERAL_BIG
                                      else if CONVERTS and integer(TOKEN_CODE[NUMBER_AT + 1]) /= C_CLOSE then T_EXPECTED_FOUND
                                      else 0
        | INTEGER_CONSTANT_TOKEN := if CONVERTS and not CONVERSION_OK then HERE
                                    else if INTEGER_CONSTANT_MESSAGE = T_EXPECTED_FOUND then NUMBER_AT + 1 else NUMBER_AT
        | VALUE_TYPE := CONSTANT_VALUE_TYPE[?]
        | SUBTYPE_TARGET := if IN_CONSTANT_ELEMENT then DECLARED_ELEMENT else DECLARED_TYPE
        | IS_SUBTYPE := VALUE_TYPE = SUBTYPE_TARGET
                        or TYPE_KIND[?][SUBTYPE_TARGET] = TK_INT
                           and (BUILTIN_SIGNED[VALUE_TYPE] = BUILTIN_SIGNED[SUBTYPE_TARGET]
                                and BUILTIN_BYTES[VALUE_TYPE] <= BUILTIN_BYTES[SUBTYPE_TARGET]
                                or BUILTIN_SIGNED[VALUE_TYPE] = 0 and BUILTIN_SIGNED[SUBTYPE_TARGET] = 1
                                   and BUILTIN_BYTES[SUBTYPE_TARGET] > BUILTIN_BYTES[VALUE_TYPE])
        | ELEMENT_COUNT := LIST_COUNT[?] + 1
        | ELEMENT_MESSAGE := if not IS_SUBTYPE then T_CONSTANT_ELEMENT
                             else if CODE0 = C_COMMA then 0
                             else if CODE0 /= C_CLOSE_BRACKET then T_EXPECTED_FOUND
                             else if ulong(ELEMENT_COUNT) /= DECLARED_SIZE then T_CONSTANT_COUNT else 0
        | SCALAR_MESSAGE := if DECLARED_ARRAY or not IS_SUBTYPE then T_CONSTANT_TYPE else 0
        | STORES_STRING := IN_CONSTANT_DEFINITION and DEFINITION_IS_STRING and DEFINITION_MESSAGE = 0
        | STORES_LIST := IN_CONSTANT_ELEMENT and ELEMENT_MESSAGE = 0 and CODE0 = C_CLOSE_BRACKET
        | STORES_SCALAR := IN_CONSTANT_SCALAR and SCALAR_MESSAGE = 0
        | STORES_CONSTANT := STORES_STRING or STORES_LIST or STORES_SCALAR
        | STORES_TABLE := STORES_STRING or STORES_LIST
        | APPENDS_POOL := IN_CONSTANT_ELEMENT and IS_SUBTYPE
        | CONSTANT_VALUE_NOW := if STORES_TABLE then long(TABLE_COUNT[?]) else CONSTANT_VALUE_HELD[?]
        | FRAME_TOP := FRAME_DEPTH[?] - 1
        | FRAME_TOP_KIND := FRAME_KIND[?][FRAME_TOP]
        | FRAME_TOP_VALUE := FRAME_VALUE[?][FRAME_TOP]
        | IN_LOOP := LOOP_NOW[?] >= 0
        | LABEL_FOLLOWS := CODE0 = C_NAME and CODE1 = C_COLONS
        | PROCESS_MESSAGE := if CODE0 = C_OPEN_BAR then 0
                             else if LABEL_FOLLOWS or CODE0 = C_ON or CODE0 = C_CASE or CODE0 = C_OPEN_BRACE then (if IN_LOOP then T_ONLY_DEFINITIONS else 0)
                             else if CODE0 = C_ITERATE or CODE0 = C_ARRAY then
                               (if IN_LOOP then T_ITERATE_NESTED else if GUARD_NODE[?] >= 0 then T_ITERATE_GUARDED else 0)
                             else 0
        | STATE_ACTION_OPENS := IN_PROCESS and LABEL_FOLLOWS and PROCESS_MESSAGE = 0 and MODEL_KIND_NOW = C_AUTOMATON
                                and not STATE_GUARDED[?]
        | STATE_GUARDED := if IN_STATE_GUARD then true else if CREATES_USE then false else STATE_GUARDED[?]
        | CREATES_USE := IN_PROCESS and CODE0 /= C_OPEN_BAR and LABEL_FOLLOWS and PROCESS_MESSAGE = 0 and not STATE_ACTION_OPENS
        | CREATES_GUARD := IN_GUARD_COLONS and CODE0 = C_COLONS or IN_CASE_GUARD and CASE_GUARD_MESSAGE = 0 or IN_STATE_GUARD
        | CASE_TOP_START := FRAME_CASE_START[?][FRAME_TOP]
        | CASE_TOP_END := FRAME_CASE_END[?][FRAME_TOP]
        | CASE_LAST_TOP := FRAME_CASE_LAST[?][FRAME_TOP]
        | CASE_AFTER_ELSE := FRAME_TOP_VALUE = 1
        | CASE_BRANCH_EXPECTED := if CASE_AFTER_ELSE then C_END else C_OPEN_BRACE
        | CASE_BRANCH_MESSAGE := if CODE0 = C_OPEN_BRACE then (if CASE_AFTER_ELSE then T_EXPECTED_FOUND else 0)
                                 else if CODE0 = C_ELSE then (if CASE_AFTER_ELSE or CASE_LAST_TOP < 0 then T_EXPECTED_FOUND else 0)
                                 else if CODE0 = C_END then (if CASE_LAST_TOP < 0 then T_EXPECTED_FOUND else 0)
                                 else T_EXPECTED_FOUND
        | CASE_BRANCH_STARTS := IN_CASE_BRANCH and (CODE0 = C_OPEN_BRACE or CODE0 = C_ELSE) and CASE_BRANCH_MESSAGE = 0
        | CASE_ENDS := IN_CASE_BRANCH and CODE0 = C_END and CASE_BRANCH_MESSAGE = 0
        | CASE_OPENS := IN_CASE_IN and CODE0 = C_IN
        | CASE_ELSE_BRANCH := if CASE_BRANCH_STARTS then CODE0 = C_ELSE else CASE_ELSE_BRANCH[?]
        | CASE_GUARD_MESSAGE := if not CASE_ELSE_BRANCH[?] and CODE0 /= C_COLON then T_EXPECTED_FOUND else 0
        | CASE_VALUE_MESSAGE := if not LITERAL_IS then T_CASE_VALUE else LITERAL_MESSAGE
        | CASE_COPYING := IN_CASE_COPY or IN_CASE_ELSE_VALUE
        | CASE_DUPLICATE := IN_CASE_SCAN and ENTRY_OP[?][CASE_VALUE_ENTRY[?][CASE_SCAN_AT[?]]] = ENTRY_OP[?][ENTRY_COUNT[?] - 1]
                            and ENTRY_VALUE[?][CASE_VALUE_ENTRY[?][CASE_SCAN_AT[?]]] = ENTRY_VALUE[?][ENTRY_COUNT[?] - 1]
        | CASE_ITEM_DONE := IN_CASE_COMPARE and CASE_BRANCH_ITEMS[?] = 0 or IN_CASE_JOIN
        | CASE_ITEM_NEXT := if CASE_ELSE_BRANCH[?] then (if CASE_VALUE_PREV[?][CASE_WALK[?]] >= 0 then P_CASE_COPY else P_CASE_WHEN)
                            else P_CASE_SEPARATOR
        | CASE_BRANCH_ITEMS := if CASE_BRANCH_STARTS then 0 else CASE_BRANCH_ITEMS[?] + integer(CASE_ITEM_DONE)
        | CASE_WALK := if CASE_BRANCH_STARTS then CASE_LAST_TOP
                       else if CASE_ITEM_DONE and CASE_ELSE_BRANCH[?] then CASE_VALUE_PREV[?][CASE_WALK[?]] else CASE_WALK[?]
        | CASE_SCAN_AT := if IN_CASE_LITERAL then CASE_LAST_TOP else if IN_CASE_SCAN then CASE_VALUE_PREV[?][CASE_SCAN_AT[?]]
                          else CASE_SCAN_AT[?]
        | CASE_LITERAL_TOKEN := if IN_CASE_LITERAL then LITERAL_MESSAGE_TOKEN else CASE_LITERAL_TOKEN[?]
        | CASE_OP_TOKEN := if CASE_ELSE_BRANCH[?] then GUARD_START_TOKEN[?] else CASE_LITERAL_TOKEN[?]
        | CASE_VALUE_SLOT := if GO and IN_CASE_LITERAL then CASE_VALUE_COUNT[?] else -1
        | CASE_VALUE_ENTRY := CASE_VALUE_ENTRY[?] next CASE_VALUE_SLOT : ENTRY_COUNT[?]
        | CASE_VALUE_PREV := CASE_VALUE_PREV[?] next CASE_VALUE_SLOT : CASE_LAST_TOP
        | CASE_VALUE_COUNT := CASE_VALUE_COUNT[?] + integer(CASE_VALUE_SLOT >= 0)
        | CASE_FRAME_SLOT := if GO and CASE_OPENS then FRAME_DEPTH[?] else -1
        | FRAME_CASE_START := FRAME_CASE_START[?] next CASE_FRAME_SLOT : EXPRESSION_START[?]
        | FRAME_CASE_END := FRAME_CASE_END[?] next CASE_FRAME_SLOT : ENTRY_COUNT[?]
        | FRAME_CASE_LAST := FRAME_CASE_LAST[?] next (if CASE_FRAME_SLOT >= 0 then CASE_FRAME_SLOT else if CASE_VALUE_SLOT >= 0 then FRAME_TOP else -1)
                             : (if CASE_FRAME_SLOT >= 0 then -1 else CASE_VALUE_COUNT[?])
        | CASE_DEPTH := CASE_DEPTH[?] + integer(GO and CASE_OPENS) - integer(GO and CASE_ENDS)
        | PATH_PARENT_START := if CREATES_USE then USE_PATH_START[?][LABEL_NODE[?]] else GUARD_PATH_START[?][GUARD_NODE[?]]
        | PATH_PARENT_LENGTH := if CREATES_USE then (if LABEL_NODE[?] >= 0 then USE_PATH_LENGTH[?][LABEL_NODE[?]] else 0)
                                else if GUARD_NODE[?] >= 0 then GUARD_PATH_LENGTH[?][GUARD_NODE[?]] else 0
        | STARTS_PATH := CREATES_USE or CREATES_GUARD
        | PATH_FROM := if STARTS_PATH then PATH_PARENT_START else if IN_PATH_COPY then PATH_FROM[?] + 1 else PATH_FROM[?]
        | PATH_LEFT := if STARTS_PATH then PATH_PARENT_LENGTH else if IN_PATH_COPY then PATH_LEFT[?] - 1 else PATH_LEFT[?]
        | PATH_APPEND := if CREATES_USE then NAME0 else if CREATES_GUARD then GUARD_COUNT[?] else PATH_APPEND[?]
        | PATH_VALUE := PATH_VALUE[?] next (if IN_PATH_COPY then PATH_COUNT[?] else -1)
                        : (if PATH_LEFT[?] > 0 then PATH_VALUE[?][PATH_FROM[?]] else PATH_APPEND[?])
        | PATH_COUNT := PATH_COUNT[?] + integer(IN_PATH_COPY)
        | FOLLOWER := if CODE0 = C_NAME then CODE1 else -1
        | EQUATION_MESSAGE := if IN_LOOP and FOLLOWER /= C_DEFINE
                                 and not (not LOOP_SEED[?] and (FOLLOWER = C_OPEN_BRACE or FOLLOWER = C_OPEN))
                              then T_ONLY_DEFINITIONS else 0
        | TUPLE_OPENS := IN_PROCESS and CODE0 = C_OPEN and CODE1 = C_NAME and (CODE2 = C_COMMA or CODE2 = C_CLOSE and CODE3 = C_DEFINE) and PROCESS_MESSAGE = 0
        | TUPLE_SEPARATOR_MESSAGE := if CODE0 = C_COMMA then 0
                                     else if CODE0 /= C_CLOSE or CODE1 /= C_DEFINE or CODE2 /= C_OPEN then T_EXPECTED_FOUND else 0
        | TUPLE_SEPARATOR_EXPECTED := if CODE0 /= C_CLOSE then C_CLOSE else if CODE1 /= C_DEFINE then C_DEFINE else C_OPEN
        | TUPLE_DEFINES := IN_TUPLE_SEPARATOR and CODE0 = C_CLOSE and TUPLE_SEPARATOR_MESSAGE = 0
        | TUPLE_ACTIVE := TUPLE_INDEX[?] >= 0
        | TUPLE_EXTRA := TUPLE_ACTIVE and TUPLE_INDEX[?] >= TUPLE_ARITY[?]
        | TUPLE_CONTINUES := IN_EQUATION_END and TUPLE_ACTIVE and CODE0 = C_COMMA
        | TUPLE_STARTS := TUPLE_DEFINES or TUPLE_CONTINUES
        | TUPLE_NEXT := if TUPLE_DEFINES then 0 else TUPLE_INDEX[?] + 1
        | TUPLE_NAME_TOKEN := TUPLE_TOKEN[?] + 1 + 2 * TUPLE_NEXT
        | TUPLE_NAMES_TARGET := TUPLE_STARTS and TUPLE_NEXT < TUPLE_ARITY[?]
        | TUPLE_FIRST_NAME := TOKEN_NAME[TUPLE_TOKEN[?] + 1] - 1
        | TUPLE_END_MESSAGE := if CODE0 /= C_COMMA and CODE0 /= C_CLOSE then T_EXPECTED_FOUND
                               else if CODE0 = C_CLOSE and TUPLE_INDEX[?] + 1 /= TUPLE_ARITY[?] then T_WRONG_ARGUMENTS else 0
        | TUPLE_TOKEN := if TUPLE_OPENS then HERE else TUPLE_TOKEN[?]
        | TUPLE_ARITY := if TUPLE_OPENS then 0 else if IN_TUPLE_NAME then TUPLE_ARITY[?] + 1 else TUPLE_ARITY[?]
        | TUPLE_INDEX := if TUPLE_DEFINES then 0 else if TUPLE_CONTINUES then TUPLE_INDEX[?] + 1
                         else if IN_EQUATION_END and TUPLE_ACTIVE then -1 else TUPLE_INDEX[?]
        | STARTS_EXPRESSION := IN_PROCESS and (CODE0 = C_ON or CODE0 = C_CASE) and PROCESS_MESSAGE = 0
                               or IN_ARRAY_TO and CODE0 = C_TO
                               or TUPLE_STARTS or CASE_BRANCH_STARTS or STATE_ACTION_OPENS
                               or IN_EQUATION and EQUATION_MESSAGE = 0 and FOLLOWER /= C_ARROW
                               or CONTINUES_GROUP
        | LAST_ENTRY := ENTRY_COUNT[?] - 1
        | LAST_IS_CALL := ENTRY_OP[?][LAST_ENTRY] = OP_CALL and LAST_ENTRY >= EXPRESSION_START[?]
        | MAKES_GROUP := TARGET[?] < 0 and (CODE0 = C_CLOCK_EQUAL or not LAST_IS_CALL)
        | EQUATION_END_MESSAGE := if IN_EQUATION_END and TUPLE_ACTIVE then TUPLE_END_MESSAGE
                                else if IN_EQUATION_END and MAKES_GROUP and CODE0 /= C_CLOCK_EQUAL then T_EXPECTED_DEFINITION else 0
        | CONTINUES_GROUP := (IN_EQUATION_END and MAKES_GROUP or IN_GROUP_MEMBER) and CODE0 = C_CLOCK_EQUAL
        | APPENDS_EQUATION := IN_EQUATION_END and not MAKES_GROUP and not TUPLE_EXTRA
        | APPENDS_MEMBER := IN_EQUATION_END and MAKES_GROUP and CODE0 = C_CLOCK_EQUAL or IN_GROUP_MEMBER or IN_SYNC
        | APPENDS_GROUP := IN_GROUP_MEMBER and CODE0 /= C_CLOCK_EQUAL or IN_SYNC and SYNC_LAST
        | IS_STATEMENT := TARGET[?] < 0 and LAST_IS_CALL
                          and (ENTRY_NAME[?][LAST_ENTRY] = N_INITIAL or ENTRY_NAME[?][LAST_ENTRY] = N_TRANSITION)
        | DEPENDENCE_MESSAGE := if CODE0 = C_ARROW then (if CODE1 /= C_NAME and CODE1 /= C_OPEN_BRACE then T_ARROW_NAMES else 0)
                                else if not SET_ARROWED[?] then T_EXPECTED_FOUND
                                else if CODE0 /= C_BAR and CODE0 /= C_BAR_CLOSE then T_ARROW_NAMES else 0
        | EMIT_LAST_J := EMIT_J[?] + 1 >= SET_RIGHT_COUNT[?]
        | EMIT_LAST := EMIT_LAST_J and EMIT_I[?] + 1 >= SET_LEFT_COUNT[?]
        | EMIT_FROM_TOKEN := SET_LEFT_START[?] + 2 * EMIT_I[?]
        | EMIT_TO_TOKEN := SET_RIGHT_START[?] + 2 * EMIT_J[?]
        | APPENDS_DEPENDENCE := IN_SET_EMIT
        | SET_MESSAGE := if IN_SET_NAME then (if CODE0 /= C_NAME then T_EXPECTED_NAME else 0)
                         else if IN_SET_SEPARATOR then (if CODE0 /= C_COMMA and CODE0 /= C_CLOSE_BRACE then T_EXPECTED_FOUND else 0)
                         else 0
        | HIDE_OPENS := (IN_POP or IN_MODEL_AFTER) and CODE0 = C_SLASH
        | INNER_WHERE_OPENS := IN_POP and CODE0 = C_WHERE
        | HIDE_MESSAGE := if IN_HIDE_NAME and CODE0 /= C_NAME then T_EXPECTED_NAME else 0
        | APPENDS_HIDE := IN_HIDE_NAME and CODE0 = C_NAME
        | EMPTY_COMPOSITION := CODE0 = C_BAR_CLOSE and integer(TOKEN_CODE[HERE - 1]) = C_OPEN_BAR
        | POP_COMPOSE_BREAKS := FRAME_TOP_KIND = FRAME_COMPOSE and CODE0 = C_BAR and CODE1 /= C_BAR_CLOSE
        | POP_ITERATE_SEEDS := FRAME_TOP_KIND = FRAME_ITERATE and not LOOP_SEED[?] and CODE0 = C_WITH
        | POP_MESSAGE := if HIDE_OPENS or INNER_WHERE_OPENS then 0
                         else if FRAME_TOP_KIND = FRAME_COMPOSE then
                           (if CODE0 /= C_BAR and CODE0 /= C_BAR_CLOSE then T_EXPECTED_FOUND else 0)
                         else if FRAME_TOP_KIND = FRAME_ITERATE and not POP_ITERATE_SEEDS and CODE0 /= C_END then T_EXPECTED_FOUND
                         else 0
        | POPS_FRAME := CASE_ENDS or IN_POP and FRAME_TOP_KIND /= FRAME_CASE and not SYNC_PENDING and not POP_COMPOSE_BREAKS and not POP_ITERATE_SEEDS and not HIDE_OPENS and not INNER_WHERE_OPENS
                      and POP_MESSAGE = 0
        | PUSHES_FRAME := IN_PROCESS and PROCESS_MESSAGE = 0 and (CODE0 = C_OPEN_BAR or LABEL_FOLLOWS and not STATE_ACTION_OPENS)
                          or CREATES_GUARD or IN_ITERATE_OF and CODE0 = C_OF or CASE_OPENS
        | PUSHED_FRAME_KIND := if IN_PROCESS then (if CODE0 = C_OPEN_BAR then FRAME_COMPOSE else FRAME_LABEL)
                               else if IN_GUARD_COLONS or IN_CASE_GUARD or IN_STATE_GUARD then FRAME_GUARD else if IN_CASE_IN then FRAME_CASE else FRAME_ITERATE
        | PUSHED_FRAME_VALUE := if IN_PROCESS then USE_COUNT[?] else if IN_GUARD_COLONS or IN_CASE_GUARD or IN_STATE_GUARD then GUARD_COUNT[?]
                                else if IN_CASE_IN then 0 else LOOP_COUNT[?] - 1
        | CASE_ELSE_MARKS := CASE_BRANCH_STARTS and CODE0 = C_ELSE
        | FRAME_KIND := FRAME_KIND[?] next (if PUSHES_FRAME then FRAME_DEPTH[?] else -1) : PUSHED_FRAME_KIND
        | FRAME_VALUE := FRAME_VALUE[?] next (if PUSHES_FRAME then FRAME_DEPTH[?] else if CASE_ELSE_MARKS then FRAME_TOP else -1)
                         : (if CASE_ELSE_MARKS then 1 else PUSHED_FRAME_VALUE)
        | FRAME_DEPTH := FRAME_DEPTH[?] + integer(PUSHES_FRAME) - integer(POPS_FRAME)
        | PENDING_TOP := PENDING_DEPTH[?] - 1
        | HAS_PENDING := PENDING_TOP >= 0
        | TOP_OP := PENDING_OP[?][PENDING_TOP]
        | TOP_PRECEDENCE := PENDING_PRECEDENCE[?][PENDING_TOP]
        | TOP_TOKEN := PENDING_TOKEN[?][PENDING_TOP]
        | TOP_IS_OPENER := HAS_PENDING and OP_IS_OPENER[TOP_OP] = 1
        | TOP_REDUCIBLE := HAS_PENDING and not TOP_IS_OPENER
        | OPENER_NOW := OPENER_TOP[?]
        | OPENER_OP := PENDING_OP[?][OPENER_NOW]
        | TOP_CALLEE := TOKEN_NAME[TOP_TOKEN] - 1
        | POST_KEY := if not HAS_PENDING then OP_CONST
                      else if TOP_OP = OP_CALL and TOP_CALLEE = N_LEFT_TT then OP_LEFT_TT
                      else if TOP_OP = OP_CALL and TOP_CALLEE = N_ABS then OP_ABS
                      else if TOP_OP = OP_OPEN_SQUARE and CODE1 = C_BACKSLASHES then OP_RECOVER_SQUARE else TOP_OP
        | INTRINSIC_CALL := POST_KEY = OP_LEFT_TT or POST_KEY = OP_ABS
        | ARGUMENTS_EXPECTED := if POST_KEY = OP_ABS then 1 else 2
        | MISSING_MESSAGE := if TOP_OP = OP_IF_MARK then T_EXPECTED_THEN else if TOP_OP = OP_THEN_MARK then T_EXPECTED_ELSE
                             else T_UNBALANCED
        | INIT_LITERAL_BASE := HERE + 1 + integer(CODE0 /= C_INIT)
        | LITERAL_AT := if IN_OPERATOR then
                          INIT_LITERAL_BASE + integer(integer(TOKEN_CODE[INIT_LITERAL_BASE]) = C_MINUS
                                                      and integer(TOKEN_CODE[INIT_LITERAL_BASE + 1]) = C_NUMBER)
                        else HERE + integer((IN_DECLARE_INIT or IN_CASE_COPY or IN_CASE_LITERAL) and CODE0 = C_MINUS and CODE1 = C_NUMBER)
        | LITERAL_CODE := integer(TOKEN_CODE[LITERAL_AT])
        | LITERAL_NEXT_CODE := integer(TOKEN_CODE[LITERAL_AT + 1])
        | LITERAL_NEGATED := IN_OPERATOR and LITERAL_AT = INIT_LITERAL_BASE + 1 or (IN_DECLARE_INIT or IN_CASE_LITERAL) and LITERAL_AT = HERE + 1
        | LITERAL_IS_NUMBER := LITERAL_CODE = C_NUMBER
        | LITERAL_IS_BOOLEAN := LITERAL_CODE = C_TRUE or LITERAL_CODE = C_FALSE
        | LITERAL_IS_TYPED_ENUM := LITERAL_CODE = C_NAME and LITERAL_NEXT_CODE = C_HASH
        | LITERAL_IS_ENUM := LITERAL_IS_TYPED_ENUM or LITERAL_CODE = C_HASH
        | LITERAL_IS := LITERAL_IS_NUMBER or LITERAL_IS_BOOLEAN or LITERAL_IS_ENUM
        | LITERAL_VALUE_NAME_AT := if LITERAL_IS_TYPED_ENUM then LITERAL_AT + 2 else LITERAL_AT + 1
        | LITERAL_MESSAGE := if LITERAL_IS_NUMBER and TOKEN_BIG[LITERAL_AT] then T_LITERAL_BIG
                             else if LITERAL_IS_ENUM and integer(TOKEN_CODE[LITERAL_VALUE_NAME_AT]) /= C_NAME then T_EXPECTED_NAME
                             else 0
        | LITERAL_MESSAGE_TOKEN := if LITERAL_IS_ENUM then LITERAL_VALUE_NAME_AT else LITERAL_AT
        | LITERAL_NUMBER := TOKEN_VALUE[LITERAL_AT]
        | LITERAL_VALUE := if LITERAL_IS_NUMBER then (if LITERAL_NEGATED then -LITERAL_NUMBER else LITERAL_NUMBER)
                           else if LITERAL_IS_BOOLEAN then long(integer(LITERAL_CODE = C_TRUE))
                           else long(TOKEN_NAME[LITERAL_VALUE_NAME_AT] - 1)
        | LITERAL_TYPE := if LITERAL_IS_BOOLEAN then BUILTIN_BOOLEAN
                          else if LITERAL_IS_ENUM then (if LITERAL_IS_TYPED_ENUM then NAME_AT_LITERAL else -1)
                          else if LITERAL_NUMBER < long(32768) then BUILTIN_SHORT
                          else if LITERAL_NUMBER < long(2147483648) then BUILTIN_INTEGER else BUILTIN_LONG
        | NAME_AT_LITERAL := TOKEN_NAME[LITERAL_AT] - 1
        | LITERAL_END := if LITERAL_IS_TYPED_ENUM then LITERAL_AT + 3 else if LITERAL_IS_ENUM then LITERAL_AT + 2 else LITERAL_AT + 1
        | DELAY_HAS_INIT := CODE1 = C_INIT
        | INIT_IS_NAME := not LITERAL_IS and LITERAL_CODE = C_NAME
        | DELAY_NAME_INIT := DELAY_HAS_INIT and INIT_IS_NAME
        | DECLARE_INIT_MESSAGE := if LITERAL_IS then LITERAL_MESSAGE else if INIT_IS_NAME then 0 else T_DELAY_INITIAL
        | CALL_HEAD_HERE := (CODE0 = C_NAME or CODE0 >= C_EVENT and CODE0 <= C_LONG)
                            and (CODE1 = C_OPEN or CODE1 = C_OPEN_BRACE and not VALUE_BRACE[HERE + 1])
        | EMPTY_CALL := CODE0 = C_CLOSE and HAS_PENDING and TOP_OP = OP_CALL and integer(TOKEN_CODE[HERE - 1]) = C_OPEN
        | OPERAND_CASE := if EMPTY_CALL then X_EMPTY_CALL
                          else if LITERAL_IS then X_LITERAL
                          else if CALL_HEAD_HERE then (if CODE1 = C_OPEN then X_CALL else X_PARAMETERS)
                          else if CODE0 = C_NAME then X_SIGNAL
                          else if CODE0 = C_OPEN then X_OPEN_PAREN
                          else if CODE0 = C_IF then X_IF
                          else if PREFIX_PRECEDENCE[CODE0] > 0 then X_PREFIX
                          else if CODE0 = C_PLUS then X_PLUS
                          else X_FAIL
        | OPERAND_MESSAGE := if OPERAND_CASE = X_LITERAL then LITERAL_MESSAGE
                             else if OPERAND_CASE = X_PREFIX and IS_FUNCTION and OP_TEMPLATE_KIND[PREFIX_OP[CODE0]] > 0 then T_FUNCTION_MEMORY
                             else if OPERAND_CASE = X_EMPTY_CALL and INTRINSIC_CALL then T_WRONG_ARGUMENTS
                             else if OPERAND_CASE = X_FAIL then T_EXPECTED_EXPRESSION else 0
        | BINARY_HERE := BINARY_PRECEDENCE[CODE0]
        | IS_TERMINATOR := CODE0 = C_BAR or CODE0 = C_BAR_CLOSE or CODE0 = C_SEMICOLON or CODE0 = C_CLOCK_EQUAL or CODE0 = C_OF
                           or CODE0 = C_WITH or CODE0 = C_END or CODE0 = C_COLONS or CODE0 = C_CLOSE
                           or CODE0 = C_COMMA and TUPLE_ACTIVE and OPENER_NOW < 0 or CODE0 = C_IN
                           or (CODE0 = C_OPEN_BRACE or CODE0 = C_ELSE) and CASE_DEPTH[?] > 0
        | OPERATOR_CASE := if BINARY_HERE > 0 then (if TOP_REDUCIBLE and TOP_PRECEDENCE >= BINARY_HERE then X_REDUCE else X_BINARY)
                           else if (CODE0 = C_THEN or CODE0 = C_ELSE) and OPENER_NOW >= 0 then
                             (if TOP_REDUCIBLE then X_REDUCE
                              else if CODE0 = C_THEN then (if TOP_OP = OP_IF_MARK then X_THEN else X_FAIL)
                              else if TOP_OP = OP_THEN_MARK then X_ELSE else X_FAIL)
                           else if CODE0 = C_DOLLAR then (if TOP_REDUCIBLE and TOP_PRECEDENCE > DELAY_PRECEDENCE then X_REDUCE else X_DELAY)
                           else if CODE0 = C_INIT and HAS_PENDING then
                             (if TOP_OP = OP_CELL or TOP_OP = OP_VAR then X_INIT
                              else if TOP_REDUCIBLE and TOP_PRECEDENCE > DELAY_PRECEDENCE then X_REDUCE else X_FAIL)
                           else if CODE0 = C_OPEN_BRACKET and CODE1 = C_QUESTION then X_PREVIOUS
                           else if CODE0 = C_OPEN_BRACKET then X_OPEN_SQUARE
                           else if (CODE0 = C_CLOSE or CODE0 = C_CLOSE_BRACKET) and OPENER_NOW >= 0 then
                             (if TOP_REDUCIBLE then X_REDUCE
                              else if TOP_OP = OP_IF_MARK or TOP_OP = OP_THEN_MARK or (OP_BRACKETED[TOP_OP] = 1) /= (CODE0 = C_CLOSE_BRACKET)
                              then X_FAIL else X_CLOSE)
                           else if CODE0 = C_COMMA and OPENER_NOW >= 0 and OPENER_OP = OP_CALL then
                             (if PENDING_TOP /= OPENER_NOW then X_REDUCE else X_COMMA)
                           else if IS_TERMINATOR then
                             (if not HAS_PENDING then X_RETURN else if TOP_IS_OPENER then X_FAIL else X_REDUCE)
                           else X_FAIL
        | DELAY_MESSAGE := if not DELAY_HAS_INIT or DELAY_NAME_INIT then 0 else if not LITERAL_IS then T_DELAY_INITIAL else LITERAL_MESSAGE
        | OPERATOR_FAIL_MESSAGE := if (CODE0 = C_THEN or CODE0 = C_ELSE) and OPENER_NOW >= 0
                                      or (CODE0 = C_CLOSE or CODE0 = C_CLOSE_BRACKET) and OPENER_NOW >= 0
                                      or IS_TERMINATOR then MISSING_MESSAGE
                                   else if OPENER_NOW >= 0 and OPENER_OP = OP_IF_MARK then T_EXPECTED_THEN
                                   else if OPENER_NOW >= 0 and OPENER_OP = OP_THEN_MARK then T_EXPECTED_ELSE
                                   else T_EXPECTED_OPERATOR
        | TEMPLATE_INIT := IN_OPERATOR and OPERATOR_CASE = X_INIT
        | INIT_MESSAGE := if INIT_IS_NAME then 0 else if not LITERAL_IS then T_DELAY_INITIAL else LITERAL_MESSAGE
        | VAR_OPERAND_BAD := REDUCES and TOP_OP = OP_VAR
                             and (ENTRY_COUNT[?] - PENDING_RIGHT_START[?][PENDING_TOP] /= 1
                                  or integer(ENTRY_OP[?][ENTRY_COUNT[?] - 1]) /= OP_SIGNAL)
        | REPEAT_WHOLE := EXPRESSION_RETURN[?] = P_EQUATION_END and REPEAT_SEEN[?] = 1 and TARGET[?] >= 0 and not TUPLE_ACTIVE
                          and LAST_ENTRY >= EXPRESSION_START[?] and integer(ENTRY_OP[?][LAST_ENTRY]) = OP_REPEAT
        | REPEAT_MISPLACED := IN_OPERATOR and OPERATOR_CASE = X_RETURN and REPEAT_SEEN[?] > 0 and not REPEAT_WHOLE
        | OPERATOR_MESSAGE := if OPERATOR_CASE = X_FAIL then OPERATOR_FAIL_MESSAGE
                              else if REPEAT_MISPLACED then T_WHOLE_DEFINITION
                              else if VAR_OPERAND_BAD then T_VAR_NAME
                              else if OPERATOR_CASE = X_INIT then INIT_MESSAGE
                              else if OPERATOR_CASE = X_BINARY and IS_FUNCTION and OP_TEMPLATE_KIND[BINARY_OP[CODE0]] > 0 then T_FUNCTION_MEMORY
                              else if OPERATOR_CASE = X_DELAY then (if IS_FUNCTION then T_FUNCTION_MEMORY else DELAY_MESSAGE)
                              else if OPERATOR_CASE = X_PREVIOUS and CODE2 /= C_CLOSE_BRACKET then T_EXPECTED_FOUND
                              else if OPERATOR_CASE = X_CLOSE and INTRINSIC_CALL and ARGUMENTS_FOUND /= ARGUMENTS_EXPECTED then T_WRONG_ARGUMENTS
                              else if OPERATOR_CASE = X_CLOSE and POST_KEY = OP_RECOVER_SQUARE then RECOVER_ARRAY_MESSAGE
                              else if OPERATOR_CASE = X_BINARY and BINARY_OP[CODE0] = OP_RECOVER and not RECOVER_READY[?] then T_RECOVERY_ACCESS
                              else 0
        | PARAMETER_MESSAGE := if CODE0 = C_NAME or CODE0 = C_NUMBER or CODE0 >= 1 and CODE0 < C_SYMBOL_BASE then 0
                               else T_STATIC_PARAMETER
        | PARAMETER_CLOSE_MESSAGE := if CODE0 /= C_CLOSE_BRACE or CODE1 /= C_OPEN then T_EXPECTED_FOUND else 0
        | REDUCES := IN_OPERATOR and (OPERATOR_CASE = X_REDUCE or OPERATOR_CASE = X_INIT)
        | CLOSES_OPENER := IN_OPERATOR and OPERATOR_CASE = X_CLOSE or IN_OPERAND and OPERAND_CASE = X_EMPTY_CALL
        | PUSHES_PENDING := IN_OPERAND and (OPERAND_CASE = X_CALL or OPERAND_CASE = X_OPEN_PAREN or OPERAND_CASE = X_IF
                                            or OPERAND_CASE = X_PREFIX)
                            or IN_PARAMETER_CLOSE and PARAMETER_CLOSE_MESSAGE = 0
                            or IN_OPERATOR and (OPERATOR_CASE = X_BINARY and STAGE_DONE or OPERATOR_CASE = X_OPEN_SQUARE)
                            or IN_BRANCH
        | UPDATES_PENDING := IN_OPERATOR and (OPERATOR_CASE = X_THEN or OPERATOR_CASE = X_ELSE or OPERATOR_CASE = X_COMMA)
        | POPS_PENDING := (REDUCES or CLOSES_OPENER) and STAGE_DONE
        | PRE_STAGING := IN_OPERATOR and OPERATOR_CASE = X_BINARY
        | INDEX_STAGING := IN_INDEX_EMIT or IN_REPEAT_EMIT
        | STAGE_KEY := if PRE_STAGING then BINARY_OP[CODE0]
                       else if IN_INDEX_EMIT then (if INDEX_IS_ARRAY[?] then OP_ARRAY_RANGE else OP_REPEAT_RANGE)
                       else if IN_REPEAT_EMIT then OP_REPEAT_BODY else POST_KEY
        | STAGE_LENGTH := if PRE_STAGING then OP_PRE_LENGTH[STAGE_KEY] else OP_POST_LENGTH[STAGE_KEY]
        | STAGE_START := if PRE_STAGING then OP_PRE_START[STAGE_KEY] else OP_POST_START[STAGE_KEY]
        | STAGING := (PRE_STAGING or REDUCES or CLOSES_OPENER or INDEX_STAGING) and STAGE_LENGTH > 0
        | STAGE_ITEM := STAGE_OP[STAGE_START + STAGE_INDEX[?]]
        | COPIES_INDEX := STAGE_ITEM = OP_INDEX_OPERAND
        | COPYING := STAGING and (STAGE_ITEM = OP_OPERAND or COPIES_INDEX or STAGE_ITEM = OP_RIGHT_OPERAND) or CASE_COPYING
        | INDEX_FRESH := STAGE_INDEX[?] = 0 and COPY_I[?] = 0
        | INDEX_BOUND_AT := if IN_REPEAT_START then ENTRY_SPLIT[?][LAST_ENTRY]
                            else if IN_INDEX_EMIT and INDEX_IS_ARRAY[?] and INDEX_FRESH then EXPRESSION_START[?] else INDEX_BOUND_AT[?]
        | INDEX_BOUND_END := if IN_REPEAT_START then LAST_ENTRY
                             else if IN_INDEX_EMIT and INDEX_IS_ARRAY[?] and INDEX_FRESH then ENTRY_COUNT[?] else INDEX_BOUND_END[?]
        | COPY_BASE := if IN_INDEX_EMIT then INDEX_BOUND_AT else if IN_REPEAT_EMIT then REPEAT_E_START[?]
                       else if IN_CASE_COPY then CASE_TOP_START else if IN_CASE_ELSE_VALUE then CASE_VALUE_ENTRY[?][CASE_WALK[?]]
                       else if COPIES_INDEX then (if PRE_STAGING then RECOVER_INDEX_START[?] else PENDING_INDEX_START[?][PENDING_TOP])
                       else if TOP_IS_OPENER or STAGE_ITEM = OP_RIGHT_OPERAND then PENDING_RIGHT_START[?][PENDING_TOP]
                       else if PENDING_TOP >= 1 then PENDING_RIGHT_START[?][PENDING_TOP - 1] else EXPRESSION_START[?]
        | STAGE_BASE := if STAGE_INDEX[?] = 0 and COPY_I[?] = 0 then ENTRY_COUNT[?] else STAGE_BASE[?]
        | COPY_END := if IN_INDEX_EMIT then INDEX_BOUND_END else if IN_REPEAT_EMIT then INDEX_BOUND_AT
                      else if IN_CASE_COPY then CASE_TOP_END else if IN_CASE_ELSE_VALUE then COPY_BASE + 1
                      else if COPIES_INDEX then (if PRE_STAGING then RECOVER_INDEX_END[?] else PENDING_INDEX_END[?][PENDING_TOP])
                      else if TOP_IS_OPENER or STAGE_ITEM = OP_RIGHT_OPERAND then STAGE_BASE
                      else PENDING_LEFT_END[?][PENDING_TOP]
        | COPY_FROM := COPY_BASE + COPY_I[?]
        | STAGE_ADVANCES := not COPYING or COPY_FROM + 1 >= COPY_END
        | STAGE_DONE := STAGE_LENGTH = 0 or STAGE_INDEX[?] = STAGE_LENGTH - 1 and STAGE_ADVANCES
        | STAGE_INDEX := if STAGING and not STAGE_DONE then STAGE_INDEX[?] + integer(STAGE_ADVANCES) else 0
        | COPY_I := if COPYING and not STAGE_ADVANCES then COPY_I[?] + 1 else 0
        | RECOVERED_CLOSE := CLOSES_OPENER and POST_KEY = OP_RECOVER_SQUARE
        | RECOVER_LATCH := RECOVERED_CLOSE and STAGE_INDEX[?] = 0
        | RECOVER_ARRAY_AT := PENDING_RIGHT_START[?][PENDING_TOP] - 1
        | RECOVER_INDEX_START := if RECOVER_LATCH then RECOVER_ARRAY_AT + 1 else RECOVER_INDEX_START[?]
        | RECOVER_INDEX_END := if RECOVER_LATCH then ENTRY_COUNT[?] else RECOVER_INDEX_END[?]
        | RECOVER_ARRAY := if RECOVER_LATCH then ENTRY_NAME[?][RECOVER_ARRAY_AT] else RECOVER_ARRAY[?]
        | RECOVER_ARRAY_TOKEN := if RECOVER_LATCH then ENTRY_TOKEN[?][RECOVER_ARRAY_AT] else RECOVER_ARRAY_TOKEN[?]
        | RECOVER_READY := if RECOVERED_CLOSE and STAGE_DONE then true else if IN_OPERAND or REDUCES then false else RECOVER_READY[?]
        | RECOVER_ARRAY_MESSAGE := if RECOVER_ARRAY_AT < EXPRESSION_START[?] or integer(ENTRY_OP[?][RECOVER_ARRAY_AT]) /= OP_SIGNAL
                                   then T_RECOVERY_ACCESS else 0
        | EMITS_SIZE := STAGING and (STAGE_ITEM = OP_SIZE or STAGE_ITEM = OP_SIZE_LESS)
        | COPY_OFFSET := ENTRY_COUNT[?] - COPY_FROM
        | ARGUMENTS_FOUND := if IN_OPERAND then 0 else PENDING_COUNT[?][PENDING_TOP] + 1
        | LEFT_TT_FALSE := IN_OPERATOR and OPERATOR_CASE = X_COMMA and POST_KEY = OP_LEFT_TT
        | EMITS_ZERO := LEFT_TT_FALSE or STAGING and STAGE_ITEM = OP_ZERO
        | EMITS_ONE := STAGING and STAGE_ITEM = OP_ONE
        | EMITS_NAMED := STAGING and (STAGE_ITEM = OP_TARGET_SIGNAL or STAGE_ITEM = OP_INDEX_SIGNAL)
        | STAGE_KIND := if COPYING then integer(ENTRY_OP[?][COPY_FROM]) else if EMITS_ZERO or EMITS_SIZE or EMITS_ONE then OP_CONST
                        else if EMITS_NAMED then OP_SIGNAL else STAGE_ITEM
        | PUSHED_OP := if IN_OPERAND then
                         (if OPERAND_CASE = X_CALL then OP_CALL else if OPERAND_CASE = X_OPEN_PAREN then OP_OPEN_PAREN
                          else if OPERAND_CASE = X_IF then OP_IF_MARK else PREFIX_OP[CODE0])
                       else if IN_PARAMETER_CLOSE then OP_CALL
                       else if IN_BRANCH then OP_BRANCH
                       else if OPERATOR_CASE = X_OPEN_SQUARE then OP_OPEN_SQUARE
                       else if OPERATOR_CASE = X_BINARY then BINARY_OP[CODE0]
                       else if OPERATOR_CASE = X_THEN then OP_THEN_MARK
                       else if OPERATOR_CASE = X_ELSE then OP_IF
                       else TOP_OP
        | PUSHED_PRECEDENCE := if IN_OPERAND then (if OPERAND_CASE = X_PREFIX then PREFIX_PRECEDENCE[CODE0] else 0)
                               else if IN_BRANCH or OPERATOR_CASE = X_ELSE then CONDITION_PRECEDENCE
                               else if OPERATOR_CASE = X_BINARY then BINARY_HERE
                               else if OPERATOR_CASE = X_OPEN_SQUARE then 0
                               else TOP_PRECEDENCE
        | PUSHED_TOKEN := if IN_PARAMETER_CLOSE then CALL_HEAD[?] else if IN_BRANCH or UPDATES_PENDING then TOP_TOKEN else HERE
        | PUSHED_COUNT := if OPERATOR_CASE = X_COMMA and IN_OPERATOR then PENDING_COUNT[?][PENDING_TOP] + 1
                          else if UPDATES_PENDING then PENDING_COUNT[?][PENDING_TOP] else 0
        | PUSHED_PARAMETERS := if IN_PARAMETER_CLOSE then PARAMETER_START[?] else if UPDATES_PENDING then PENDING_PARAMETERS[?][PENDING_TOP] else -1
        | PUSHED_PARAMETER_COUNT := if IN_PARAMETER_CLOSE then PARAMETER_COUNT[?]
                                    else if UPDATES_PENDING then PENDING_PARAMETER_COUNT[?][PENDING_TOP] else 0
        | PUSHED_OPENER := OP_IS_OPENER[PUSHED_OP] = 1
        | PENDING_SLOT := if PUSHES_PENDING then PENDING_DEPTH[?] else if UPDATES_PENDING then PENDING_TOP else -1
        | PENDING_OP := PENDING_OP[?] next PENDING_SLOT : PUSHED_OP
        | PENDING_PRECEDENCE := PENDING_PRECEDENCE[?] next PENDING_SLOT : PUSHED_PRECEDENCE
        | PENDING_TOKEN := PENDING_TOKEN[?] next PENDING_SLOT : PUSHED_TOKEN
        | PENDING_COUNT := PENDING_COUNT[?] next PENDING_SLOT : PUSHED_COUNT
        | PENDING_PARAMETERS := PENDING_PARAMETERS[?] next PENDING_SLOT : PUSHED_PARAMETERS
        | PENDING_PARAMETER_COUNT := PENDING_PARAMETER_COUNT[?] next PENDING_SLOT : PUSHED_PARAMETER_COUNT
        | PUSHED_SPLIT := if IN_OPERATOR and OPERATOR_CASE = X_COMMA and PENDING_COUNT[?][PENDING_TOP] = 1 then ENTRY_COUNT[?]
                          else if UPDATES_PENDING then PENDING_SPLIT[?][PENDING_TOP] else -1
        | PENDING_SPLIT := PENDING_SPLIT[?] next PENDING_SLOT : PUSHED_SPLIT
        | PENDING_RIGHT_START := PENDING_RIGHT_START[?] next PENDING_SLOT : ENTRY_COUNT[?] + integer(APPENDS_ENTRY)
        | PENDING_LEFT_END := PENDING_LEFT_END[?] next PENDING_SLOT : STAGE_BASE
        | PENDING_INDEX_START := PENDING_INDEX_START[?] next PENDING_SLOT : RECOVER_INDEX_START[?]
        | PENDING_INDEX_END := PENDING_INDEX_END[?] next PENDING_SLOT : RECOVER_INDEX_END[?]
        | PENDING_OPENER_BELOW := PENDING_OPENER_BELOW[?] next (if PUSHES_PENDING then PENDING_DEPTH[?] else -1) : OPENER_NOW
        | PENDING_DEPTH := PENDING_DEPTH[?] + integer(PUSHES_PENDING) - integer(POPS_PENDING)
        | OPENER_TOP := if PUSHES_PENDING and PUSHED_OPENER then PENDING_DEPTH[?]
                        else if CLOSES_OPENER and STAGE_DONE or IN_OPERATOR and OPERATOR_CASE = X_ELSE then PENDING_OPENER_BELOW[?][PENDING_TOP]
                        else OPENER_NOW
        | ENTRY_KIND := if IN_OPERAND then
                          (if OPERAND_CASE = X_EMPTY_CALL then OP_CALL
                           else if OPERAND_CASE = X_LITERAL then (if LITERAL_IS_ENUM then OP_ENUMCONST else OP_CONST)
                           else if OPERAND_CASE = X_SIGNAL then OP_SIGNAL else -1)
                        else if IN_OPERATOR then
                          (if OPERATOR_CASE = X_REDUCE or OPERATOR_CASE = X_INIT then (if STAGE_LENGTH > 0 then STAGE_KIND else TOP_OP)
                           else if OPERATOR_CASE = X_CLOSE then
                             (if STAGE_LENGTH > 0 then STAGE_KIND else if TOP_OP = OP_CALL then OP_CALL
                              else if TOP_OP = OP_OPEN_SQUARE then OP_INDEX else -1)
                           else if OPERATOR_CASE = X_BINARY then (if STAGE_LENGTH > 0 then STAGE_KIND else -1)
                           else if LEFT_TT_FALSE then OP_CONST
                           else if OPERATOR_CASE = X_DELAY then OP_DELAY
                           else if OPERATOR_CASE = X_PREVIOUS then OP_PREV else -1)
                        else if CASE_COPYING or INDEX_STAGING then STAGE_KIND
                        else if IN_CASE_LITERAL then (if LITERAL_IS_ENUM then OP_ENUMCONST else OP_CONST)
                        else if IN_CASE_COMPARE then (if CASE_ELSE_BRANCH[?] then OP_NE else OP_EQ)
                        else if IN_CASE_JOIN then (if CASE_ELSE_BRANCH[?] then OP_AND else OP_OR)
                        else if IN_CASE_WHEN or IN_STATE_WHEN then OP_UWHEN
                        else if IN_STATE_SIGNAL or IN_SYNC then OP_SIGNAL
                        else if IN_STATE_CALL then OP_CALL
                        else -1
        | APPENDS_ENTRY := ENTRY_KIND >= 0
        | ENTRY_FROM_TOP := REDUCES or CLOSES_OPENER
        | ENTRY_SLOT := if APPENDS_ENTRY then ENTRY_COUNT[?] else -1
        | ENTRY_OP := ENTRY_OP[?] next ENTRY_SLOT : ENTRY_KIND
        | ENTRY_TOKEN := ENTRY_TOKEN[?] next ENTRY_SLOT
                         : (if COPYING then ENTRY_TOKEN[?][COPY_FROM] else if EMITS_SIZE then RECOVER_ARRAY_TOKEN
                            else if ENTRY_FROM_TOP then TOP_TOKEN
                            else if INDEX_STAGING then INDEX_TOKEN[?]
                            else if IN_CASE_COMPARE or IN_CASE_JOIN or IN_CASE_WHEN then CASE_OP_TOKEN
                            else if IN_SYNC then MODEL_TOKEN[?][MODEL_NOW] else HERE)
        | PARSED_ENTRY_NAME := if COPYING then ENTRY_NAME[?][COPY_FROM]
                            else if EMITS_SIZE then RECOVER_ARRAY
                            else if EMITS_NAMED then (if STAGE_ITEM = OP_TARGET_SIGNAL then TARGET[?] else INDEX_NAME[?])
                            else if IN_STATE_CALL then N_ISIN
                            else if IN_SYNC then SIGNAL_NAME[?][MODEL_SIGNAL_START[?][MODEL_NOW] + SYNC_I[?]]
                            else if ENTRY_KIND = OP_CALL then TOP_CALLEE
                            else if ENTRY_KIND = OP_SIGNAL then NAME0
                            else if ENTRY_KIND = OP_ENUMCONST then integer(LITERAL_VALUE)
                            else if CARRIES_INIT and INIT_GIVEN and INIT_IS_NAME then NAME_AT_LITERAL else -1
        | CARRIES_INIT := ENTRY_KIND = OP_DELAY or ENTRY_KIND = OP_CELL or ENTRY_KIND = OP_VAR
        | INIT_GIVEN := if ENTRY_KIND = OP_DELAY then DELAY_HAS_INIT else TEMPLATE_INIT
        | ENTRY_NAME := ENTRY_NAME[?] next ENTRY_SLOT : PARSED_ENTRY_NAME
        | ENTRY_VALUE := ENTRY_VALUE[?] next ENTRY_SLOT
                         : (if COPYING then ENTRY_VALUE[?][COPY_FROM]
                            else if IN_STATE_CALL then long(1)
                            else if ENTRY_KIND = OP_CALL then long(PENDING_COUNT[?][PENDING_TOP] + integer(OPERATOR_CASE = X_CLOSE and IN_OPERATOR))
                            else if EMITS_ZERO then long(0) else if EMITS_ONE then long(1) else if EMITS_SIZE then long(-integer(STAGE_ITEM = OP_SIZE_LESS))
                            else LITERAL_VALUE)
        | ENTRY_TYPE := ENTRY_TYPE[?] next ENTRY_SLOT
                        : (if COPYING then ENTRY_TYPE[?][COPY_FROM]
                           else if CARRIES_INIT and (not INIT_GIVEN or INIT_IS_NAME) then -1
                           else if LEFT_TT_FALSE then BUILTIN_BOOLEAN else if EMITS_ZERO or EMITS_ONE then BUILTIN_SHORT
                           else if EMITS_SIZE then -1 else LITERAL_TYPE)
        | ENTRY_AUX := ENTRY_AUX[?] next ENTRY_SLOT
                       : (if COPYING then ENTRY_AUX[?][COPY_FROM] else if EMITS_SIZE then INIT_SIZE
                          else if IN_STATE_CALL then -1
                          else if IN_INDEX_EMIT and STAGE_ITEM = OP_RANGE and not INDEX_IS_ARRAY[?] then INDEX_TOTAL[?]
                          else if ENTRY_KIND = OP_CALL then PENDING_PARAMETERS[?][PENDING_TOP]
                          else if CARRIES_INIT then
                            (if not INIT_GIVEN then INIT_NONE else if INIT_IS_NAME then INIT_NAME
                             else if LITERAL_IS_ENUM then INIT_ENUMCONST else INIT_CONST)
                          else -1)
        | ENTRY_AUX2 := ENTRY_AUX2[?] next ENTRY_SLOT
                        : (if COPYING then ENTRY_AUX2[?][COPY_FROM]
                           else if IN_STATE_CALL then 0
                           else if ENTRY_KIND = OP_CALL then PENDING_PARAMETER_COUNT[?][PENDING_TOP]
                           else if LEFT_TT_FALSE then HERE else if INDEX_STAGING then INDEX_TOKEN[?] else if EMITS_ZERO then TOP_TOKEN
                           else if EMITS_SIZE then RECOVER_ARRAY_TOKEN else LITERAL_AT)
        | COPIED_SPLIT := ENTRY_SPLIT[?][COPY_FROM]
        | ENTRY_SPLIT := ENTRY_SPLIT[?] next ENTRY_SLOT
                         : (if COPYING then (if COPIED_SPLIT >= 0 then COPIED_SPLIT + COPY_OFFSET else -1)
                            else if ENTRY_KIND = OP_CALL and not IN_STATE_CALL then PENDING_SPLIT[?][PENDING_TOP]
                            else if ENTRY_FROM_TOP and (OP_TEMPLATE_KIND[ENTRY_KIND] > 0 or ENTRY_KIND = OP_REPEAT)
                            then PENDING_RIGHT_START[?][PENDING_TOP] else -1)
        | TEMPLATE_ENTRIES := TEMPLATE_ENTRIES[?] + integer(APPENDS_ENTRY and OP_TEMPLATE_KIND[ENTRY_KIND] > 0)
        | ENTRY_COUNT := ENTRY_COUNT[?] + integer(APPENDS_ENTRY)
        | COUNTS_REPEAT := APPENDS_ENTRY and ENTRY_KIND = OP_REPEAT and not COPYING
        | REPEAT_SEEN := if STARTS_EXPRESSION then 0 else REPEAT_SEEN[?] + integer(COUNTS_REPEAT)
        | REPEAT_FIRST_TOKEN := if COUNTS_REPEAT and REPEAT_SEEN[?] = 0 then TOP_TOKEN else REPEAT_FIRST_TOKEN[?]
        | COUNTS_INTRINSIC := ENTRY_KIND = OP_CALL and PARSED_ENTRY_NAME >= N_INITIAL and PARSED_ENTRY_NAME <= N_ISIN
        | STARTS_BODY := IN_MODEL_BODY and CODE0 = C_OPEN_BAR
        | BODY_INTRINSICS := if STARTS_BODY then 0 else BODY_INTRINSICS[?] + integer(COUNTS_INTRINSIC)
        | BODY_STATEMENTS := if STARTS_BODY then 0 else BODY_STATEMENTS[?] + integer(APPENDS_EQUATION and IS_STATEMENT)
        | BODY_EQUATION_START := if STARTS_BODY then EQUATION_COUNT[?] else BODY_EQUATION_START[?]
        | BODY_GROUP_START := if STARTS_BODY then GROUP_COUNT[?] else BODY_GROUP_START[?]
        | BODY_DEPENDENCE_START := if STARTS_BODY then DEPENDENCE_COUNT[?] else BODY_DEPENDENCE_START[?]
        | BODY_GUARD_START := if STARTS_BODY then GUARD_COUNT[?] else BODY_GUARD_START[?]
        | BODY_USE_START := if STARTS_BODY then USE_COUNT[?] else BODY_USE_START[?]
        | BODY_MEMBER_START := if STARTS_BODY then MEMBER_COUNT[?] else BODY_MEMBER_START[?]
        | BODY_HIDE_START := if STARTS_BODY then HIDE_COUNT[?] else BODY_HIDE_START[?]
        | MODEL_MESSAGE := if IN_START then (if MODEL_CLASS[CODE0] /= 1 then T_EXPECTED_FOUND else 0)
                           else if IN_MODEL_NAME then (if not MODEL_NAME_OK then T_EXPECTED_NAME else if MODEL_NAME_CLASHES then
                                                         (if RESERVED then T_RESERVED else T_DECLARED_TWICE) else 0)
                           else if IN_MODEL_EQUAL then (if CODE0 /= C_EQUAL then T_EXPECTED_FOUND else 0)
                           else if IN_MODEL_OPEN then (if CODE0 /= C_OPEN then T_EXPECTED_FOUND else 0)
                           else if IN_MODEL_CLOSE then (if CODE0 /= C_CLOSE then T_EXPECTED_FOUND else if NEEDS_OUTPUT then T_CLASS_NEEDS_OUTPUT else 0)
                           else if IN_MODEL_BODY then
                             (if PRAGMAS_OPEN then 0 else if CODE0 /= C_OPEN_BAR then T_EXPECTED_FOUND else 0)
                           else if IN_MODEL_AFTER then
                             (if CODE0 /= C_WHERE and CODE0 /= C_SEMICOLON and CODE0 /= C_SLASH then T_EXPECTED_FOUND else 0)
                           else if IN_PROGRAM then (if INNER_WHERE[?] and MODEL_CLASS[CODE0] = 1 then T_MODEL_IN_INNER_WHERE else 0)
                           else if IN_END_SEMICOLON then (if CODE0 /= C_SEMICOLON then T_EXPECTED_FOUND else 0)
                           else if IN_END_CHECK then (if CODE0 /= C_EOF then T_UNEXPECTED_AFTER else 0)
                           else if IN_TYPE_STATEMENT then (if TYPE_STATEMENT_CLASHES then CLASH_MESSAGE else 0)
                           else if IN_TYPE_SKIP then (if CODE0 = C_EOF then T_EXPECTED_FOUND else 0)
                           else 0
        | EXPECTED_CODE := if IN_START then C_PROCESS else if IN_MODEL_EQUAL or IN_CONSTANT_EQUAL then C_EQUAL
                           else if IN_MODEL_OPEN then C_OPEN else if IN_MODEL_CLOSE then C_CLOSE
                           else if IN_MODEL_BODY then C_OPEN_BAR else if IN_TYPE_CLOSE then C_CLOSE_BRACKET
                           else if IN_PRAGMA_OPEN then C_OPEN_BRACE
                           else if IN_PRAGMA_CLOSE or IN_PRAGMA_SKIP or IN_SET_SEPARATOR then C_CLOSE_BRACE
                           else if IN_DEPENDENCE then C_ARROW
                           else if IN_CASE_IN then C_IN else if IN_CASE_BRANCH then CASE_BRANCH_EXPECTED
                           else if IN_CASE_SEPARATOR then C_CLOSE_BRACE else if IN_CASE_GUARD then C_COLON
                           else if IN_EQUATION_END then C_CLOSE
                           else if IN_TUPLE_SEPARATOR then TUPLE_SEPARATOR_EXPECTED
                           else if IN_GUARD_COLONS then C_COLONS else if IN_ITERATE_OF then C_OF else if IN_ARRAY_TO then C_TO
                           else if IN_POP then (if FRAME_TOP_KIND = FRAME_COMPOSE then C_BAR_CLOSE else C_END)
                           else if IN_PARAMETER_CLOSE then (if CODE0 /= C_CLOSE_BRACE then C_CLOSE_BRACE else C_OPEN)
                           else if IN_OPERATOR then C_CLOSE_BRACKET
                           else if IN_INTEGER_CONSTANT then C_CLOSE
                           else if IN_CONSTANT_ELEMENT then C_CLOSE_BRACKET
                           else C_SEMICOLON
        | TYPE_MESSAGE := if IN_TYPE_SIZE then (if SIZE_MESSAGE /= 0 then SIZE_MESSAGE else if not SIZE_POSITIVE then T_CAPACITY_POSITIVE else 0)
                          else if IN_TYPE_CLOSE then (if CODE0 /= C_CLOSE_BRACKET then T_EXPECTED_FOUND else 0)
                          else if IN_TYPE_NAME then
                            (if TOKEN_TYPE < 0 then T_EXPECTED_TYPE else 0)
                          else 0
        | SEPARATOR_MESSAGE := if CODE0 /= C_COMMA and CODE0 /= C_SEMICOLON
                                    and not (IN_DECLARE_SEPARATOR and CODE0 = C_INIT and not DECLARE_INITED[?])
                                 then T_EXPECTED_FOUND else 0
        | STATEMENT_MESSAGE := if IN_DECLARE_NAME then DECLARE_MESSAGE
                               else if IN_DECLARE_INIT then DECLARE_INIT_MESSAGE
                               else if IN_DECLARE_SEPARATOR or IN_LABEL_SEPARATOR or IN_CONSTANT_SEPARATOR then SEPARATOR_MESSAGE
                               else if IN_CONSTANT_NAME then CONSTANT_NAME_MESSAGE
                               else if IN_CONSTANT_EQUAL then (if CODE0 /= C_EQUAL then T_EXPECTED_FOUND else 0)
                               else if IN_CONSTANT_DEFINITION then DEFINITION_MESSAGE
                               else if IN_INTEGER_CONSTANT then INTEGER_CONSTANT_MESSAGE
                               else if IN_CONSTANT_ELEMENT then ELEMENT_MESSAGE
                               else if IN_CONSTANT_SCALAR then SCALAR_MESSAGE
                               else if IN_LABEL_NAME then (if CODE0 /= C_NAME then T_EXPECTED_NAME else if DECLARED then CLASH_MESSAGE else 0)
                               else 0
        | BODY_MESSAGE := if IN_PROCESS then PROCESS_MESSAGE
                          else if IN_GUARD_COLONS then (if CODE0 /= C_COLONS then T_EXPECTED_FOUND else 0)
                          else if IN_ITERATE_NAME then (if CODE0 /= C_NAME then T_EXPECTED_NAME else 0)
                          else if IN_ITERATE_OF then (if CODE0 /= C_OF then T_EXPECTED_FOUND else 0)
                          else if IN_ARRAY_TO then (if CODE0 /= C_TO then T_EXPECTED_FOUND else 0)
                          else if IN_REPEAT_START then
                            (if IN_LOOP then T_ITERATE_NESTED else if GUARD_NODE[?] >= 0 or LABEL_NODE[?] >= 0 then T_TEMPLATE_GUARDED else 0)
                          else if IN_INDEX_TYPE then (if DRAIN_OK then 0 else T_CONSTANT_BOUND)
                          else if IN_INDEX_DECLARE then INDEX_DECLARE_MESSAGE
                          else if IN_EQUATION then EQUATION_MESSAGE
                          else if IN_DEPENDENCE then DEPENDENCE_MESSAGE
                          else if IN_SET_NAME or IN_SET_SEPARATOR then SET_MESSAGE
                          else if IN_HIDE_NAME then HIDE_MESSAGE
                          else if IN_TUPLE_NAME then (if CODE0 /= C_NAME then T_EXPECTED_NAME else 0)
                          else if IN_TUPLE_SEPARATOR then TUPLE_SEPARATOR_MESSAGE
                          else if IN_CASE_IN then (if CODE0 /= C_IN then T_EXPECTED_FOUND else 0)
                          else if IN_CASE_BRANCH then CASE_BRANCH_MESSAGE
                          else if IN_CASE_COPY and not CASE_ELSE_BRANCH[?] then CASE_VALUE_MESSAGE
                          else if IN_CASE_SCAN then (if CASE_DUPLICATE then T_CASE_DUPLICATE else 0)
                          else if IN_CASE_SEPARATOR then (if CODE0 /= C_COMMA and CODE0 /= C_CLOSE_BRACE then T_EXPECTED_FOUND else 0)
                          else if IN_CASE_GUARD then CASE_GUARD_MESSAGE
                          else if IN_EQUATION_END then EQUATION_END_MESSAGE
                          else if IN_POP then POP_MESSAGE
                          else if IN_OPERAND then OPERAND_MESSAGE
                          else if IN_PARAMETER then PARAMETER_MESSAGE
                          else if IN_PARAMETER_CLOSE then PARAMETER_CLOSE_MESSAGE
                          else if IN_OPERATOR then OPERATOR_MESSAGE
                          else 0
        | FULL_TABLE := if CREATES_MODEL and MODEL_COUNT[?] >= MODEL_CAP then F_CAP_MODELS
                        else if (IN_COPY_TYPES or CREATES_ARRAY_TYPE or MAKES_STATE_TYPE) and TYPE_COUNT[?] >= TYPE_CAP then F_CAP_TYPES
                        else if (APPENDS_SIGNAL or APPENDS_INDEX_SIGNAL) and SIGNAL_COUNT[?] >= SIGNAL_CAP then F_CAP_SIGNALS
                        else if PUSHES_LOCAL and LOCAL_COUNT[?] >= LOCAL_CAP then F_CAP_LOCALS
                        else if STORES_CONSTANT and CONSTANT_COUNT[?] >= CONSTANT_CAP then F_CAP_CONSTANTS
                        else if (STORES_TABLE and TABLE_COUNT[?] >= TABLE_CAP or APPENDS_POOL and POOL_COUNT[?] >= POOL_CAP) then F_CAP_TABLES
                        else if (APPENDS_LABEL and LABEL_COUNT[?] >= LABEL_CAP or CREATES_USE and USE_COUNT[?] >= LABEL_CAP) then F_CAP_LABELS
                        else if CREATES_GUARD and GUARD_COUNT[?] >= GUARD_CAP then F_CAP_GUARDS
                        else if IN_ITERATE_NAME and LOOP_COUNT[?] >= LOOP_CAP then F_CAP_LOOPS
                        else if INDEX_EQUATION and (LOOP_COUNT[?] >= LOOP_CAP or INDEX_TOTAL[?] + 1 >= GUARD_CAP) then F_CAP_LOOPS
                        else if (APPENDS_EQUATION or INDEX_EQUATION) and EQUATION_COUNT[?] >= EQUATION_CAP then F_CAP_EQUATIONS
                        else if APPENDS_ENTRY and ENTRY_COUNT[?] >= ENTRY_CAP then F_CAP_ENTRIES
                        else if (APPENDS_GROUP and GROUP_COUNT[?] >= GROUP_CAP or APPENDS_MEMBER and MEMBER_COUNT[?] >= MEMBER_CAP) then F_CAP_GROUPS
                        else if APPENDS_DEPENDENCE and DEPENDENCE_COUNT[?] >= DEPENDENCE_CAP then F_CAP_DEPENDENCES
                        else if APPENDS_HIDE and HIDE_COUNT[?] >= SIGNAL_CAP then F_CAP_SIGNALS
                        else if (PUSHES_FRAME and FRAME_DEPTH[?] >= STACK_CAP or PUSHES_PENDING and PENDING_DEPTH[?] >= STACK_CAP) then F_CAP_STACK
                        else if IN_PATH_COPY and PATH_COUNT[?] >= PATH_CAP then F_CAP_PATHS
                        else 0
        | STEP_MESSAGE := if STATE = P_STALL then 0
                          else if FULL_TABLE /= 0 then T_CAPACITY
                          else if MODEL_MESSAGE /= 0 then MODEL_MESSAGE
                          else if PRAGMA_MESSAGE_HERE /= 0 then PRAGMA_MESSAGE_HERE
                          else if TYPE_MESSAGE /= 0 then TYPE_MESSAGE
                          else if STATEMENT_MESSAGE /= 0 then STATEMENT_MESSAGE
                          else BODY_MESSAGE
        | STEP_TOKEN := if STEP_MESSAGE = T_FUNCTION_MEMORY then HERE
                        else if IN_REPEAT_START then ENTRY_TOKEN[?][LAST_ENTRY]
                        else if IN_INDEX_TYPE then ENTRY_TOKEN[?][DRAIN_BOUND]
                        else if IN_INDEX_DECLARE then INDEX_ID_TOKEN[?][DRAIN_ID]
                        else if REPEAT_MISPLACED then REPEAT_FIRST_TOKEN[?]
                        else if STEP_MESSAGE = T_VAR_NAME then TOP_TOKEN
                        else if IN_OPERATOR and OPERATOR_CASE = X_INIT then (if LITERAL_IS then LITERAL_MESSAGE_TOKEN else LITERAL_AT)
                        else if STEP_MESSAGE = T_CLASS_NEEDS_OUTPUT then MODEL_TOKEN[?][MODEL_NOW]
                        else if IN_OPERAND and OPERAND_CASE = X_LITERAL or IN_OPERATOR and OPERATOR_CASE = X_DELAY and DELAY_HAS_INIT and LITERAL_IS
                        then LITERAL_MESSAGE_TOKEN
                        else if IN_OPERATOR and OPERATOR_CASE = X_DELAY then LITERAL_AT
                        else if IN_DECLARE_INIT then (if LITERAL_IS then LITERAL_MESSAGE_TOKEN else LITERAL_AT)
                        else if IN_CASE_COPY then (if LITERAL_IS then LITERAL_MESSAGE_TOKEN else HERE)
                        else if IN_CASE_SCAN then CASE_LITERAL_TOKEN[?]
                        else if IN_OPERATOR and OPERATOR_CASE = X_PREVIOUS then HERE + 2
                        else if IN_DEPENDENCE and CODE0 = C_ARROW then HERE + 1
                        else if IN_PARAMETER_CLOSE and CODE0 = C_CLOSE_BRACE then HERE + 1
                        else if STEP_MESSAGE = T_PRAGMAS_END and CODE0 = C_END then HERE + 1
                        else if STEP_MESSAGE = T_WRONG_ARGUMENTS then (if IN_EQUATION_END then TUPLE_TOKEN[?] else TOP_TOKEN)
                        else if IN_TUPLE_SEPARATOR and CODE0 = C_CLOSE then HERE + 1 + integer(CODE1 = C_DEFINE)
                        else if STEP_MESSAGE = T_RECOVERY_ACCESS and OPERATOR_CASE = X_CLOSE then HERE + 1
                        else if IN_INTEGER_CONSTANT then INTEGER_CONSTANT_TOKEN
                        else if IN_CONSTANT_DEFINITION or IN_CONSTANT_ELEMENT and STEP_MESSAGE /= T_EXPECTED_FOUND or IN_CONSTANT_SCALAR
                        then DECLARE_TOKEN[?]
                        else HERE
        | STEP_ARGUMENT0 := if STEP_MESSAGE = T_CAPACITY then FULL_TABLE
                            else if STEP_MESSAGE = T_EXPECTED_FOUND then EXPECTED_CODE
                            else if IN_INDEX_TYPE then INDEX_ID_OP_TOKEN[?][DRAIN_ID]
                            else if STEP_MESSAGE = T_DECLARED_TWICE then
                              (if IN_MODEL_NAME then F_ROLE_MODEL else if IN_TYPE_STATEMENT then F_ROLE_TYPE
                               else if IN_CONSTANT_NAME then F_ROLE_CONSTANT else if IN_LABEL_NAME then F_ROLE_LABEL else F_ROLE_SIGNAL)
                            else if STEP_MESSAGE = T_EXTERNAL_SIGNAL then DECLARED_BASE
                            else if STEP_MESSAGE = T_CONSTANT_STRING or STEP_MESSAGE = T_CONSTANT_LIST or STEP_MESSAGE = T_CONSTANT_ELEMENT
                                    or STEP_MESSAGE = T_CONSTANT_TYPE or STEP_MESSAGE = T_CONSTANT_COUNT then DECLARE_NAME[?]
                            else if STEP_MESSAGE = T_RESERVED or STEP_MESSAGE = T_NAME_OF_MODEL or STEP_MESSAGE = T_CONSTANT_UNDECLARED
                                    or STEP_MESSAGE = T_INPUT_SCALAR or STEP_MESSAGE = T_OUTPUT_ARRAY
                                    or STEP_MESSAGE = T_PRAGMA_TOP_ONLY then LOOKUP_KEY
                            else if STEP_MESSAGE = T_INTERRUPT_TWICE then INTERRUPT_VALUE
                            else if STEP_MESSAGE = T_CLASS_NEEDS_OUTPUT then MODEL_KIND_NOW
                            else if STEP_MESSAGE = T_FUNCTION_MEMORY then MODEL_NAME[?][MODEL_NOW]
                            else if STEP_MESSAGE = T_WRONG_ARGUMENTS then (if IN_EQUATION_END then TUPLE_FIRST_NAME else TOP_CALLEE)
                            else STEP_TOKEN
        | STEP_ARGUMENT1 := if STEP_MESSAGE = T_EXPECTED_FOUND or STEP_MESSAGE = T_FUNCTION_MEMORY then STEP_TOKEN
                            else if STEP_MESSAGE = T_CLASS_NEEDS_OUTPUT then MODEL_NAME[?][MODEL_NOW]
                            else if STEP_MESSAGE = T_DECLARED_TWICE then LOOKUP_KEY
                            else if STEP_MESSAGE = T_WRONG_ARGUMENTS then (if IN_EQUATION_END then TUPLE_ARITY[?] else ARGUMENTS_EXPECTED)
                            else DECLARED_TYPE
        | STEP_ARGUMENT2 := if STEP_MESSAGE = T_CONSTANT_COUNT then (if IN_CONSTANT_DEFINITION then STRING_BYTES else ELEMENT_COUNT)
                            else if STEP_MESSAGE = T_WRONG_ARGUMENTS then (if IN_EQUATION_END then TUPLE_INDEX[?] + 1 else ARGUMENTS_FOUND)
                            else VALUE_TYPE
        | FAILS := STEP_MESSAGE /= 0
        | GO := not FAILS
        | NEXT_AT := if not GO then HERE
                     else if IN_START or IN_MODEL_NAME or IN_MODEL_EQUAL or IN_MODEL_OPEN or IN_MODEL_CLOSE or IN_END_SEMICOLON
                             or IN_TYPE_SKIP or IN_TYPE_CLOSE or IN_TYPE_NAME or IN_DECLARE_NAME
                             or IN_DECLARE_SEPARATOR or IN_CONSTANT_NAME or IN_CONSTANT_EQUAL or IN_CONSTANT_SEPARATOR
                             or IN_LABEL_NAME or IN_LABEL_SEPARATOR or IN_GUARD_COLONS or IN_ITERATE_NAME or IN_ITERATE_OF or IN_ARRAY_TO
                             or PRAGMAS_OPEN or IN_PRAGMA_OPEN or IN_PRAGMA_OBJECT or IN_PRAGMA_CLOSE or IN_PRAGMA_STATEMENT
                             or IN_PRAGMA_SKIP or IN_SET_NAME or IN_SET_SEPARATOR or IN_ALIAS_END or IN_HIDE_NAME or IN_TUPLE_NAME
                     then HERE + 1
                     else if IN_TUPLE_SEPARATOR then HERE + 1 + 2 * integer(CODE0 = C_CLOSE)
                     else if IN_CASE_IN or IN_CASE_BRANCH or IN_CASE_SEPARATOR then HERE + 1
                     else if IN_CASE_LITERAL then LITERAL_END
                     else if IN_CASE_GUARD then HERE + integer(not CASE_ELSE_BRANCH[?])
                     else if IN_PRAGMA_OTHER then HERE + integer(CODE0 = C_OPEN_BRACE or CODE0 = C_STRING)
                     else if IN_PRAGMA_TEXT then HERE + integer(CODE0 = C_STRING)
                     else if IN_HIDE_SEPARATOR then HERE + integer(CODE0 = C_COMMA or CODE0 = C_SLASH)
                     else if IN_PRAGMA_NAME then HERE + 1 + integer(PRAGMAS_CLOSE)
                     else if IN_TYPE_STATEMENT then HERE + 1 + integer(ALIAS_STATEMENT)
                     else if IN_DECLARE_INIT then LITERAL_END
                     else if IN_MODEL_QUESTION then HERE + integer(CODE0 = C_QUESTION)
                     else if IN_MODEL_BANG then HERE + integer(CODE0 = C_BANG)
                     else if IN_MODEL_AFTER then HERE + 1
                     else if IN_PROGRAM then HERE + integer(MODEL_CLASS[CODE0] = 1 or CODE0 = C_END or CODE0 = C_TYPE or CODE0 = C_CONSTANT
                                                           or CODE0 = C_LABEL)
                     else if IN_TYPE then HERE + integer(CODE0 = C_OPEN_BRACKET)
                     else if IN_TYPE_SIZE then HERE + 1
                     else if IN_CONSTANT_DEFINITION then HERE + integer(DEFINITION_IS_STRING or CODE0 = C_OPEN_BRACKET)
                     else if IN_INTEGER_CONSTANT then NUMBER_AT + 1 + integer(CONVERTS)
                     else if IN_CONSTANT_ELEMENT then HERE + 1
                     else if IN_PROCESS then
                       (if CODE0 = C_OPEN_BAR or CODE0 = C_ON or CODE0 = C_CASE or CODE0 = C_ITERATE or CODE0 = C_ARRAY or CODE0 = C_OPEN_BRACE
                           or TUPLE_OPENS
                        then HERE + 1
                        else if LABEL_FOLLOWS and not STATE_ACTION_OPENS then HERE + 2 else HERE)
                     else if IN_EQUATION then (if FOLLOWER = C_ARROW then HERE + 1 else if FOLLOWER = C_DEFINE then HERE + 2 else HERE)
                     else if IN_DEPENDENCE then HERE + 2 * integer(CODE0 = C_ARROW)
                     else if IN_EQUATION_END or IN_GROUP_MEMBER then HERE + integer(CONTINUES_GROUP or IN_EQUATION_END and TUPLE_ACTIVE)
                     else if IN_POP then
                       (if SYNC_PENDING then HERE
                        else if HIDE_OPENS or INNER_WHERE_OPENS then HERE + 1
                        else if FRAME_TOP_KIND = FRAME_COMPOSE then (if POP_COMPOSE_BREAKS or CODE0 = C_BAR_CLOSE then HERE + 1 else HERE + 2)
                        else if FRAME_TOP_KIND = FRAME_ITERATE then HERE + 1 else HERE)
                     else if IN_OPERAND then
                       (if OPERAND_CASE = X_LITERAL then LITERAL_END
                        else if OPERAND_CASE = X_CALL or OPERAND_CASE = X_PARAMETERS then HERE + 2 else HERE + 1)
                     else if IN_PARAMETER then HERE + 1 + integer(CODE1 = C_COMMA)
                     else if IN_PARAMETER_CLOSE then HERE + 2
                     else if IN_OPERATOR then
                       (if OPERATOR_CASE = X_REDUCE or OPERATOR_CASE = X_RETURN then HERE
                        else if OPERATOR_CASE = X_CLOSE or OPERATOR_CASE = X_BINARY then HERE + integer(STAGE_DONE)
                        else if OPERATOR_CASE = X_DELAY then (if DELAY_HAS_INIT then LITERAL_END else HERE + 1)
                        else if OPERATOR_CASE = X_INIT then LITERAL_END
                        else if OPERATOR_CASE = X_PREVIOUS then HERE + 3 else HERE + 1)
                     else HERE
        | AT := NEXT_AT
        | NEXT_STATE := if FAILS then P_FAILED
                        else if STATE = P_STALL then STATE_BEFORE
                        else if IN_COPY_TYPES then (if COPY_DONE then P_START else P_COPY_TYPES)
                        else if IN_START then P_MODEL_NAME
                        else if IN_MODEL_NAME then P_MODEL_EQUAL
                        else if IN_MODEL_EQUAL then P_MODEL_OPEN
                        else if IN_MODEL_OPEN then P_MODEL_QUESTION
                        else if IN_MODEL_QUESTION then (if CODE0 = C_QUESTION then P_INPUTS else P_MODEL_BANG)
                        else if IN_INPUTS then (if CODE0 = C_BANG or CODE0 = C_CLOSE then P_MODEL_BANG else P_TYPE)
                        else if IN_MODEL_BANG then (if CODE0 = C_BANG then P_OUTPUTS else P_MODEL_CLOSE)
                        else if IN_OUTPUTS then (if CODE0 = C_CLOSE then P_MODEL_CLOSE else P_TYPE)
                        else if IN_MODEL_CLOSE then P_MODEL_BODY
                        else if IN_MODEL_BODY then (if PRAGMAS_OPEN then P_PRAGMA_NAME else P_PROCESS)
                        else if IN_PRAGMA_NAME then
                          (if PRAGMAS_CLOSE then P_MODEL_BODY else if not PRAGMA_KNOWN then P_PRAGMA_OTHER
                           else if NAME0 = N_MACHINE then P_PRAGMA_STATEMENT else P_PRAGMA_OPEN)
                        else if IN_PRAGMA_OTHER then (if CODE0 = C_OPEN_BRACE then P_PRAGMA_SKIP else P_PRAGMA_NAME)
                        else if IN_PRAGMA_SKIP then (if CODE0 = C_CLOSE_BRACE then P_PRAGMA_TEXT else P_PRAGMA_SKIP)
                        else if IN_PRAGMA_TEXT then P_PRAGMA_NAME
                        else if IN_PRAGMA_OPEN then P_PRAGMA_OBJECT
                        else if IN_PRAGMA_OBJECT then P_PRAGMA_CLOSE
                        else if IN_PRAGMA_CLOSE then (if PRAGMA_KIND = N_INTERRUPT then P_PRAGMA_STATEMENT else P_PRAGMA_NAME)
                        else if IN_PRAGMA_STATEMENT then P_PRAGMA_NAME
                        else if IN_MODEL_AFTER or IN_END_SEMICOLON then
                          (if IN_MODEL_AFTER and CODE0 = C_SLASH then P_HIDE_NAME
                           else if IN_MODEL_AFTER and CODE0 = C_WHERE then P_PROGRAM else if PARENT_NOW < 0 then P_END_CHECK else P_PROGRAM)
                        else if IN_PROGRAM then
                          (if MODEL_CLASS[CODE0] = 1 then P_MODEL_NAME else if CODE0 = C_END then (if INNER_WHERE[?] then P_POP else P_END_SEMICOLON)
                           else if CODE0 = C_TYPE then P_TYPE_STATEMENT else if CODE0 = C_LABEL then P_LABEL_NAME else P_TYPE)
                        else if IN_END_CHECK then P_DONE
                        else if IN_TYPE_STATEMENT then (if ALIAS_STATEMENT then P_TYPE else P_TYPE_SKIP)
                        else if IN_ALIAS_END then P_PROGRAM
                        else if IN_TYPE_SKIP then (if CODE0 = C_SEMICOLON then P_PROGRAM else P_TYPE_SKIP)
                        else if IN_TYPE then (if CODE0 = C_OPEN_BRACKET then P_TYPE_SIZE else P_TYPE_NAME)
                        else if IN_TYPE_SIZE then P_TYPE_CLOSE
                        else if IN_TYPE_CLOSE then P_TYPE_NAME
                        else if IN_INDEX_TYPE then P_TYPE_INTERN
                        else if IN_INDEX_DECLARE then INDEX_RETURN[?]
                        else if TYPE_FINISHED then RETURN_STATE[?]
                        else if IN_TYPE_NAME or IN_TYPE_INTERN then P_TYPE_INTERN
                        else if IN_DECLARE_NAME then P_DECLARE_SEPARATOR
                        else if IN_DECLARE_INIT then P_DECLARE_SEPARATOR
                        else if IN_DECLARE_SEPARATOR then
                          (if CODE0 = C_INIT then P_DECLARE_INIT else if CODE0 = C_COMMA then P_DECLARE_NAME else if ROLE[?] = ROLE_INPUT then P_INPUTS
                           else if ROLE[?] = ROLE_OUTPUT then P_OUTPUTS else P_PROGRAM)
                        else if IN_CONSTANT_NAME then P_CONSTANT_EQUAL
                        else if IN_CONSTANT_EQUAL then P_CONSTANT_DEFINITION
                        else if IN_CONSTANT_DEFINITION then
                          (if DEFINITION_IS_STRING then P_CONSTANT_SEPARATOR else P_INTEGER_CONSTANT)
                        else if IN_INTEGER_CONSTANT then CONSTANT_RETURN[?]
                        else if IN_CONSTANT_ELEMENT then (if CODE0 = C_COMMA then P_INTEGER_CONSTANT else P_CONSTANT_SEPARATOR)
                        else if IN_CONSTANT_SCALAR then P_CONSTANT_SEPARATOR
                        else if IN_CONSTANT_SEPARATOR then (if CODE0 = C_COMMA then P_CONSTANT_NAME else P_PROGRAM)
                        else if IN_LABEL_NAME then P_LABEL_SEPARATOR
                        else if IN_LABEL_SEPARATOR then (if CODE0 = C_COMMA then P_LABEL_NAME else P_PROGRAM)
                        else if IN_PROCESS then
                          (if CODE0 = C_OPEN_BAR then P_PROCESS else if EMPTY_COMPOSITION then P_POP else if TUPLE_OPENS then P_TUPLE_NAME
                           else if CODE0 = C_OPEN_BRACE then P_SET_NAME else if STATE_ACTION_OPENS then P_STATE_SIGNAL
                           else if LABEL_FOLLOWS then P_PATH_COPY
                           else if CODE0 = C_ON or CODE0 = C_CASE then P_OPERAND else if CODE0 = C_ITERATE or CODE0 = C_ARRAY then P_ITERATE_NAME
                           else P_EQUATION)
                        else if IN_PATH_COPY then (if PATH_LEFT[?] > 0 then P_PATH_COPY else P_PROCESS)
                        else if IN_GUARD_COLONS then P_PATH_COPY
                        else if IN_ITERATE_NAME then (if INDEX_IS_ARRAY[?] then P_ARRAY_TO else P_ITERATE_OF)
                        else if IN_ARRAY_TO then P_OPERAND
                        else if IN_REPEAT_START then P_INDEX_EMIT
                        else if IN_INDEX_EMIT then (if not STAGE_DONE then P_INDEX_EMIT else if INDEX_IS_ARRAY[?] then P_ITERATE_OF else P_REPEAT_EMIT)
                        else if IN_REPEAT_EMIT then (if not STAGE_DONE then P_REPEAT_EMIT else P_EQUATION_END)
                        else if IN_TUPLE_NAME then P_TUPLE_SEPARATOR
                        else if IN_TUPLE_SEPARATOR then (if CODE0 = C_COMMA then P_TUPLE_NAME else P_OPERAND)
                        else if IN_CASE_IN then P_CASE_BRANCH
                        else if IN_CASE_BRANCH then (if CODE0 = C_END then P_POP else P_CASE_COPY)
                        else if IN_CASE_COPY then
                          (if not STAGE_ADVANCES then P_CASE_COPY else if CASE_ELSE_BRANCH[?] then P_CASE_ELSE_VALUE else P_CASE_LITERAL)
                        else if IN_CASE_LITERAL then (if CASE_LAST_TOP >= 0 then P_CASE_SCAN else P_CASE_COMPARE)
                        else if IN_CASE_SCAN then (if CASE_VALUE_PREV[?][CASE_SCAN_AT[?]] >= 0 then P_CASE_SCAN else P_CASE_COMPARE)
                        else if IN_CASE_ELSE_VALUE then P_CASE_COMPARE
                        else if IN_CASE_COMPARE then (if CASE_BRANCH_ITEMS[?] > 0 then P_CASE_JOIN else CASE_ITEM_NEXT)
                        else if IN_CASE_JOIN then CASE_ITEM_NEXT
                        else if IN_CASE_SEPARATOR then (if CODE0 = C_COMMA then P_CASE_COPY else P_CASE_WHEN)
                        else if IN_CASE_WHEN then P_CASE_GUARD
                        else if IN_CASE_GUARD or IN_STATE_GUARD then P_PATH_COPY
                        else if IN_STATE_SIGNAL then P_STATE_CALL
                        else if IN_SYNC then (if SYNC_LAST then P_POP else P_SYNC)
                        else if IN_STATE_CALL then P_STATE_WHEN
                        else if IN_STATE_WHEN then P_STATE_GUARD
                        else if IN_ITERATE_OF then P_PROCESS
                        else if IN_EQUATION then (if FOLLOWER = C_ARROW then P_DEPENDENCE else P_OPERAND)
                        else if IN_DEPENDENCE then (if CODE0 /= C_ARROW then P_POP else if CODE1 = C_OPEN_BRACE then P_SET_NAME else P_SET_EMIT)
                        else if IN_SET_NAME then P_SET_SEPARATOR
                        else if IN_SET_SEPARATOR then
                          (if CODE0 = C_COMMA then P_SET_NAME else if SET_READING_RIGHT[?] then P_SET_EMIT else P_DEPENDENCE)
                        else if IN_SET_EMIT then (if EMIT_LAST then P_DEPENDENCE else P_SET_EMIT)
                        else if IN_HIDE_NAME then P_HIDE_SEPARATOR
                        else if IN_HIDE_SEPARATOR then (if CODE0 = C_COMMA or CODE0 = C_SLASH then P_HIDE_NAME else HIDE_RETURN[?])
                        else if IN_EQUATION_END or IN_GROUP_MEMBER then (if CONTINUES_GROUP or TUPLE_CONTINUES then P_OPERAND else P_POP)
                        else if IN_POP then
                          (if HIDE_OPENS then P_HIDE_NAME else if INNER_WHERE_OPENS then P_PROGRAM
                           else if POP_COMPOSE_BREAKS or POP_ITERATE_SEEDS then P_PROCESS
                           else if FRAME_TOP_KIND = FRAME_CASE then P_CASE_BRANCH
                           else if SYNC_PENDING then P_SYNC
                           else if FRAME_DEPTH[?] = 1 then P_MODEL_AFTER else P_POP)
                        else if IN_OPERAND then
                          (if OPERAND_CASE = X_EMPTY_CALL or OPERAND_CASE = X_LITERAL or OPERAND_CASE = X_SIGNAL then P_OPERATOR
                           else if OPERAND_CASE = X_PARAMETERS then P_PARAMETER else P_OPERAND)
                        else if IN_PARAMETER then (if CODE1 = C_COMMA then P_PARAMETER else P_PARAMETER_CLOSE)
                        else if IN_PARAMETER_CLOSE then P_OPERAND
                        else if IN_OPERATOR then
                          (if OPERATOR_CASE = X_RETURN then EXPRESSION_RETURN[?]
                           else if OPERATOR_CASE = X_ELSE then P_BRANCH
                           else if OPERATOR_CASE = X_BINARY and STAGE_DONE or OPERATOR_CASE = X_THEN or OPERATOR_CASE = X_OPEN_SQUARE
                                   or OPERATOR_CASE = X_COMMA then P_OPERAND
                           else P_OPERATOR)
                        else if IN_BRANCH then P_OPERAND
                        else STATE_BEFORE
        | PARSE_STATE := NEXT_STATE
        | RETURN_STATE := if IN_INPUTS or IN_OUTPUTS or IN_PROGRAM and CODE0 /= C_CONSTANT then P_DECLARE_NAME
                          else if IN_PROGRAM then P_CONSTANT_NAME else if IN_TYPE_STATEMENT then P_ALIAS_END
                          else if IN_INDEX_TYPE then P_INDEX_DECLARE else RETURN_STATE[?]
        | INDEX_RETURN := if IN_INDEX_TYPE then STATE_BEFORE else INDEX_RETURN[?]
        | INDEX_IS_ARRAY := if IN_PROCESS and (CODE0 = C_ITERATE or CODE0 = C_ARRAY) then CODE0 = C_ARRAY
                            else if IN_REPEAT_START then false else INDEX_IS_ARRAY[?]
        | INDEX_NAME := if IN_REPEAT_START then N_REPEAT_MARK + (INDEX_TOTAL[?] + 1) * NAME_CAP
                        else if IN_ITERATE_NAME then NAME0 else INDEX_NAME[?]
        | INDEX_TOKEN := if IN_REPEAT_START then ENTRY_TOKEN[?][LAST_ENTRY] else if IN_ITERATE_NAME then HERE else INDEX_TOKEN[?]
        | REPEAT_E_START := if IN_REPEAT_START then EXPRESSION_START[?] else REPEAT_E_START[?]
        | INDEX_EQUATION := IN_INDEX_EMIT and STAGE_DONE
        | REPEAT_LOOP := if INDEX_EQUATION and not INDEX_IS_ARRAY[?] then LOOP_COUNT[?] else if IN_EQUATION_END then -1 else REPEAT_LOOP[?]
        | INDEX_SLOT := if GO and INDEX_EQUATION then INDEX_TOTAL[?] else -1
        | INDEX_ID_NAME := INDEX_ID_NAME[?] next INDEX_SLOT : INDEX_NAME[?]
        | INDEX_ID_BOUND := INDEX_ID_BOUND[?] next INDEX_SLOT : INDEX_BOUND_AT
        | INDEX_ID_BOUND_END := INDEX_ID_BOUND_END[?] next INDEX_SLOT : INDEX_BOUND_END
        | INDEX_ID_TOKEN := INDEX_ID_TOKEN[?] next INDEX_SLOT : INDEX_TOKEN[?]
        | INDEX_ID_OP_TOKEN := INDEX_ID_OP_TOKEN[?] next INDEX_SLOT : INDEX_TOKEN[?] - integer(INDEX_IS_ARRAY[?])
        | INDEX_ID_ARRAY := INDEX_ID_ARRAY[?] next INDEX_SLOT : INDEX_IS_ARRAY[?]
        | INDEX_ID_MODEL := INDEX_ID_MODEL[?] next INDEX_SLOT : MODEL_NOW
        | INDEX_ID_TYPE := INDEX_ID_TYPE[?] next (if GO and IN_INDEX_DECLARE then DRAIN_ID else -1) : PARSED_TYPE[?]
        | INDEX_STACK := INDEX_STACK[?] next (if INDEX_SLOT >= 0 then INDEX_DEPTH[?] else -1) : INDEX_TOTAL[?]
        | INDEX_DEPTH := INDEX_DEPTH[?] + integer(INDEX_SLOT >= 0) - integer(GO and IN_INDEX_DECLARE)
        | INDEX_TOTAL := INDEX_TOTAL[?] + integer(INDEX_SLOT >= 0)
        | ALIAS_NAME := if IN_TYPE_STATEMENT then NAME0 else ALIAS_NAME[?]
        | NAME_ALIAS := NAME_ALIAS[?] next (if GO and IN_ALIAS_END then ALIAS_NAME[?] else -1) : PARSED_TYPE[?] + 1
        | INNER_WHERE := if INNER_WHERE_OPENS then true else if IN_PROGRAM and CODE0 = C_END then false else INNER_WHERE[?]
        | PRAGMA_ITEMS := if PRAGMAS_OPEN then 0 else if IN_PRAGMA_NAME and not PRAGMAS_CLOSE then PRAGMA_ITEMS[?] + 1 else PRAGMA_ITEMS[?]
        | SET_STARTS := IN_PROCESS and CODE0 = C_OPEN_BRACE
        | SET_FROM_NAME := IN_EQUATION and FOLLOWER = C_ARROW
        | SET_RIGHT_OPENS := IN_DEPENDENCE and CODE0 = C_ARROW
        | SET_LEFT_START := if SET_STARTS then HERE + 1 else if SET_FROM_NAME then HERE
                            else if IN_SET_EMIT and EMIT_LAST then SET_RIGHT_START[?] else SET_LEFT_START[?]
        | SET_LEFT_COUNT := if SET_STARTS then 0 else if SET_FROM_NAME then 1
                            else if IN_SET_NAME and not SET_READING_RIGHT[?] then SET_LEFT_COUNT[?] + 1
                            else if IN_SET_EMIT and EMIT_LAST then SET_RIGHT_COUNT[?] else SET_LEFT_COUNT[?]
        | SET_RIGHT_START := if SET_RIGHT_OPENS then HERE + 1 + integer(CODE1 = C_OPEN_BRACE) else SET_RIGHT_START[?]
        | SET_RIGHT_COUNT := if SET_RIGHT_OPENS then integer(CODE1 /= C_OPEN_BRACE)
                             else if IN_SET_NAME and SET_READING_RIGHT[?] then SET_RIGHT_COUNT[?] + 1 else SET_RIGHT_COUNT[?]
        | SET_READING_RIGHT := if SET_STARTS then false else if SET_RIGHT_OPENS then true else SET_READING_RIGHT[?]
        | SET_ARROWED := if SET_STARTS or SET_FROM_NAME then false else if IN_SET_EMIT then true else SET_ARROWED[?]
        | EMIT_J := if IN_SET_EMIT and not EMIT_LAST_J then EMIT_J[?] + 1 else 0
        | EMIT_I := if IN_SET_EMIT then (if EMIT_LAST then 0 else EMIT_I[?] + integer(EMIT_LAST_J)) else 0
        | HIDE_RETURN := if HIDE_OPENS then STATE else HIDE_RETURN[?]
        | DECLARE_INITED := if IN_DECLARE_NAME then false else if IN_DECLARE_INIT then true else DECLARE_INITED[?]
        | INIT_SLOT := if GO and IN_DECLARE_INIT then SIGNAL_COUNT[?] - 1 else -1
        | SIGNAL_INIT_KIND := SIGNAL_INIT_KIND[?] next INIT_SLOT
                              : (if INIT_IS_NAME then INIT_NAME else if LITERAL_IS_ENUM then INIT_ENUMCONST else INIT_CONST)
        | SIGNAL_INIT_VALUE := SIGNAL_INIT_VALUE[?] next INIT_SLOT : LITERAL_VALUE
        | SIGNAL_INIT_TYPE := SIGNAL_INIT_TYPE[?] next INIT_SLOT : LITERAL_TYPE
        | SIGNAL_INIT_NAME := SIGNAL_INIT_NAME[?] next INIT_SLOT : NAME_AT_LITERAL
        | SIGNAL_INIT_TOKEN := SIGNAL_INIT_TOKEN[?] next INIT_SLOT : LITERAL_AT
        | ROLE := if IN_MODEL_QUESTION then ROLE_INPUT else if IN_MODEL_BANG then ROLE_OUTPUT else if IN_PROGRAM then ROLE_LOCAL else ROLE[?]
        | PENDING_MODEL_KIND := if IN_START or IN_PROGRAM then CODE0 else PENDING_MODEL_KIND[?]
        | ARRAY_SIZE := if IN_TYPE then ulong(0) else if IN_TYPE_SIZE then ulong(SIZE_VALUE) else if IN_INDEX_TYPE then DRAIN_SIZE
                      else ARRAY_SIZE[?]
        | ARRAY_BUCKET := if IN_TYPE_NAME then BUCKET_HERE else if IN_INDEX_TYPE then DRAIN_BUCKET else ARRAY_BUCKET[?]
        | CANDIDATE := if IN_TYPE_NAME then ARRAY_HEAD[?][BUCKET_HERE] - 1 else if IN_INDEX_TYPE then ARRAY_HEAD[?][DRAIN_BUCKET] - 1
                       else if IN_TYPE_INTERN then ARRAY_NEXT[?][INTERN_CANDIDATE] - 1 else CANDIDATE[?]
        | ARRAY_ELEMENT := if IN_TYPE_NAME then ELEMENT_TYPE else if IN_INDEX_TYPE then BUILTIN_INTEGER else ARRAY_ELEMENT[?]
        | PARSED_TYPE := if TYPE_FINISHED then FINISHED_TYPE else PARSED_TYPE[?]
        | DECLARE_NAME := if IN_CONSTANT_NAME then NAME0 else DECLARE_NAME[?]
        | DECLARE_TOKEN := if IN_CONSTANT_NAME then HERE else DECLARE_TOKEN[?]
        | CONSTANT_RETURN := if IN_CONSTANT_DEFINITION then (if CODE0 = C_OPEN_BRACKET then P_CONSTANT_ELEMENT else P_CONSTANT_SCALAR)
                             else CONSTANT_RETURN[?]
        | CONSTANT_VALUE_HELD := if IN_INTEGER_CONSTANT then (if CONVERTS then WRAPPED else SIGNED_LITERAL) else CONSTANT_VALUE_HELD[?]
        | CONSTANT_VALUE_TYPE := if IN_INTEGER_CONSTANT then (if CONVERTS then TOKEN_TYPE else CONSTANT_LITERAL_TYPE)
                                 else CONSTANT_VALUE_TYPE[?]
        | LIST_COUNT := if IN_CONSTANT_DEFINITION then 0 else if APPENDS_POOL then LIST_COUNT[?] + 1 else LIST_COUNT[?]
        | LIST_START := if IN_CONSTANT_DEFINITION then POOL_COUNT[?] else LIST_START[?]
        | LOOP_NOW := if IN_ITERATE_OF then LOOP_COUNT[?] - 1 else if POPS_FRAME and FRAME_TOP_KIND = FRAME_ITERATE then -1 else LOOP_NOW[?]
        | LOOP_SEED := if IN_ITERATE_OF then false else if IN_POP and POP_ITERATE_SEEDS then true else LOOP_SEED[?]
        | LABEL_NODE := if CREATES_USE then USE_COUNT[?]
                        else if POPS_FRAME and FRAME_TOP_KIND = FRAME_LABEL then USE_PARENT[?][FRAME_TOP_VALUE] else LABEL_NODE[?]
        | GUARD_NODE := if CREATES_GUARD then GUARD_COUNT[?]
                        else if POPS_FRAME and FRAME_TOP_KIND = FRAME_GUARD then GUARD_CONTEXT[?][FRAME_TOP_VALUE] else GUARD_NODE[?]
        | GUARD_START_TOKEN := if IN_PROCESS and CODE0 = C_ON or CASE_BRANCH_STARTS or STATE_ACTION_OPENS then HERE else GUARD_START_TOKEN[?]
        | EXPRESSION_START := if STARTS_EXPRESSION or IN_REPEAT_EMIT and INDEX_FRESH then ENTRY_COUNT[?] else EXPRESSION_START[?]
        | EXPRESSION_RETURN := if not STARTS_EXPRESSION then EXPRESSION_RETURN[?]
                               else if TUPLE_STARTS then P_EQUATION_END else if IN_PROCESS and CODE0 = C_CASE then P_CASE_IN
                               else if IN_PROCESS then P_GUARD_COLONS else if IN_EQUATION then P_EQUATION_END
                               else if IN_ARRAY_TO then P_INDEX_EMIT else P_GROUP_MEMBER
        | TARGET := if IN_EQUATION then (if FOLLOWER = C_DEFINE then NAME0 else -1)
                    else if TUPLE_NAMES_TARGET then TOKEN_NAME[TUPLE_NAME_TOKEN] - 1 else TARGET[?]
        | EQUATION_TOKEN := if IN_EQUATION or SET_STARTS then HERE else if TUPLE_NAMES_TARGET then TUPLE_NAME_TOKEN else EQUATION_TOKEN[?]
        | GROUP_MEMBER_START := if IN_EQUATION_END or IN_SYNC and SYNC_I[?] = 0 then MEMBER_COUNT[?] else GROUP_MEMBER_START[?]
        | CALL_HEAD := if IN_OPERAND then HERE else CALL_HEAD[?]
        | PARAMETER_START := if IN_OPERAND then HERE + 2 else PARAMETER_START[?]
        | PARAMETER_COUNT := if IN_OPERAND then 0 else if IN_PARAMETER then PARAMETER_COUNT[?] + 1 else PARAMETER_COUNT[?]
        | CURRENT_MODEL := if CREATES_MODEL then MODEL_COUNT[?] else if CLOSES_MODEL then PARENT_NOW else MODEL_NOW
        | TYPE_SLOT := if GO and (IN_COPY_TYPES or CREATES_ARRAY_TYPE or MAKES_STATE_TYPE) then TYPE_COUNT[?] else -1
        | TYPE_KIND := TYPE_KIND[?] next TYPE_SLOT
                       : (if IN_COPY_TYPES then (if COPY_IS_BUILTIN then BUILTIN_KIND[COPIED_TYPE] else USER_TYPE_KIND[COPIED_USER])
                          else if CREATES_ARRAY_TYPE then TK_ARRAY else TK_ENUM)
        | TYPE_BYTES := TYPE_BYTES[?] next (if GO and MACHINE_STATEMENT then BUILTIN_POINTER else TYPE_SLOT)
                        : (if MACHINE_STATEMENT then 4 else if IN_COPY_TYPES then
                             (if COPY_IS_BUILTIN then BUILTIN_BYTES[COPIED_TYPE] else if USER_TYPE_KIND[COPIED_USER] = TK_ENUM then 4 else 0)
                           else if CREATES_ARRAY_TYPE then 8 else 4)
        | TYPE_SIGNED := TYPE_SIGNED[?] next TYPE_SLOT : IN_COPY_TYPES and COPY_IS_BUILTIN and BUILTIN_SIGNED[COPIED_TYPE] = 1
        | TYPE_NAME := TYPE_NAME[?] next TYPE_SLOT
                       : (if IN_COPY_TYPES then (if COPY_IS_BUILTIN then COPIED_TYPE else USER_TYPE_NAME[COPIED_USER])
                          else if CREATES_ARRAY_TYPE then -1 else MODEL_NOW)
        | TYPE_STATE := TYPE_STATE[?] next TYPE_SLOT : MAKES_STATE_TYPE
        | TYPE_VALUE_START := TYPE_VALUE_START[?] next TYPE_SLOT
                              : (if IN_COPY_TYPES and not COPY_IS_BUILTIN then USER_TYPE_VALUE_START[COPIED_USER] else 0)
        | TYPE_VALUE_COUNT := TYPE_VALUE_COUNT[?] next TYPE_SLOT
                              : (if IN_COPY_TYPES and not COPY_IS_BUILTIN then USER_TYPE_VALUE_COUNT[COPIED_USER] else 0)
        | TYPE_ELEMENT := TYPE_ELEMENT[?] next TYPE_SLOT : (if CREATES_ARRAY_TYPE then ARRAY_ELEMENT[?] else -1)
        | TYPE_SIZE := TYPE_SIZE[?] next TYPE_SLOT : (if CREATES_ARRAY_TYPE then ARRAY_SIZE[?] else ulong(0))
        | ARRAY_NEXT := ARRAY_NEXT[?] next TYPE_SLOT : (if CREATES_ARRAY_TYPE then ARRAY_HEAD[?][ARRAY_BUCKET[?]] else 0)
        | ARRAY_HEAD := ARRAY_HEAD[?] next (if GO and CREATES_ARRAY_TYPE then ARRAY_BUCKET[?] else -1) : TYPE_COUNT[?] + 1
        | TYPE_COUNT := TYPE_COUNT[?] + integer(TYPE_SLOT >= 0)
        | MODEL_SLOT := if GO and CREATES_MODEL then MODEL_COUNT[?] else -1
        | MODEL_NAME := MODEL_NAME[?] next MODEL_SLOT : NAME0
        | MODEL_KIND := MODEL_KIND[?] next MODEL_SLOT : PENDING_MODEL_KIND[?]
        | MODEL_PARENT := MODEL_PARENT[?] next MODEL_SLOT : MODEL_NOW
        | MODEL_TOKEN := MODEL_TOKEN[?] next MODEL_SLOT : HERE
        | MODEL_SIGNAL_START := MODEL_SIGNAL_START[?] next MODEL_SLOT : SIGNAL_COUNT[?]
        | MODEL_LABEL_START := MODEL_LABEL_START[?] next MODEL_SLOT : LABEL_COUNT[?]
        | NAME_MODEL := NAME_MODEL[?] next (if GO and CREATES_MODEL then NAME0 else -1) : true
        | MODEL_COUNT := MODEL_COUNT[?] + integer(MODEL_SLOT >= 0)
        | MODEL_INPUTS := MODEL_INPUTS[?] next (if IN_MODEL_BANG then MODEL_NOW else -1) : SIGNAL_COUNT[?] - MODEL_SIGNAL_START[?][MODEL_NOW]
        | ENDS_BODY := IN_POP and POPS_FRAME and FRAME_DEPTH[?] = 1
        | BODY_SLOT := if ENDS_BODY then MODEL_NOW else -1
        | MODEL_EQUATION_START := MODEL_EQUATION_START[?] next BODY_SLOT : BODY_EQUATION_START[?]
        | MODEL_EQUATION_END := MODEL_EQUATION_END[?] next BODY_SLOT : EQUATION_COUNT[?]
        | MODEL_GROUP_START := MODEL_GROUP_START[?] next BODY_SLOT : BODY_GROUP_START[?]
        | MODEL_GROUP_END := MODEL_GROUP_END[?] next BODY_SLOT : GROUP_COUNT[?]
        | MODEL_DEPENDENCE_START := MODEL_DEPENDENCE_START[?] next BODY_SLOT : BODY_DEPENDENCE_START[?]
        | MODEL_DEPENDENCE_END := MODEL_DEPENDENCE_END[?] next BODY_SLOT : DEPENDENCE_COUNT[?]
        | MODEL_GUARD_START := MODEL_GUARD_START[?] next BODY_SLOT : BODY_GUARD_START[?]
        | MODEL_GUARD_END := MODEL_GUARD_END[?] next BODY_SLOT : GUARD_COUNT[?]
        | MODEL_USE_START := MODEL_USE_START[?] next BODY_SLOT : BODY_USE_START[?]
        | MODEL_USE_END := MODEL_USE_END[?] next BODY_SLOT : USE_COUNT[?]
        | MODEL_MEMBER_START := MODEL_MEMBER_START[?] next BODY_SLOT : BODY_MEMBER_START[?]
        | MODEL_MEMBER_END := MODEL_MEMBER_END[?] next BODY_SLOT : MEMBER_COUNT[?]
        | MODEL_INTRINSICS := MODEL_INTRINSICS[?] next BODY_SLOT : BODY_INTRINSICS[?]
        | MODEL_STATEMENTS := MODEL_STATEMENTS[?] next BODY_SLOT : BODY_STATEMENTS[?]
        | CLOSE_SLOT := if GO and CLOSES_MODEL then MODEL_NOW else -1
        | MODEL_CLOSED := MODEL_CLOSED[?] next CLOSE_SLOT : true
        | MODEL_CLOSE_SIGNALS := MODEL_CLOSE_SIGNALS[?] next CLOSE_SLOT : SIGNAL_COUNT[?]
        | MODEL_CLOSE_EQUATIONS := MODEL_CLOSE_EQUATIONS[?] next CLOSE_SLOT : EQUATION_COUNT[?]
        | MODEL_CLOSE_GROUPS := MODEL_CLOSE_GROUPS[?] next CLOSE_SLOT : GROUP_COUNT[?]
        | MODEL_CLOSE_LABELS := MODEL_CLOSE_LABELS[?] next CLOSE_SLOT : LABEL_COUNT[?]
        | MODEL_STATE_TYPE := MODEL_STATE_TYPE[?] next CLOSE_SLOT : (if MAKES_STATE_TYPE then TYPE_COUNT[?] else -1)
        | CLOSE_ORDER := CLOSE_ORDER[?] next (if CLOSE_SLOT >= 0 then CLOSED_COUNT[?] else -1) : MODEL_NOW
        | CLOSED_COUNT := CLOSED_COUNT[?] + integer(CLOSE_SLOT >= 0)
        | LOCAL_SLOT := if GO and PUSHES_LOCAL then LOCAL_COUNT[?] else -1
        | LOCAL_MODEL := LOCAL_MODEL[?] next LOCAL_SLOT : MODEL_NOW
        | LOCAL_PREVIOUS := LOCAL_PREVIOUS[?] next LOCAL_SLOT : LOCAL_TOP + 1
        | LOCAL_HEAD := LOCAL_HEAD[?] next (if STALE then LOOKUP_KEY else if LOCAL_SLOT >= 0 then NAME0 else -1)
                        : (if STALE then LOCAL_PREVIOUS[?][LOCAL_TOP] else LOCAL_COUNT[?] + 1)
        | LOCAL_COUNT := LOCAL_COUNT[?] + integer(LOCAL_SLOT >= 0)
        | SIGNAL_SLOT := if GO and (APPENDS_SIGNAL or APPENDS_INDEX_SIGNAL) then SIGNAL_COUNT[?] else -1
        | SIGNAL_NAME := SIGNAL_NAME[?] next SIGNAL_SLOT : LOOKUP_KEY
        | SIGNAL_ROLE := SIGNAL_ROLE[?] next SIGNAL_SLOT : (if APPENDS_INDEX_SIGNAL then ROLE_LOCAL else ROLE[?])
        | SIGNAL_TYPE := SIGNAL_TYPE[?] next SIGNAL_SLOT : DECLARED_TYPE
        | SIGNAL_MODEL := SIGNAL_MODEL[?] next SIGNAL_SLOT : MODEL_NOW
        | SIGNAL_TOKEN := SIGNAL_TOKEN[?] next SIGNAL_SLOT : (if APPENDS_INDEX_SIGNAL then INDEX_ID_TOKEN[?][DRAIN_ID] else HERE)
        | NAME_SIGNAL_EVER := NAME_SIGNAL_EVER[?] next (if SIGNAL_SLOT >= 0 then LOOKUP_KEY else -1) : true
        | MODEL_HAS_SIGNAL := MODEL_LAST_SIGNAL[?][MODEL_NOW] > 0
        | MODEL_FIRST_SIGNAL := MODEL_FIRST_SIGNAL[?] next (if SIGNAL_SLOT >= 0 and not MODEL_HAS_SIGNAL then MODEL_NOW else -1)
                                : SIGNAL_COUNT[?] + 1
        | SIGNAL_NEXT := SIGNAL_NEXT[?] next (if SIGNAL_SLOT >= 0 and MODEL_HAS_SIGNAL then MODEL_LAST_SIGNAL[?][MODEL_NOW] - 1 else -1)
                         : SIGNAL_COUNT[?] + 1
        | MODEL_LAST_SIGNAL := MODEL_LAST_SIGNAL[?] next SIGNAL_SLOT_MODEL : SIGNAL_COUNT[?] + 1
        | SIGNAL_SLOT_MODEL := if SIGNAL_SLOT >= 0 then MODEL_NOW else -1
        | SIGNAL_COUNT := SIGNAL_COUNT[?] + integer(SIGNAL_SLOT >= 0)
        | LABEL_SLOT := if GO and APPENDS_LABEL then LABEL_COUNT[?] else -1
        | LABEL_NAME := LABEL_NAME[?] next LABEL_SLOT : NAME0
        | LABEL_MODEL := LABEL_MODEL[?] next LABEL_SLOT : MODEL_NOW
        | NAME_LABEL_EVER := NAME_LABEL_EVER[?] next (if LABEL_SLOT >= 0 then NAME0 else -1) : true
        | MODEL_HAS_LABEL := MODEL_LAST_LABEL[?][MODEL_NOW] > 0
        | MODEL_FIRST_LABEL := MODEL_FIRST_LABEL[?] next (if LABEL_SLOT >= 0 and not MODEL_HAS_LABEL then MODEL_NOW else -1)
                               : LABEL_COUNT[?] + 1
        | LABEL_NEXT := LABEL_NEXT[?] next (if LABEL_SLOT >= 0 and MODEL_HAS_LABEL then MODEL_LAST_LABEL[?][MODEL_NOW] - 1 else -1)
                        : LABEL_COUNT[?] + 1
        | MODEL_LAST_LABEL := MODEL_LAST_LABEL[?] next (if LABEL_SLOT >= 0 then MODEL_NOW else -1) : LABEL_COUNT[?] + 1
        | LABEL_COUNT := LABEL_COUNT[?] + integer(LABEL_SLOT >= 0)
        | CONSTANT_SLOT := if GO and STORES_CONSTANT then CONSTANT_COUNT[?] else -1
        | CONSTANT_NAME := CONSTANT_NAME[?] next CONSTANT_SLOT : DECLARE_NAME[?]
        | CONSTANT_TYPE := CONSTANT_TYPE[?] next CONSTANT_SLOT : DECLARED_TYPE
        | CONSTANT_VALUE := CONSTANT_VALUE[?] next CONSTANT_SLOT : CONSTANT_VALUE_NOW
        | NAME_CONSTANT := NAME_CONSTANT[?] next (if CONSTANT_SLOT >= 0 then DECLARE_NAME[?] else -1) : CONSTANT_COUNT[?] + 1
        | CONSTANT_COUNT := CONSTANT_COUNT[?] + integer(CONSTANT_SLOT >= 0)
        | TABLE_SLOT := if GO and STORES_TABLE then TABLE_COUNT[?] else -1
        | TABLE_TYPE := TABLE_TYPE[?] next TABLE_SLOT : DECLARED_TYPE
        | TABLE_FROM_STRING := TABLE_FROM_STRING[?] next TABLE_SLOT : STORES_STRING
        | TABLE_START := TABLE_START[?] next TABLE_SLOT : (if STORES_STRING then TOKEN_TEXT[HERE] else LIST_START[?])
        | TABLE_LENGTH := TABLE_LENGTH[?] next TABLE_SLOT : (if STORES_STRING then STRING_BYTES else ELEMENT_COUNT)
        | TABLE_COUNT := TABLE_COUNT[?] + integer(TABLE_SLOT >= 0)
        | POOL_VALUE := POOL_VALUE[?] next (if GO and APPENDS_POOL then POOL_COUNT[?] else -1) : CONSTANT_VALUE_HELD[?]
        | POOL_COUNT := POOL_COUNT[?] + integer(GO and APPENDS_POOL)
        | USE_SLOT := if GO and CREATES_USE then USE_COUNT[?] else -1
        | USE_MODEL := USE_MODEL[?] next USE_SLOT : MODEL_NOW
        | USE_NAME := USE_NAME[?] next USE_SLOT : NAME0
        | USE_TOKEN := USE_TOKEN[?] next USE_SLOT : HERE
        | USE_PARENT := USE_PARENT[?] next USE_SLOT : LABEL_NODE[?]
        | USE_PATH_START := USE_PATH_START[?] next USE_SLOT : PATH_COUNT[?]
        | USE_PATH_LENGTH := USE_PATH_LENGTH[?] next USE_SLOT : PATH_PARENT_LENGTH + 1
        | USE_COUNT := USE_COUNT[?] + integer(USE_SLOT >= 0)
        | GUARD_SLOT := if GO and CREATES_GUARD then GUARD_COUNT[?] else -1
        | GUARD_MODEL := GUARD_MODEL[?] next GUARD_SLOT : MODEL_NOW
        | GUARD_ENTRY_START := GUARD_ENTRY_START[?] next GUARD_SLOT : EXPRESSION_START[?]
        | GUARD_ENTRY_COUNT := GUARD_ENTRY_COUNT[?] next GUARD_SLOT : ENTRY_COUNT[?] - EXPRESSION_START[?]
        | GUARD_TOKEN := GUARD_TOKEN[?] next GUARD_SLOT : GUARD_START_TOKEN[?]
        | GUARD_CONTEXT := GUARD_CONTEXT[?] next GUARD_SLOT : GUARD_NODE[?]
        | GUARD_LABELS := GUARD_LABELS[?] next GUARD_SLOT : LABEL_NODE[?]
        | GUARD_PATH_START := GUARD_PATH_START[?] next GUARD_SLOT : PATH_COUNT[?]
        | GUARD_PATH_LENGTH := GUARD_PATH_LENGTH[?] next GUARD_SLOT : PATH_PARENT_LENGTH + 1
        | GUARD_EQUATION_FIRST := GUARD_EQUATION_FIRST[?] next GUARD_SLOT : EQUATION_COUNT[?]
        | GUARD_GROUP_FIRST := GUARD_GROUP_FIRST[?] next GUARD_SLOT : GROUP_COUNT[?]
        | GUARD_DEPENDENCE_FIRST := GUARD_DEPENDENCE_FIRST[?] next GUARD_SLOT : DEPENDENCE_COUNT[?]
        | GUARD_CLOSE_SLOT := if POPS_FRAME and FRAME_TOP_KIND = FRAME_GUARD then FRAME_TOP_VALUE else -1
        | GUARD_END := GUARD_END[?] next GUARD_CLOSE_SLOT : GUARD_COUNT[?]
        | GUARD_EQUATION_LAST := GUARD_EQUATION_LAST[?] next GUARD_CLOSE_SLOT : EQUATION_COUNT[?]
        | GUARD_GROUP_LAST := GUARD_GROUP_LAST[?] next GUARD_CLOSE_SLOT : GROUP_COUNT[?]
        | GUARD_DEPENDENCE_LAST := GUARD_DEPENDENCE_LAST[?] next GUARD_CLOSE_SLOT : DEPENDENCE_COUNT[?]
        | GUARD_COUNT := GUARD_COUNT[?] + integer(GUARD_SLOT >= 0)
        | GUARD_DEPTH_MAX := if GUARD_SLOT >= 0 and PATH_PARENT_LENGTH + 1 > GUARD_DEPTH_MAX[?] then PATH_PARENT_LENGTH + 1
                             else GUARD_DEPTH_MAX[?]
        | LOOP_SLOT := if GO and (IN_ITERATE_NAME or INDEX_EQUATION and not INDEX_IS_ARRAY[?]) then LOOP_COUNT[?] else -1
        | LOOP_NAME := LOOP_NAME[?] next LOOP_SLOT : INDEX_NAME
        | LOOP_TOKEN := LOOP_TOKEN[?] next LOOP_SLOT : INDEX_TOKEN
        | LOOP_MODEL := LOOP_MODEL[?] next LOOP_SLOT : MODEL_NOW
        | LOOP_COUNT := LOOP_COUNT[?] + integer(LOOP_SLOT >= 0)
        | EQUATION_SLOT := if GO and (APPENDS_EQUATION or INDEX_EQUATION) then EQUATION_COUNT[?] else -1
        | EQUATION_TARGET := EQUATION_TARGET[?] next EQUATION_SLOT : (if INDEX_EQUATION then INDEX_NAME[?] else TARGET[?])
        | EQUATION_ENTRY_START := EQUATION_ENTRY_START[?] next EQUATION_SLOT : (if INDEX_EQUATION then STAGE_BASE else EXPRESSION_START[?])
        | EQUATION_ENTRY_COUNT := EQUATION_ENTRY_COUNT[?] next EQUATION_SLOT
                                  : (if INDEX_EQUATION then ENTRY_COUNT[?] + 1 - STAGE_BASE else ENTRY_COUNT[?] - EXPRESSION_START[?])
        | EQUATION_POSITION := EQUATION_POSITION[?] next EQUATION_SLOT : (if INDEX_EQUATION then INDEX_TOKEN[?] else EQUATION_TOKEN[?])
        | EQUATION_LOOP := EQUATION_LOOP[?] next EQUATION_SLOT
                           : (if INDEX_EQUATION then -1 else if REPEAT_LOOP[?] >= 0 then REPEAT_LOOP[?] else LOOP_NOW[?])
        | EQUATION_SEED := EQUATION_SEED[?] next EQUATION_SLOT : not INDEX_EQUATION and LOOP_SEED[?] and LOOP_NOW[?] >= 0
        | EQUATION_MODEL := EQUATION_MODEL[?] next EQUATION_SLOT : MODEL_NOW
        | EQUATION_LABELS := EQUATION_LABELS[?] next EQUATION_SLOT : LABEL_NODE[?]
        | EQUATION_GUARDS := EQUATION_GUARDS[?] next EQUATION_SLOT : GUARD_NODE[?]
        | EQUATION_STATEMENT := EQUATION_STATEMENT[?] next EQUATION_SLOT : IS_STATEMENT and not INDEX_EQUATION
        | EQUATION_COUNT := EQUATION_COUNT[?] + integer(EQUATION_SLOT >= 0)
        | MEMBER_SLOT := if GO and APPENDS_MEMBER then MEMBER_COUNT[?] else -1
        | MEMBER_ENTRY_START := MEMBER_ENTRY_START[?] next MEMBER_SLOT : (if IN_SYNC then ENTRY_COUNT[?] else EXPRESSION_START[?])
        | MEMBER_ENTRY_COUNT := MEMBER_ENTRY_COUNT[?] next MEMBER_SLOT : (if IN_SYNC then 1 else ENTRY_COUNT[?] - EXPRESSION_START[?])
        | MEMBER_COUNT := MEMBER_COUNT[?] + integer(MEMBER_SLOT >= 0)
        | GROUP_SLOT := if GO and APPENDS_GROUP then GROUP_COUNT[?] else -1
        | GROUP_POSITION := GROUP_POSITION[?] next GROUP_SLOT : (if IN_SYNC then MODEL_TOKEN[?][MODEL_NOW] else EQUATION_TOKEN[?])
        | GROUP_MODEL := GROUP_MODEL[?] next GROUP_SLOT : MODEL_NOW
        | GROUP_GUARDS := GROUP_GUARDS[?] next GROUP_SLOT : GUARD_NODE[?]
        | GROUP_MEMBER_FIRST := GROUP_MEMBER_FIRST[?] next GROUP_SLOT : GROUP_MEMBER_START[?]
        | GROUP_MEMBER_TOTAL := GROUP_MEMBER_TOTAL[?] next GROUP_SLOT : MEMBER_COUNT[?] + 1 - GROUP_MEMBER_START[?]
        | GROUP_COUNT := GROUP_COUNT[?] + integer(GROUP_SLOT >= 0)
        | DEPENDENCE_SLOT := if GO and APPENDS_DEPENDENCE then DEPENDENCE_COUNT[?] else -1
        | DEPENDENCE_FROM_NAME := DEPENDENCE_FROM_NAME[?] next DEPENDENCE_SLOT : TOKEN_NAME[EMIT_FROM_TOKEN] - 1
        | DEPENDENCE_FROM_TOKEN := DEPENDENCE_FROM_TOKEN[?] next DEPENDENCE_SLOT : EMIT_FROM_TOKEN
        | DEPENDENCE_TO_NAME := DEPENDENCE_TO_NAME[?] next DEPENDENCE_SLOT : TOKEN_NAME[EMIT_TO_TOKEN] - 1
        | DEPENDENCE_TO_TOKEN := DEPENDENCE_TO_TOKEN[?] next DEPENDENCE_SLOT : EMIT_TO_TOKEN
        | DEPENDENCE_POSITION := DEPENDENCE_POSITION[?] next DEPENDENCE_SLOT : EQUATION_TOKEN[?]
        | DEPENDENCE_MODEL := DEPENDENCE_MODEL[?] next DEPENDENCE_SLOT : MODEL_NOW
        | DEPENDENCE_GUARDS := DEPENDENCE_GUARDS[?] next DEPENDENCE_SLOT : GUARD_NODE[?]
        | DEPENDENCE_COUNT := DEPENDENCE_COUNT[?] + integer(DEPENDENCE_SLOT >= 0)
        | HIDE_SLOT := if GO and APPENDS_HIDE then HIDE_COUNT[?] else -1
        | HIDE_NAME := HIDE_NAME[?] next HIDE_SLOT : NAME0
        | HIDE_TOKEN := HIDE_TOKEN[?] next HIDE_SLOT : HERE
        | HIDE_COUNT := HIDE_COUNT[?] + integer(HIDE_SLOT >= 0)
        | HIDE_RANGE_SLOT := if GO and IN_MODEL_AFTER and CODE0 /= C_SLASH then MODEL_NOW else -1
        | MODEL_HIDE_START := MODEL_HIDE_START[?] next HIDE_RANGE_SLOT : BODY_HIDE_START[?]
        | MODEL_HIDE_END := MODEL_HIDE_END[?] next HIDE_RANGE_SLOT : HIDE_COUNT[?]
        | PRAGMA_SLOT := if GO and (IN_PRAGMA_STATEMENT and PRAGMA_KIND = N_INTERRUPT or IN_PRAGMA_CLOSE and PRAGMA_KIND = N_BOOT)
                         then PRAGMA_COUNT[?] else -1
        | MACHINE_TOKEN := if GO and MACHINE_STATEMENT then HERE - 1 else MACHINE_TOKEN[?]
        | PRAGMA_IRQ := PRAGMA_IRQ[?] next PRAGMA_SLOT : (if IN_PRAGMA_STATEMENT then INTERRUPT_VALUE else BOOT_ID)
        | PRAGMA_OBJECT := PRAGMA_OBJECT[?] next PRAGMA_SLOT : PRAGMA_NAME_HELD
        | PRAGMA_TOKEN := PRAGMA_TOKEN[?] next PRAGMA_SLOT : PRAGMA_TOKEN_HELD
        | PRAGMA_COUNT := PRAGMA_COUNT[?] + integer(PRAGMA_SLOT >= 0)
        | PRAGMA_HAS_BOOT := PRAGMA_HAS_BOOT[?] or PRAGMA_SLOT >= 0 and IN_PRAGMA_CLOSE
        | PRAGMA_USED := if PRAGMA_SLOT >= 0 then PRAGMA_USED[?] or INTERRUPT_BIT else PRAGMA_USED[?]
        | FIRST_PARSE_FAILURE := FAILS and STATE_BEFORE /= P_FAILED
        | PARSE_MESSAGE := if FIRST_PARSE_FAILURE then STEP_MESSAGE else PARSE_MESSAGE[?]
        | PARSE_TOKEN := if FIRST_PARSE_FAILURE then STEP_TOKEN else PARSE_TOKEN[?]
        | PARSE_ARGUMENT0 := if FIRST_PARSE_FAILURE then STEP_ARGUMENT0 else PARSE_ARGUMENT0[?]
        | PARSE_ARGUMENT1 := if FIRST_PARSE_FAILURE then STEP_ARGUMENT1 else PARSE_ARGUMENT1[?]
        | PARSE_ARGUMENT2 := if FIRST_PARSE_FAILURE then STEP_ARGUMENT2 else PARSE_ARGUMENT2[?]
        |)
     with (| AT := 0 | PARSE_STATE := P_COPY_TYPES | CURRENT_MODEL := -1 | RETURN_STATE := 0 | ROLE := 0
           | PENDING_MODEL_KIND := 0 | ARRAY_SIZE := ulong(0) | CANDIDATE := -1 | ARRAY_ELEMENT := 0 | ARRAY_BUCKET := 0 | PARSED_TYPE := 0
           | DECLARE_NAME := 0 | DECLARE_TOKEN := 0 | CONSTANT_RETURN := 0 | CONSTANT_VALUE_HELD := long(0)
           | CONSTANT_VALUE_TYPE := 0 | LIST_COUNT := 0 | LIST_START := 0 | LOOP_NOW := -1 | LOOP_SEED := false
           | LABEL_NODE := -1 | GUARD_NODE := -1 | GUARD_START_TOKEN := 0 | EXPRESSION_START := 0 | EXPRESSION_RETURN := 0
           | TARGET := -1 | EQUATION_TOKEN := 0 | ALIAS_NAME := 0 | INNER_WHERE := false | PRAGMA_ITEMS := 0
           | SET_LEFT_START := 0 | SET_LEFT_COUNT := 0 | SET_RIGHT_START := 0 | SET_RIGHT_COUNT := 0
           | SET_READING_RIGHT := false | SET_ARROWED := false | EMIT_I := 0 | EMIT_J := 0 | HIDE_RETURN := 0 | STAGE_INDEX := 0 | COPY_I := 0
           | STAGE_BASE := 0 | RECOVER_INDEX_START := 0 | RECOVER_INDEX_END := 0 | RECOVER_ARRAY := 0 | RECOVER_ARRAY_TOKEN := 0
           | RECOVER_READY := false | TUPLE_TOKEN := 0 | TUPLE_ARITY := 0 | TUPLE_INDEX := -1
           | CASE_ELSE_BRANCH := false | CASE_BRANCH_ITEMS := 0 | CASE_WALK := -1 | CASE_SCAN_AT := -1 | CASE_LITERAL_TOKEN := 0
           | CASE_VALUE_COUNT := 0 | CASE_DEPTH := 0 | STATE_GUARDED := false | SYNC_I := 0 | SYNC_DONE := false
           | HIDE_COUNT := 0 | BODY_HIDE_START := 0 | DECLARE_INITED := false | GROUP_MEMBER_START := 0 | CALL_HEAD := 0
           | PARAMETER_START := 0 | PARAMETER_COUNT := 0 | PATH_FROM := 0 | PATH_LEFT := 0 | PATH_APPEND := 0
           | PATH_COUNT := 0 | FRAME_DEPTH := 0 | PENDING_DEPTH := 0 | OPENER_TOP := -1 | ENTRY_COUNT := 0 | TEMPLATE_ENTRIES := 0
           | BODY_INTRINSICS := 0 | BODY_STATEMENTS := 0 | BODY_EQUATION_START := 0 | BODY_GROUP_START := 0
           | BODY_DEPENDENCE_START := 0 | BODY_GUARD_START := 0 | BODY_USE_START := 0 | BODY_MEMBER_START := 0 | GUARD_DEPTH_MAX := 0
           | TYPE_COUNT := 0 | MODEL_COUNT := 0
           | CLOSED_COUNT := 0 | LOCAL_COUNT := 0 | SIGNAL_COUNT := 0 | LABEL_COUNT := 0 | CONSTANT_COUNT := 0
           | TABLE_COUNT := 0 | POOL_COUNT := 0 | USE_COUNT := 0 | GUARD_COUNT := 0 | LOOP_COUNT := 0 | EQUATION_COUNT := 0
           | MEMBER_COUNT := 0 | GROUP_COUNT := 0 | DEPENDENCE_COUNT := 0 | PARSE_MESSAGE := 0 | PARSE_TOKEN := 0
           | PARSE_ARGUMENT0 := 0 | PARSE_ARGUMENT1 := 0 | PARSE_ARGUMENT2 := 0 | PRAGMA_KIND := 0 | PRAGMA_NAME_HELD := 0
           | PRAGMA_TOKEN_HELD := 0 | PRAGMA_COUNT := 0 | PRAGMA_HAS_BOOT := false | PRAGMA_USED := ulong(0)
           | MACHINE_TOKEN := -1 | INDEX_IS_ARRAY := false | INDEX_NAME := 0 | INDEX_TOKEN := 0 | INDEX_BOUND_AT := 0
           | INDEX_BOUND_END := 0 | REPEAT_E_START := 0 | REPEAT_LOOP := -1 | INDEX_TOTAL := 0 | INDEX_DEPTH := 0 | INDEX_RETURN := 0
           | REPEAT_SEEN := 0 | REPEAT_FIRST_TOKEN := 0 |)
     end
   | PLATFORM := if MACHINE_TOKEN >= 0 then PLATFORM_MPS2 else if PRAGMA_COUNT > 0 then PLATFORM_VIRT else PLATFORM_MACOS
   | PRAGMA_CHECKS := PARSES and PARSE_MESSAGE = 0 and PARSE_STATE = P_DONE and PLATFORM /= PLATFORM_MACOS
   | INTERRUPT_LOWEST := if PLATFORM = PLATFORM_MPS2 then 15 else 16
   | INTERRUPT_HIGHEST := if PLATFORM = PLATFORM_MPS2 then 47 else 31
   | PC_INDEX := 0 .. (if PRAGMA_CHECKS then (PRAGMA_COUNT + 1) * SIGNAL_COUNT - 1 else -1)
   | iterate PC_INDEX of
       (| PC_PRAGMA := PC_INDEX / SIGNAL_COUNT
        | PC_SIGNAL := PC_INDEX modulo SIGNAL_COUNT
        | PC_NAMING := PC_PRAGMA < PRAGMA_COUNT
        | PC_TOP_INPUT := SIGNAL_MODEL[PC_SIGNAL] = 0 and SIGNAL_ROLE[PC_SIGNAL] = ROLE_INPUT
        | PC_MATCHES := PC_NAMING and SIGNAL_MODEL[PC_SIGNAL] = 0 and SIGNAL_NAME[PC_SIGNAL] = PRAGMA_OBJECT[PC_PRAGMA]
        | PC_FOUND := PC_MATCHES or PC_SIGNAL > 0 and PC_FOUND[?]
        | PC_IRQ := PRAGMA_IRQ[if PC_NAMING then PC_PRAGMA else 0]
        | PC_OUT_OF_RANGE := PC_NAMING and PC_SIGNAL = 0 and PC_IRQ /= BOOT_ID
                             and (PC_IRQ < INTERRUPT_LOWEST or PC_IRQ > INTERRUPT_HIGHEST)
        | PC_STEP_MESSAGE := if PC_OUT_OF_RANGE then
                               (if PLATFORM = PLATFORM_MPS2 then T_INTERRUPT_NUMBER_MPS2 else T_INTERRUPT_NUMBER)
                             else if PC_MATCHES then
                               (if SIGNAL_ROLE[PC_SIGNAL] /= ROLE_INPUT then T_PRAGMA_INPUT
                                else if SIGNAL_TYPE[PC_SIGNAL] /= BUILTIN_EVENT then T_PRAGMA_EVENT
                                else if SIGNAL_IRQ1[?][PC_SIGNAL] > 0 then T_PRAGMA_TWICE else 0)
                             else if PC_NAMING and PC_SIGNAL = SIGNAL_COUNT - 1 and not PC_FOUND then T_PRAGMA_INPUT
                             else if not PC_NAMING and PC_TOP_INPUT and SIGNAL_IRQ1[?][PC_SIGNAL] = 0 then T_INPUT_UNNAMED
                             else if not PC_NAMING and PC_SIGNAL = SIGNAL_COUNT - 1 and PRAGMA_COUNT > 0 and not PRAGMA_HAS_BOOT
                             then T_BOOT_MISSING
                             else 0
        | SIGNAL_IRQ1 := SIGNAL_IRQ1[?] next (if PC_MATCHES and PC_STEP_MESSAGE = 0 then PC_SIGNAL else -1) : PRAGMA_IRQ[PC_PRAGMA] + 1
        | PC_FIRST := PC_STEP_MESSAGE /= 0 and PRAGMA_MESSAGE[?] = 0
        | PRAGMA_MESSAGE := if PC_FIRST then PC_STEP_MESSAGE else PRAGMA_MESSAGE[?]
        | PRAGMA_MESSAGE_TOKEN := if not PC_FIRST then PRAGMA_MESSAGE_TOKEN[?] else if PC_OUT_OF_RANGE then PRAGMA_TOKEN[PC_PRAGMA] + 2
                                  else if PC_NAMING then PRAGMA_TOKEN[PC_PRAGMA]
                                  else if PC_STEP_MESSAGE = T_BOOT_MISSING then PRAGMA_TOKEN[0] - 2 else SIGNAL_TOKEN[PC_SIGNAL]
        | PRAGMA_ARGUMENT0 := if not PC_FIRST then PRAGMA_ARGUMENT0[?] else if PC_OUT_OF_RANGE then PRAGMA_TOKEN[PC_PRAGMA] + 2
                              else if PC_NAMING then PRAGMA_OBJECT[PC_PRAGMA]
                              else SIGNAL_NAME[PC_SIGNAL]
        |)
     with (| PC_FOUND := false | PRAGMA_MESSAGE := 0 | PRAGMA_MESSAGE_TOKEN := 0 | PRAGMA_ARGUMENT0 := 0 |)
     end
   | PRAGMA_FAILED := PRAGMA_CHECKS and PRAGMA_MESSAGE /= 0
   | FINISH_BOUND := long(64) + long(24) * long(MODEL_COUNT) + long(LABEL_COUNT) + long(2) * long(USE_COUNT)
                     + long(4) * long(SIGNAL_COUNT) + long(16) * long(EQUATION_COUNT) + long(2) * long(MEMBER_COUNT)
                     + long(16) * long(GUARD_COUNT) + long(6) * long(ENTRY_COUNT) + long(2) * long(DEPENDENCE_COUNT)
                     + long(HIDE_COUNT) + long(SIGNAL_COUNT) + long(2) * long(MODEL_COUNT)
                     + long(64) * long(TEMPLATE_ENTRIES) + (if TEMPLATE_ENTRIES > 0 then long(4) * long(ENTRY_COUNT) else long(0))
                     + long(GUARD_DEPTH_MAX + 1) * (long(4) * long(ENTRY_COUNT) + long(4) * long(EQUATION_COUNT)
                                                   + long(2) * long(MEMBER_COUNT) + long(2) * long(DEPENDENCE_COUNT)
                                                   + long(8) * long(GUARD_COUNT) * long(SIGNAL_COUNT + 4))
   | FINISH_INDEX := 0 .. (if PARSES and CLOSED_COUNT > 0 then FINISH_BOUND else long(-1))
   | iterate FINISH_INDEX of
       (| PHASE := FINISH_PHASE[?]
        | CLOSE_RANK := FINISH_MODEL_ORDINAL[?]
        | MODEL_HERE := CLOSE_ORDER[CLOSE_RANK]
        | MODEL_STAMP := CLOSE_RANK + 1
        | WORK_ROW := FINISH_ROW[?]
        | STEP := FINISH_SUB[?]
        | AUTOMATON_NOW := MODEL_KIND[MODEL_HERE] = C_AUTOMATON
        | STATE_TYPE_NOW := MODEL_STATE_TYPE[MODEL_HERE]
        | MODEL_AT := MODEL_TOKEN[MODEL_HERE]
        | MODEL_KEY := MODEL_NAME[MODEL_HERE]
        | GUARD_NOW := MODEL_GUARD_START[MODEL_HERE] + GUARD_NUMBER[?] - 1
        | GUARD_SUFFIX := GUARD_NUMBER[?] * NAME_CAP
        | GUARD_AT := GUARD_TOKEN[GUARD_NOW]
        | AT_START := PHASE = PHASE_START
        | AT_LABEL := PHASE = PHASE_LABEL
        | AT_USE := PHASE = PHASE_USE
        | AT_SIGNAL := PHASE = PHASE_SIGNAL
        | AT_HIDE := PHASE = PHASE_HIDE
        | AT_INITS := PHASE = PHASE_INITS
        | AT_STATEMENT := PHASE = PHASE_STATEMENT
        | AT_REWRITE := PHASE >= PHASE_REWRITE_EQ and PHASE <= PHASE_REWRITE_TRIGGER
        | AT_CLOCK := PHASE = PHASE_CLOCK
        | AT_STATE := PHASE = PHASE_STATE
        | AT_CUR := PHASE = PHASE_CUR
        | AT_CUR_TAIL := PHASE = PHASE_CUR_TAIL
        | AT_GROUP := PHASE = PHASE_GROUP
        | AT_GUARD_START := PHASE = PHASE_GUARD_START
        | AT_DEFINE_PARSE := PHASE = PHASE_DEFINE_PARSE
        | AT_DEFINE_FINISH := PHASE = PHASE_DEFINE_FINISH
        | AT_READ := PHASE >= PHASE_READ_PARSE and PHASE <= PHASE_READ_MEMBERS
        | AT_READ_DEPS := PHASE = PHASE_READ_DEPS
        | AT_ON := PHASE = PHASE_ON
        | AT_FILTER := PHASE = PHASE_FILTER
        | ALL_CLOSED := CLOSE_RANK >= CLOSED_COUNT
        | LABELS_DONE := WORK_ROW < 0
        | USES_DONE := WORK_ROW >= MODEL_USE_END[MODEL_HERE]
        | USE_UNDECLARED := LABEL_STAMP[?][USE_NAME[WORK_ROW]] /= MODEL_STAMP
        | SIGNALS_DONE := WORK_ROW < 0
        | INITS_DONE := WORK_ROW < 0
        | INIT_UNUSED_HERE := not INITS_DONE and SIGNAL_INIT_KIND[WORK_ROW] /= INIT_NONE
                              and INIT_USED[?][SIGNAL_NAME[WORK_ROW]] /= MODEL_STAMP
        | HIDES_DONE := WORK_ROW >= MODEL_HIDE_END[MODEL_HERE]
        | HIDE_KEY := HIDE_NAME[WORK_ROW]
        | HIDE_ROLE := OWN_ROLE[?][HIDE_KEY]
        | HIDE_FINISH_MESSAGE := if HIDES_DONE then 0 else if OWN_STAMP[?][HIDE_KEY] /= MODEL_STAMP then T_SIGNAL_UNDECLARED
                                 else if HIDE_ROLE /= ROLE_LOCAL then T_HIDES_OUTPUT else 0
        | STATEMENTS_DONE := WORK_ROW >= MODEL_EQUATION_END[MODEL_HERE]
        | ST_START := EQUATION_ENTRY_START[WORK_ROW]
        | ST_COUNT := EQUATION_ENTRY_COUNT[WORK_ROW]
        | ST_CALL := ST_START + ST_COUNT - 1
        | ST_NAME := ENTRY_NAME[ST_CALL]
        | ST_ARGUMENTS := integer(ENTRY_VALUE[ST_CALL])
        | ST_TOKEN := ENTRY_TOKEN[ST_CALL]
        | ST_INITIAL := ST_NAME = N_INITIAL
        | ST_EXPECTED := if ST_INITIAL then 1 else 3
        | ST_SHAPE_OK := ENTRY_OP[ST_START] = OP_SIGNAL
                         and (if ST_INITIAL then ST_COUNT = 2
                              else ENTRY_SPLIT[ST_CALL] = ST_START + 2 and ENTRY_OP[ST_START + 1] = OP_SIGNAL)
        | ST_STATE := ENTRY_NAME[ST_START + STEP]
        | ST_STATE_TOKEN := ENTRY_TOKEN[ST_START + STEP]
        | ST_KNOWN := STATE_STAMP[?][ST_STATE] = MODEL_STAMP
        | ST_ORDINAL := if ST_KNOWN then STATE_ORDINAL[?][ST_STATE] else STATE_COUNT[?]
        | ST_IS_STATEMENT := not STATEMENTS_DONE and EQUATION_STATEMENT[WORK_ROW]
        | AUTOMATON_STATEMENT_MESSAGE := if not ST_IS_STATEMENT then 0
                               else if STEP = 0 and ST_ARGUMENTS /= ST_EXPECTED then T_WRONG_ARGUMENTS
                               else if STEP = 0 and EQUATION_LABELS[WORK_ROW] >= 0 then T_LABEL_PLACED
                               else if STEP = 0 and ST_INITIAL and EQUATION_GUARDS[WORK_ROW] >= 0 then T_CANNOT_GUARD
                               else if STEP = 0 and not ST_SHAPE_OK then T_EXPECTS_STATE
                               else if LABEL_STAMP[?][ST_STATE] /= MODEL_STAMP then T_NOT_LABEL_OF
                               else if STEP = 0 and ST_INITIAL and HAS_INITIAL[?] then T_ONE_INITIAL
                               else 0
        | REGISTERS_STATE := AT_STATEMENT and ST_IS_STATEMENT and AUTOMATON_STATEMENT_MESSAGE = 0 and not ST_KNOWN
        | RECORDS_INITIAL := AT_STATEMENT and ST_IS_STATEMENT and AUTOMATON_STATEMENT_MESSAGE = 0 and ST_INITIAL
        | RECORDS_TRANSITION := AT_STATEMENT and ST_IS_STATEMENT and AUTOMATON_STATEMENT_MESSAGE = 0 and STEP = 1
        | RW_HEADER := AT_REWRITE and STEP < 0
        | RW_ITEMS_END := if PHASE = PHASE_REWRITE_EQ then MODEL_EQUATION_END[MODEL_HERE] else if PHASE = PHASE_REWRITE_MEMBER then MODEL_MEMBER_END[MODEL_HERE]
                          else if PHASE = PHASE_REWRITE_GUARD then MODEL_GUARD_END[MODEL_HERE] else TRANSITION_COUNT[?]
        | RW_PHASE_DONE := RW_HEADER and WORK_ROW >= RW_ITEMS_END
        | TRIGGER_GUARDED := TRANSITION_GUARD[?][WORK_ROW] > 0
        | RW_ITEM_START := if PHASE = PHASE_REWRITE_EQ then EQUATION_ENTRY_START[WORK_ROW] else if PHASE = PHASE_REWRITE_MEMBER then MEMBER_ENTRY_START[WORK_ROW]
                           else if PHASE = PHASE_REWRITE_GUARD then GUARD_ENTRY_START[WORK_ROW] else TRANSITION_TRIGGER_START[?][WORK_ROW]
        | RW_ITEM_COUNT := if PHASE = PHASE_REWRITE_EQ then (if AUTOMATON_NOW and EQUATION_STATEMENT[WORK_ROW] then 0 else EQUATION_ENTRY_COUNT[WORK_ROW])
                           else if PHASE = PHASE_REWRITE_MEMBER then MEMBER_ENTRY_COUNT[WORK_ROW]
                           else if PHASE = PHASE_REWRITE_GUARD then GUARD_ENTRY_COUNT[WORK_ROW]
                           else TRANSITION_TRIGGER_END[?][WORK_ROW] - TRANSITION_TRIGGER_START[?][WORK_ROW] + 2 * integer(TRIGGER_GUARDED)
        | RW_REAL_END := if PHASE = PHASE_REWRITE_TRIGGER then TRANSITION_TRIGGER_END[?][WORK_ROW] else RW_LAST[?]
        | REST := TEMPLATE_PC[?] >= 0
        | REST_ROW := if REST then TEMPLATE_PC[?] else 0
        | REST_KIND := if REST then TEMPLATE_ROW_KIND[REST_ROW] else -1
        | REST_COPY := REST_KIND = TPK_LEFT or REST_KIND = TPK_RIGHT
        | TR_INIT_ROW := REST_KIND = TPK_EMIT and (TEMPLATE_ROW_REF[REST_ROW] = TPV_INIT or TEMPLATE_ROW_REF[REST_ROW] = TPV_INIT_DECL)
        | TEMPLATE_AT_HELD := TEMPLATE_AT[?]
        | RW_ENTRY := if TR_INIT_ROW then TEMPLATE_AT_HELD else RW_AT[?]
        | ITEM_LAST_ENTRY := RW_ITEM_START + RW_ITEM_COUNT - 1
        | WHOLE_HERE := RW_HEADER and PHASE = PHASE_REWRITE_EQ and not RW_PHASE_DONE and RW_ITEM_COUNT > 0
                        and OP_TEMPLATE_KIND[ENTRY_OP[ITEM_LAST_ENTRY]] = 1 and EQUATION_TARGET[WORK_ROW] >= 0
        | SKIPPED := AT_REWRITE and STEP >= 0 and not REST and not RW_IS_EXTENSION
                     and (TEMPLATE_AT_HELD >= 0 and RW_ENTRY >= SKIP_FROM[?] and RW_ENTRY < TEMPLATE_AT_HELD
                          or RW_ENTRY + 1 < RW_LAST[?] and ENTRY_OP[RW_ENTRY + 1] = OP_VAR)
        | TR_OP_KIND := if RW_IS_EXTENSION or RW_HEADER then 0 else OP_TEMPLATE_KIND[RW_OP]
        | AT_CONSTRUCT := AT_REWRITE and STEP >= 0 and not REST and not SKIPPED and TR_OP_KIND > 0
        | RW_LIVE := AT_REWRITE and STEP >= 0 and not SKIPPED and not AT_CONSTRUCT and (not REST or REST_COPY)
        | CONSTRUCT := if REST then TEMPLATE_AT_HELD else RW_ENTRY
        | CONSTRUCT_SPLIT := ENTRY_SPLIT[CONSTRUCT]
        | CONSTRUCT_TOKEN := ENTRY_TOKEN[CONSTRUCT]
        | OPERAND_NAME := ENTRY_NAME[CONSTRUCT - 1]
        | BOUND_OP := ENTRY_OP[CONSTRUCT_SPLIT]
        | BOUND_CONSTANT := if BOUND_OP = OP_SIGNAL then NAME_CONSTANT[ENTRY_NAME[CONSTRUCT_SPLIT]] - 1 else -1
        | BOUND_TYPE := if BOUND_OP = OP_CONST then ENTRY_TYPE[CONSTRUCT_SPLIT]
                        else if BOUND_CONSTANT >= 0 then CONSTANT_TYPE[BOUND_CONSTANT] else -1
        | BOUND_VALUE := if BOUND_OP = OP_CONST then ENTRY_VALUE[CONSTRUCT_SPLIT]
                         else if BOUND_CONSTANT >= 0 then CONSTANT_VALUE[BOUND_CONSTANT] else long(0)
        | BOUND_OK := CONSTRUCT - CONSTRUCT_SPLIT = 1 and BOUND_TYPE >= 0
                      and TYPE_KIND[if BOUND_TYPE >= 0 then BOUND_TYPE else 0] = TK_INT and BOUND_VALUE >= long(1)
        | GUARDED_ITEM := EQUATION_GUARDS[WORK_ROW] >= 0 or EQUATION_LABELS[WORK_ROW] >= 0
        | CONSTRUCT_MESSAGE := if TR_OP_KIND = 0 or STEP /= 0 or not (AT_CONSTRUCT or RW_LIVE) then 0
                               else if TR_OP_KIND = 1 then
                                 (if REST or RW_ENTRY /= TEMPLATE_AT_HELD then T_WHOLE_DEFINITION
                                  else if GUARDED_ITEM then T_TEMPLATE_GUARDED
                                  else if RW_OP = OP_COUNT and not BOUND_OK then T_CONSTANT_BOUND else 0)
                               else if REST or PHASE /= PHASE_REWRITE_EQ or RW_TARGET < 0 or TEMPLATE_AT_HELD >= 0 then T_VAR_CONTEXT
                               else if GUARDED_ITEM then T_TEMPLATE_GUARDED
                               else if OWN_STAMP[?][OPERAND_NAME] /= MODEL_STAMP then T_SIGNAL_UNDECLARED else 0
        | NONMONO_HERE := RW_LIVE and not REST and STEP = 0 and OP_ARITY[RW_OP] > 0 and OP_MONOCHRONOUS[RW_OP] = 0
        | ITEM_NONMONO := if RW_HEADER then false else ITEM_NONMONO[?] or NONMONO_HERE
        | TEMPLATE_NOW := if RW_HEADER then (if WHOLE_HERE then ITEM_LAST_ENTRY else -1)
                          else if AT_CONSTRUCT and TR_OP_KIND = 2 then RW_ENTRY else TEMPLATE_AT_HELD
        | TEMPLATE_SAFE := if TEMPLATE_NOW >= 0 then TEMPLATE_NOW else 0
        | REST_DUE := AT_REWRITE and STEP >= 0 and not REST and RW_ITEM_DONE and TEMPLATE_NOW >= 0
        | VAR_MONO_MESSAGE := if REST_DUE and ENTRY_OP[TEMPLATE_SAFE] = OP_VAR and ITEM_NONMONO then T_VAR_CONTEXT else 0
        | TEMPLATE_MESSAGE := if CONSTRUCT_MESSAGE /= 0 then CONSTRUCT_MESSAGE else VAR_MONO_MESSAGE
        | ENTERS_REST := REST_DUE and GOES
        | REST_ROW_DONE := not REST_COPY or RW_ENTRY_DONE and RW_ENTRY + 1 >= RW_LAST[?]
        | REST_ENDS := REST_KIND = TPK_END
        | NEXT_TEMPLATE_PC := if ENTERS_REST then OP_TEMPLATE_REST_START[ENTRY_OP[TEMPLATE_SAFE]]
                              else if REST and not REST_ENDS then REST_ROW + integer(REST_ROW_DONE) else -1
        | TEMPLATE_PC := NEXT_TEMPLATE_PC
        | TEMPLATE_AT := if REST_ENDS then -1 else TEMPLATE_NOW
        | SKIP_FROM := if WHOLE_HERE then
                         (if OP_TEMPLATE_SKIPS_LEFT[ENTRY_OP[ITEM_LAST_ENTRY]] = 1 then RW_ITEM_START else ENTRY_SPLIT[ITEM_LAST_ENTRY])
                       else SKIP_FROM[?]
        | NEXT_ROW_KIND := TEMPLATE_ROW_KIND[if NEXT_TEMPLATE_PC >= 0 then NEXT_TEMPLATE_PC else 0]
        | MOVES_TO_COPY := (ENTERS_REST or REST and REST_ROW_DONE and not REST_ENDS)
                           and (NEXT_ROW_KIND = TPK_LEFT or NEXT_ROW_KIND = TPK_RIGHT)
        | COPY_RANGE_START := if NEXT_ROW_KIND = TPK_LEFT then RW_ITEM_START else ENTRY_SPLIT[TEMPLATE_SAFE]
        | COPY_RANGE_END := if NEXT_ROW_KIND = TPK_LEFT then ENTRY_SPLIT[TEMPLATE_SAFE] else TEMPLATE_SAFE
        | TEMPLATE_ORDINAL := if PHASE /= PHASE_REWRITE_EQ and NEXT_PHASE = PHASE_REWRITE_EQ then 1
                              else TEMPLATE_ORDINAL[?] + integer(REST_ENDS)
        | TR_ROW := if REST then REST_ROW else OP_TEMPLATE_INLINE_START[RW_OP] + STEP
        | TR_EMITTING := AT_CONSTRUCT or REST_KIND = TPK_EMIT
        | TR_REF := TEMPLATE_ROW_REF[TR_ROW]
        | TR_OP := TEMPLATE_ROW_OP[TR_ROW]
        | TR_ROW_NAME := TEMPLATE_ROW_NAME[TR_ROW]
        | TR_NAME := if TR_ROW_NAME = TPR_TARGET then RW_TARGET else if TR_ROW_NAME = TPR_OPERAND then OPERAND_NAME
                     else if TR_ROW_NAME >= 0 then TR_ROW_NAME + TEMPLATE_ORDINAL[?] * NAME_CAP else -1
        | TR_ROW_TYPE := TEMPLATE_ROW_TYPE[TR_ROW]
        | TR_TYPE := if TR_ROW_TYPE = TPR_TARGET then OWN_TYPE[?][RW_TARGET]
                     else if TR_ROW_TYPE = TPR_OPERAND then OWN_TYPE[?][OPERAND_NAME]
                     else if TR_ROW_TYPE = TPR_BOUND then BOUND_TYPE else TR_ROW_TYPE
        | TR_VALUE := if TR_REF = TPV_BOUND then BOUND_VALUE - long(1) else long(TEMPLATE_ROW_VALUE[TR_ROW])
        | TEMPLATE_DEFINES := REST_KIND = TPK_DEFINE
        | TEMPLATE_GROUPS := REST_KIND = TPK_GROUP
        | SEGMENT_BEGIN := if ENTERS_REST then ITEM_END_VALUE else if TEMPLATE_DEFINES or TEMPLATE_GROUPS then FINAL_COUNT[?]
                           else SEGMENT_BEGIN[?]
        | RW_EXTENSION := RW_ENTRY - RW_REAL_END
        | RW_IS_EXTENSION := PHASE = PHASE_REWRITE_TRIGGER and RW_EXTENSION >= 0
        | RW_OP := ENTRY_OP[RW_ENTRY]
        | RW_NAME := ENTRY_NAME[RW_ENTRY]
        | RW_INTRINSIC := RW_LIVE and not RW_IS_EXTENSION and RW_OP = OP_CALL and RW_NAME >= N_INITIAL and RW_NAME <= N_ISIN
        | RW_ARGUMENTS := integer(ENTRY_VALUE[RW_ENTRY])
        | RW_IS_DELAY := not RW_IS_EXTENSION and (RW_OP = OP_DELAY and RW_LIVE or TR_INIT_ROW)
        | RW_TARGET := EQUATION_TARGET[WORK_ROW]
        | RW_DECL_SITE := (PHASE = PHASE_REWRITE_EQ and RW_IS_DELAY and not REST and RW_ENTRY = RW_LAST[?] - 1 and RW_TARGET >= 0
                           or TR_INIT_ROW and TEMPLATE_ROW_REF[REST_ROW] = TPV_INIT_DECL and TEMPLATE_AT_HELD = ITEM_LAST_ENTRY)
                          and OWN_STAMP[?][RW_TARGET] = MODEL_STAMP
        | RW_DECL_ROW := if RW_DECL_SITE and ENTRY_AUX[RW_ENTRY] = INIT_NONE then OWN_INIT[?][RW_TARGET] - 1 else -1
        | RW_FILLS_DECL := RW_DECL_ROW >= 0
        | RW_INIT_KIND := if RW_FILLS_DECL then SIGNAL_INIT_KIND[RW_DECL_ROW] else ENTRY_AUX[RW_ENTRY]
        | RW_INIT_NAMED := RW_IS_DELAY and RW_INIT_KIND = INIT_NAME
        | RW_INIT_CONSTANT := NAME_CONSTANT[if RW_FILLS_DECL then SIGNAL_INIT_NAME[RW_DECL_ROW] else RW_NAME] - 1
        | RW_INIT_TOKEN := if RW_FILLS_DECL then SIGNAL_INIT_TOKEN[RW_DECL_ROW] else ENTRY_AUX2[RW_ENTRY]
        | RW_IS_SIZE := RW_LIVE and not RW_IS_EXTENSION and RW_OP = OP_CONST and ENTRY_AUX[RW_ENTRY] = INIT_SIZE
        | RW_SIZE_CONSTANT := NAME_CONSTANT[RW_NAME] - 1
        | RW_SIZE_TYPE := if OWN_STAMP[?][RW_NAME] = MODEL_STAMP then OWN_TYPE[?][RW_NAME]
                          else if RW_SIZE_CONSTANT >= 0 then CONSTANT_TYPE[RW_SIZE_CONSTANT] else -1
        | RW_SIZE := if RW_SIZE_TYPE >= 0 then long(TYPE_SIZE[RW_SIZE_TYPE]) else long(1)
        | RW_SIZE_VALUE := RW_SIZE + ENTRY_VALUE[RW_ENTRY]
        | RW_INIT_MESSAGE := if STEP = 0 and RW_INIT_NAMED and RW_INIT_CONSTANT < 0 then T_DELAY_INITIAL
                             else if STEP = 0 and RW_IS_SIZE and RW_SIZE = long(0) then T_NOT_ARRAY else 0
        | RW_PREVIOUS_NAME := ENTRY_NAME[RW_ENTRY - 1]
        | RW_NEXT_IS_ISIN := RW_LIVE and AUTOMATON_NOW and RW_ENTRY + 1 < RW_REAL_END and ENTRY_OP[RW_ENTRY + 1] = OP_CALL
                             and ENTRY_NAME[RW_ENTRY + 1] = N_ISIN
        | RW_MESSAGE := if not RW_INTRINSIC or STEP /= 0 then 0
                        else if not AUTOMATON_NOW then T_ONLY_AUTOMATON
                        else if RW_NAME /= N_ISIN then T_NO_OUTPUT
                        else if PHASE = PHASE_REWRITE_EQ and EQUATION_TARGET[WORK_ROW] < 0 and RW_ENTRY = RW_LAST[?] - 1 then T_HAS_OUTPUT
                        else if RW_ARGUMENTS /= 1 then T_WRONG_ARGUMENTS
                        else if RW_ENTRY = RW_ITEM_FIRST[?] or ENTRY_OP[RW_ENTRY - 1] /= OP_SIGNAL then T_EXPECTS_STATE
                        else if STATE_STAMP[?][RW_PREVIOUS_NAME] /= MODEL_STAMP then T_NOT_STATE
                        else 0
        | RW_ENTRY_DONE := if AT_CONSTRUCT then STEP + 1 >= OP_TEMPLATE_INLINE_LENGTH[RW_OP] else not RW_INTRINSIC or STEP = 1
        | RW_ITEM_DONE := RW_ENTRY_DONE and RW_ENTRY + 1 >= RW_LAST[?]
        | RW_EMITS := AT_REWRITE and STEP >= 0 and (RW_LIVE or TR_EMITTING)
        | CLOCK_DONE := SYNTH_COUNT[?] >= MODEL_INPUTS[MODEL_HERE]
        | CLOCK_LAST_SUB := if SYNTH_COUNT[?] > 0 then 2 else 1
        | CUR_DONE := WORK_ROW >= TRANSITION_COUNT[?]
        | CUR_GUARD_NUMBER := TRANSITION_GUARD[?][WORK_ROW]
        | CUR_TOKEN := TRANSITION_TOKEN[?][WORK_ROW]
        | CUR_LAST_SUB := if WORK_ROW > TRANSITION_FIRST[?] then 7 else 6
        | HAS_TRANSITIONS := TRANSITION_COUNT[?] > TRANSITION_FIRST[?]
        | GUARD_LAST_EQUATION := GUARD_EQUATION_LAST[GUARD_NOW]
        | CHAIN_START_NOW := if GUARD_END[GUARD_NOW] - 1 > GUARD_NOW then FILTER_ROW_START[?][GUARD_END[GUARD_NOW] - 1]
                             else FINISH_EQUATION_COUNT[?]
        | DEFINE_PARSE_DONE := WORK_ROW >= GUARD_LAST_EQUATION
        | DEFINE_FINISH_DONE := WORK_ROW >= FINISH_EQUATION_COUNT[?]
        | DEFINED_KEY := if AT_DEFINE_PARSE then EQUATION_TARGET[WORK_ROW] else FINISH_EQUATION_TARGET[?][WORK_ROW]
        | DEFINES := (AT_DEFINE_PARSE and not DEFINE_PARSE_DONE or AT_DEFINE_FINISH and not DEFINE_FINISH_DONE)
                     and DEFINED_KEY >= 0 and DEFINED_KEY < NAME_CAP
        | GUARD_FIRST_GROUP := GUARD_GROUP_FIRST[GUARD_NOW]
        | GUARD_LAST_GROUP := GUARD_GROUP_LAST[GUARD_NOW] - 1
        | READ_START := if PHASE = PHASE_READ_PARSE then
                          (if GUARD_EQUATION_FIRST[GUARD_NOW] < GUARD_LAST_EQUATION then EQUATION_FINAL_START[?][GUARD_EQUATION_FIRST[GUARD_NOW]] else 0)
                        else if PHASE = PHASE_READ_FINISH then
                          (if CHAIN_START[?] < FINISH_EQUATION_COUNT[?] then FINISH_EQUATION_FINAL_START[?][CHAIN_START[?]] else 0)
                        else if GUARD_FIRST_GROUP <= GUARD_LAST_GROUP then MEMBER_FINAL_START[?][GROUP_MEMBER_FIRST[GUARD_FIRST_GROUP]]
                        else 0
        | READ_END := if PHASE = PHASE_READ_PARSE then
                        (if GUARD_EQUATION_FIRST[GUARD_NOW] < GUARD_LAST_EQUATION then EQUATION_FINAL_END[?][GUARD_LAST_EQUATION - 1] else 0)
                      else if PHASE = PHASE_READ_FINISH then
                        (if CHAIN_START[?] < FINISH_EQUATION_COUNT[?] then FINAL_COUNT[?] else 0)
                      else if GUARD_FIRST_GROUP <= GUARD_LAST_GROUP then
                        MEMBER_FINAL_END[?][GROUP_MEMBER_FIRST[GUARD_LAST_GROUP] + GROUP_MEMBER_TOTAL[GUARD_LAST_GROUP] - 1]
                      else 0
        | READ_HEADER := AT_READ and STEP < 0
        | READ_ENTRY := RW_AT[?]
        | READ_ENTRY_DONE := READ_ENTRY >= RW_LAST[?]
        | READ_KEY := if AT_READ_DEPS then
                        (if STEP = 0 then (if DEPENDENCE_RENAMED_FROM[?][WORK_ROW] > 0 then DEPENDENCE_RENAMED_FROM[?][WORK_ROW] - 1 else DEPENDENCE_FROM_NAME[WORK_ROW])
                         else if DEPENDENCE_RENAMED_TO[?][WORK_ROW] > 0 then DEPENDENCE_RENAMED_TO[?][WORK_ROW] - 1 else DEPENDENCE_TO_NAME[WORK_ROW])
                      else FINAL_NAME[?][READ_ENTRY]
        | DEPS_DONE := WORK_ROW >= GUARD_DEPENDENCE_LAST[GUARD_NOW]
        | READS := AT_READ and STEP >= 0 and not READ_ENTRY_DONE and FINAL_OP[?][READ_ENTRY] = OP_SIGNAL
                   or AT_READ_DEPS and not DEPS_DONE
        | IS_INPUT := READS and READ_KEY >= 0 and READ_KEY < NAME_CAP and OWN_STAMP[?][READ_KEY] = MODEL_STAMP
                      and DEFINED_STAMP[?][READ_KEY] /= GUARD_STAMP[?]
        | NEW_INPUT := IS_INPUT and INPUT_STAMP[?][READ_KEY] /= GUARD_STAMP[?]
        | RENAMED_KEY := READ_KEY + GUARD_SUFFIX
        | ON_HEADER := AT_ON and STEP < 0
        | ON_COPYING := AT_ON and STEP = 0
        | ON_ROWS := AT_ON and STEP = 1
        | FILTER_DONE := WORK_ROW >= INPUT_COUNT[?]
        | FILTER_KEY := INPUT_LIST[?][WORK_ROW]
        | COPIES_FINAL := ON_COPYING or AT_CUR and STEP = 5
        | COPY_SOURCE := RW_AT[?]
        | EMITS := RW_EMITS and not (RW_INTRINSIC and STEP = 0 and RW_MESSAGE /= 0)
                   or AT_CLOCK and not CLOCK_DONE
                   or AT_STATE and STEP < 2
                   or AT_CUR and not CUR_DONE
                   or AT_CUR_TAIL and (STEP = 0 or STEP = 1 and HAS_TRANSITIONS)
                   or AT_GROUP and STEP < 2
                   or ON_COPYING
                   or AT_FILTER and not FILTER_DONE and STEP < 3
        | EMIT_OP := if COPIES_FINAL then FINAL_OP[?][COPY_SOURCE]
                     else if AT_REWRITE then
                       (if TR_INIT_ROW then OP_DELAY else if TR_EMITTING then TR_OP
                        else if RW_IS_EXTENSION then (if RW_EXTENSION = 0 then OP_SIGNAL else OP_WHEN)
                        else if RW_INTRINSIC then (if STEP = 0 then OP_CONST else OP_EQ)
                        else RW_OP)
                     else if AT_CLOCK then (if STEP = 0 then OP_SIGNAL else if STEP = 1 then OP_CLOCK else OP_DEFAULT)
                     else if AT_STATE then (if STEP = 0 then OP_SIGNAL else OP_DELAY)
                     else if AT_CUR then
                       (if STEP = 0 or STEP = 2 then OP_CONST else if STEP = 1 then OP_SIGNAL else if STEP = 3 then OP_EQ
                        else if STEP = 4 or STEP = 6 then OP_WHEN else OP_DEFAULT)
                     else if AT_CUR_TAIL then (if STEP = 0 then OP_SIGNAL else OP_DEFAULT)
                     else if AT_GROUP then OP_SIGNAL
                     else if STEP = 2 then OP_WHEN else OP_SIGNAL
        | EMIT_NAME := if COPIES_FINAL then FINAL_NAME[?][COPY_SOURCE]
                       else if AT_REWRITE then
                         (if TR_EMITTING and not TR_INIT_ROW then TR_NAME
                          else if RW_IS_EXTENSION then N_ON_MARK + TRANSITION_GUARD[?][WORK_ROW] * NAME_CAP
                          else if RW_NEXT_IS_ISIN then N_STATE_MARK else if RW_INIT_NAMED then -1 else RW_NAME)
                       else if AT_CLOCK then SIGNAL_NAME[WORK_ROW]
                       else if AT_STATE then N_CURRENT_MARK
                       else if AT_CUR or AT_CUR_TAIL then N_STATE_MARK
                       else if AT_GROUP then (if STEP = 0 then N_CURRENT_MARK else N_CLOCK_MARK)
                       else if STEP = 0 then FILTER_KEY else N_ON_MARK + GUARD_SUFFIX
        | EMIT_TOKEN := if COPIES_FINAL then FINAL_TOKEN[?][COPY_SOURCE]
                        else if AT_REWRITE then
                          (if TR_EMITTING then CONSTRUCT_TOKEN
                           else if RW_IS_EXTENSION then TRANSITION_TOKEN[?][WORK_ROW]
                           else if RW_NEXT_IS_ISIN then ENTRY_TOKEN[RW_ENTRY + 1] else ENTRY_TOKEN[RW_ENTRY])
                        else if AT_CUR then CUR_TOKEN
                        else if AT_FILTER then GUARD_AT
                        else MODEL_AT
        | EMIT_VALUE := if COPIES_FINAL then FINAL_VALUE[?][COPY_SOURCE]
                        else if AT_REWRITE then
                          (if TR_EMITTING and not TR_INIT_ROW then TR_VALUE
                           else if RW_INTRINSIC then long(STATE_ORDINAL[?][RW_PREVIOUS_NAME])
                           else if RW_INIT_NAMED then CONSTANT_VALUE[RW_INIT_CONSTANT]
                           else if RW_IS_SIZE then RW_SIZE_VALUE
                           else if RW_FILLS_DECL then SIGNAL_INIT_VALUE[RW_DECL_ROW] else ENTRY_VALUE[RW_ENTRY])
                        else if AT_STATE then long(INITIAL_ORDINAL[?])
                        else if AT_CUR then long(if STEP = 0 then TRANSITION_TARGET[?][WORK_ROW] else TRANSITION_SOURCE[?][WORK_ROW])
                        else long(0)
        | EMIT_TYPE := if COPIES_FINAL then FINAL_TYPE[?][COPY_SOURCE]
                       else if AT_REWRITE then
                         (if TR_EMITTING and not TR_INIT_ROW then (if TR_OP = OP_CONST or TR_OP = OP_DELAY then TR_TYPE else -1)
                          else if RW_INTRINSIC then STATE_TYPE_NOW else if RW_INIT_NAMED then CONSTANT_TYPE[RW_INIT_CONSTANT]
                          else if RW_IS_SIZE then (if RW_SIZE_VALUE < long(32768) then BUILTIN_SHORT else BUILTIN_INTEGER)
                          else if RW_FILLS_DECL then SIGNAL_INIT_TYPE[RW_DECL_ROW] else ENTRY_TYPE[RW_ENTRY])
                       else STATE_TYPE_NOW
        | EMIT_AUX := if COPIES_FINAL then FINAL_AUX[?][COPY_SOURCE]
                      else if AT_REWRITE then
                        (if TR_EMITTING and not TR_INIT_ROW then (if TR_OP = OP_DELAY then INIT_CONST else -1)
                         else if RW_INTRINSIC or RW_IS_EXTENSION or RW_IS_SIZE or INDEX_DECLARES then -1
                         else if RW_INIT_NAMED then INIT_CONST
                         else if RW_FILLS_DECL then RW_INIT_KIND else ENTRY_AUX[RW_ENTRY])
                      else if AT_STATE then INIT_CONST
                      else -1
        | EMIT_AUX2 := if COPIES_FINAL then FINAL_AUX2[?][COPY_SOURCE]
                       else if AT_REWRITE then
                         (if TR_EMITTING and not TR_INIT_ROW then CONSTRUCT_TOKEN
                          else if RW_INTRINSIC or RW_IS_EXTENSION then 0 else if RW_FILLS_DECL then RW_INIT_TOKEN else ENTRY_AUX2[RW_ENTRY])
                       else 0
        | WRITES_FINAL_NAME := EMITS or IS_INPUT and AT_READ
        | FINAL_SLOT := if EMITS then FINAL_COUNT[?] else -1
        | FINAL_NAME_SLOT := if EMITS then FINAL_COUNT[?] else if IS_INPUT and AT_READ then READ_ENTRY else -1
        | FINAL_OP := FINAL_OP[?] next FINAL_SLOT : EMIT_OP
        | FINAL_MODEL := FINAL_MODEL[?] next FINAL_SLOT : MODEL_HERE
        | FINAL_NAME := FINAL_NAME[?] next FINAL_NAME_SLOT : (if EMITS then EMIT_NAME else RENAMED_KEY)
        | FINAL_TOKEN := FINAL_TOKEN[?] next FINAL_SLOT : EMIT_TOKEN
        | FINAL_VALUE := FINAL_VALUE[?] next FINAL_SLOT : EMIT_VALUE
        | FINAL_TYPE := FINAL_TYPE[?] next FINAL_SLOT : EMIT_TYPE
        | FINAL_AUX := FINAL_AUX[?] next FINAL_SLOT : EMIT_AUX
        | FINAL_AUX2 := FINAL_AUX2[?] next FINAL_SLOT : EMIT_AUX2
        | FINAL_COUNT := FINAL_COUNT[?] + integer(EMITS)
        | CLOCK_ROWS := AT_CLOCK and CLOCK_DONE
        | STATE_ROWS := AT_STATE and STEP = 2
        | CUR_ROWS := AT_CUR_TAIL and STEP = 2
        | FILTER_ROWS := AT_FILTER and not FILTER_DONE and STEP = 3
        | WRITES_ROWS := CLOCK_ROWS or STATE_ROWS or CUR_ROWS or ON_ROWS or FILTER_ROWS or TEMPLATE_DEFINES
        | INDEX_DECLARES := PHASE = PHASE_REWRITE_EQ and RW_LIVE and not REST and RW_OP = OP_RANGE and ENTRY_AUX[RW_ENTRY] >= 0
        | ROW_KEY := if INDEX_DECLARES then RW_TARGET else if TEMPLATE_DEFINES then TR_NAME else if CLOCK_ROWS then N_CLOCK_MARK else if STATE_ROWS then N_STATE_MARK else if CUR_ROWS then N_CURRENT_MARK
                     else if ON_ROWS then N_ON_MARK + GUARD_SUFFIX else FILTER_KEY + GUARD_SUFFIX
        | ROW_TYPE := if INDEX_DECLARES then INDEX_ID_TYPE[ENTRY_AUX[RW_ENTRY]] else if TEMPLATE_DEFINES then TR_TYPE else if CLOCK_ROWS or ON_ROWS then BUILTIN_EVENT else if FILTER_ROWS then OWN_TYPE[?][FILTER_KEY] else STATE_TYPE_NOW
        | ROW_TOKEN := if INDEX_DECLARES then ENTRY_TOKEN[RW_ENTRY] else if TEMPLATE_DEFINES then CONSTRUCT_TOKEN else if ON_ROWS or FILTER_ROWS then GUARD_AT else MODEL_AT
        | FULL := EMITS and FINAL_COUNT[?] >= FINAL_CAP
                  or WRITES_ROWS and (FINISH_SIGNAL_COUNT[?] >= SIGNAL_CAP or FINISH_EQUATION_COUNT[?] >= EQUATION_CAP)
                  or INDEX_DECLARES and FINISH_SIGNAL_COUNT[?] >= SIGNAL_CAP
                  or (AT_GROUP and STEP = 2 or TEMPLATE_GROUPS) and FINISH_GROUP_COUNT[?] >= GROUP_CAP
                  or REST_DUE and TEMPLATE_ORDINAL[?] >= GUARD_CAP
                  or NEW_INPUT and INPUT_COUNT[?] >= SIGNAL_CAP
                  or REGISTERS_STATE and STATE_COUNT[?] >= SIGNAL_CAP
                  or RECORDS_TRANSITION and TRANSITION_COUNT[?] >= EQUATION_CAP
        | STEP_FINISH_MESSAGE := if PHASE = PHASE_DONE or PHASE = PHASE_FAILED then 0
                                 else if FULL then T_CAPACITY
                                 else if AT_USE and not USES_DONE and USE_UNDECLARED then T_LABEL_UNDECLARED
                                 else if AT_SIGNAL and SIGNALS_DONE and AUTOMATON_NOW and MODEL_INPUTS[MODEL_HERE] = 0 then T_NO_INPUT
                                 else if AT_HIDE then HIDE_FINISH_MESSAGE
                                 else if AT_STATEMENT and STATEMENTS_DONE and not HAS_INITIAL[?] then T_ONE_INITIAL
                                 else if AT_STATEMENT then AUTOMATON_STATEMENT_MESSAGE
                                 else if AT_REWRITE and STEP >= 0 then
                                   (if TEMPLATE_MESSAGE /= 0 then TEMPLATE_MESSAGE else if RW_MESSAGE /= 0 then RW_MESSAGE else RW_INIT_MESSAGE)
                                 else if AT_INITS and INIT_UNUSED_HERE then T_INIT_UNUSED
                                 else 0
        | FINISH_FAILS := STEP_FINISH_MESSAGE /= 0
        | FINISH_STEP_TOKEN := if FULL then MODEL_AT
                               else if AT_USE then USE_TOKEN[WORK_ROW]
                               else if AT_HIDE then HIDE_TOKEN[WORK_ROW]
                               else if AT_STATEMENT and not STATEMENTS_DONE then
                                 (if AUTOMATON_STATEMENT_MESSAGE = T_NOT_LABEL_OF then ST_STATE_TOKEN else ST_TOKEN)
                               else if AT_REWRITE then
                                 (if CONSTRUCT_MESSAGE = T_CONSTANT_BOUND then ENTRY_TOKEN[CONSTRUCT_SPLIT]
                                  else if CONSTRUCT_MESSAGE = T_SIGNAL_UNDECLARED then ENTRY_TOKEN[RW_ENTRY - 1]
                                  else if CONSTRUCT_MESSAGE /= 0 then ENTRY_TOKEN[RW_ENTRY]
                                  else if TEMPLATE_MESSAGE /= 0 then ENTRY_TOKEN[TEMPLATE_SAFE]
                                  else if RW_MESSAGE = T_NOT_STATE then ENTRY_TOKEN[RW_ENTRY - 1]
                                  else if RW_MESSAGE = 0 and RW_INIT_MESSAGE /= 0 and not RW_IS_SIZE then RW_INIT_TOKEN
                                  else ENTRY_TOKEN[RW_ENTRY])
                               else if AT_INITS then SIGNAL_TOKEN[WORK_ROW]
                               else MODEL_AT
        | FINISH_STEP_ARGUMENT0 := if FULL then F_CAP_FINISH
                                   else if AT_USE then USE_NAME[WORK_ROW]
                                   else if AT_HIDE then HIDE_KEY
                                   else if AT_INITS then SIGNAL_NAME[WORK_ROW]
                                   else if AT_REWRITE and TEMPLATE_MESSAGE /= 0 then
                                     (if TEMPLATE_MESSAGE = T_SIGNAL_UNDECLARED then OPERAND_NAME else ENTRY_TOKEN[RW_ENTRY])
                                   else if STEP_FINISH_MESSAGE = T_NO_INPUT or STEP_FINISH_MESSAGE = T_ONE_INITIAL then MODEL_KEY
                                   else if STEP_FINISH_MESSAGE = T_LABEL_PLACED then USE_NAME[EQUATION_LABELS[WORK_ROW]]
                                   else if STEP_FINISH_MESSAGE = T_NOT_LABEL_OF then ST_STATE
                                   else if AT_STATEMENT then ST_NAME
                                   else if STEP_FINISH_MESSAGE = T_NOT_STATE then RW_PREVIOUS_NAME
                                   else RW_NAME
        | FINISH_STEP_ARGUMENT1 := if STEP_FINISH_MESSAGE = T_WRONG_ARGUMENTS then (if AT_STATEMENT then ST_EXPECTED else 1)
                                   else if STEP_FINISH_MESSAGE = T_LABEL_PLACED then ST_NAME
                                   else if AT_HIDE then ROLE_FRAGMENT[HIDE_ROLE]
                                   else if AT_INITS then SIGNAL_NAME[WORK_ROW]
                                   else MODEL_KEY
        | FINISH_STEP_ARGUMENT2 := if AT_HIDE then MODEL_KEY else if AT_STATEMENT then ST_ARGUMENTS else RW_ARGUMENTS
        | FIRST_FINISH_FAILURE := FINISH_FAILS
        | FINISH_MESSAGE := if FIRST_FINISH_FAILURE then STEP_FINISH_MESSAGE else FINISH_MESSAGE[?]
        | FINISH_TOKEN := if FIRST_FINISH_FAILURE then FINISH_STEP_TOKEN else FINISH_TOKEN[?]
        | FINISH_ARGUMENT0 := if FIRST_FINISH_FAILURE then FINISH_STEP_ARGUMENT0 else FINISH_ARGUMENT0[?]
        | FINISH_ARGUMENT1 := if FIRST_FINISH_FAILURE then FINISH_STEP_ARGUMENT1 else FINISH_ARGUMENT1[?]
        | FINISH_ARGUMENT2 := if FIRST_FINISH_FAILURE then FINISH_STEP_ARGUMENT2 else FINISH_ARGUMENT2[?]
        | GOES := not FINISH_FAILS
        | NEXT_PHASE := if FINISH_FAILS then PHASE_FAILED
                        else if AT_START then (if ALL_CLOSED then PHASE_DONE else PHASE_LABEL)
                        else if AT_LABEL then (if LABELS_DONE then PHASE_USE else PHASE_LABEL)
                        else if AT_USE then (if USES_DONE then PHASE_SIGNAL else PHASE_USE)
                        else if AT_SIGNAL then (if not SIGNALS_DONE then PHASE_SIGNAL else PHASE_HIDE)
                        else if AT_HIDE then (if not HIDES_DONE then PHASE_HIDE else if AUTOMATON_NOW then PHASE_STATEMENT else PHASE_REWRITE_EQ)
                        else if AT_STATEMENT then (if STATEMENTS_DONE then PHASE_REWRITE_EQ else PHASE_STATEMENT)
                        else if RW_PHASE_DONE then
                          (if PHASE = PHASE_REWRITE_EQ then PHASE_REWRITE_MEMBER else if PHASE = PHASE_REWRITE_MEMBER then PHASE_REWRITE_GUARD
                           else if PHASE = PHASE_REWRITE_GUARD then PHASE_INITS
                           else PHASE_CLOCK)
                        else if AT_REWRITE then PHASE
                        else if AT_INITS then
                          (if not INITS_DONE then PHASE_INITS else if AUTOMATON_NOW then PHASE_REWRITE_TRIGGER else PHASE_GUARD_START)
                        else if AT_CLOCK then (if CLOCK_DONE then PHASE_STATE else PHASE_CLOCK)
                        else if AT_STATE then (if STEP = 2 then PHASE_CUR else PHASE_STATE)
                        else if AT_CUR then (if CUR_DONE then PHASE_CUR_TAIL else PHASE_CUR)
                        else if AT_CUR_TAIL then (if STEP = 2 then PHASE_GROUP else PHASE_CUR_TAIL)
                        else if AT_GROUP then (if STEP = 2 then PHASE_GUARD_START else PHASE_GROUP)
                        else if AT_GUARD_START then (if GUARD_NUMBER[?] = 0 then PHASE_START else PHASE_DEFINE_PARSE)
                        else if AT_DEFINE_PARSE then (if DEFINE_PARSE_DONE then PHASE_DEFINE_FINISH else PHASE_DEFINE_PARSE)
                        else if AT_DEFINE_FINISH then (if DEFINE_FINISH_DONE then PHASE_READ_PARSE else PHASE_DEFINE_FINISH)
                        else if AT_READ then
                          (if STEP >= 0 and READ_ENTRY_DONE then (if PHASE = PHASE_READ_MEMBERS then PHASE_READ_DEPS else PHASE + 1) else PHASE)
                        else if AT_READ_DEPS then (if DEPS_DONE then PHASE_ON else PHASE_READ_DEPS)
                        else if AT_ON then (if ON_ROWS then PHASE_FILTER else PHASE_ON)
                        else if AT_FILTER then (if FILTER_DONE then PHASE_GUARD_START else PHASE_FILTER)
                        else PHASE
        | FINISH_PHASE := NEXT_PHASE
        | PHASE_CHANGES := NEXT_PHASE /= PHASE
        | ENTRY_ROW := if NEXT_PHASE = PHASE_LABEL then MODEL_FIRST_LABEL[MODEL_HERE] - 1
                       else if NEXT_PHASE = PHASE_USE then MODEL_USE_START[MODEL_HERE]
                       else if NEXT_PHASE = PHASE_HIDE then MODEL_HIDE_START[MODEL_HERE]
                       else if NEXT_PHASE = PHASE_SIGNAL or NEXT_PHASE = PHASE_CLOCK or NEXT_PHASE = PHASE_INITS
                       then MODEL_FIRST_SIGNAL[MODEL_HERE] - 1
                       else if NEXT_PHASE = PHASE_STATEMENT or NEXT_PHASE = PHASE_REWRITE_EQ then MODEL_EQUATION_START[MODEL_HERE]
                       else if NEXT_PHASE = PHASE_REWRITE_MEMBER then MODEL_MEMBER_START[MODEL_HERE]
                       else if NEXT_PHASE = PHASE_REWRITE_GUARD then MODEL_GUARD_START[MODEL_HERE]
                       else if NEXT_PHASE = PHASE_REWRITE_TRIGGER or NEXT_PHASE = PHASE_CUR then TRANSITION_FIRST[?]
                       else if NEXT_PHASE = PHASE_DEFINE_PARSE then GUARD_EQUATION_FIRST[GUARD_NOW]
                       else if NEXT_PHASE = PHASE_DEFINE_FINISH then CHAIN_START[?]
                       else if NEXT_PHASE = PHASE_READ_DEPS then GUARD_DEPENDENCE_FIRST[GUARD_NOW]
                       else if NEXT_PHASE = PHASE_FILTER then GUARD_INPUT_START[?]
                       else 0
        | NEXT_ROW := if PHASE_CHANGES then ENTRY_ROW
                      else if AT_LABEL then LABEL_NEXT[WORK_ROW] - 1
                      else if AT_USE or AT_HIDE then WORK_ROW + 1
                      else if AT_SIGNAL or AT_INITS then SIGNAL_NEXT[WORK_ROW] - 1
                      else if AT_STATEMENT then (if ST_IS_STATEMENT and STEP = 0 and not ST_INITIAL then WORK_ROW else WORK_ROW + 1)
                      else if AT_REWRITE then
                        (if RW_HEADER then (if RW_ITEM_COUNT = 0 then WORK_ROW + 1 else WORK_ROW)
                         else if REST then (if REST_ENDS then WORK_ROW + 1 else WORK_ROW)
                         else if RW_ITEM_DONE and not ENTERS_REST then WORK_ROW + 1 else WORK_ROW)
                      else if AT_CLOCK then (if STEP = CLOCK_LAST_SUB then SIGNAL_NEXT[WORK_ROW] - 1 else WORK_ROW)
                      else if AT_CUR then (if STEP = CUR_LAST_SUB then WORK_ROW + 1 else WORK_ROW)
                      else if AT_DEFINE_PARSE or AT_DEFINE_FINISH then WORK_ROW + 1
                      else if AT_READ_DEPS then (if STEP = 1 then WORK_ROW + 1 else WORK_ROW)
                      else if AT_FILTER then (if STEP = 3 then WORK_ROW + 1 else WORK_ROW)
                      else WORK_ROW
        | FINISH_ROW := NEXT_ROW
        | NEXT_SUB := if PHASE_CHANGES then
                        (if NEXT_PHASE >= PHASE_REWRITE_EQ and NEXT_PHASE <= PHASE_REWRITE_TRIGGER
                            or NEXT_PHASE >= PHASE_READ_PARSE and NEXT_PHASE <= PHASE_READ_MEMBERS or NEXT_PHASE = PHASE_ON then -1 else 0)
                      else if AT_REWRITE then
                        (if RW_HEADER then (if RW_ITEM_COUNT = 0 then -1 else 0)
                         else if REST then (if REST_ENDS then -1 else if REST_COPY and not RW_ENTRY_DONE then STEP + 1 else 0)
                         else if ENTERS_REST then 0
                         else if RW_ITEM_DONE then -1 else if RW_ENTRY_DONE then 0 else STEP + 1)
                      else if AT_READ then 0
                      else if AT_STATEMENT then (if ST_IS_STATEMENT and STEP = 0 and not ST_INITIAL then 1 else 0)
                      else if AT_CLOCK then (if STEP = CLOCK_LAST_SUB then 0 else STEP + 1)
                      else if AT_CUR then
                        (if STEP = CUR_LAST_SUB then 0
                         else if STEP = 5 then (if RW_AT[?] + 1 >= RW_LAST[?] then 6 else 5) else STEP + 1)
                      else if AT_STATE or AT_CUR_TAIL or AT_GROUP then STEP + 1
                      else if AT_READ_DEPS then 1 - STEP
                      else if AT_ON then (if STEP < 0 then 0 else if RW_AT[?] + 1 >= RW_LAST[?] then 1 else 0)
                      else if AT_FILTER then (if STEP = 3 then 0 else STEP + 1)
                      else 0
        | FINISH_SUB := NEXT_SUB
        | RW_AT := if RW_HEADER then RW_ITEM_START
                   else if MOVES_TO_COPY then COPY_RANGE_START
                   else if REST and not REST_COPY then RW_AT[?]
                   else if AT_REWRITE then (if RW_ENTRY_DONE then RW_ENTRY + 1 else RW_ENTRY)
                   else if AT_CUR and STEP = 4 then TRANSITION_FINAL_START[?][WORK_ROW]
                   else if AT_CUR and STEP = 5 then RW_AT[?] + 1
                   else if READ_HEADER then READ_START
                   else if AT_READ then RW_AT[?] + 1
                   else if ON_HEADER then GUARD_FINAL_START[?][GUARD_NOW]
                   else if ON_COPYING then RW_AT[?] + 1
                   else RW_AT[?]
        | RW_LAST := if RW_HEADER then RW_ITEM_START + RW_ITEM_COUNT
                     else if MOVES_TO_COPY then COPY_RANGE_END
                     else if AT_CUR and STEP = 4 then TRANSITION_FINAL_END[?][WORK_ROW]
                     else if READ_HEADER then READ_END
                     else if ON_HEADER then GUARD_FINAL_END[?][GUARD_NOW]
                     else RW_LAST[?]
        | RW_ITEM_FIRST := if RW_HEADER then RW_ITEM_START else if MOVES_TO_COPY then COPY_RANGE_START else RW_ITEM_FIRST[?]
        | ITEM_BEGIN := if RW_HEADER or ON_HEADER or AT_GROUP and STEP = 0 or AT_FILTER and STEP = 0
                           or NEXT_PHASE /= PHASE and (NEXT_PHASE = PHASE_CLOCK or NEXT_PHASE = PHASE_STATE or NEXT_PHASE = PHASE_CUR)
                        then FINAL_COUNT[?] else ITEM_BEGIN[?]
        | ITEM_ENDS := AT_REWRITE and (RW_HEADER and RW_ITEM_COUNT = 0 or not RW_HEADER and not REST and RW_ITEM_DONE and GOES)
        | ITEM_END_VALUE := FINAL_COUNT[?] + integer(EMITS)
        | ITEM_SLOT_EQUATION := if ITEM_ENDS and PHASE = PHASE_REWRITE_EQ then WORK_ROW else -1
        | ITEM_SLOT_MEMBER := if ITEM_ENDS and PHASE = PHASE_REWRITE_MEMBER then WORK_ROW else -1
        | ITEM_SLOT_GUARD := if ITEM_ENDS and PHASE = PHASE_REWRITE_GUARD then WORK_ROW else -1
        | ITEM_SLOT_TRIGGER := if ITEM_ENDS and PHASE = PHASE_REWRITE_TRIGGER then WORK_ROW else -1
        | ITEM_START_VALUE := if RW_HEADER then FINAL_COUNT[?] else ITEM_BEGIN[?]
        | EQUATION_FINAL_START := EQUATION_FINAL_START[?] next ITEM_SLOT_EQUATION : ITEM_START_VALUE
        | EQUATION_FINAL_END := EQUATION_FINAL_END[?] next ITEM_SLOT_EQUATION : ITEM_END_VALUE
        | MEMBER_FINAL_START := MEMBER_FINAL_START[?] next ITEM_SLOT_MEMBER : ITEM_START_VALUE
        | MEMBER_FINAL_END := MEMBER_FINAL_END[?] next ITEM_SLOT_MEMBER : ITEM_END_VALUE
        | GUARD_FINAL_START := GUARD_FINAL_START[?] next ITEM_SLOT_GUARD : ITEM_START_VALUE
        | GUARD_FINAL_END := GUARD_FINAL_END[?] next ITEM_SLOT_GUARD : ITEM_END_VALUE
        | TRANSITION_FINAL_START := TRANSITION_FINAL_START[?] next ITEM_SLOT_TRIGGER : ITEM_START_VALUE
        | TRANSITION_FINAL_END := TRANSITION_FINAL_END[?] next ITEM_SLOT_TRIGGER : ITEM_END_VALUE
        | LABEL_STAMP := LABEL_STAMP[?] next (if AT_LABEL and not LABELS_DONE then LABEL_NAME[WORK_ROW] else -1) : MODEL_STAMP
        | OWN_SLOT := if AT_SIGNAL and not SIGNALS_DONE then SIGNAL_NAME[WORK_ROW] else if STATE_ROWS then N_STATE_MARK else -1
        | OWN_STAMP := OWN_STAMP[?] next OWN_SLOT : MODEL_STAMP
        | OWN_TYPE := OWN_TYPE[?] next OWN_SLOT : (if STATE_ROWS then STATE_TYPE_NOW else SIGNAL_TYPE[WORK_ROW])
        | OWN_ROLE := OWN_ROLE[?] next OWN_SLOT : (if STATE_ROWS then ROLE_LOCAL else SIGNAL_ROLE[WORK_ROW])
        | OWN_INIT := OWN_INIT[?] next OWN_SLOT
                      : (if STATE_ROWS or SIGNAL_INIT_KIND[WORK_ROW] = INIT_NONE then 0 else WORK_ROW + 1)
        | INIT_USED := INIT_USED[?] next (if AT_REWRITE and STEP = 0 and RW_DECL_SITE then RW_TARGET else -1) : MODEL_STAMP
        | STATE_SLOT := if REGISTERS_STATE and GOES then ST_STATE else -1
        | STATE_STAMP := STATE_STAMP[?] next STATE_SLOT : MODEL_STAMP
        | STATE_ORDINAL := STATE_ORDINAL[?] next STATE_SLOT : STATE_COUNT[?]
        | STATE_COUNT := if AT_SIGNAL then 0 else STATE_COUNT[?] + integer(STATE_SLOT >= 0)
        | HAS_INITIAL := if AT_SIGNAL then false else HAS_INITIAL[?] or RECORDS_INITIAL
        | INITIAL_ORDINAL := if RECORDS_INITIAL then ST_ORDINAL else INITIAL_ORDINAL[?]
        | TRANSITION_SOURCE_HELD := if AT_STATEMENT and STEP = 0 then ST_ORDINAL else TRANSITION_SOURCE_HELD[?]
        | TRANSITION_FIRST := if AT_SIGNAL then TRANSITION_COUNT[?] else TRANSITION_FIRST[?]
        | TRANSITION_SLOT := if RECORDS_TRANSITION and GOES then TRANSITION_COUNT[?] else -1
        | TRANSITION_SOURCE := TRANSITION_SOURCE[?] next TRANSITION_SLOT : TRANSITION_SOURCE_HELD[?]
        | TRANSITION_TARGET := TRANSITION_TARGET[?] next TRANSITION_SLOT : ST_ORDINAL
        | TRANSITION_TRIGGER_START := TRANSITION_TRIGGER_START[?] next TRANSITION_SLOT : ST_START + 2
        | TRANSITION_TRIGGER_END := TRANSITION_TRIGGER_END[?] next TRANSITION_SLOT : ST_CALL
        | TRANSITION_GUARD := TRANSITION_GUARD[?] next TRANSITION_SLOT
                              : (if EQUATION_GUARDS[WORK_ROW] >= 0 then EQUATION_GUARDS[WORK_ROW] - MODEL_GUARD_START[MODEL_HERE] + 1 else 0)
        | TRANSITION_TOKEN := TRANSITION_TOKEN[?] next TRANSITION_SLOT : ST_TOKEN
        | TRANSITION_COUNT := TRANSITION_COUNT[?] + integer(TRANSITION_SLOT >= 0)
        | SYNTH_COUNT := if NEXT_PHASE = PHASE_CLOCK and PHASE /= PHASE_CLOCK then 0
                         else if AT_CLOCK and STEP = CLOCK_LAST_SUB then SYNTH_COUNT[?] + 1 else SYNTH_COUNT[?]
        | GUARD_NUMBER := if NEXT_PHASE = PHASE_GUARD_START and PHASE /= PHASE_GUARD_START and PHASE /= PHASE_FILTER
                          then MODEL_GUARD_END[MODEL_HERE] - MODEL_GUARD_START[MODEL_HERE]
                          else if AT_FILTER and FILTER_DONE then GUARD_NUMBER[?] - 1 else GUARD_NUMBER[?]
        | STARTS_GUARD := AT_GUARD_START and GUARD_NUMBER[?] > 0
        | GUARD_STAMP := if STARTS_GUARD then GUARD_STAMP[?] + 1 else GUARD_STAMP[?]
        | CHAIN_START := if STARTS_GUARD then CHAIN_START_NOW else CHAIN_START[?]
        | GUARD_INPUT_START := if STARTS_GUARD then INPUT_COUNT[?] else GUARD_INPUT_START[?]
        | FILTER_ROW_START := FILTER_ROW_START[?] next (if STARTS_GUARD then GUARD_NOW else -1) : FINISH_EQUATION_COUNT[?]
        | DEFINED_STAMP := DEFINED_STAMP[?] next (if DEFINES then DEFINED_KEY else -1) : GUARD_STAMP[?]
        | INPUT_STAMP := INPUT_STAMP[?] next (if NEW_INPUT then READ_KEY else -1) : GUARD_STAMP[?]
        | INPUT_LIST := INPUT_LIST[?] next (if NEW_INPUT and GOES then INPUT_COUNT[?] else -1) : READ_KEY
        | INPUT_COUNT := INPUT_COUNT[?] + integer(NEW_INPUT and GOES)
        | DEPENDENCE_RENAMED_FROM := DEPENDENCE_RENAMED_FROM[?] next (if IS_INPUT and AT_READ_DEPS and STEP = 0 then WORK_ROW else -1)
                                     : RENAMED_KEY + 1
        | DEPENDENCE_RENAMED_TO := DEPENDENCE_RENAMED_TO[?] next (if IS_INPUT and AT_READ_DEPS and STEP = 1 then WORK_ROW else -1)
                                   : RENAMED_KEY + 1
        | FINISH_SIGNAL_SLOT := if (WRITES_ROWS or INDEX_DECLARES) and GOES then FINISH_SIGNAL_COUNT[?] else -1
        | FINISH_SIGNAL_NAME := FINISH_SIGNAL_NAME[?] next FINISH_SIGNAL_SLOT : ROW_KEY
        | FINISH_SIGNAL_TYPE := FINISH_SIGNAL_TYPE[?] next FINISH_SIGNAL_SLOT : ROW_TYPE
        | FINISH_SIGNAL_MODEL := FINISH_SIGNAL_MODEL[?] next FINISH_SIGNAL_SLOT : MODEL_HERE
        | FINISH_SIGNAL_TOKEN := FINISH_SIGNAL_TOKEN[?] next FINISH_SIGNAL_SLOT : ROW_TOKEN
        | FINISH_SIGNAL_COUNT := FINISH_SIGNAL_COUNT[?] + integer(FINISH_SIGNAL_SLOT >= 0)
        | FINISH_EQUATION_SLOT := if WRITES_ROWS and GOES then FINISH_EQUATION_COUNT[?] else -1
        | FINISH_EQUATION_TARGET := FINISH_EQUATION_TARGET[?] next FINISH_EQUATION_SLOT : ROW_KEY
        | FINISH_EQUATION_FINAL_START := FINISH_EQUATION_FINAL_START[?] next FINISH_EQUATION_SLOT
                                         : (if TEMPLATE_DEFINES then SEGMENT_BEGIN[?] else ITEM_BEGIN[?])
        | FINISH_EQUATION_FINAL_END := FINISH_EQUATION_FINAL_END[?] next FINISH_EQUATION_SLOT : FINAL_COUNT[?]
        | FINISH_EQUATION_TOKEN := FINISH_EQUATION_TOKEN[?] next FINISH_EQUATION_SLOT : ROW_TOKEN
        | FINISH_EQUATION_MODEL := FINISH_EQUATION_MODEL[?] next FINISH_EQUATION_SLOT : MODEL_HERE
        | FINISH_EQUATION_LABELS := FINISH_EQUATION_LABELS[?] next FINISH_EQUATION_SLOT
                                    : (if ON_ROWS or FILTER_ROWS then GUARD_LABELS[GUARD_NOW] else -1)
        | FINISH_EQUATION_GUARDS := FINISH_EQUATION_GUARDS[?] next FINISH_EQUATION_SLOT
                                    : (if ON_ROWS or FILTER_ROWS then GUARD_CONTEXT[GUARD_NOW] else -1)
        | FINISH_EQUATION_COUNT := FINISH_EQUATION_COUNT[?] + integer(FINISH_EQUATION_SLOT >= 0)
        | FINISH_GROUP_SLOT := if (AT_GROUP and STEP = 2 or TEMPLATE_GROUPS) and GOES then FINISH_GROUP_COUNT[?] else -1
        | FINISH_GROUP_MODEL := FINISH_GROUP_MODEL[?] next FINISH_GROUP_SLOT : MODEL_HERE
        | FINISH_GROUP_FINAL := FINISH_GROUP_FINAL[?] next FINISH_GROUP_SLOT : (if TEMPLATE_GROUPS then SEGMENT_BEGIN[?] else ITEM_BEGIN[?])
        | FINISH_GROUP_COUNT := FINISH_GROUP_COUNT[?] + integer(FINISH_GROUP_SLOT >= 0)
        | FINISH_MODEL_ORDINAL := if AT_GUARD_START and GUARD_NUMBER[?] = 0 then CLOSE_RANK + 1 else CLOSE_RANK
        |)
     with (| FINISH_PHASE := PHASE_START | FINISH_MODEL_ORDINAL := 0 | FINISH_ROW := 0 | FINISH_SUB := 0 | GUARD_NUMBER := 0
           | FINAL_COUNT := 0 | RW_AT := 0 | RW_LAST := 0 | RW_ITEM_FIRST := 0 | ITEM_BEGIN := 0 | STATE_COUNT := 0
           | HAS_INITIAL := false | INITIAL_ORDINAL := 0 | TRANSITION_SOURCE_HELD := 0 | TRANSITION_FIRST := 0
           | TRANSITION_COUNT := 0 | SYNTH_COUNT := 0 | GUARD_STAMP := 0 | CHAIN_START := 0 | GUARD_INPUT_START := 0
           | INPUT_COUNT := 0 | FINISH_SIGNAL_COUNT := 0 | FINISH_EQUATION_COUNT := 0 | FINISH_GROUP_COUNT := 0
           | TEMPLATE_PC := -1 | TEMPLATE_AT := -1 | SKIP_FROM := 0 | SEGMENT_BEGIN := 0 | TEMPLATE_ORDINAL := 1
           | ITEM_NONMONO := false
           | FINISH_MESSAGE := 0 | FINISH_TOKEN := 0 | FINISH_ARGUMENT0 := 0 | FINISH_ARGUMENT1 := 0 | FINISH_ARGUMENT2 := 0 |)
     end
   | SOURCE_TOO_BIG := BUFFER_OK and ERRNO = 0 and not SOURCE_FITS
   | ERROR := if SOURCE_TOO_BIG then ERROR_SRC else LEX_ERROR
   | ERROR_LEAD := SRC[LEX_ERROR_AT]
   | ERROR_MULTIBYTE := ERROR_LEAD >= ubyte(192)
   | ERROR_FIRST_CONTINUES := ERROR_MULTIBYTE and SRC[LEX_ERROR_AT + 1] >= ubyte(128) and SRC[LEX_ERROR_AT + 1] < ubyte(192)
   | ERROR_SECOND_CONTINUES := ERROR_FIRST_CONTINUES and SRC[LEX_ERROR_AT + 2] >= ubyte(128) and SRC[LEX_ERROR_AT + 2] < ubyte(192)
   | ERROR_THIRD_CONTINUES := ERROR_SECOND_CONTINUES and SRC[LEX_ERROR_AT + 3] >= ubyte(128) and SRC[LEX_ERROR_AT + 3] < ubyte(192)
   | ERROR_CHARACTER_LENGTH := 1 + integer(ERROR_FIRST_CONTINUES) + integer(ERROR_SECOND_CONTINUES) + integer(ERROR_THIRD_CONTINUES)
   | FINISHES := PARSES and CLOSED_COUNT > 0 and not PRAGMA_FAILED
   | FINISH_FAILED := FINISHES and FINISH_MESSAGE /= 0
   | FINISH_INCOMPLETE := FINISHES and not FINISH_FAILED and FINISH_PHASE /= PHASE_DONE
   | PARSE_FAILED := PARSES and PARSE_MESSAGE /= 0
   | PARSE_INCOMPLETE := PARSES and not PARSE_FAILED and PARSE_STATE /= P_DONE
   | PASS_MESSAGE := if ERROR = ERROR_UNEXPECTED then T_UNEXPECTED_CHARACTER else if ERROR = ERROR_ESCAPE then T_ESCAPE
                else if ERROR = ERROR_ESCAPE_RANGE then T_ESCAPE_RANGE else if ERROR /= ERROR_NONE then T_CAPACITY
                else if not TEXT_OK then 0 else if INTERN_ERROR_TOKEN >= 0 then T_CAPACITY
                else if PRESCAN_MESSAGE /= 0 then PRESCAN_MESSAGE else if PRAGMA_FAILED then PRAGMA_MESSAGE
                else if FINISH_FAILED then FINISH_MESSAGE
                else if FINISH_INCOMPLETE then T_CAPACITY else if PARSE_FAILED then PARSE_MESSAGE
                else if PARSE_INCOMPLETE then T_CAPACITY else 0
   | MESSAGE_TOKEN := if INTERN_ERROR_TOKEN >= 0 then INTERN_ERROR_TOKEN else if PRESCAN_MESSAGE /= 0 then PRESCAN_TOKEN
                      else if PRAGMA_FAILED then PRAGMA_MESSAGE_TOKEN
                      else if FINISH_FAILED then FINISH_TOKEN else if PARSE_FAILED then PARSE_TOKEN
                      else if INSTANTIATE_FAILED then INSTANTIATE_TOKEN else if LOWER_FAILED then LW_TOKEN
                      else if POST_FAILED then PO_TOKEN else if CLOCK_MESSAGE /= 0 then CLOCK_TOKEN else 0
   | MESSAGE_LINE := if SOURCE_TOO_BIG or MESSAGE_TOKEN < 0 then 1 else if ERROR /= ERROR_NONE then LEX_ERROR_LINE
                     else TOKEN_LINE[MESSAGE_TOKEN]
   | MESSAGE_COLUMN := if SOURCE_TOO_BIG or MESSAGE_TOKEN < 0 then 1 else if ERROR /= ERROR_NONE then LEX_ERROR_COLUMN
                       else TOKEN_COLUMN[MESSAGE_TOKEN]
   | PASS_ARGUMENT0 := if ERROR = ERROR_UNEXPECTED or ERROR = ERROR_ESCAPE then LEX_ERROR_AT
                          else if ERROR = ERROR_ESCAPE_RANGE then LEX_ERROR_VALUE else if ERROR = ERROR_SRC then F_CAP_SRC
                          else if ERROR = ERROR_TOKENS then F_CAP_TOKENS else if INTERN_ERROR_TOKEN >= 0 then F_CAP_NAMES
                          else if PRESCAN_MESSAGE /= 0 then PRESCAN_ARGUMENT0 else if PRAGMA_FAILED then PRAGMA_ARGUMENT0
                          else if FINISH_FAILED then FINISH_ARGUMENT0
                          else if FINISH_INCOMPLETE then F_CAP_FINISH else if PARSE_FAILED then PARSE_ARGUMENT0
                          else if PARSE_INCOMPLETE then F_CAP_PARSE else if INSTANTIATE_FAILED then INSTANTIATE_ARGUMENT0
                          else if INSTANTIATE_INCOMPLETE then F_CAP_INSTANTIATE else if LOWER_FAILED then LW_ARGUMENT0
                          else if POST_FAILED then PO_ARGUMENT0 else if EXPAND_FAILED then F_CAP_ROW_DEPENDENCES
                          else if CLOCK_MESSAGE /= 0 then CLOCK_ARGUMENT0 else F_CAP_LOWER
   | MESSAGE_ARGUMENT1 := if PRESCAN_MESSAGE /= 0 then PRESCAN_ARGUMENT1 else if FINISH_FAILED then FINISH_ARGUMENT1
                          else if PARSE_FAILED then PARSE_ARGUMENT1 else if LOWER_FAILED then LW_ARGUMENT1
                          else if CLOCK_MESSAGE /= 0 then
                            (if CLOCK_MESSAGE = T_INPUT_SHARED then SIGNAL_NAME[CF_SIGNAL_SOURCE] else 0)
                          else INSTANTIATE_ARGUMENT1
   | MESSAGE_ARGUMENT2 := if FINISH_FAILED then FINISH_ARGUMENT2 else if PARSE_FAILED then PARSE_ARGUMENT2
                          else if LOWER_FAILED then LW_ARGUMENT2 else if CLOCK_MESSAGE /= 0 then SCHEDULE_ARGUMENT2 else INSTANTIATE_ARGUMENT2
   | MESSAGE_INSTANCE := if LOWER_FAILED then LW_INSTANCE else if CLOCK_MESSAGE /= 0 then 0 else PO_INSTANCE
   | INSTANTIATES := (DUMP_PASS = 0 or DUMP_PASS = 3 or DUMP_PASS = 4 or DUMP_PASS = 5 or DUMP_PASS = 6 or DUMP_PASS = 7) and FINISHES and PASS_MESSAGE = 0
   | SPAN_BOUND := long(SIGNAL_COUNT) + long(FINISH_SIGNAL_COUNT) + long(FINISH_EQUATION_COUNT) + long(FINISH_GROUP_COUNT)
                   + long(LOOP_COUNT) + long(MODEL_COUNT) + long(LABEL_COUNT) + long(USE_COUNT) + long(GUARD_COUNT)
                   + long(FINAL_COUNT)
   | SPAN_INDEX := 0 .. (if INSTANTIATES then SPAN_BOUND else long(-1))
   | iterate SPAN_INDEX of
       (| SPAN_SIGNAL_MODEL := SIGNAL_MODEL[SPAN_INDEX]
        | SPAN_ROLE := if SPAN_INDEX < SIGNAL_COUNT then SIGNAL_ROLE[SPAN_INDEX] else ROLE_LOCAL
        | MODEL_INPUT_TOTAL := MODEL_INPUT_TOTAL[?] next (if SPAN_ROLE = ROLE_INPUT then SPAN_SIGNAL_MODEL else -1)
                               : MODEL_INPUT_TOTAL[?][SPAN_SIGNAL_MODEL] + 1
        | MODEL_OUTPUT_TOTAL := MODEL_OUTPUT_TOTAL[?] next (if SPAN_ROLE = ROLE_OUTPUT then SPAN_SIGNAL_MODEL else -1)
                                : MODEL_OUTPUT_TOTAL[?][SPAN_SIGNAL_MODEL] + 1
        | SPAN_FINISH_SIGNAL_MODEL := FINISH_SIGNAL_MODEL[SPAN_INDEX]
        | SPAN_FINISH_SIGNAL_SLOT := if SPAN_INDEX < FINISH_SIGNAL_COUNT then SPAN_FINISH_SIGNAL_MODEL else -1
        | MODEL_FINISH_SIGNAL_START := MODEL_FINISH_SIGNAL_START[?]
                                       next (if SPAN_INDEX = 0 or FINISH_SIGNAL_MODEL[SPAN_INDEX - 1] /= SPAN_FINISH_SIGNAL_MODEL
                                             then SPAN_FINISH_SIGNAL_SLOT else -1)
                                       : SPAN_INDEX
        | MODEL_FINISH_SIGNAL_END := MODEL_FINISH_SIGNAL_END[?] next SPAN_FINISH_SIGNAL_SLOT : SPAN_INDEX + 1
        | SPAN_FINISH_EQUATION_MODEL := FINISH_EQUATION_MODEL[SPAN_INDEX]
        | SPAN_FINISH_EQUATION_SLOT := if SPAN_INDEX < FINISH_EQUATION_COUNT then SPAN_FINISH_EQUATION_MODEL else -1
        | MODEL_FINISH_EQUATION_START := MODEL_FINISH_EQUATION_START[?]
                                         next (if SPAN_INDEX = 0 or FINISH_EQUATION_MODEL[SPAN_INDEX - 1] /= SPAN_FINISH_EQUATION_MODEL
                                               then SPAN_FINISH_EQUATION_SLOT else -1)
                                         : SPAN_INDEX
        | MODEL_FINISH_EQUATION_END := MODEL_FINISH_EQUATION_END[?] next SPAN_FINISH_EQUATION_SLOT : SPAN_INDEX + 1
        | SPAN_FINISH_GROUP_MODEL := FINISH_GROUP_MODEL[SPAN_INDEX]
        | SPAN_FINISH_GROUP_SLOT := if SPAN_INDEX < FINISH_GROUP_COUNT then SPAN_FINISH_GROUP_MODEL else -1
        | MODEL_FINISH_GROUP_START := MODEL_FINISH_GROUP_START[?]
                                      next (if SPAN_INDEX = 0 or FINISH_GROUP_MODEL[SPAN_INDEX - 1] /= SPAN_FINISH_GROUP_MODEL
                                            then SPAN_FINISH_GROUP_SLOT else -1)
                                      : SPAN_INDEX
        | MODEL_FINISH_GROUP_END := MODEL_FINISH_GROUP_END[?] next SPAN_FINISH_GROUP_SLOT : SPAN_INDEX + 1
        | SPAN_LOOP_MODEL := LOOP_MODEL[SPAN_INDEX]
        | SPAN_LOOP_SLOT := if SPAN_INDEX < LOOP_COUNT then SPAN_LOOP_MODEL else -1
        | MODEL_LOOP_START := MODEL_LOOP_START[?]
                              next (if SPAN_INDEX = 0 or LOOP_MODEL[SPAN_INDEX - 1] /= SPAN_LOOP_MODEL then SPAN_LOOP_SLOT else -1)
                              : SPAN_INDEX
        | MODEL_LOOP_END := MODEL_LOOP_END[?] next SPAN_LOOP_SLOT : SPAN_INDEX + 1
        | SPAN_MODEL_NAME := MODEL_NAME[SPAN_INDEX]
        | MODEL_OF_NAME := MODEL_OF_NAME[?]
                           next (if SPAN_INDEX < MODEL_COUNT and MODEL_OF_NAME[?][SPAN_MODEL_NAME] = 0 then SPAN_MODEL_NAME else -1)
                           : SPAN_INDEX + 1
        | SPAN_SIGNAL_SLOT := if SPAN_INDEX < SIGNAL_COUNT then SPAN_SIGNAL_MODEL else -1
        | MODEL_SIGNAL_TOTAL := MODEL_SIGNAL_TOTAL[?] next SPAN_SIGNAL_SLOT : MODEL_SIGNAL_TOTAL[?][SPAN_SIGNAL_MODEL] + 1
        | SPAN_LABEL_MODEL := LABEL_MODEL[SPAN_INDEX]
        | SPAN_LABEL_SLOT := if SPAN_INDEX < LABEL_COUNT then SPAN_LABEL_MODEL else -1
        | MODEL_LABEL_TOTAL := MODEL_LABEL_TOTAL[?] next SPAN_LABEL_SLOT : MODEL_LABEL_TOTAL[?][SPAN_LABEL_MODEL] + 1
        | SPAN_ENTRY_MODEL := FINAL_MODEL[SPAN_INDEX]
        | SPAN_ENTRY_SLOT := if SPAN_INDEX < FINAL_COUNT then SPAN_ENTRY_MODEL else -1
        | MODEL_ENTRY_TOTAL := MODEL_ENTRY_TOTAL[?] next SPAN_ENTRY_SLOT : MODEL_ENTRY_TOTAL[?][SPAN_ENTRY_MODEL] + 1
        | SPAN_CALLS := SPAN_ENTRY_SLOT >= 0 and FINAL_OP[SPAN_INDEX] = OP_CALL and NAME_MODEL[FINAL_NAME[SPAN_INDEX]]
        | MODEL_CALL_TOTAL := MODEL_CALL_TOTAL[?] next (if SPAN_CALLS then SPAN_ENTRY_MODEL else -1)
                              : MODEL_CALL_TOTAL[?][SPAN_ENTRY_MODEL] + 1
        | SITE_SLOT := if SPAN_CALLS then SITE_COUNT[?] else -1
        | SITE_CALLER := SITE_CALLER[?] next SITE_SLOT : SPAN_ENTRY_MODEL
        | SITE_NAME := SITE_NAME[?] next SITE_SLOT : FINAL_NAME[SPAN_INDEX]
        | SITE_COUNT := SITE_COUNT[?] + integer(SITE_SLOT >= 0)
        | USE_PATH_LIMIT := if SPAN_INDEX < USE_COUNT and USE_PATH_LENGTH[SPAN_INDEX] > USE_PATH_LIMIT[?]
                            then USE_PATH_LENGTH[SPAN_INDEX] else USE_PATH_LIMIT[?]
        | GUARD_PATH_LIMIT := if SPAN_INDEX < GUARD_COUNT and GUARD_PATH_LENGTH[SPAN_INDEX] > GUARD_PATH_LIMIT[?]
                              then GUARD_PATH_LENGTH[SPAN_INDEX] else GUARD_PATH_LIMIT[?]
        |)
     with (| SITE_COUNT := 0 | USE_PATH_LIMIT := 0 | GUARD_PATH_LIMIT := 0 |)
     end
   | PATH_LIMIT := USE_PATH_LIMIT + GUARD_PATH_LIMIT + 1
   | RELAX_ROUND_LENGTH := SITE_COUNT + MODEL_COUNT
   | RELAX_BOUND := long(MODEL_COUNT) * long(RELAX_ROUND_LENGTH) - long(1)
   | RELAX_INDEX := 0 .. (if INSTANTIATES then RELAX_BOUND else long(-1))
   | iterate RELAX_INDEX of
       (| RELAX_POSITION := RELAX_AT[?]
        | RELAX_DEPTH := RELAX_ROUND[?]
        | RELAX_SITE_PHASE := RELAX_POSITION < SITE_COUNT
        | RELAX_CALLER := SITE_CALLER[RELAX_POSITION]
        | RELAX_CALLEE := MODEL_OF_NAME[SITE_NAME[RELAX_POSITION]] - 1
        | CALLER_LEVEL := if RELAX_DEPTH = 0 then integer(RELAX_CALLER = 0) else LEVEL_NOW[?][RELAX_CALLER]
        | LEVEL_SUM := LEVEL_NEXT[?][RELAX_CALLEE] + CALLER_LEVEL
        | RELAX_M := RELAX_POSITION - SITE_COUNT
        | LEVEL_SLOT := if RELAX_SITE_PHASE then RELAX_CALLEE else RELAX_M
        | LEVEL_NEXT := LEVEL_NEXT[?] next LEVEL_SLOT
                        : (if not RELAX_SITE_PHASE then 0 else if LEVEL_SUM > INSTANCE_CAP then INSTANCE_CAP else LEVEL_SUM)
        | MODEL_LEVEL := if RELAX_DEPTH = 0 then integer(RELAX_M = 0) else LEVEL_NOW[?][RELAX_M]
        | LEVEL_NOW := LEVEL_NOW[?] next (if RELAX_SITE_PHASE then -1 else RELAX_M) : LEVEL_NEXT[?][RELAX_M]
        | MODEL_ROW_COUNT := MODEL_LABEL_TOTAL[RELAX_M] + MODEL_SIGNAL_TOTAL[RELAX_M]
                             + MODEL_FINISH_SIGNAL_END[RELAX_M] - MODEL_FINISH_SIGNAL_START[RELAX_M]
                             + MODEL_LOOP_END[RELAX_M] - MODEL_LOOP_START[RELAX_M]
                             + MODEL_EQUATION_END[RELAX_M] - MODEL_EQUATION_START[RELAX_M]
                             + MODEL_FINISH_EQUATION_END[RELAX_M] - MODEL_FINISH_EQUATION_START[RELAX_M]
                             + MODEL_GROUP_END[RELAX_M] - MODEL_GROUP_START[RELAX_M]
                             + MODEL_MEMBER_END[RELAX_M] - MODEL_MEMBER_START[RELAX_M]
                             + 3 * (MODEL_FINISH_GROUP_END[RELAX_M] - MODEL_FINISH_GROUP_START[RELAX_M])
                             + MODEL_DEPENDENCE_END[RELAX_M] - MODEL_DEPENDENCE_START[RELAX_M]
        | RELAX_CALL_COST := long(RELAX_DEPTH + 2) * long(PATH_LIMIT + 2) + long(8)
        | MODEL_STEP_COST := long(16) + long(3) * long(MODEL_ROW_COUNT) + long(4) * long(MODEL_ENTRY_TOTAL[RELAX_M])
                             + long(MODEL_CALL_TOTAL[RELAX_M]) * RELAX_CALL_COST
        | WORK_BOUND := WORK_BOUND[?] + (if RELAX_SITE_PHASE then long(0) else long(MODEL_LEVEL) * MODEL_STEP_COST)
        | RELAX_ENDS_ROUND := RELAX_POSITION + 1 = RELAX_ROUND_LENGTH
        | RELAX_AT := if RELAX_ENDS_ROUND then 0 else RELAX_POSITION + 1
        | RELAX_ROUND := RELAX_DEPTH + integer(RELAX_ENDS_ROUND)
        |)
     with (| RELAX_AT := 0 | RELAX_ROUND := 0 | WORK_BOUND := long(0) |)
     end
   | INSTANTIATE_BOUND := long(64) + WORK_BOUND
   | INSTANTIATE_INDEX := 0 .. (if INSTANTIATES then INSTANTIATE_BOUND else long(-1))
   | iterate INSTANTIATE_INDEX of
       (| IP_NOW := IP_STATE[?]
        | INST := INSTANCE_AT[?]
        | INST_MODEL := INSTANCE_MODEL[?][INST]
        | INST_MARK := INST + 1
        | ROW_NOW := ROW_CURSOR[?]
        | MEMBER_ORDINAL := MEMBER_CURSOR[?]
        | AT_IP_ROOT := IP_NOW = IP_ROOT
        | AT_IP_INSTANCE := IP_NOW = IP_INSTANCE
        | AT_IP_LABEL := IP_NOW = IP_LABEL
        | AT_IP_SIGNAL := IP_NOW = IP_SIGNAL
        | AT_IP_FINISH_SIGNAL := IP_NOW = IP_FINISH_SIGNAL
        | AT_IP_LOOP := IP_NOW = IP_LOOP
        | AT_IP_EQUATION := IP_NOW = IP_EQUATION
        | AT_IP_FINISH_EQUATION := IP_NOW = IP_FINISH_EQUATION
        | AT_IP_GROUP := IP_NOW = IP_GROUP
        | AT_IP_FINISH_GROUP := IP_NOW = IP_FINISH_GROUP
        | AT_IP_DEPENDENCE := IP_NOW = IP_DEPENDENCE
        | AT_IP_ENTRY := IP_NOW = IP_ENTRY
        | AT_IP_ANCESTRY := IP_NOW = IP_ANCESTRY
        | AT_IP_PATH := IP_NOW = IP_PATH
        | AT_IP_INPUT := IP_NOW = IP_INPUT
        | AT_IP_EMIT := IP_NOW = IP_EMIT
        | INSTANCES_DONE := INST >= INSTANCE_TOTAL[?]
        | LABEL_LIVE := AT_IP_LABEL and ROW_NOW >= 0
        | PARSE_SIGNAL_LIVE := AT_IP_SIGNAL and ROW_NOW >= 0
        | FINISH_SIGNAL_LIVE := AT_IP_FINISH_SIGNAL and ROW_NOW < MODEL_FINISH_SIGNAL_END[INST_MODEL]
        | SIGNAL_WANTED := PARSE_SIGNAL_LIVE or FINISH_SIGNAL_LIVE
        | SIGNAL_KEY_NOW := if PARSE_SIGNAL_LIVE then SIGNAL_NAME[ROW_NOW] else FINISH_SIGNAL_NAME[ROW_NOW]
        | LOOP_LIVE := AT_IP_LOOP and ROW_NOW < MODEL_LOOP_END[INST_MODEL]
        | EQUATION_LIVE := AT_IP_EQUATION and ROW_NOW < MODEL_EQUATION_END[INST_MODEL]
        | EQUATION_SKIPS := EQUATION_LIVE and EQUATION_STATEMENT[ROW_NOW]
        | SELECTS_PARSE_EQUATION := EQUATION_LIVE and not EQUATION_STATEMENT[ROW_NOW]
        | SELECTS_FINISH_EQUATION := AT_IP_FINISH_EQUATION and ROW_NOW < MODEL_FINISH_EQUATION_END[INST_MODEL]
        | SELECTS_EQUATION := SELECTS_PARSE_EQUATION or SELECTS_FINISH_EQUATION
        | PARSE_GROUP_LIVE := AT_IP_GROUP and ROW_NOW < MODEL_GROUP_END[INST_MODEL]
        | FINISH_GROUP_LIVE := AT_IP_FINISH_GROUP and ROW_NOW < MODEL_FINISH_GROUP_END[INST_MODEL]
        | GROUP_MEMBER_COUNT := if AT_IP_GROUP then GROUP_MEMBER_TOTAL[ROW_NOW] else 2
        | SELECTS_MEMBER := (PARSE_GROUP_LIVE or FINISH_GROUP_LIVE) and MEMBER_ORDINAL < GROUP_MEMBER_COUNT
        | GROUP_ADVANCES := (PARSE_GROUP_LIVE or FINISH_GROUP_LIVE) and not SELECTS_MEMBER
        | SELECTS := SELECTS_EQUATION or SELECTS_MEMBER
        | SELECT_TARGET := if SELECTS_PARSE_EQUATION then EQUATION_TARGET[ROW_NOW] else FINISH_EQUATION_TARGET[ROW_NOW]
        | SELECT_SEED := SELECTS_PARSE_EQUATION and EQUATION_SEED[ROW_NOW]
        | SELECT_TOKEN := if SELECTS_PARSE_EQUATION then EQUATION_POSITION[ROW_NOW] else FINISH_EQUATION_TOKEN[ROW_NOW]
        | SELECT_MEMBER_ROW := GROUP_MEMBER_FIRST[ROW_NOW] + MEMBER_ORDINAL
        | DEPENDENCE_LIVE := AT_IP_DEPENDENCE and ROW_NOW < MODEL_DEPENDENCE_END[INST_MODEL]
        | FROM_KEY := if DEPENDENCE_RENAMED_FROM[ROW_NOW] > 0 then DEPENDENCE_RENAMED_FROM[ROW_NOW] - 1 else DEPENDENCE_FROM_NAME[ROW_NOW]
        | TO_KEY := if DEPENDENCE_RENAMED_TO[ROW_NOW] > 0 then DEPENDENCE_RENAMED_TO[ROW_NOW] - 1 else DEPENDENCE_TO_NAME[ROW_NOW]
        | E := ENTRY_CURSOR[?]
        | POSTFIX_END_NOW := POSTFIX_END[?]
        | ENTRY_LIVE := AT_IP_ENTRY and E < POSTFIX_END_NOW
        | E_OP := FINAL_OP[E]
        | E_NAME := FINAL_NAME[E]
        | E_TOKEN := FINAL_TOKEN[E]
        | E_COUNT := integer(FINAL_VALUE[E])
        | E_PARAMS := FINAL_AUX2[E]
        | E_IS_LEAF := E_OP = OP_SIGNAL or E_OP = OP_CONST or E_OP = OP_ENUMCONST
        | E_IS_CALL := E_OP = OP_CALL
        | E_ARITY := if E_IS_CALL then E_COUNT else OP_ARITY[E_OP]
        | CHECK_KEY := if AT_IP_LOOP then LOOP_NAME[ROW_NOW] else if AT_IP_DEPENDENCE then FROM_KEY
                       else if SELECTS_EQUATION then SELECT_TARGET else E_NAME
        | CHECK_OWNED := CHECK_KEY >= NAME_CAP or OWNED_MARK[?][CHECK_KEY] = INST_MARK
        | CHECK_LABELED := LABELED_MARK[?][CHECK_KEY] = INST_MARK
        | TO_OWNED := TO_KEY >= NAME_CAP or OWNED_MARK[?][TO_KEY] = INST_MARK
        | TO_LABELED := LABELED_MARK[?][TO_KEY] = INST_MARK
        | LOOP_FAILS := LOOP_LIVE and not CHECK_OWNED
        | TARGET_FAILS := SELECTS_EQUATION and SELECT_TARGET >= 0 and not SELECT_SEED and not CHECK_OWNED
        | SIGNAL_CHECKED := ENTRY_LIVE and E_OP = OP_SIGNAL
        | SIGNAL_LABEL_FAILS := SIGNAL_CHECKED and not CHECK_OWNED and CHECK_LABELED
        | SIGNAL_UNDECLARED_FAILS := SIGNAL_CHECKED and not CHECK_OWNED and not CHECK_LABELED and NAME_CONSTANT[E_NAME] <= 0
        | CALL_LIVE := ENTRY_LIVE and E_IS_CALL
        | AS_PROCESS := POSTFIX_TARGET[?] < 0 and not POSTFIX_IS_MEMBER[?] and E = POSTFIX_END_NOW - 1
        | CALLS_TYPE := E_NAME < BUILTIN_TYPE_COUNT or NAME_TYPE[E_NAME] > 0 or NAME_ALIAS[E_NAME] > 0 or E_NAME = N_INDICES
        | CALLS_BUILTIN := not CALLS_TYPE and E_NAME >= N_LOAD and E_NAME <= N_INSTRUCTION
        | TYPE_CALL_LIVE := CALL_LIVE and CALLS_TYPE
        | TYPE_PROCESS_FAILS := TYPE_CALL_LIVE and AS_PROCESS
        | TYPE_SHAPE_FAILS := TYPE_CALL_LIVE and (E_COUNT /= 1 or E_PARAMS /= 0)
        | BUILTIN_LIVE := CALL_LIVE and CALLS_BUILTIN
        | BUILTIN_INPUTS := if E_NAME = N_STORE then 2 else if E_NAME = N_SYSCALL then 7 else 1
        | BUILTIN_HAS_OUTPUT := E_NAME /= N_STORE
        | BUILTIN_ITERATE_FAILS := BUILTIN_LIVE and POSTFIX_LOOP[?] >= 0
                                   and (POSTFIX_SEED[?] or E_NAME /= N_LOAD and E_NAME /= N_STORE)
        | BUILTIN_COUNT_FAILS := BUILTIN_LIVE and E_COUNT /= BUILTIN_INPUTS
        | BUILTIN_PROCESS_FAILS := BUILTIN_LIVE and AS_PROCESS and BUILTIN_HAS_OUTPUT
        | BUILTIN_EXPRESSION_FAILS := BUILTIN_LIVE and not AS_PROCESS and not BUILTIN_HAS_OUTPUT
        | PURE_INSTANCE := INSTANCE_PURE[?][INST]
        | PURE_MODEL := INSTANCE_MODEL[?][PURE_INSTANCE]
        | BUILTIN_UNSAFE_FAILS := BUILTIN_LIVE and PURE_INSTANCE >= 0
        | MODEL_CALL_LIVE := CALL_LIVE and not CALLS_TYPE and not CALLS_BUILTIN
        | CALLEE := MODEL_OF_NAME[E_NAME] - 1
        | CALLEE_UNDECLARED_FAILS := MODEL_CALL_LIVE and CALLEE < 0
        | CALLEE_PARAMS_FAILS := MODEL_CALL_LIVE and E_PARAMS /= 0
        | CALLEE_ITERATE_FAILS := MODEL_CALL_LIVE and POSTFIX_LOOP[?] >= 0
        | STARTS_ANCESTRY := MODEL_CALL_LIVE and not CALLEE_UNDECLARED_FAILS and not CALLEE_PARAMS_FAILS
                             and not CALLEE_ITERATE_FAILS
        | WALKER := ANCESTOR_CURSOR[?]
        | ANCESTRY_PASSES := AT_IP_ANCESTRY and WALKER < 0
        | SELF_CALL_FAILS := AT_IP_ANCESTRY and WALKER >= 0 and INSTANCE_MODEL[?][WALKER] = CALLEE
        | CALLEE_INPUTS := MODEL_INPUT_TOTAL[CALLEE]
        | CALLEE_OUTPUTS := MODEL_OUTPUT_TOTAL[CALLEE]
        | CALLEE_FIRST_SIGNAL := MODEL_SIGNAL_START[CALLEE]
        | CALLEE_OUTPUT_KEY := SIGNAL_NAME[CALLEE_FIRST_SIGNAL + CALLEE_INPUTS]
        | CALLEE_KIND := MODEL_KIND[CALLEE]
        | CALLEE_COUNT_FAILS := ANCESTRY_PASSES and E_COUNT /= CALLEE_INPUTS
        | CALLEE_OUTPUTS_FAILS := ANCESTRY_PASSES and CALLEE_OUTPUTS >= 2
        | CALLEE_PROCESS_FAILS := ANCESTRY_PASSES and AS_PROCESS and CALLEE_OUTPUTS > 0
        | CALLEE_EXPRESSION_FAILS := ANCESTRY_PASSES and not AS_PROCESS and CALLEE_OUTPUTS = 0
        | FUNCTION_CALL_FAILS := ANCESTRY_PASSES and MODEL_KIND[INST_MODEL] = C_FUNCTION and CALLEE_KIND /= C_FUNCTION
        | FROM_FAILS := DEPENDENCE_LIVE and not CHECK_OWNED and not CHECK_LABELED
        | TO_FAILS := DEPENDENCE_LIVE and not TO_OWNED and not TO_LABELED
        | CALL_LABEL_ADDED := not POSTFIX_IS_MEMBER[?] and POSTFIX_TARGET[?] >= 0 and not POSTFIX_SEED[?]
        | CALLER_LABEL_START := INSTANCE_LABEL_START[?][INST]
        | CALLER_LABEL_LENGTH := INSTANCE_LABEL_LENGTH[?][INST]
        | CALLER_GUARD_START := INSTANCE_GUARD_START[?][INST]
        | CALLER_GUARD_LENGTH := INSTANCE_GUARD_LENGTH[?][INST]
        | POSTFIX_LABEL_NODE := POSTFIX_LABELS[?]
        | POSTFIX_GUARD_NODE := POSTFIX_GUARDS[?]
        | POSTFIX_LABEL_LENGTH := if POSTFIX_LABEL_NODE < 0 then 0 else USE_PATH_LENGTH[POSTFIX_LABEL_NODE]
        | POSTFIX_GUARD_LENGTH := if POSTFIX_GUARD_NODE < 0 then 0 else GUARD_PATH_LENGTH[POSTFIX_GUARD_NODE]
        | NEW_LABEL_LENGTH := CALLER_LABEL_LENGTH + POSTFIX_LABEL_LENGTH + integer(CALL_LABEL_ADDED)
        | NEW_GUARD_LENGTH := CALLER_GUARD_LENGTH + POSTFIX_GUARD_LENGTH
        | PATH_K := PATH_STEP[?]
        | PATH_NEW := CALL_INSTANCE[?]
        | PATH_LABEL_TOTAL := INSTANCE_LABEL_LENGTH[?][PATH_NEW]
        | PATH_LIVE := AT_IP_PATH and PATH_K < PATH_LABEL_TOTAL + INSTANCE_GUARD_LENGTH[?][PATH_NEW]
        | IN_LABEL_PART := PATH_K < PATH_LABEL_TOTAL
        | PART_K := if IN_LABEL_PART then PATH_K else PATH_K - PATH_LABEL_TOTAL
        | PART_INHERITED := if IN_LABEL_PART then CALLER_LABEL_LENGTH else CALLER_GUARD_LENGTH
        | PART_INHERITED_AT := (if IN_LABEL_PART then CALLER_LABEL_START else CALLER_GUARD_START) + PART_K
        | PART_NODE_LENGTH := if IN_LABEL_PART then POSTFIX_LABEL_LENGTH else POSTFIX_GUARD_LENGTH
        | FROM_INHERITED := PART_K < PART_INHERITED
        | FROM_NODE := not FROM_INHERITED and PART_K < PART_INHERITED + PART_NODE_LENGTH
        | NODE_VALUE := PATH_VALUE[(if IN_LABEL_PART then USE_PATH_START[POSTFIX_LABEL_NODE] else GUARD_PATH_START[POSTFIX_GUARD_NODE])
                                   + PART_K - PART_INHERITED]
        | NODE_GUARD_KEY := N_ON_MARK + (NODE_VALUE - MODEL_GUARD_START[GUARD_MODEL[NODE_VALUE]] + 1) * NAME_CAP
        | PATH_KEY_NOW := if FROM_INHERITED then FLAT_PATH_KEY[?][PART_INHERITED_AT]
                          else if FROM_NODE then (if IN_LABEL_PART then NODE_VALUE else NODE_GUARD_KEY) else POSTFIX_TARGET[?]
        | PATH_INSTANCE_NOW := if FROM_INHERITED then FLAT_PATH_INSTANCE[?][PART_INHERITED_AT] else INST
        | PATH_CALL_NOW := if FROM_INHERITED then FLAT_PATH_CALL[?][PART_INHERITED_AT] else not FROM_NODE
        | INPUT_I := INPUT_CURSOR[?]
        | OPERAND_BASE := START_TOP[?] - E_ARITY
        | SEGMENT_FROM := START_STACK[?][OPERAND_BASE + INPUT_I]
        | SEGMENT_TO := if INPUT_I + 1 < E_ARITY then START_STACK[?][OPERAND_BASE + INPUT_I + 1] else WORK_TOP[?]
        | INPUT_LIVE := AT_IP_INPUT and INPUT_I < E_ARITY
        | COPY_NOW := COPY_CURSOR[?]
        | INPUT_COPIES := INPUT_LIVE and COPY_NOW < SEGMENT_TO
        | INPUT_CLOSES := INPUT_LIVE and COPY_NOW >= SEGMENT_TO
        | CALL_FINISHES := AT_IP_INPUT and INPUT_I >= E_ARITY
        | INPUT_KEY := SIGNAL_NAME[CALLEE_FIRST_SIGNAL + INPUT_I]
        | CALLEE_ORDERED := CALLEE_KIND /= C_PROCESS
        | EMIT_COPIES := AT_IP_EMIT and COPY_NOW < WORK_TOP[?]
        | EMIT_CLOSES := AT_IP_EMIT and COPY_NOW >= WORK_TOP[?]
        | EQUATION_ROW_WANTED := INPUT_CLOSES or EMIT_CLOSES and not POSTFIX_IS_MEMBER[?] and WORK_TOP[?] > 0
        | MEMBER_ROW_WANTED := EMIT_CLOSES and POSTFIX_IS_MEMBER[?]
        | DEPENDENCE_ROW_WANTED := DEPENDENCE_LIVE or INPUT_CLOSES and CALLEE_ORDERED and CALLEE_OUTPUTS = 1
        | ENTRY_COPY_WANTED := INPUT_COPIES or EMIT_COPIES
        | PLAIN_ENTRY := ENTRY_LIVE and not MODEL_CALL_LIVE
        | LABEL_ROW_WANTED := LABEL_LIVE or ANCESTRY_PASSES and CALL_LABEL_ADDED
        | GROUP_ROW_WANTED := SELECTS_MEMBER and MEMBER_ORDINAL = 0
        | OVERFLOW_FRAGMENT := if SIGNAL_WANTED and FLAT_SIGNAL_COUNT[?] >= SIGNAL_CAP then F_CAP_SIGNALS
                               else if LABEL_ROW_WANTED and FLAT_LABEL_COUNT[?] >= LABEL_CAP then F_CAP_LABELS
                               else if LOOP_LIVE and FLAT_LOOP_COUNT[?] >= LOOP_CAP then F_CAP_LOOPS
                               else if EQUATION_ROW_WANTED and FLAT_EQUATION_COUNT[?] >= EQUATION_CAP then F_CAP_EQUATIONS
                               else if ENTRY_COPY_WANTED and FLAT_ENTRY_COUNT[?] >= FINAL_CAP then F_CAP_ENTRIES
                               else if ANCESTRY_PASSES and INSTANCE_TOTAL[?] >= INSTANCE_CAP then F_CAP_INSTANCES
                               else if PATH_LIVE and FLAT_PATH_COUNT[?] >= FLAT_PATH_CAP then F_CAP_PATHS
                               else if GROUP_ROW_WANTED and FLAT_GROUP_COUNT[?] >= GROUP_CAP then F_CAP_GROUPS
                               else if MEMBER_ROW_WANTED and FLAT_MEMBER_COUNT[?] >= MEMBER_CAP then F_CAP_GROUPS
                               else if DEPENDENCE_ROW_WANTED and FLAT_DEPENDENCE_COUNT[?] >= DEPENDENCE_CAP then F_CAP_DEPENDENCES
                               else 0
        | FAULT_MESSAGE := if LOOP_FAILS or TARGET_FAILS then T_SIGNAL_UNDECLARED
                          else if SIGNAL_LABEL_FAILS then T_LABEL_AS_SIGNAL
                          else if SIGNAL_UNDECLARED_FAILS then T_SIGNAL_UNDECLARED
                          else if TYPE_PROCESS_FAILS then T_HAS_OUTPUT
                          else if TYPE_SHAPE_FAILS then (if E_NAME = N_INDICES then T_INDICES_CONSTANT else T_CONVERSION_ONE)
                          else if BUILTIN_ITERATE_FAILS then T_CALLS_IN_ITERATE
                          else if BUILTIN_COUNT_FAILS then T_WRONG_ARGUMENTS
                          else if BUILTIN_PROCESS_FAILS then T_HAS_OUTPUT
                          else if BUILTIN_EXPRESSION_FAILS then T_NO_OUTPUT
                          else if BUILTIN_UNSAFE_FAILS then T_UNSAFE_CALL
                          else if CALLEE_UNDECLARED_FAILS then T_MODEL_UNDECLARED
                          else if CALLEE_PARAMS_FAILS then T_NO_STATIC_PARAMETERS
                          else if CALLEE_ITERATE_FAILS then T_CALLS_IN_ITERATE
                          else if SELF_CALL_FAILS then T_CALLS_ITSELF
                          else if FUNCTION_CALL_FAILS then T_FUNCTION_CALL
                          else if CALLEE_COUNT_FAILS then T_WRONG_ARGUMENTS
                          else if CALLEE_OUTPUTS_FAILS then T_TOO_MANY_OUTPUTS
                          else if CALLEE_PROCESS_FAILS then T_HAS_OUTPUT
                          else if CALLEE_EXPRESSION_FAILS then T_NO_OUTPUT
                          else if FROM_FAILS or TO_FAILS then T_SIGNAL_UNDECLARED
                          else if OVERFLOW_FRAGMENT /= 0 then T_CAPACITY else 0
        | FAILS_NOW := FAULT_MESSAGE /= 0
        | FAULT_TOKEN := if LOOP_FAILS then LOOP_TOKEN[ROW_NOW] else if TARGET_FAILS then SELECT_TOKEN
                        else if FROM_FAILS then DEPENDENCE_FROM_TOKEN[ROW_NOW] else if TO_FAILS then DEPENDENCE_TO_TOKEN[ROW_NOW]
                        else if OVERFLOW_FRAGMENT /= 0 then 0 else E_TOKEN
        | FAULT_ARGUMENT0 := if OVERFLOW_FRAGMENT /= 0 and FAULT_MESSAGE = T_CAPACITY then OVERFLOW_FRAGMENT
                           else if FROM_FAILS then FROM_KEY else if TO_FAILS then TO_KEY
                           else if LOOP_FAILS or TARGET_FAILS then CHECK_KEY
                           else if FAULT_MESSAGE = T_FUNCTION_CALL then MODEL_NAME[INST_MODEL] else E_NAME
        | FAULT_ARGUMENT1 := if FAULT_MESSAGE = T_UNSAFE_CALL then MODEL_KIND[PURE_MODEL]
                           else if FAULT_MESSAGE = T_FUNCTION_CALL then CALLEE_KIND
                           else if FAULT_MESSAGE = T_TOO_MANY_OUTPUTS then CALLEE_OUTPUTS
                           else if BUILTIN_LIVE then BUILTIN_INPUTS else CALLEE_INPUTS
        | FAULT_ARGUMENT2 := if FAULT_MESSAGE = T_UNSAFE_CALL then MODEL_NAME[PURE_MODEL]
                           else if FAULT_MESSAGE = T_FUNCTION_CALL then MODEL_NAME[CALLEE] else E_COUNT
        | INSTANTIATE_MESSAGE := if FAILS_NOW then FAULT_MESSAGE else INSTANTIATE_MESSAGE[?]
        | INSTANTIATE_TOKEN := if FAILS_NOW then FAULT_TOKEN else INSTANTIATE_TOKEN[?]
        | INSTANTIATE_ARGUMENT0 := if FAILS_NOW then FAULT_ARGUMENT0 else INSTANTIATE_ARGUMENT0[?]
        | INSTANTIATE_ARGUMENT1 := if FAILS_NOW then FAULT_ARGUMENT1 else INSTANTIATE_ARGUMENT1[?]
        | INSTANTIATE_ARGUMENT2 := if FAILS_NOW then FAULT_ARGUMENT2 else INSTANTIATE_ARGUMENT2[?]
        | GOES_ON := not FAILS_NOW
        | OWNED_SLOT := if SIGNAL_WANTED and GOES_ON and SIGNAL_KEY_NOW < NAME_CAP then SIGNAL_KEY_NOW else -1
        | OWNED_MARK := OWNED_MARK[?] next OWNED_SLOT : INST_MARK
        | LABELED_MARK := LABELED_MARK[?] next (if LABEL_LIVE and GOES_ON then LABEL_NAME[ROW_NOW] else -1) : INST_MARK
        | SIGNAL_ROW_SLOT := if SIGNAL_WANTED and GOES_ON then FLAT_SIGNAL_COUNT[?] else -1
        | FLAT_SIGNAL_SOURCE := FLAT_SIGNAL_SOURCE[?] next SIGNAL_ROW_SLOT : (if PARSE_SIGNAL_LIVE then ROW_NOW else -ROW_NOW - 1)
        | FLAT_SIGNAL_INSTANCE := FLAT_SIGNAL_INSTANCE[?] next SIGNAL_ROW_SLOT : INST
        | FLAT_SIGNAL_COUNT := FLAT_SIGNAL_COUNT[?] + integer(SIGNAL_ROW_SLOT >= 0)
        | LABEL_ROW_SLOT := if LABEL_ROW_WANTED and GOES_ON then FLAT_LABEL_COUNT[?] else -1
        | FLAT_LABEL_KEY := FLAT_LABEL_KEY[?] next LABEL_ROW_SLOT : (if LABEL_LIVE then LABEL_NAME[ROW_NOW] else POSTFIX_TARGET[?])
        | FLAT_LABEL_INSTANCE := FLAT_LABEL_INSTANCE[?] next LABEL_ROW_SLOT : INST
        | FLAT_LABEL_CALL := FLAT_LABEL_CALL[?] next LABEL_ROW_SLOT : not LABEL_LIVE
        | FLAT_LABEL_COUNT := FLAT_LABEL_COUNT[?] + integer(LABEL_ROW_SLOT >= 0)
        | LOOP_ROW_SLOT := if LOOP_LIVE and GOES_ON then FLAT_LOOP_COUNT[?] else -1
        | FLAT_LOOP_SOURCE := FLAT_LOOP_SOURCE[?] next LOOP_ROW_SLOT : ROW_NOW
        | FLAT_LOOP_INSTANCE := FLAT_LOOP_INSTANCE[?] next LOOP_ROW_SLOT : INST
        | FLAT_LOOP_OF := FLAT_LOOP_OF[?] next (if LOOP_ROW_SLOT >= 0 then ROW_NOW else -1) : LOOP_ROW_SLOT
        | FLAT_LOOP_COUNT := FLAT_LOOP_COUNT[?] + integer(LOOP_ROW_SLOT >= 0)
        | POSTFIX_START := if SELECTS_PARSE_EQUATION then EQUATION_FINAL_START[ROW_NOW]
                           else if SELECTS_FINISH_EQUATION then FINISH_EQUATION_FINAL_START[ROW_NOW]
                           else if SELECTS_MEMBER and AT_IP_GROUP then MEMBER_FINAL_START[SELECT_MEMBER_ROW]
                           else if SELECTS_MEMBER then FINISH_GROUP_FINAL[ROW_NOW] + MEMBER_ORDINAL else POSTFIX_START[?]
        | POSTFIX_END := if SELECTS_PARSE_EQUATION then EQUATION_FINAL_END[ROW_NOW]
                         else if SELECTS_FINISH_EQUATION then FINISH_EQUATION_FINAL_END[ROW_NOW]
                         else if SELECTS_MEMBER and AT_IP_GROUP then MEMBER_FINAL_END[SELECT_MEMBER_ROW]
                         else if SELECTS_MEMBER then FINISH_GROUP_FINAL[ROW_NOW] + MEMBER_ORDINAL + 1 else POSTFIX_END_NOW
        | POSTFIX_TARGET := if SELECTS then (if SELECTS_EQUATION then SELECT_TARGET else -1) else POSTFIX_TARGET[?]
        | POSTFIX_IS_MEMBER := if SELECTS then SELECTS_MEMBER else POSTFIX_IS_MEMBER[?]
        | POSTFIX_SEED := if SELECTS then SELECT_SEED else POSTFIX_SEED[?]
        | POSTFIX_LOOP := if SELECTS then (if SELECTS_PARSE_EQUATION then EQUATION_LOOP[ROW_NOW] else -1) else POSTFIX_LOOP[?]
        | POSTFIX_TOKEN := if SELECTS_EQUATION then SELECT_TOKEN else POSTFIX_TOKEN[?]
        | POSTFIX_LABELS := if SELECTS then
                              (if SELECTS_PARSE_EQUATION then EQUATION_LABELS[ROW_NOW]
                               else if SELECTS_FINISH_EQUATION then FINISH_EQUATION_LABELS[ROW_NOW] else -1)
                            else POSTFIX_LABEL_NODE
        | POSTFIX_GUARDS := if SELECTS then
                              (if SELECTS_PARSE_EQUATION then EQUATION_GUARDS[ROW_NOW]
                               else if SELECTS_FINISH_EQUATION then FINISH_EQUATION_GUARDS[ROW_NOW]
                               else if AT_IP_GROUP then GROUP_GUARDS[ROW_NOW] else -1)
                            else POSTFIX_GUARD_NODE
        | POSTFIX_RETURN := if SELECTS then IP_NOW else POSTFIX_RETURN[?]
        | GROUP_ROW_SLOT := if GROUP_ROW_WANTED and GOES_ON then FLAT_GROUP_COUNT[?] else -1
        | FLAT_GROUP_TOKEN := FLAT_GROUP_TOKEN[?] next GROUP_ROW_SLOT
                              : (if AT_IP_GROUP then GROUP_POSITION[ROW_NOW] else MODEL_TOKEN[FINISH_GROUP_MODEL[ROW_NOW]])
        | FLAT_GROUP_GUARDS := FLAT_GROUP_GUARDS[?] next GROUP_ROW_SLOT : (if AT_IP_GROUP then GROUP_GUARDS[ROW_NOW] else -1)
        | FLAT_GROUP_INSTANCE := FLAT_GROUP_INSTANCE[?] next GROUP_ROW_SLOT : INST
        | FLAT_GROUP_MEMBER_FIRST := FLAT_GROUP_MEMBER_FIRST[?] next GROUP_ROW_SLOT : FLAT_MEMBER_COUNT[?]
        | FLAT_GROUP_MEMBER_TOTAL := FLAT_GROUP_MEMBER_TOTAL[?] next GROUP_ROW_SLOT : GROUP_MEMBER_COUNT
        | FLAT_GROUP_COUNT := FLAT_GROUP_COUNT[?] + integer(GROUP_ROW_SLOT >= 0)
        | ENTRY_START_VALUE := if PLAIN_ENTRY or CALL_FINISHES then (if E_ARITY > 0 then START_STACK[?][OPERAND_BASE] else WORK_TOP[?])
                               else 0
        | CALL_HAS_OUTPUT := CALLEE_OUTPUTS > 0
        | WORK_SLOT := if PLAIN_ENTRY and GOES_ON then WORK_TOP[?]
                       else if CALL_FINISHES and CALL_HAS_OUTPUT then ENTRY_START_VALUE else -1
        | WORK_SOURCE := WORK_SOURCE[?] next WORK_SLOT : E
        | WORK_OP := WORK_OP[?] next WORK_SLOT
                     : (if CALL_FINISHES then OP_SIGNAL else if BUILTIN_LIVE then OP_EFFECT else E_OP)
        | WORK_NAME := WORK_NAME[?] next WORK_SLOT : (if CALL_FINISHES then CALLEE_OUTPUT_KEY else E_NAME)
        | WORK_INSTANCE := WORK_INSTANCE[?] next WORK_SLOT
                           : (if CALL_FINISHES then CALL_INSTANCE[?] else if SIGNAL_CHECKED and CHECK_OWNED then INST else 0)
        | START_SLOT := if E_ARITY = 0 and (PLAIN_ENTRY and GOES_ON or CALL_FINISHES and CALL_HAS_OUTPUT) then START_TOP[?] else -1
        | START_STACK := START_STACK[?] next START_SLOT : WORK_TOP[?]
        | WORK_TOP := if SELECTS then 0 else if PLAIN_ENTRY then WORK_TOP[?] + 1
                      else if CALL_FINISHES then ENTRY_START_VALUE + integer(CALL_HAS_OUTPUT) else WORK_TOP[?]
        | START_TOP := if SELECTS then 0 else if PLAIN_ENTRY then START_TOP[?] - E_ARITY + 1
                       else if CALL_FINISHES then START_TOP[?] - E_ARITY + integer(CALL_HAS_OUTPUT) else START_TOP[?]
        | ENTRY_CURSOR := if SELECTS then POSTFIX_START else if PLAIN_ENTRY or CALL_FINISHES then E + 1 else E
        | CREATES_INSTANCE := ANCESTRY_PASSES and GOES_ON
        | NEW_INSTANCE := INSTANCE_TOTAL[?]
        | INSTANCE_SLOT := if CREATES_INSTANCE then NEW_INSTANCE else if AT_IP_ROOT then 0 else -1
        | NEW_MODEL := if AT_IP_ROOT then 0 else CALLEE
        | NEW_KIND := MODEL_KIND[NEW_MODEL]
        | NEW_PURE := NEW_KIND = C_NODE or NEW_KIND = C_FUNCTION or NEW_KIND = C_AUTOMATON
        | CALLEE_TALLY := MODEL_INSTANCE_TALLY[?][CALLEE] + 1
        | MODEL_INSTANCE_TALLY := MODEL_INSTANCE_TALLY[?] next (if CREATES_INSTANCE then CALLEE else -1) : CALLEE_TALLY
        | INSTANCE_MODEL := INSTANCE_MODEL[?] next INSTANCE_SLOT : NEW_MODEL
        | INSTANCE_PARENT := INSTANCE_PARENT[?] next INSTANCE_SLOT : (if AT_IP_ROOT then -1 else INST)
        | INSTANCE_ORDINAL := INSTANCE_ORDINAL[?] next INSTANCE_SLOT : (if AT_IP_ROOT then 0 else CALLEE_TALLY)
        | INSTANCE_PURE := INSTANCE_PURE[?] next INSTANCE_SLOT
                           : (if NEW_PURE then INSTANCE_SLOT else if AT_IP_ROOT then -1 else PURE_INSTANCE)
        | INSTANCE_LABEL_START := INSTANCE_LABEL_START[?] next INSTANCE_SLOT : FLAT_PATH_COUNT[?]
        | INSTANCE_LABEL_LENGTH := INSTANCE_LABEL_LENGTH[?] next INSTANCE_SLOT : (if AT_IP_ROOT then 0 else NEW_LABEL_LENGTH)
        | INSTANCE_GUARD_START := INSTANCE_GUARD_START[?] next INSTANCE_SLOT
                                  : FLAT_PATH_COUNT[?] + (if AT_IP_ROOT then 0 else NEW_LABEL_LENGTH)
        | INSTANCE_GUARD_LENGTH := INSTANCE_GUARD_LENGTH[?] next INSTANCE_SLOT : (if AT_IP_ROOT then 0 else NEW_GUARD_LENGTH)
        | INSTANCE_TOTAL := INSTANCE_TOTAL[?] + integer(INSTANCE_SLOT >= 0)
        | CALL_INSTANCE := if CREATES_INSTANCE then NEW_INSTANCE else CALL_INSTANCE[?]
        | PATH_SLOT := if PATH_LIVE and GOES_ON then FLAT_PATH_COUNT[?] else -1
        | FLAT_PATH_KEY := FLAT_PATH_KEY[?] next PATH_SLOT : PATH_KEY_NOW
        | FLAT_PATH_INSTANCE := FLAT_PATH_INSTANCE[?] next PATH_SLOT : PATH_INSTANCE_NOW
        | FLAT_PATH_CALL := FLAT_PATH_CALL[?] next PATH_SLOT : PATH_CALL_NOW
        | FLAT_PATH_COUNT := FLAT_PATH_COUNT[?] + integer(PATH_SLOT >= 0)
        | PATH_STEP := if CREATES_INSTANCE then 0 else PATH_K + integer(PATH_LIVE)
        | ENTRY_SLOT_FLAT := if ENTRY_COPY_WANTED and GOES_ON then FLAT_ENTRY_COUNT[?] else -1
        | COPIED_SOURCE := WORK_SOURCE[?][COPY_NOW]
        | COPIED_OP := WORK_OP[?][COPY_NOW]
        | FLAT_ENTRY_SOURCE := FLAT_ENTRY_SOURCE[?] next ENTRY_SLOT_FLAT : COPIED_SOURCE
        | FLAT_ENTRY_OP := FLAT_ENTRY_OP[?] next ENTRY_SLOT_FLAT : COPIED_OP
        | FLAT_ENTRY_NAME := FLAT_ENTRY_NAME[?] next ENTRY_SLOT_FLAT : WORK_NAME[?][COPY_NOW]
        | FLAT_ENTRY_INSTANCE := FLAT_ENTRY_INSTANCE[?] next ENTRY_SLOT_FLAT : WORK_INSTANCE[?][COPY_NOW]
        | FLAT_ENTRY_COUNT := FLAT_ENTRY_COUNT[?] + integer(ENTRY_SLOT_FLAT >= 0)
        | FLAT_PARAMETER_TOTAL := FLAT_PARAMETER_TOTAL[?]
                                  + (if ENTRY_SLOT_FLAT >= 0 and (COPIED_OP = OP_CALL or COPIED_OP = OP_EFFECT)
                                     then FINAL_AUX2[COPIED_SOURCE] else 0)
        | COPY_CURSOR := if AT_IP_PATH and not PATH_LIVE then (if E_ARITY > 0 then START_STACK[?][OPERAND_BASE] else 0)
                         else if AT_IP_ENTRY and not ENTRY_LIVE then 0
                         else COPY_NOW + integer(ENTRY_COPY_WANTED)
        | INPUT_CURSOR := if AT_IP_PATH then 0 else INPUT_I + integer(INPUT_CLOSES)
        | EQUATION_ROW_SLOT := if EQUATION_ROW_WANTED and GOES_ON then FLAT_EQUATION_COUNT[?] else -1
        | ROW_LENGTH := if INPUT_CLOSES then SEGMENT_TO - SEGMENT_FROM else WORK_TOP[?]
        | FLAT_EQUATION_TARGET := FLAT_EQUATION_TARGET[?] next EQUATION_ROW_SLOT : (if INPUT_CLOSES then INPUT_KEY else POSTFIX_TARGET[?])
        | FLAT_EQUATION_TARGET_INSTANCE := FLAT_EQUATION_TARGET_INSTANCE[?] next EQUATION_ROW_SLOT
                                           : (if INPUT_CLOSES then CALL_INSTANCE[?] else INST)
        | FLAT_EQUATION_START := FLAT_EQUATION_START[?] next EQUATION_ROW_SLOT : FLAT_ENTRY_COUNT[?] - ROW_LENGTH
        | FLAT_EQUATION_END := FLAT_EQUATION_END[?] next EQUATION_ROW_SLOT : FLAT_ENTRY_COUNT[?]
        | FLAT_EQUATION_TOKEN := FLAT_EQUATION_TOKEN[?] next EQUATION_ROW_SLOT : (if INPUT_CLOSES then E_TOKEN else POSTFIX_TOKEN[?])
        | FLAT_EQUATION_LOOP := FLAT_EQUATION_LOOP[?] next EQUATION_ROW_SLOT
                                : (if INPUT_CLOSES or POSTFIX_LOOP[?] < 0 then -1 else FLAT_LOOP_OF[?][POSTFIX_LOOP[?]])
        | FLAT_EQUATION_SEED := FLAT_EQUATION_SEED[?] next EQUATION_ROW_SLOT : not INPUT_CLOSES and POSTFIX_SEED[?]
        | FLAT_EQUATION_CONTEXT := FLAT_EQUATION_CONTEXT[?] next EQUATION_ROW_SLOT : INST
        | FLAT_EQUATION_LABELS := FLAT_EQUATION_LABELS[?] next EQUATION_ROW_SLOT : POSTFIX_LABEL_NODE
        | FLAT_EQUATION_GUARDS := FLAT_EQUATION_GUARDS[?] next EQUATION_ROW_SLOT : POSTFIX_GUARD_NODE
        | FLAT_EQUATION_COUNT := FLAT_EQUATION_COUNT[?] + integer(EQUATION_ROW_SLOT >= 0)
        | FLAT_LIST_TOTAL := FLAT_LIST_TOTAL[?]
                             + (if EQUATION_ROW_SLOT >= 0 then CALLER_LABEL_LENGTH + POSTFIX_LABEL_LENGTH + CALLER_GUARD_LENGTH
                                                               + POSTFIX_GUARD_LENGTH
                                else 0)
                             + (if GROUP_ROW_SLOT >= 0 then CALLER_GUARD_LENGTH + POSTFIX_GUARD_LENGTH else 0)
        | MEMBER_ROW_SLOT := if MEMBER_ROW_WANTED and GOES_ON then FLAT_MEMBER_COUNT[?] else -1
        | FLAT_MEMBER_START := FLAT_MEMBER_START[?] next MEMBER_ROW_SLOT : FLAT_ENTRY_COUNT[?] - WORK_TOP[?]
        | FLAT_MEMBER_END := FLAT_MEMBER_END[?] next MEMBER_ROW_SLOT : FLAT_ENTRY_COUNT[?]
        | FLAT_MEMBER_COUNT := FLAT_MEMBER_COUNT[?] + integer(MEMBER_ROW_SLOT >= 0)
        | DEPENDENCE_ROW_SLOT := if DEPENDENCE_ROW_WANTED and GOES_ON then FLAT_DEPENDENCE_COUNT[?] else -1
        | FLAT_DEPENDENCE_INSTANCE := FLAT_DEPENDENCE_INSTANCE[?] next DEPENDENCE_ROW_SLOT
                                      : (if INPUT_CLOSES then CALL_INSTANCE[?] else INST)
        | FLAT_DEPENDENCE_FROM_KEY := FLAT_DEPENDENCE_FROM_KEY[?] next DEPENDENCE_ROW_SLOT : (if INPUT_CLOSES then INPUT_KEY else FROM_KEY)
        | FLAT_DEPENDENCE_TO_KEY := FLAT_DEPENDENCE_TO_KEY[?] next DEPENDENCE_ROW_SLOT
                                    : (if INPUT_CLOSES then CALLEE_OUTPUT_KEY else TO_KEY)
        | FLAT_DEPENDENCE_FROM_TOKEN := FLAT_DEPENDENCE_FROM_TOKEN[?] next DEPENDENCE_ROW_SLOT
                                        : (if INPUT_CLOSES then E_TOKEN else DEPENDENCE_FROM_TOKEN[ROW_NOW])
        | FLAT_DEPENDENCE_TO_TOKEN := FLAT_DEPENDENCE_TO_TOKEN[?] next DEPENDENCE_ROW_SLOT
                                      : (if INPUT_CLOSES then E_TOKEN else DEPENDENCE_TO_TOKEN[ROW_NOW])
        | FLAT_DEPENDENCE_TOKEN := FLAT_DEPENDENCE_TOKEN[?] next DEPENDENCE_ROW_SLOT
                                   : (if INPUT_CLOSES then E_TOKEN else DEPENDENCE_POSITION[ROW_NOW])
        | FLAT_DEPENDENCE_COUNT := FLAT_DEPENDENCE_COUNT[?] + integer(DEPENDENCE_ROW_SLOT >= 0)
        | ANCESTOR_CURSOR := if STARTS_ANCESTRY then INST else if AT_IP_ANCESTRY then INSTANCE_PARENT[?][WALKER] else WALKER
        | IP_STATE := if FAILS_NOW then IP_FAILED
                      else if AT_IP_ROOT then IP_INSTANCE
                      else if AT_IP_INSTANCE then (if INSTANCES_DONE then IP_DONE else IP_LABEL)
                      else if AT_IP_LABEL then (if LABEL_LIVE then IP_LABEL else IP_SIGNAL)
                      else if AT_IP_SIGNAL then (if PARSE_SIGNAL_LIVE then IP_SIGNAL else IP_FINISH_SIGNAL)
                      else if AT_IP_FINISH_SIGNAL then (if FINISH_SIGNAL_LIVE then IP_FINISH_SIGNAL else IP_LOOP)
                      else if AT_IP_LOOP then (if LOOP_LIVE then IP_LOOP else IP_EQUATION)
                      else if AT_IP_EQUATION then
                        (if SELECTS_PARSE_EQUATION then IP_ENTRY else if EQUATION_LIVE then IP_EQUATION else IP_FINISH_EQUATION)
                      else if AT_IP_FINISH_EQUATION then (if SELECTS_FINISH_EQUATION then IP_ENTRY else IP_GROUP)
                      else if AT_IP_GROUP then
                        (if SELECTS_MEMBER then IP_ENTRY else if PARSE_GROUP_LIVE then IP_GROUP else IP_FINISH_GROUP)
                      else if AT_IP_FINISH_GROUP then
                        (if SELECTS_MEMBER then IP_ENTRY else if FINISH_GROUP_LIVE then IP_FINISH_GROUP else IP_DEPENDENCE)
                      else if AT_IP_DEPENDENCE then (if DEPENDENCE_LIVE then IP_DEPENDENCE else IP_INSTANCE)
                      else if AT_IP_ENTRY then (if not ENTRY_LIVE then IP_EMIT else if STARTS_ANCESTRY then IP_ANCESTRY else IP_ENTRY)
                      else if AT_IP_ANCESTRY then (if ANCESTRY_PASSES then IP_PATH else IP_ANCESTRY)
                      else if AT_IP_PATH then (if PATH_LIVE then IP_PATH else IP_INPUT)
                      else if AT_IP_INPUT then (if CALL_FINISHES then IP_ENTRY else IP_INPUT)
                      else if AT_IP_EMIT then (if EMIT_CLOSES then POSTFIX_RETURN[?] else IP_EMIT)
                      else IP_NOW
        | ROW_CURSOR := if AT_IP_INSTANCE then MODEL_FIRST_LABEL[INST_MODEL] - 1
                        else if AT_IP_LABEL then (if LABEL_LIVE then LABEL_NEXT[ROW_NOW] - 1 else MODEL_FIRST_SIGNAL[INST_MODEL] - 1)
                        else if AT_IP_SIGNAL then
                          (if PARSE_SIGNAL_LIVE then SIGNAL_NEXT[ROW_NOW] - 1 else MODEL_FINISH_SIGNAL_START[INST_MODEL])
                        else if AT_IP_FINISH_SIGNAL then (if FINISH_SIGNAL_LIVE then ROW_NOW + 1 else MODEL_LOOP_START[INST_MODEL])
                        else if AT_IP_LOOP then (if LOOP_LIVE then ROW_NOW + 1 else MODEL_EQUATION_START[INST_MODEL])
                        else if AT_IP_EQUATION then
                          (if EQUATION_LIVE then ROW_NOW + integer(EQUATION_SKIPS) else MODEL_FINISH_EQUATION_START[INST_MODEL])
                        else if AT_IP_FINISH_EQUATION then (if SELECTS_FINISH_EQUATION then ROW_NOW else MODEL_GROUP_START[INST_MODEL])
                        else if AT_IP_GROUP then
                          (if PARSE_GROUP_LIVE then ROW_NOW + integer(GROUP_ADVANCES) else MODEL_FINISH_GROUP_START[INST_MODEL])
                        else if AT_IP_FINISH_GROUP then
                          (if FINISH_GROUP_LIVE then ROW_NOW + integer(GROUP_ADVANCES) else MODEL_DEPENDENCE_START[INST_MODEL])
                        else if AT_IP_DEPENDENCE then ROW_NOW + 1
                        else ROW_NOW + integer(EMIT_CLOSES and not POSTFIX_IS_MEMBER[?])
        | MEMBER_CURSOR := if GROUP_ADVANCES then 0 else MEMBER_ORDINAL + integer(EMIT_CLOSES and POSTFIX_IS_MEMBER[?])
        | INSTANCE_AT := INST + integer(AT_IP_DEPENDENCE and not DEPENDENCE_LIVE)
        |)
     with (| IP_STATE := IP_ROOT | INSTANCE_AT := 0 | ROW_CURSOR := 0 | MEMBER_CURSOR := 0 | ENTRY_CURSOR := 0
           | WORK_TOP := 0 | START_TOP := 0 | ANCESTOR_CURSOR := -1 | PATH_STEP := 0 | INPUT_CURSOR := 0 | COPY_CURSOR := 0
           | CALL_INSTANCE := 0 | INSTANCE_TOTAL := 0 | POSTFIX_START := 0 | POSTFIX_END := 0 | POSTFIX_TARGET := -1
           | POSTFIX_IS_MEMBER := false | POSTFIX_SEED := false | POSTFIX_LOOP := -1 | POSTFIX_TOKEN := 0
           | POSTFIX_LABELS := -1 | POSTFIX_GUARDS := -1 | POSTFIX_RETURN := IP_EQUATION | FLAT_SIGNAL_COUNT := 0
           | FLAT_LABEL_COUNT := 0 | FLAT_LOOP_COUNT := 0 | FLAT_GROUP_COUNT := 0 | FLAT_MEMBER_COUNT := 0
           | FLAT_ENTRY_COUNT := 0 | FLAT_PATH_COUNT := 0 | FLAT_EQUATION_COUNT := 0 | FLAT_DEPENDENCE_COUNT := 0
           | FLAT_PARAMETER_TOTAL := 0 | FLAT_LIST_TOTAL := 0 | INSTANTIATE_MESSAGE := 0 | INSTANTIATE_TOKEN := 0
           | INSTANTIATE_ARGUMENT0 := 0 | INSTANTIATE_ARGUMENT1 := 0 | INSTANTIATE_ARGUMENT2 := 0 |)
     end
   | INSTANTIATE_FAILED := INSTANTIATES and IP_STATE = IP_FAILED
   | INSTANTIATE_INCOMPLETE := INSTANTIATES and IP_STATE /= IP_DONE and IP_STATE /= IP_FAILED
   | FLAT_READY := INSTANTIATES and IP_STATE = IP_DONE
   | DUMP_RUNS := DUMP_PASS = 2 and FINISHES and PASS_MESSAGE = 0 or DUMP_PASS = 3 and FLAT_READY or ROWS_DUMP and ROWS_READY or CLOCKS_DUMP and CLOCKS_READY or SCHEDULE_DUMP and SCHEDULE_READY
   | FLAT_DUMP := DUMP_PASS = 3
   | ROWS_DUMP := DUMP_PASS = 4
   | LOWERS := FLAT_READY and (DUMP_PASS = 0 or DUMP_PASS = 4 or DUMP_PASS = 5 or DUMP_PASS = 6 or DUMP_PASS = 7)
   | LOWER_BOUND := long(64) + long(2) * long(FLAT_SIGNAL_COUNT) + long(FLAT_LABEL_COUNT) + long(2) * long(TYPE_COUNT)
                    + long(VALUE_COUNT) + long(TABLE_COUNT) + long(POOL_COUNT) + long(FLAT_LOOP_COUNT)
                    + long(6) * long(FLAT_EQUATION_COUNT) + long(2) * long(FLAT_GROUP_COUNT) + long(2) * long(FLAT_MEMBER_COUNT)
                    + long(4) * long(FLAT_ENTRY_COUNT)
   | LOWER_INDEX := 0 .. (if LOWERS then LOWER_BOUND else long(-1))
   | iterate LOWER_INDEX of
       (| LW_NOW := LW_STATE[?]
        | LW_I := LW_CURSOR[?]
        | LW_K := LW_SUB[?]
        | AT_LS_SIGNAL := LW_NOW = LS_SIGNAL
        | AT_LS_LABEL := LW_NOW = LS_LABEL
        | AT_LS_VALUE := LW_NOW = LS_VALUE
        | AT_LS_ARRAY := LW_NOW = LS_ARRAY
        | AT_LS_TABLE := LW_NOW = LS_TABLE
        | AT_LS_LOOP := LW_NOW = LS_LOOP
        | AT_LS_EQUATION := LW_NOW = LS_EQUATION
        | AT_LS_GROUP := LW_NOW = LS_GROUP
        | AT_LS_START := LW_NOW = LS_START
        | AT_LS_SCAN := LW_NOW = LS_SCAN
        | AT_LS_ENTRY := LW_NOW = LS_ENTRY
        | AT_LS_NEVER := LW_NOW = LS_NEVER
        | AT_LS_MEMBERS := LW_NOW = LS_MEMBERS
        | LW_SIGNAL_LIVE := AT_LS_SIGNAL and LW_I < FLAT_SIGNAL_COUNT
        | LW_SIGNAL_SOURCE := FLAT_SIGNAL_SOURCE[LW_I]
        | LW_SIGNAL_KEY_NOW := if LW_SIGNAL_SOURCE >= 0 then SIGNAL_NAME[LW_SIGNAL_SOURCE] else FINISH_SIGNAL_NAME[-LW_SIGNAL_SOURCE - 1]
        | LW_SIGNAL_TYPE_NOW := if LW_SIGNAL_SOURCE >= 0 then SIGNAL_TYPE[LW_SIGNAL_SOURCE] else FINISH_SIGNAL_TYPE[-LW_SIGNAL_SOURCE - 1]
        | LW_SIGNAL_INPUT := FLAT_SIGNAL_INSTANCE[LW_I] = 0 and LW_SIGNAL_SOURCE >= 0 and SIGNAL_ROLE[LW_SIGNAL_SOURCE] = ROLE_INPUT
        | LW_LABEL_LIVE := AT_LS_LABEL and LW_I < FLAT_LABEL_COUNT
        | LW_VALUE_TYPE_LIVE := AT_LS_VALUE and LW_I < TYPE_COUNT
        | LW_VALUE_LIVE := LW_VALUE_TYPE_LIVE and LW_K < TYPE_VALUE_COUNT[LW_I]
        | LW_VALUE_KEY := VALUE_NAME[TYPE_VALUE_START[LW_I] + LW_K]
        | LW_ARRAY_LIVE := AT_LS_ARRAY and LW_I < TYPE_COUNT and TYPE_KIND[LW_I] = TK_ARRAY
        | LW_TABLE_LIVE := AT_LS_TABLE and LW_I < TABLE_COUNT
        | LW_TABLE_TYPE := TABLE_TYPE[LW_I]
        | LW_TABLE_CANDIDATE := LW_TABLE_LIVE and not TABLE_FROM_STRING[LW_I] and TYPE_KIND[LW_TABLE_TYPE] = TK_ARRAY
                                and TYPE_ELEMENT[LW_TABLE_TYPE] = BUILTIN_INTEGER
                                and TYPE_SIZE[LW_TABLE_TYPE] = ulong(TABLE_LENGTH[LW_I]) and LW_IOTA[?][LW_TABLE_TYPE] = 0
        | LW_TABLE_WALKS := LW_TABLE_CANDIDATE and LW_K < TABLE_LENGTH[LW_I]
        | LW_TABLE_MATCHES := POOL_VALUE[TABLE_START[LW_I] + LW_K] = long(LW_K)
        | LW_TABLE_OK := if LW_K = 0 then LW_TABLE_MATCHES else LW_TABLE_OK[?] and LW_TABLE_MATCHES
        | LW_TABLE_IOTA := LW_TABLE_CANDIDATE and not LW_TABLE_WALKS and (LW_K = 0 or LW_TABLE_OK[?])
        | LW_LOOP_LIVE := AT_LS_LOOP and LW_I < FLAT_LOOP_COUNT
        | LW_LOOP_SOURCE := FLAT_LOOP_SOURCE[LW_I]
        | LW_EQUATION_LIVE := AT_LS_EQUATION and LW_I < FLAT_EQUATION_COUNT
        | LW_EQ_TARGET := FLAT_EQUATION_TARGET[LW_I]
        | LW_EQ_TARGET_INSTANCE := FLAT_EQUATION_TARGET_INSTANCE[LW_I]
        | LW_EQ_SEED := FLAT_EQUATION_SEED[LW_I]
        | LW_EQ_LOOP := FLAT_EQUATION_LOOP[LW_I]
        | LW_EQ_TOKEN := FLAT_EQUATION_TOKEN[LW_I]
        | LW_EQ_LOOP_NAME := LOOP_NAME[FLAT_LOOP_SOURCE[LW_EQ_LOOP]]
        | LW_EQ_LOOP_INSTANCE := FLAT_LOOP_INSTANCE[LW_EQ_LOOP]
        | LW_LOOP_DEFINES := LW_EQ_LOOP >= 0 and not LW_EQ_SEED and LW_EQ_TARGET >= 0
        | LW_GUARD_NODE := if AT_LS_GROUP then FLAT_GROUP_GUARDS[LW_I] else FLAT_EQUATION_GUARDS[LW_I]
        | LW_GUARD_CONTEXT := if AT_LS_GROUP then FLAT_GROUP_INSTANCE[LW_I] else FLAT_EQUATION_CONTEXT[LW_I]
        | LW_GUARD_NODE_LENGTH := if LW_GUARD_NODE < 0 then 0 else GUARD_PATH_LENGTH[LW_GUARD_NODE]
        | LW_GUARD_INHERITED := INSTANCE_GUARD_LENGTH[LW_GUARD_CONTEXT]
        | LW_GUARD_LAST := PATH_VALUE[GUARD_PATH_START[LW_GUARD_NODE] + LW_GUARD_NODE_LENGTH - 1]
        | LW_GUARD_AT := INSTANCE_GUARD_START[LW_GUARD_CONTEXT] + LW_GUARD_INHERITED - 1
        | LW_GUARD_KEY := if LW_GUARD_NODE_LENGTH > 0
                          then N_ON_MARK + (LW_GUARD_LAST - MODEL_GUARD_START[GUARD_MODEL[LW_GUARD_LAST]] + 1) * NAME_CAP
                          else FLAT_PATH_KEY[LW_GUARD_AT]
        | LW_GUARD_INSTANCE := if LW_GUARD_NODE_LENGTH > 0 then LW_GUARD_CONTEXT else FLAT_PATH_INSTANCE[LW_GUARD_AT]
        | LW_HAS_GUARD := LW_GUARD_NODE_LENGTH > 0 or LW_GUARD_INHERITED > 0
        | LW_EQ_STEP := if not LW_EQUATION_LIVE then 3
                        else if LW_K <= 0 and LW_EQ_TARGET >= 0 then 0
                        else if LW_K <= 1 and LW_LOOP_DEFINES then 1
                        else if LW_K <= 2 and LW_HAS_GUARD then 2 else 3
        | LW_EQ_MORE := LW_EQ_STEP < 1 and LW_LOOP_DEFINES or LW_EQ_STEP < 2 and LW_HAS_GUARD
        | LW_GROUP_LIVE := AT_LS_GROUP and LW_I < FLAT_GROUP_COUNT
        | LW_START_LIVE := AT_LS_START and LW_I < FLAT_EQUATION_COUNT
        | LW_START_SIGNAL := LW_EQ_SIGNAL[?][LW_I] - 1
        | LW_E := LW_ENTRY[?]
        | LW_END_NOW := LW_FL_END[?]
        | LW_SCAN_LIVE := AT_LS_SCAN and LW_E < LW_END_NOW
        | LW_ENTRY_LIVE := AT_LS_ENTRY and LW_E < LW_END_NOW
        | LW_FINISHING := AT_LS_ENTRY and LW_E >= LW_END_NOW
        | LW_SRC := FLAT_ENTRY_SOURCE[LW_E]
        | LW_OP := FLAT_ENTRY_OP[LW_E]
        | LW_NAME := FLAT_ENTRY_NAME[LW_E]
        | LW_INST := FLAT_ENTRY_INSTANCE[LW_E]
        | LW_ENTRY_TOKEN := FINAL_TOKEN[LW_SRC]
        | LW_LOOP_NOW := LW_FL_LOOP[?]
        | LW_TOP_NOW := LW_TOP[?]
        | LW_SCAN_READS := LW_SCAN_LIVE and LW_OP = OP_SIGNAL
        | LW_IS_SIGNAL := LW_ENTRY_LIVE and LW_OP = OP_SIGNAL
        | LW_IS_ITER := LW_IS_SIGNAL and LW_LOOP_NOW >= 0 and LW_NAME = LOOP_NAME[FLAT_LOOP_SOURCE[LW_LOOP_NOW]]
                        and LW_INST = FLAT_LOOP_INSTANCE[LW_LOOP_NOW]
        | LW_LOOKS_SIGNAL := LW_IS_SIGNAL and not LW_IS_ITER
        | LW_IS_CONST := LW_ENTRY_LIVE and LW_OP = OP_CONST
        | LW_IS_EFFECT := LW_ENTRY_LIVE and LW_OP = OP_EFFECT
        | LW_INITIAL := FINAL_AUX[LW_SRC]
        | LW_IS_DELAY := LW_ENTRY_LIVE and LW_OP = OP_DELAY
        | LW_IS_ENUM := LW_ENTRY_LIVE and LW_OP = OP_ENUMCONST
        | LW_ENUM_LIVE := LW_IS_ENUM or LW_IS_DELAY and LW_INITIAL = 2
        | LW_IS_LEAF := LW_IS_SIGNAL or LW_IS_CONST or LW_IS_ENUM
        | LW_OPERATOR := LW_ENTRY_LIVE and not LW_IS_LEAF and not LW_IS_EFFECT
        | LW_UNARY := LW_OP = OP_CALL or OP_ARITY[LW_OP] = 1
        | LW_LEFT := if LW_UNARY then LW_STACK[?][LW_TOP_NOW - 1] else LW_STACK[?][LW_TOP_NOW - 2]
        | LW_RIGHT := if LW_UNARY then -1 else LW_STACK[?][LW_TOP_NOW - 1]
        | LW_LEFT_OP := ROWS_OP[?][LW_LEFT]
        | LW_RIGHT_OP := ROWS_OP[?][LW_RIGHT]
        | LT := ROWS_TYPE[?][LW_LEFT]
        | RT := if LW_RIGHT >= 0 then ROWS_TYPE[?][LW_RIGHT] else LT
        | LT_NEW := LT >= TYPE_COUNT
        | LT_KIND := if LT_NEW then TK_ARRAY else TYPE_KIND[LT]
        | LT_ELEMENT := if LT_NEW then NEW_TYPE_ELEMENT[?][LT - TYPE_COUNT] else TYPE_ELEMENT[LT]
        | LT_SIZE := if LT_NEW then NEW_TYPE_SIZE[?][LT - TYPE_COUNT] else TYPE_SIZE[LT]
        | LT_INT := LT_KIND = TK_INT
        | LT_LOGICAL := LT_KIND = TK_EVENT or LT_KIND = TK_BOOLEAN
        | RT_NEW := RT >= TYPE_COUNT
        | RT_KIND := if RT_NEW then TK_ARRAY else TYPE_KIND[RT]
        | RT_ELEMENT := if RT_NEW then NEW_TYPE_ELEMENT[?][RT - TYPE_COUNT] else TYPE_ELEMENT[RT]
        | RT_SIZE := if RT_NEW then NEW_TYPE_SIZE[?][RT - TYPE_COUNT] else TYPE_SIZE[RT]
        | RT_INT := RT_KIND = TK_INT
        | RT_LOGICAL := RT_KIND = TK_EVENT or RT_KIND = TK_BOOLEAN
        | LW_ARRAY_OPERAND := LT_KIND = TK_ARRAY or RT_KIND = TK_ARRAY
        | LW_LEFT_VALUE := ROWS_VALUE[?][LW_LEFT]
        | LW_IS_INDICES := LW_OPERATOR and LW_OP = OP_CALL and LW_NAME = N_INDICES
        | LW_INDICES_COUNT := if LT = BUILTIN_ULONG then (if LW_LEFT_VALUE = long(0) then long(0) else long(1)) else LW_LEFT_VALUE
        | LW_IS_GATHER := LW_OPERATOR and LW_OP = OP_INDEX and RT_KIND = TK_ARRAY
        | LW_IS_PREV := LW_OPERATOR and LW_OP = OP_PREV
        | LW_PREV_INSTANCE := FLAT_SIGNAL_INSTANCE[LW_LEFT]
        | LW_ENUM_TYPE_KEY := FINAL_TYPE[LW_SRC]
        | LW_ENUM_VALUE_KEY := integer(FINAL_VALUE[LW_SRC])
        | LW_ENUM_TOKEN := if LW_IS_DELAY then FINAL_AUX2[LW_SRC] else LW_ENTRY_TOKEN
        | LW_ENUM_NAMED := LW_ENUM_TYPE_KEY >= 0
        | LW_ENUM_NAMED_TYPE := if LW_ENUM_TYPE_KEY < BUILTIN_TYPE_COUNT then LW_ENUM_TYPE_KEY else if NAME_TYPE[LW_ENUM_TYPE_KEY] > 0 then NAME_TYPE[LW_ENUM_TYPE_KEY] - 1 else NAME_ALIAS[LW_ENUM_TYPE_KEY] - 1
        | LW_ENUM_HOLDERS := HOLDER_COUNT[?][LW_ENUM_VALUE_KEY]
        | LW_ENUM_TYPE := if LW_ENUM_NAMED then LW_ENUM_NAMED_TYPE else HOLDER_TYPE[?][LW_ENUM_VALUE_KEY]
        | LW_START_LOOKS := LW_START_LIVE and LW_EQ_SEED
        | LW_PAIR_KEY_NAME := if LW_IS_PREV then LW_SIGNAL_KEY[?][LW_LEFT] else if LW_SCAN_READS then LW_NAME else LW_EQ_TARGET
        | LW_PAIR_KEY_INSTANCE := if LW_IS_PREV then LW_PREV_INSTANCE else if LW_SCAN_READS then LW_INST else LW_EQ_TARGET_INSTANCE
        | LW_PAIR_KEY_LOOP := if LW_IS_PREV then LW_LOOP_NOW else LW_EQ_LOOP
        | LW_LOOKS_PAIR := LW_IS_PREV or LW_SCAN_READS or LW_START_LOOKS or LW_EQ_STEP = 1
        | LW_LOOKS_ARRAY := LW_IS_INDICES or LW_IS_GATHER
        | LW_ARRAY_ELEMENT := if LW_IS_INDICES then BUILTIN_INTEGER else LT_ELEMENT
        | LW_ARRAY_SIZE := if LW_IS_INDICES then ulong(LW_LEFT_VALUE) else RT_SIZE
        | LW_LOOKS_GUARD := LW_EQ_STEP = 2 or LW_GROUP_LIVE and LW_HAS_GUARD
        | LK_LIVE := LW_SIGNAL_LIVE or LW_LABEL_LIVE or LW_VALUE_LIVE or LW_ARRAY_LIVE or LW_LOOP_LIVE or LW_EQ_STEP < 3
                     or LW_GROUP_LIVE and LW_HAS_GUARD or LW_START_LOOKS or LW_SCAN_READS or LW_LOOKS_SIGNAL or LW_ENUM_LIVE
                     or LW_IS_PREV or LW_LOOKS_ARRAY
        | LK_A := if LW_SIGNAL_LIVE then long(LW_SIGNAL_KEY_NOW)
                  else if LW_LABEL_LIVE then long(FLAT_LABEL_KEY[LW_I])
                  else if LW_VALUE_LIVE then long(LW_VALUE_KEY)
                  else if LW_ARRAY_LIVE then long(TYPE_SIZE[LW_I])
                  else if LW_LOOP_LIVE then long(LOOP_NAME[LW_LOOP_SOURCE])
                  else if LW_LOOKS_PAIR then long(LW_PAIR_KEY_NAME)
                  else if LW_LOOKS_GUARD then long(LW_GUARD_KEY)
                  else if LW_EQ_STEP = 0 then long(LW_EQ_TARGET)
                  else if LW_LOOKS_SIGNAL then long(LW_NAME)
                  else if LW_ENUM_LIVE then long(LW_ENUM_VALUE_KEY)
                  else long(LW_ARRAY_SIZE)
        | LK_B := if LW_SIGNAL_LIVE then long(FLAT_SIGNAL_INSTANCE[LW_I]) * long(KEY_STRIDE) + long(KEY_SIGNAL)
                  else if LW_LABEL_LIVE then long(FLAT_LABEL_INSTANCE[LW_I]) * long(KEY_STRIDE)
                                             + long(if FLAT_LABEL_CALL[LW_I] then KEY_CALL_LABEL else KEY_LABEL)
                  else if LW_VALUE_LIVE then long(LW_I) * long(KEY_STRIDE) + long(KEY_VALUE)
                  else if LW_ARRAY_LIVE then long(TYPE_ELEMENT[LW_I]) * long(KEY_STRIDE) + long(KEY_ARRAY)
                  else if LW_LOOP_LIVE then long(FLAT_LOOP_INSTANCE[LW_I]) * long(KEY_STRIDE) + long(KEY_SIGNAL)
                  else if LW_LOOKS_PAIR then (long(LW_PAIR_KEY_INSTANCE) * long(LOOP_CAP + 1) + long(LW_PAIR_KEY_LOOP + 1)) * long(KEY_STRIDE)
                                             + long(KEY_PAIR)
                  else if LW_LOOKS_GUARD then long(LW_GUARD_INSTANCE) * long(KEY_STRIDE) + long(KEY_SIGNAL)
                  else if LW_EQ_STEP = 0 then long(LW_EQ_TARGET_INSTANCE) * long(KEY_STRIDE) + long(KEY_SIGNAL)
                  else if LW_LOOKS_SIGNAL then long(LW_INST) * long(KEY_STRIDE) + long(KEY_SIGNAL)
                  else if LW_ENUM_LIVE then long(LW_ENUM_TYPE) * long(KEY_STRIDE) + long(KEY_VALUE)
                  else long(LW_ARRAY_ELEMENT) * long(KEY_STRIDE) + long(KEY_ARRAY)
        | LK_WANTS_INSERT := LW_SIGNAL_LIVE or LW_LABEL_LIVE or LW_VALUE_LIVE or LW_ARRAY_LIVE or LW_EQ_STEP = 1 or LW_LOOKS_ARRAY
        | LK_HASH := integer((ulong(LK_A) * HASH_K1 + ulong(LK_B) * HASH_K2) shr HASH_SHIFT)
        | LK_N0 := HASH_HEAD[?][LK_HASH] - 1
        | LK_M0 := LK_N0 >= 0 and HN_A[?][LK_N0] = LK_A and HN_B[?][LK_N0] = LK_B
        | LK_N1 := if LK_N0 >= 0 then HN_NEXT[?][LK_N0] - 1 else -1
        | LK_M1 := LK_N1 >= 0 and HN_A[?][LK_N1] = LK_A and HN_B[?][LK_N1] = LK_B
        | LK_N2 := if LK_N1 >= 0 then HN_NEXT[?][LK_N1] - 1 else -1
        | LK_M2 := LK_N2 >= 0 and HN_A[?][LK_N2] = LK_A and HN_B[?][LK_N2] = LK_B
        | LK_N3 := if LK_N2 >= 0 then HN_NEXT[?][LK_N2] - 1 else -1
        | LK_M3 := LK_N3 >= 0 and HN_A[?][LK_N3] = LK_A and HN_B[?][LK_N3] = LK_B
        | LK_N4 := if LK_N3 >= 0 then HN_NEXT[?][LK_N3] - 1 else -1
        | LK_M4 := LK_N4 >= 0 and HN_A[?][LK_N4] = LK_A and HN_B[?][LK_N4] = LK_B
        | LK_N5 := if LK_N4 >= 0 then HN_NEXT[?][LK_N4] - 1 else -1
        | LK_M5 := LK_N5 >= 0 and HN_A[?][LK_N5] = LK_A and HN_B[?][LK_N5] = LK_B
        | LK_N6 := if LK_N5 >= 0 then HN_NEXT[?][LK_N5] - 1 else -1
        | LK_M6 := LK_N6 >= 0 and HN_A[?][LK_N6] = LK_A and HN_B[?][LK_N6] = LK_B
        | LK_N7 := if LK_N6 >= 0 then HN_NEXT[?][LK_N6] - 1 else -1
        | LK_M7 := LK_N7 >= 0 and HN_A[?][LK_N7] = LK_A and HN_B[?][LK_N7] = LK_B
        | LK_NODE := if LK_M0 then LK_N0 else if LK_M1 then LK_N1 else if LK_M2 then LK_N2 else if LK_M3 then LK_N3
                     else if LK_M4 then LK_N4 else if LK_M5 then LK_N5 else if LK_M6 then LK_N6 else if LK_M7 then LK_N7 else -1
        | LK_FOUND := LK_NODE >= 0
        | LK_VALUE := if LK_FOUND then HN_VALUE[?][LK_NODE] else -1
        | LK_UNSURE := LK_LIVE and not LK_FOUND and LK_N7 >= 0 and HN_NEXT[?][LK_N7] > 0
        | LK_INSERTS := LK_LIVE and LK_WANTS_INSERT and not LK_FOUND and not LK_UNSURE
        | LK_NEW := HN_COUNT[?]
        | LK_FULL := LK_INSERTS and LK_NEW >= HASH_NODE_CAP
        | LW_NEW_TYPE := TYPE_COUNT + NEW_TYPE_COUNT[?]
        | LW_TYPE_FULL := LW_LOOKS_ARRAY and LK_INSERTS and NEW_TYPE_COUNT[?] >= NEW_TYPE_CAP
        | LK_INSERT_VALUE := if LW_VALUE_LIVE then LW_K else if LW_LOOKS_ARRAY then LW_NEW_TYPE else LW_I
        | HN_SLOT := if LK_INSERTS and not LK_FULL then LK_NEW else -1
        | HN_A := HN_A[?] next HN_SLOT : LK_A
        | HN_B := HN_B[?] next HN_SLOT : LK_B
        | HN_VALUE := HN_VALUE[?] next HN_SLOT : LK_INSERT_VALUE
        | HN_NEXT := HN_NEXT[?] next HN_SLOT : LK_N0 + 1
        | HASH_HEAD := HASH_HEAD[?] next (if HN_SLOT >= 0 then LK_HASH else -1) : HN_SLOT + 1
        | HN_COUNT := HN_COUNT[?] + integer(HN_SLOT >= 0)
        | LW_HOLDER_SLOT := if LW_VALUE_LIVE and LK_INSERTS then LW_VALUE_KEY else -1
        | HOLDER_COUNT := HOLDER_COUNT[?] next LW_HOLDER_SLOT : HOLDER_COUNT[?][LW_VALUE_KEY] + 1
        | HOLDER_TYPE := HOLDER_TYPE[?] next (if HOLDER_COUNT[?][LW_VALUE_KEY] = 0 then LW_HOLDER_SLOT else -1) : LW_I
        | LW_NEW_TYPE_SLOT := if LW_LOOKS_ARRAY and HN_SLOT >= 0 and not LW_TYPE_FULL then NEW_TYPE_COUNT[?] else -1
        | NEW_TYPE_ELEMENT := NEW_TYPE_ELEMENT[?] next LW_NEW_TYPE_SLOT : LW_ARRAY_ELEMENT
        | NEW_TYPE_SIZE := NEW_TYPE_SIZE[?] next LW_NEW_TYPE_SLOT : LW_ARRAY_SIZE
        | NEW_TYPE_COUNT := NEW_TYPE_COUNT[?] + integer(LW_NEW_TYPE_SLOT >= 0)
        | LW_INTERNED := if LK_FOUND then LK_VALUE else LW_NEW_TYPE
        | LW_IOTA_TABLE := LW_IOTA[?][LW_INTERNED] - 1
        | LW_NEW_TABLE := TABLE_COUNT + NEW_TABLE_COUNT[?]
        | LW_TABLE_FULL := LW_IS_INDICES and LW_IOTA_TABLE < 0 and NEW_TABLE_COUNT[?] >= NEW_TABLE_CAP
        | LW_LOOP_SIGNAL := LK_VALUE
        | LW_LOOP_TYPE := ROWS_TYPE[?][LW_LOOP_SIGNAL]
        | LW_LOOP_UNDECLARED := LW_LOOP_LIVE and not LK_FOUND
        | LW_LOOP_NOT_INDEX := LW_LOOP_LIVE and not (TYPE_KIND[LW_LOOP_TYPE] = TK_ARRAY and TYPE_KIND[TYPE_ELEMENT[LW_LOOP_TYPE]] = TK_INT)
        | LW_INDEX_DEFINED := LW_EQ_STEP = 0 and LW_LOOP_DEFINES and LW_EQ_TARGET = LW_EQ_LOOP_NAME
                              and LW_EQ_TARGET_INSTANCE = LW_EQ_LOOP_INSTANCE
        | LW_TARGET_UNDECLARED := LW_EQ_STEP = 0 and LW_LOOP_DEFINES and not LK_FOUND
        | LW_START_SEED_FAILS := LW_START_LOOKS and not LK_FOUND
        | LW_START_DEFINES := LW_START_LIVE and not LW_EQ_SEED and LW_EQ_TARGET >= 0
        | LW_START_UNDECLARED := LW_START_DEFINES and LW_START_SIGNAL < 0
        | LW_START_INPUT := LW_START_DEFINES and ROWS_OP[?][LW_START_SIGNAL] = OP_INPUT
        | LW_START_TWICE := LW_START_DEFINES and SIGNAL_TOP[?][LW_START_SIGNAL] > 0
        | LW_SCAN_FAILS := LW_SCAN_READS and LK_FOUND
        | LW_SIGNAL_FOUND := LW_LOOKS_SIGNAL and LK_FOUND
        | LW_CONSTANT := NAME_CONSTANT[LW_NAME] - 1
        | LW_FROM_CONSTANT := LW_LOOKS_SIGNAL and not LK_FOUND and LW_INST = 0 and LW_CONSTANT >= 0
        | LW_SIGNAL_UNDECLARED := LW_LOOKS_SIGNAL and not LK_FOUND and not LW_FROM_CONSTANT
        | LW_ENUM_UNDECLARED := LW_ENUM_LIVE and not LW_ENUM_NAMED and LW_ENUM_HOLDERS = 0
        | LW_ENUM_AMBIGUOUS := LW_ENUM_LIVE and not LW_ENUM_NAMED and LW_ENUM_HOLDERS > 1
        | LW_ENUM_TYPE_UNDECLARED := LW_ENUM_LIVE and LW_ENUM_NAMED and LW_ENUM_NAMED_TYPE < 0
        | LW_ENUM_NO_VALUE := LW_ENUM_LIVE and not LK_FOUND
        | LW_ENUM_ARGUMENT0 := if LW_ENUM_MESSAGE = T_ENUM_UNDECLARED or LW_ENUM_MESSAGE = T_ENUM_AMBIGUOUS then LW_ENUM_VALUE_KEY
                               else LW_ENUM_TYPE_KEY
        | LW_ENUM_MESSAGE := if LW_ENUM_UNDECLARED then T_ENUM_UNDECLARED else if LW_ENUM_AMBIGUOUS then T_ENUM_AMBIGUOUS
                             else if LW_ENUM_TYPE_UNDECLARED then T_TYPE_UNDECLARED else if LW_ENUM_NO_VALUE then T_NO_VALUE else 0
        | FX_STEP := LW_FX_STEP[?]
        | FX_COUNT := integer(FINAL_VALUE[LW_SRC])
        | FX_PARAMS := FINAL_AUX2[LW_SRC]
        | FX_P0 := FINAL_AUX[LW_SRC]
        | FX_P1 := FX_P0 + 2
        | FX_KEY0 := TOKEN_NAME[FX_P0] - 1
        | FX_KEY1 := TOKEN_NAME[FX_P1] - 1
        | FX_TYPE0 := if FX_KEY0 < 0 then -1 else if FX_KEY0 < BUILTIN_TYPE_COUNT then FX_KEY0 else if NAME_TYPE[FX_KEY0] > 0 then NAME_TYPE[FX_KEY0] - 1 else NAME_ALIAS[FX_KEY0] - 1
        | FX_TYPE1 := if FX_KEY1 < 0 then -1 else if FX_KEY1 < BUILTIN_TYPE_COUNT then FX_KEY1 else if NAME_TYPE[FX_KEY1] > 0 then NAME_TYPE[FX_KEY1] - 1 else NAME_ALIAS[FX_KEY1] - 1
        | FX_IS_LOAD := LW_NAME = N_LOAD
        | FX_IS_STORE := LW_NAME = N_STORE
        | FX_IS_SYSCALL := LW_NAME = N_SYSCALL
        | FX_IS_INSTRUCTION := LW_NAME = N_INSTRUCTION
        | FX_EXPECTED := if FX_IS_SYSCALL then 1 else 2
        | FX_CONSTANT1 := NAME_CONSTANT[FX_KEY1] - 1
        | FX_NUMBER1 := TOKEN_KIND[FX_P1] = ubyte(KIND_NUMBER)
        | FX_WORD_CONSTANT := FX_CONSTANT1 >= 0 and TYPE_KIND[CONSTANT_TYPE[FX_CONSTANT1]] = TK_INT
        | FX_WORD := if FX_NUMBER1 then TOKEN_VALUE[FX_P1] else CONSTANT_VALUE[FX_CONSTANT1]
        | FX_WORD_BIG := FX_NUMBER1 and TOKEN_BIG[FX_P1] or FX_WORD < long(0) or FX_WORD >= long(4294967296)
        | FX_CHECKS := LW_IS_EFFECT and FX_STEP = 0
        | FX_BASE := LW_TOP_NOW - FX_COUNT
        | FX_O0 := LW_STACK[?][FX_BASE]
        | FX_O1 := LW_STACK[?][FX_BASE + 1]
        | FX_O2 := LW_STACK[?][FX_BASE + 2]
        | FX_O3 := LW_STACK[?][FX_BASE + 3]
        | FX_O4 := LW_STACK[?][FX_BASE + 4]
        | FX_O5 := LW_STACK[?][FX_BASE + 5]
        | FX_O6 := LW_STACK[?][FX_BASE + 6]
        | FX_PAIR_AT := if FX_COUNT > 0 and ROWS_OP[?][FX_O0] = OP_PAIR then FX_O0
                        else if FX_COUNT > 1 and ROWS_OP[?][FX_O1] = OP_PAIR then FX_O1
                        else if FX_COUNT > 2 and ROWS_OP[?][FX_O2] = OP_PAIR then FX_O2
                        else if FX_COUNT > 3 and ROWS_OP[?][FX_O3] = OP_PAIR then FX_O3
                        else if FX_COUNT > 4 and ROWS_OP[?][FX_O4] = OP_PAIR then FX_O4
                        else if FX_COUNT > 5 and ROWS_OP[?][FX_O5] = OP_PAIR then FX_O5
                        else if FX_COUNT > 6 and ROWS_OP[?][FX_O6] = OP_PAIR then FX_O6 else -1
        | FX_T0 := ROWS_TYPE[?][FX_O0]
        | FX_T1 := ROWS_TYPE[?][FX_O1]
        | FX_T2 := ROWS_TYPE[?][FX_O2]
        | FX_T3 := ROWS_TYPE[?][FX_O3]
        | FX_T4 := ROWS_TYPE[?][FX_O4]
        | FX_T5 := ROWS_TYPE[?][FX_O5]
        | FX_T6 := ROWS_TYPE[?][FX_O6]
        | FX_K0 := if FX_T0 >= TYPE_COUNT then TK_ARRAY else TYPE_KIND[FX_T0]
        | FX_K1 := if FX_T1 >= TYPE_COUNT then TK_ARRAY else TYPE_KIND[FX_T1]
        | FX_K2 := if FX_T2 >= TYPE_COUNT then TK_ARRAY else TYPE_KIND[FX_T2]
        | FX_K3 := if FX_T3 >= TYPE_COUNT then TK_ARRAY else TYPE_KIND[FX_T3]
        | FX_K4 := if FX_T4 >= TYPE_COUNT then TK_ARRAY else TYPE_KIND[FX_T4]
        | FX_K5 := if FX_T5 >= TYPE_COUNT then TK_ARRAY else TYPE_KIND[FX_T5]
        | FX_K6 := if FX_T6 >= TYPE_COUNT then TK_ARRAY else TYPE_KIND[FX_T6]
        | FX_SYSCALL_AT := if FX_K0 /= TK_INT and FX_K0 /= TK_POINTER then 0
                           else if FX_K1 /= TK_INT and FX_K1 /= TK_POINTER then 1
                           else if FX_K2 /= TK_INT and FX_K2 /= TK_POINTER then 2
                           else if FX_K3 /= TK_INT and FX_K3 /= TK_POINTER then 3
                           else if FX_K4 /= TK_INT and FX_K4 /= TK_POINTER then 4
                           else if FX_K5 /= TK_INT and FX_K5 /= TK_POINTER then 5
                           else if FX_K6 /= TK_INT and FX_K6 /= TK_POINTER then 6 else -1
        | FX_SYSCALL_TYPE := if FX_SYSCALL_AT = 0 then FX_T0 else if FX_SYSCALL_AT = 1 then FX_T1 else if FX_SYSCALL_AT = 2 then FX_T2
                             else if FX_SYSCALL_AT = 3 then FX_T3 else if FX_SYSCALL_AT = 4 then FX_T4
                             else if FX_SYSCALL_AT = 5 then FX_T5 else FX_T6
        | FX_ROW_TYPE := if FX_IS_LOAD then FX_TYPE1 else if FX_IS_STORE then BUILTIN_EVENT
                         else if FX_IS_SYSCALL then BUILTIN_LONG else BUILTIN_ULONG
        | FX_MESSAGE := if FX_IS_SYSCALL and PLATFORM = PLATFORM_VIRT then T_SYSCALL_VIRT
                        else if FX_IS_SYSCALL and PLATFORM = PLATFORM_MPS2 then T_SYSCALL_MPS2
                        else if FX_PARAMS /= FX_EXPECTED then T_STATIC_COUNT
                        else if FX_TYPE0 < 0 then T_TYPE_UNDECLARED_TEXT
                        else if TYPE_KIND[FX_TYPE0] /= TK_EXTERNAL then T_RESOURCE_EXTERNAL
                        else if (FX_IS_LOAD or FX_IS_STORE) and FX_TYPE1 < 0 then T_TYPE_UNDECLARED_TEXT
                        else if (FX_IS_LOAD or FX_IS_STORE) and TYPE_KIND[FX_TYPE1] /= TK_INT and TYPE_KIND[FX_TYPE1] /= TK_POINTER
                        then T_ACCESS_TYPE
                        else if FX_IS_INSTRUCTION and not FX_NUMBER1 and not FX_WORD_CONSTANT then T_WORD_CONSTANT
                        else if FX_IS_INSTRUCTION and FX_WORD_BIG then T_WORD_RANGE
                        else if FX_PAIR_AT >= 0 then T_PAIR_OPERAND
                        else if (FX_IS_LOAD or FX_IS_STORE) and FX_T0 /= BUILTIN_POINTER then T_INPUT_POINTER
                        else if FX_IS_STORE and not LUB_SUBTYPE then T_STORE_TYPE
                        else if FX_IS_SYSCALL and FX_SYSCALL_AT >= 0 then T_SYSCALL_INPUT
                        else if FX_IS_INSTRUCTION and not LUB_SUBTYPE then T_INSTRUCTION_INPUT else 0
        | FX_TOKEN := if FX_MESSAGE = T_PAIR_OPERAND then ROWS_TOKEN[?][FX_PAIR_AT]
                      else if FX_MESSAGE = T_TYPE_UNDECLARED_TEXT and FX_TYPE0 >= 0 or FX_MESSAGE = T_ACCESS_TYPE
                              or FX_MESSAGE = T_WORD_CONSTANT or FX_MESSAGE = T_WORD_RANGE then FX_P1
                      else if FX_MESSAGE = T_TYPE_UNDECLARED_TEXT or FX_MESSAGE = T_RESOURCE_EXTERNAL then FX_P0
                      else LW_ENTRY_TOKEN
        | FX_ARGUMENT0 := if FX_MESSAGE = T_TYPE_UNDECLARED_TEXT then FX_TOKEN else if FX_MESSAGE = T_STORE_TYPE then FX_TYPE1
                          else if FX_MESSAGE = T_SYSCALL_INPUT then FX_SYSCALL_AT + 1
                          else if FX_MESSAGE = T_INSTRUCTION_INPUT then FX_T0 else LW_NAME
        | FX_ARGUMENT1 := if FX_MESSAGE = T_STATIC_COUNT then FX_EXPECTED else if FX_MESSAGE = T_ACCESS_TYPE then FX_P1
                          else if FX_MESSAGE = T_INPUT_POINTER then FX_T0 else if FX_MESSAGE = T_STORE_TYPE then FX_T1
                          else FX_SYSCALL_TYPE
        | FX_EMITS_ARG := LW_IS_EFFECT and FX_STEP > 0 and FX_STEP <= FX_COUNT
        | FX_EMITS_EFFECT := LW_IS_EFFECT and FX_STEP > FX_COUNT
        | FX_OPERAND := LW_STACK[?][LW_TOP_NOW - FX_STEP]
        | FX_PREVIOUS := LW_FX_PREVIOUS[?]
        | LW_NOT_IN_ITERATE := LW_LOOP_NOW >= 0 and (LW_OP = OP_WHEN or LW_OP = OP_UWHEN or LW_OP = OP_DEFAULT or LW_OP = OP_DELAY
                                                   or LW_OP = OP_CLOCK or LW_OP = OP_RANGE)
        | LW_LEFT_ARRAY_VALUE := LW_LEFT_OP = OP_GATHER or LW_LEFT_OP = OP_NEXT or LW_LEFT_OP = OP_RANGE
        | LW_RIGHT_ARRAY_VALUE := LW_RIGHT >= 0 and (LW_RIGHT_OP = OP_GATHER or LW_RIGHT_OP = OP_NEXT or LW_RIGHT_OP = OP_RANGE)
        | LW_RIGHT_PAIR := LW_RIGHT >= 0 and LW_RIGHT_OP = OP_PAIR and LW_OP /= OP_NEXT
        | LW_PREV_MESSAGE := if LW_LEFT >= FLAT_SIGNAL_COUNT then T_PREV_SIGNAL else if LW_LOOP_NOW < 0 then T_PREV_OUTSIDE
                             else if not LK_FOUND then T_PREV_UNDEFINED else 0
        | LW_INDICES_FAILS := LW_LEFT_OP /= OP_CONST or not LT_INT or LW_INDICES_COUNT <= long(0)
        | LW_INDEXES := LW_OP = OP_INDEX or LW_OP = OP_NEXT
        | LW_INDEX_ROW := if LW_OP = OP_NEXT then ROWS_LEFT[?][LW_RIGHT] else LW_RIGHT
        | LW_INDEX_TYPE := ROWS_TYPE[?][LW_INDEX_ROW]
        | LW_INDEX_TOKEN := if LW_INDEX_ROW < FLAT_SIGNAL_COUNT then SIGNAL_DEF_TOKEN[?][LW_INDEX_ROW] - 1
                            else ROWS_TOKEN[?][LW_INDEX_ROW]
        | LW_INDEX_INT := LW_INDEX_TYPE < TYPE_COUNT and TYPE_KIND[LW_INDEX_TYPE] = TK_INT
        | LW_INDEX_VALUE := ROWS_VALUE[?][LW_INDEX_ROW]
        | LW_INDEX_OUTSIDE := ROWS_OP[?][LW_INDEX_ROW] = OP_CONST
                              and (LW_INDEX_TYPE /= BUILTIN_ULONG and LW_INDEX_VALUE < long(0) or ulong(LW_INDEX_VALUE) >= LT_SIZE)
        | LW_IS_NEXT := LW_OP = OP_NEXT
        | LW_FROM_REPEAT := integer(TOKEN_CODE[LW_ENTRY_TOKEN]) = C_BAR_STAR
        | LW_RANGE_SIZE := if LW_LOOP_NOW >= 0 then LOOP_SIZE[?][LW_LOOP_NOW] else ulong(0)
        | LW_INDEX_SIGNAL_ROW := if ROWS_OP[?][LW_INDEX_ROW] = OP_ITER then ROWS_LEFT[?][LW_INDEX_ROW] else -1
        | LW_INDEX_DEF := if LW_INDEX_SIGNAL_ROW >= 0 then SIGNAL_TOP[?][LW_INDEX_SIGNAL_ROW] - 1 else -1
        | LW_INDEX_DEF_SAFE := if LW_INDEX_DEF >= 0 then LW_INDEX_DEF else 0
        | LW_INDEX_COUNTS := LW_INDEX_DEF >= 0
                             and (ROWS_OP[?][LW_INDEX_DEF_SAFE] = OP_RANGE
                                  and (integer(TOKEN_CODE[ROWS_TOKEN[?][LW_INDEX_DEF_SAFE]]) = C_BAR_STAR
                                       or integer(TOKEN_CODE[ROWS_TOKEN[?][LW_INDEX_DEF_SAFE] - 1]) = C_ARRAY)
                                  or ROWS_OP[?][LW_INDEX_DEF_SAFE] = OP_TABLE
                                     and long(LW_IOTA[?][ROWS_TYPE[?][LW_INDEX_DEF_SAFE]] - 1) = ROWS_VALUE[?][LW_INDEX_DEF_SAFE])
        | LW_RANGE_MISMATCH := LW_IS_NEXT and LW_LOOP_NOW >= 0 and LW_INDEX_COUNTS
                               and (if LW_FROM_REPEAT then LW_RANGE_SIZE /= LT_SIZE else LW_RANGE_SIZE > LT_SIZE)
        | LW_CALL_TYPE := if LW_NAME < BUILTIN_TYPE_COUNT then LW_NAME else if NAME_TYPE[LW_NAME] > 0 then NAME_TYPE[LW_NAME] - 1
                          else NAME_ALIAS[LW_NAME] - 1
        | LW_CALL_KIND := TYPE_KIND[LW_CALL_TYPE]
        | LW_CONVERTS := LT = LW_CALL_TYPE
                         or LW_CALL_KIND = TK_INT and (LT_INT or LT_KIND = TK_BOOLEAN or LT_KIND = TK_ENUM)
                         or LW_CALL_TYPE = BUILTIN_POINTER and (LT = BUILTIN_ULONG or LT = BUILTIN_UINTEGER)
                         or LT = BUILTIN_POINTER and (LW_CALL_TYPE = BUILTIN_ULONG or LW_CALL_TYPE = BUILTIN_UINTEGER)
        | LW_INTEGER_OP := LW_OP = OP_ADD or LW_OP = OP_SUB or LW_OP = OP_MUL or LW_OP = OP_DIV or LW_OP = OP_MOD or LW_OP = OP_NEG
        | LW_COMPARE_OP := LW_OP = OP_EQ or LW_OP = OP_NE or LW_OP = OP_LT or LW_OP = OP_LE or LW_OP = OP_GT or LW_OP = OP_GE
        | LW_LOGIC_OP := LW_OP = OP_AND or LW_OP = OP_OR or LW_OP = OP_XOR or LW_OP = OP_NOT
        | LW_SHIFT_OP := LW_OP = OP_SHL or LW_OP = OP_SHR
        | LW_POINTER_ARITHMETIC := (LW_OP = OP_ADD or LW_OP = OP_SUB) and (LT = BUILTIN_POINTER or RT = BUILTIN_POINTER)
        | LW_IF_EFFECT := FIRST_EFFECT[?][LW_RIGHT] - 1
        | LW_INITIAL_TYPE := if LW_INITIAL = 1 then FINAL_TYPE[LW_SRC] else LW_ENUM_TYPE
        | LW_INITIAL_VALUE := if LW_INITIAL = 1 then FINAL_VALUE[LW_SRC] else long(LK_VALUE)
        | LW_OPERATOR_MESSAGE := if LW_NOT_IN_ITERATE then T_NOT_IN_ITERATE
                                 else if LW_LEFT_OP = OP_PAIR then T_PAIR_OPERAND
                                 else if LW_LEFT_ARRAY_VALUE then T_ARRAY_VALUE
                                 else if LW_RIGHT_PAIR then T_PAIR_OPERAND
                                 else if LW_RIGHT_ARRAY_VALUE then T_ARRAY_VALUE
                                 else if LW_IS_PREV and LW_PREV_MESSAGE /= 0 then LW_PREV_MESSAGE
                                 else if LW_IS_INDICES and LW_INDICES_FAILS then T_INDICES_CONSTANT
                                 else if LW_IS_INDICES then 0
                                 else if LW_INDEXES and LT_KIND /= TK_ARRAY then T_NOT_ARRAY
                                 else if LW_OP = OP_RANGE then
                                   (if LW_LEFT_OP /= OP_CONST or LW_LEFT_VALUE /= long(0) or not LT_INT then T_RANGE_START
                                    else if not RT_INT then T_RANGE_BOUND else 0)
                                 else if LW_OP = OP_PREV then 0
                                 else if LW_IS_GATHER then (if TYPE_KIND[RT_ELEMENT] /= TK_INT then T_INDEX_INTEGER else 0)
                                 else if LW_INDEXES then
                                   (if LW_IS_NEXT and LW_RIGHT_OP /= OP_PAIR then T_NEXT_PAIR
                                    else if not LW_INDEX_INT then T_INDEX_INTEGER
                                    else if LW_INDEX_OUTSIDE then T_INDEX_RANGE
                                    else if LW_RANGE_MISMATCH then (if LW_FROM_REPEAT then T_REPEAT_SIZE else T_RANGE_FIT)
                                    else if LW_IS_NEXT and not LUB_SUBTYPE then
                                      (if LW_FROM_REPEAT then T_REPEAT_TYPE else T_NEXT_TYPE)
                                    else 0)
                                 else if LW_OP = OP_DELAY and LW_ARRAY_OPERAND then T_DELAY_ARRAY
                                 else if LW_ARRAY_OPERAND and LW_OP /= OP_CALL then T_SCALAR_OPERANDS
                                 else if LW_OP = OP_PAIR then 0
                                 else if LW_OP = OP_BRANCH then (if LUB < 0 then T_IF_TYPES else 0)
                                 else if LW_OP = OP_IF then
                                   (if not LT_LOGICAL then T_IF_CONDITION else if LW_IF_EFFECT >= 0 then T_EFFECT_IN_IF else 0)
                                 else if LW_OP = OP_CALL then (if LW_CONVERTS then 0 else T_NO_CONVERSION)
                                 else if LW_POINTER_ARITHMETIC then
                                   (if LT /= BUILTIN_POINTER or not RT_INT then T_POINTER_OFFSET else 0)
                                 else if LW_FROM_ABS and not (LT_INT and TYPE_SIGNED[LT]) then T_ABS_SIGNED
                                 else if LW_INTEGER_OP then
                                   (if not (LT_INT and RT_INT) then T_INTEGER_OPERANDS else if LUB < 0 then T_COMPARABLE else 0)
                                 else if LW_COMPARE_OP then
                                   (if LUB >= 0 then 0 else if LT_INT and RT_INT then T_COMPARABLE else T_ONE_TYPE)
                                 else if LW_LOGIC_OP then
                                   (if LT_LOGICAL and RT_LOGICAL then 0 else if not (LT_INT and RT_INT) then T_BOOLEAN_OPERANDS
                                    else if TYPE_SIGNED[LT] or TYPE_SIGNED[RT] then T_UNSIGNED_OPERANDS else 0)
                                 else if LW_SHIFT_OP then
                                   (if LT_INT and not TYPE_SIGNED[LT] and RT_INT then 0 else T_UNSIGNED_OPERANDS)
                                 else if LW_OP = OP_WHEN then (if RT_LOGICAL then 0 else T_WHEN_CONDITION)
                                 else if LW_OP = OP_UWHEN then (if LT_LOGICAL then 0 else T_WHEN_CONDITION)
                                 else if LW_OP = OP_DEFAULT then (if LUB < 0 then T_ONE_TYPE else 0)
                                 else if LW_OP = OP_CLOCK then (if LW_COUNTER_OP >= 0 and LT /= BUILTIN_EVENT then T_COUNTER_EVENT else 0)
                                 else if LW_INITIAL = 2 and LW_ENUM_MESSAGE /= 0 then LW_ENUM_MESSAGE
                                 else if LW_INITIAL /= 0 and (LT = BUILTIN_EVENT or not LUB_SUBTYPE) then T_DELAY_MATCH else 0
        | LW_OPERATOR_TOKEN := if LW_OPERATOR_MESSAGE = T_PAIR_OPERAND then
                                 (if LW_LEFT_OP = OP_PAIR then ROWS_TOKEN[?][LW_LEFT] else ROWS_TOKEN[?][LW_RIGHT])
                               else if LW_OPERATOR_MESSAGE = T_EFFECT_IN_IF then ROWS_TOKEN[?][LW_IF_EFFECT]
                               else if LW_INDEXES and not LW_IS_GATHER and (LW_OPERATOR_MESSAGE = T_INDEX_INTEGER
                                                                         or LW_OPERATOR_MESSAGE = T_INDEX_RANGE)
                               then LW_INDEX_TOKEN
                               else if LW_OPERATOR_MESSAGE = LW_ENUM_MESSAGE then LW_ENUM_TOKEN
                               else LW_ENTRY_TOKEN
        | LW_OP_TEXT := OP_TEXT_FRAGMENT[LW_OP]
        | LW_COUNTER_OP := if integer(TOKEN_CODE[LW_ENTRY_TOKEN]) = C_AFTER then OP_AFTER else if integer(TOKEN_CODE[LW_ENTRY_TOKEN]) = C_FROM then OP_FROM
                           else if integer(TOKEN_CODE[LW_ENTRY_TOKEN]) = C_COUNT then OP_COUNT else -1
        | LW_FROM_ABS := LW_OP = OP_LT and integer(TOKEN_CODE[LW_ENTRY_TOKEN]) = C_NAME and TOKEN_NAME[LW_ENTRY_TOKEN] - 1 = N_ABS
        | LW_OPERATOR_ARGUMENT0 := if LW_OPERATOR_MESSAGE = T_PREV_OUTSIDE or LW_OPERATOR_MESSAGE = T_PREV_UNDEFINED
                                   then LW_SIGNAL_KEY[?][LW_LEFT]
                                   else if LW_OPERATOR_MESSAGE = T_NEXT_TYPE or LW_OPERATOR_MESSAGE = T_REPEAT_TYPE then LT_ELEMENT
                                   else if LW_OPERATOR_MESSAGE = T_IF_TYPES or LW_OPERATOR_MESSAGE = T_NO_CONVERSION
                                           or LW_OPERATOR_MESSAGE = T_ABS_SIGNED then LT
                                   else if LW_OPERATOR_MESSAGE = T_EFFECT_IN_IF then EFFECT_KIND[?][integer(ROWS_VALUE[?][LW_IF_EFFECT])]
                                   else if LW_OPERATOR_MESSAGE = LW_ENUM_MESSAGE then LW_ENUM_ARGUMENT0
                                   else if LW_OPERATOR_MESSAGE = T_COUNTER_EVENT then OP_TEXT_FRAGMENT[LW_COUNTER_OP]
                                   else if LW_OPERATOR_MESSAGE = T_REPEAT_SIZE or LW_OPERATOR_MESSAGE = T_RANGE_FIT then integer(LW_RANGE_SIZE)
                                   else LW_OP_TEXT
        | LW_OPERATOR_ARGUMENT1 := if LW_OPERATOR_MESSAGE = T_NEXT_TYPE or LW_OPERATOR_MESSAGE = T_REPEAT_TYPE or LW_OPERATOR_MESSAGE = T_IF_TYPES then RT
                                   else if LW_OPERATOR_MESSAGE = T_NO_CONVERSION then LW_CALL_TYPE
                                   else if LW_OPERATOR_MESSAGE = T_REPEAT_SIZE or LW_OPERATOR_MESSAGE = T_RANGE_FIT then integer(LT_SIZE)
                                   else if LW_OPERATOR_MESSAGE = T_NO_VALUE then LW_ENUM_VALUE_KEY else LT
        | LUB_A := if LW_FINISHING then LW_END_TYPE
                   else if FX_CHECKS then (if FX_IS_STORE then FX_T1 else FX_T0)
                   else if LW_IS_NEXT then RT
                   else if LW_IS_DELAY then LW_INITIAL_TYPE else LT
        | LUB_B := if LW_FINISHING then LW_END_SIGNAL_TYPE
                   else if FX_CHECKS then (if FX_IS_STORE then FX_TYPE1 else BUILTIN_ULONG)
                   else if LW_IS_NEXT then LT_ELEMENT
                   else if LW_IS_DELAY then LT else RT
        | LUB_A_KIND := if LUB_A >= TYPE_COUNT then TK_ARRAY else TYPE_KIND[LUB_A]
        | LUB_B_KIND := if LUB_B >= TYPE_COUNT then TK_ARRAY else TYPE_KIND[LUB_B]
        | LUB_A_BYTES := TYPE_BYTES[LUB_A]
        | LUB_B_BYTES := TYPE_BYTES[LUB_B]
        | LUB_A_SIGNED := TYPE_SIGNED[LUB_A]
        | LUB_B_SIGNED := TYPE_SIGNED[LUB_B]
        | LUB_UNSIGNED_BYTES := if LUB_A_SIGNED then LUB_B_BYTES else LUB_A_BYTES
        | LUB_SIGNED_BYTES := if LUB_A_SIGNED then LUB_A_BYTES else LUB_B_BYTES
        | LUB_SIGNED := if LUB_A_SIGNED then LUB_A else LUB_B
        | LUB_WIDENED := if LUB_UNSIGNED_BYTES = 1 then BUILTIN_SHORT else if LUB_UNSIGNED_BYTES = 2 then BUILTIN_INTEGER
                         else if LUB_UNSIGNED_BYTES = 4 then BUILTIN_LONG else -1
        | LUB := if LUB_A = LUB_B then LUB_A
                 else if (LUB_A_KIND = TK_EVENT or LUB_A_KIND = TK_BOOLEAN) and (LUB_B_KIND = TK_EVENT or LUB_B_KIND = TK_BOOLEAN)
                 then BUILTIN_BOOLEAN
                 else if LUB_A_KIND /= TK_INT or LUB_B_KIND /= TK_INT then -1
                 else if LUB_A_SIGNED = LUB_B_SIGNED then (if LUB_A_BYTES > LUB_B_BYTES then LUB_A else LUB_B)
                 else if LUB_SIGNED_BYTES > LUB_UNSIGNED_BYTES then LUB_SIGNED else LUB_WIDENED
        | LUB_SUBTYPE := LUB = LUB_B
        | LW_RESULT_OP := if LW_IS_ITER then OP_ITER else if LW_FROM_CONSTANT then
                            (if TYPE_KIND[CONSTANT_TYPE[LW_CONSTANT]] = TK_ARRAY then OP_TABLE else OP_CONST)
                          else if LW_IS_CONST or LW_IS_ENUM then OP_CONST
                          else if LW_IS_GATHER then OP_GATHER
                          else if LW_OP = OP_INDEX then OP_ELEMENT
                          else if LW_OP = OP_CALL then OP_CONVERT else LW_OP
        | LW_RESULT_TYPE := if LW_IS_ITER then TYPE_ELEMENT[ROWS_TYPE[?][LOOP_INDEX[?][LW_LOOP_NOW]]]
                            else if LW_FROM_CONSTANT then CONSTANT_TYPE[LW_CONSTANT]
                            else if LW_IS_CONST then FINAL_TYPE[LW_SRC]
                            else if LW_IS_ENUM then LW_ENUM_TYPE
                            else if LW_OP = OP_RANGE or LW_OP = OP_PREV or LW_IS_NEXT or LW_SHIFT_OP or LW_IS_DELAY
                                    or LW_OP = OP_WHEN or LW_POINTER_ARITHMETIC then LT
                            else if LW_IS_GATHER then LW_INTERNED
                            else if LW_OP = OP_INDEX then LT_ELEMENT
                            else if LW_OP = OP_PAIR or LW_OP = OP_IF or LW_OP = OP_MOD then RT
                            else if LW_OP = OP_CALL then LW_CALL_TYPE
                            else if LW_COMPARE_OP then BUILTIN_BOOLEAN
                            else if LW_LOGIC_OP and LT_LOGICAL and RT_LOGICAL then BUILTIN_BOOLEAN
                            else if LW_OP = OP_UWHEN or LW_OP = OP_CLOCK then BUILTIN_EVENT else LUB
        | LW_RESULT_VALUE := if LW_FROM_CONSTANT then CONSTANT_VALUE[LW_CONSTANT]
                             else if LW_IS_CONST then FINAL_VALUE[LW_SRC]
                             else if LW_IS_ENUM then long(LK_VALUE)
                             else if LW_IS_DELAY then
                               (if LT = BUILTIN_EVENT then long(1) else if LW_INITIAL /= 0 then LW_INITIAL_VALUE else long(0))
                             else long(0)
        | LW_END_TOP := LW_STACK[?][LW_TOP_NOW - 1]
        | LW_END_TOP_OP := ROWS_OP[?][LW_END_TOP]
        | LW_END_TOP_TYPE := ROWS_TYPE[?][LW_END_TOP]
        | LW_MEMBER_NOW := LW_FL_MEMBER[?]
        | LW_SIGNAL_NOW := LW_FL_OWNER[?]
        | LW_END_SIGNAL_TYPE := ROWS_TYPE[?][LW_SIGNAL_NOW]
        | LW_END_SEED := LW_FINISHING and not LW_MEMBER_NOW and LW_EQ_SEED
        | LW_END_DEFINES := LW_FINISHING and not LW_MEMBER_NOW and not LW_EQ_SEED and LW_SIGNAL_NOW >= 0
        | LW_END_RANGE := LW_END_DEFINES and LW_END_TOP_OP = OP_RANGE
        | LW_END_TYPE := if LW_END_RANGE then LW_END_SIGNAL_TYPE else LW_END_TOP_TYPE
        | LW_END_SIGNAL_ARRAY := TYPE_KIND[LW_END_SIGNAL_TYPE] = TK_ARRAY
        | LW_END_MESSAGE := if LW_END_TOP_OP = OP_PAIR then T_PAIR_OPERAND
                            else if LW_END_SEED and LW_END_SIGNAL_ARRAY
                                    and not (LW_END_TOP_OP = OP_TABLE or LW_END_TOP < FLAT_SIGNAL_COUNT and LW_END_TOP_TYPE = LW_END_SIGNAL_TYPE)
                            then T_WITH_ARRAY
                            else if LW_END_RANGE and not (LW_END_SIGNAL_ARRAY and TYPE_KIND[TYPE_ELEMENT[LW_END_SIGNAL_TYPE]] = TK_INT)
                            then T_RANGE_DEFINES
                            else if (LW_END_SEED or LW_END_DEFINES) and not LUB_SUBTYPE then T_SIGNAL_TYPE
                            else if LW_END_DEFINES and LW_END_SIGNAL_ARRAY and LW_END_TOP_OP /= OP_TABLE and LW_END_TOP_OP /= OP_GATHER
                                    and LW_END_TOP_OP /= OP_NEXT and LW_END_TOP_OP /= OP_RANGE
                            then T_ARRAY_DEFINITION else 0
        | LW_NEVER_LIVE := AT_LS_NEVER and LW_I < FLAT_SIGNAL_COUNT
        | LW_NEVER_FAILS := LW_NEVER_LIVE and SIGNAL_TOP[?][LW_I] = 0 and ROWS_OP[?][LW_I] /= OP_INPUT
        | LW_MEMBERS_LIVE := AT_LS_MEMBERS and LW_I < FLAT_GROUP_COUNT
        | LW_MEMBER_STARTS := LW_MEMBERS_LIVE and LW_K < FLAT_GROUP_MEMBER_TOTAL[LW_I]
        | LW_MEMBERS_CLOSE := LW_MEMBERS_LIVE and not LW_MEMBER_STARTS
        | LW_MEMBER_INDEX := FLAT_GROUP_MEMBER_FIRST[LW_I] + LW_K
        | LW_GROUP_FAILS := LW_MEMBERS_CLOSE and LW_GROUP_ARRAY[?]
        | LW_CREATES := LW_SIGNAL_LIVE or LW_IS_ITER or LW_FROM_CONSTANT or LW_IS_CONST or LW_IS_ENUM
                        or LW_OPERATOR and not LW_IS_INDICES or FX_EMITS_ARG or FX_EMITS_EFFECT or LW_END_SEED
        | LW_PUSHES := LW_IS_SIGNAL or LW_IS_CONST or LW_IS_ENUM
        | LW_ROW := ROW_COUNT[?]
        | LW_OVERFLOW := if LK_LIVE and LK_UNSURE or LK_FULL then F_CAP_LOOKUPS
                         else if LW_TYPE_FULL then F_CAP_TYPES
                         else if LW_TABLE_FULL then F_CAP_TABLES
                         else if LW_CREATES and LW_ROW >= ROWS_CAP then F_CAP_ROWS
                         else if LW_PUSHES and LW_TOP_NOW >= LOWER_STACK_CAP then F_CAP_STACK else 0
        | LW_MESSAGE_NOW := if LW_LOOP_UNDECLARED then T_FLAT_UNDECLARED
                            else if LW_LOOP_NOT_INDEX then T_ITERATE_INDEX
                            else if LW_INDEX_DEFINED then T_INDEX_DEFINED
                            else if LW_TARGET_UNDECLARED then T_FLAT_UNDECLARED
                            else if LW_START_SEED_FAILS then T_WITH_UNDEFINED
                            else if LW_START_UNDECLARED then T_FLAT_UNDECLARED
                            else if LW_START_INPUT then T_INPUT_DEFINED
                            else if LW_START_TWICE then T_DEFINED_TWICE
                            else if LW_SCAN_FAILS then T_WITH_READS
                            else if LW_SIGNAL_UNDECLARED then T_FLAT_UNDECLARED
                            else if LW_IS_ENUM and LW_ENUM_MESSAGE /= 0 then LW_ENUM_MESSAGE
                            else if FX_CHECKS and FX_MESSAGE /= 0 then FX_MESSAGE
                            else if LW_OPERATOR and LW_OPERATOR_MESSAGE /= 0 then LW_OPERATOR_MESSAGE
                            else if LW_FINISHING and LW_END_MESSAGE /= 0 then LW_END_MESSAGE
                            else if LW_NEVER_FAILS then T_NEVER_DEFINED
                            else if LW_GROUP_FAILS then T_ARRAY_VALUE
                            else if LW_OVERFLOW /= 0 then T_CAPACITY else 0
        | LW_FAILS := LW_MESSAGE_NOW /= 0
        | LW_START_TOKEN := LW_FL_TOKEN[?]
        | LW_TOKEN_NOW := if LW_LOOP_LIVE then LOOP_TOKEN[LW_LOOP_SOURCE]
                          else if AT_LS_EQUATION or AT_LS_START or AT_LS_SCAN then LW_EQ_TOKEN
                          else if LW_IS_SIGNAL or LW_IS_ENUM then (if LW_IS_ENUM then LW_ENUM_TOKEN else LW_ENTRY_TOKEN)
                          else if FX_CHECKS then FX_TOKEN
                          else if LW_OPERATOR then LW_OPERATOR_TOKEN
                          else if LW_FINISHING and LW_END_TOP_OP = OP_PAIR then ROWS_TOKEN[?][LW_END_TOP]
                          else if LW_FINISHING then LW_START_TOKEN
                          else if LW_NEVER_LIVE then -1
                          else if LW_MEMBERS_LIVE then FLAT_GROUP_TOKEN[LW_I] else 0
        | LW_FLAT_KEY := if LW_LOOP_LIVE then LOOP_NAME[LW_LOOP_SOURCE]
                         else if AT_LS_EQUATION or AT_LS_START or AT_LS_SCAN or LW_FINISHING then LW_EQ_TARGET
                         else if LW_IS_SIGNAL then LW_NAME
                         else if LW_NEVER_LIVE then LW_SIGNAL_KEY[?][LW_I] else LW_SIGNAL_KEY[?][LW_LEFT]
        | LW_FLAT_INSTANCE := if LW_LOOP_LIVE then FLAT_LOOP_INSTANCE[LW_I]
                              else if AT_LS_EQUATION or AT_LS_START or AT_LS_SCAN or LW_FINISHING then LW_EQ_TARGET_INSTANCE
                              else if LW_IS_SIGNAL then LW_INST
                              else if LW_NEVER_LIVE then FLAT_SIGNAL_INSTANCE[LW_I] else LW_PREV_INSTANCE
        | LW_ARGUMENT0_NOW := if LW_MESSAGE_NOW = T_CAPACITY then LW_OVERFLOW
                              else if LW_IS_ENUM then LW_ENUM_ARGUMENT0
                              else if FX_CHECKS then FX_ARGUMENT0
                              else if LW_OPERATOR and LW_OPERATOR_MESSAGE /= T_INDEX_RANGE then LW_OPERATOR_ARGUMENT0
                              else LW_FLAT_KEY
        | LW_ARGUMENT1_NOW := if FX_CHECKS then FX_ARGUMENT1 else if LW_IS_ENUM then LW_ENUM_VALUE_KEY
                              else if LW_FINISHING then LW_END_SIGNAL_TYPE else LW_OPERATOR_ARGUMENT1
        | LW_ARGUMENT2_NOW := if FX_CHECKS then FX_PARAMS else if LW_FINISHING then LW_END_TYPE else RT
        | LW_MESSAGE := if LW_FAILS then LW_MESSAGE_NOW else LW_MESSAGE[?]
        | LW_TOKEN := if LW_FAILS then LW_TOKEN_NOW else LW_TOKEN[?]
        | LW_ARGUMENT0 := if LW_FAILS then LW_ARGUMENT0_NOW else LW_ARGUMENT0[?]
        | LW_ARGUMENT1 := if LW_FAILS then LW_ARGUMENT1_NOW else LW_ARGUMENT1[?]
        | LW_ARGUMENT2 := if LW_FAILS then LW_ARGUMENT2_NOW else LW_ARGUMENT2[?]
        | LW_INSTANCE := if LW_FAILS then LW_FLAT_INSTANCE else LW_INSTANCE[?]
        | LW_LONG0 := if LW_FAILS then LW_INDEX_VALUE else LW_LONG0[?]
        | LW_LONG0_UNSIGNED := if LW_FAILS then LW_INDEX_TYPE = BUILTIN_ULONG else LW_LONG0_UNSIGNED[?]
        | LW_LONG1 := if LW_FAILS then long(LT_SIZE - ulong(1)) else LW_LONG1[?]
        | LW_GOES := not LW_FAILS
        | LW_ROW_SLOT := if LW_CREATES and LW_GOES then LW_ROW else -1
        | LW_ROW_OP := if LW_SIGNAL_LIVE then (if LW_SIGNAL_INPUT then OP_INPUT else OP_COPY)
                       else if FX_EMITS_ARG then OP_ARG else if FX_EMITS_EFFECT then OP_EFFECT
                       else if LW_END_SEED then OP_SEED else LW_RESULT_OP
        | LW_ROW_LEFT := if LW_SIGNAL_LIVE then -1 else if LW_IS_ITER then LOOP_INDEX[?][LW_LOOP_NOW]
                         else if LW_IS_LEAF then -1 else if FX_EMITS_ARG then FX_OPERAND else if FX_EMITS_EFFECT then FX_PREVIOUS
                         else if LW_END_SEED then LW_END_TOP else LW_LEFT
        | LW_ROW_RIGHT := if LW_SIGNAL_LIVE or LW_IS_LEAF or FX_EMITS_EFFECT then -1 else if FX_EMITS_ARG then FX_PREVIOUS
                          else if LW_END_SEED then LW_SIGNAL_NOW else LW_RIGHT
        | LW_ROW_VALUE := if FX_EMITS_EFFECT then long(EFFECT_COUNT[?]) else if LW_SIGNAL_LIVE or FX_EMITS_ARG or LW_END_SEED then long(0)
                          else LW_RESULT_VALUE
        | LW_ROW_TYPE := if LW_SIGNAL_LIVE then LW_SIGNAL_TYPE_NOW else if FX_EMITS_ARG then ROWS_TYPE[?][FX_OPERAND]
                         else if FX_EMITS_EFFECT then FX_ROW_TYPE else if LW_END_SEED then LW_END_SIGNAL_TYPE else LW_RESULT_TYPE
        | LW_ROW_CTX := LW_ROW_OP = OP_CONST or LW_ROW_OP = OP_TABLE
                        or OP_MONOCHRONOUS[LW_ROW_OP] = 1 and ROWS_CTX[?][LW_ROW_LEFT] and (LW_ROW_RIGHT < 0 or ROWS_CTX[?][LW_ROW_RIGHT])
                        or LW_ROW_OP = OP_DEFAULT and ROWS_CTX[?][LW_ROW_LEFT]
        | LW_CARRIED_TOKEN := LW_CUR_TOKEN[?]
        | LW_ROW_TOKEN := if LW_SIGNAL_LIVE then -1 else if LW_IS_CONST or LW_IS_ENUM then LW_CARRIED_TOKEN
                          else if LW_END_SEED then LW_START_TOKEN else LW_ENTRY_TOKEN
        | LW_INDICES_REWRITES := LW_IS_INDICES and LW_GOES
        | LW_REWRITE_TABLE := if LW_IOTA_TABLE >= 0 then LW_IOTA_TABLE else LW_NEW_TABLE
        | LW_RANGE_REWRITES := LW_END_RANGE and LW_GOES
        | LW_NEVER_WRITES := LW_NEVER_LIVE and LW_GOES
        | ROWS_OP := ROWS_OP[?] next (if LW_INDICES_REWRITES then LW_LEFT else LW_ROW_SLOT)
                     : (if LW_INDICES_REWRITES then OP_TABLE else LW_ROW_OP)
        | ROWS_LEFT := ROWS_LEFT[?] next (if LW_NEVER_WRITES then LW_I else LW_ROW_SLOT)
                       : (if LW_NEVER_WRITES then SIGNAL_TOP[?][LW_I] - 1 else LW_ROW_LEFT)
        | ROWS_RIGHT := ROWS_RIGHT[?] next LW_ROW_SLOT : LW_ROW_RIGHT
        | ROWS_VALUE := ROWS_VALUE[?] next (if LW_INDICES_REWRITES then LW_LEFT else LW_ROW_SLOT)
                        : (if LW_INDICES_REWRITES then long(LW_REWRITE_TABLE) else LW_ROW_VALUE)
        | ROWS_TYPE := ROWS_TYPE[?] next (if LW_INDICES_REWRITES then LW_LEFT else if LW_RANGE_REWRITES then LW_END_TOP else LW_ROW_SLOT)
                       : (if LW_INDICES_REWRITES then LW_INTERNED else if LW_RANGE_REWRITES then LW_END_SIGNAL_TYPE else LW_ROW_TYPE)
        | ROWS_CTX := ROWS_CTX[?] next (if LW_INDICES_REWRITES then LW_LEFT else LW_ROW_SLOT) : LW_INDICES_REWRITES or LW_ROW_CTX
        | ROWS_TOKEN := ROWS_TOKEN[?] next (if LW_NEVER_WRITES then LW_I else LW_ROW_SLOT)
                        : (if LW_NEVER_WRITES then SIGNAL_DEF_TOKEN[?][LW_I] - 1 else LW_ROW_TOKEN)
        | ROWS_OWNER := ROWS_OWNER[?] next LW_ROW_SLOT : (if LW_SIGNAL_LIVE then LW_I else LW_SIGNAL_NOW)
        | ROWS_LOOP := ROWS_LOOP[?] next (if LW_NEVER_WRITES then LW_I else LW_ROW_SLOT)
                       : (if LW_NEVER_WRITES then SIGNAL_LOOP_MARK[?][LW_I] - 1 else if LW_END_SEED then LW_EQ_LOOP else LW_LOOP_NOW)
        | ROWS_GUARD := ROWS_GUARD[?] next (if LW_NEVER_WRITES then LW_I else LW_ROW_SLOT)
                        : (if LW_NEVER_WRITES then SIGNAL_DEF_GUARD[?][LW_I] - 1 else LW_FL_GUARD[?])
        | FIRST_EFFECT := FIRST_EFFECT[?] next LW_ROW_SLOT
                          : (if FX_EMITS_EFFECT then LW_ROW + 1 else if LW_SIGNAL_LIVE or LW_IS_LEAF then 0
                             else if FIRST_EFFECT[?][LW_ROW_RIGHT] > 0 then FIRST_EFFECT[?][LW_ROW_RIGHT]
                             else FIRST_EFFECT[?][LW_ROW_LEFT])
        | ROW_COUNT := LW_ROW + integer(LW_ROW_SLOT >= 0)
        | LW_SIGNAL_KEY := LW_SIGNAL_KEY[?] next (if LW_SIGNAL_LIVE then LW_I else -1) : LW_SIGNAL_KEY_NOW
        | LW_EFFECT_SLOT := if FX_EMITS_EFFECT and LW_GOES then EFFECT_COUNT[?] else -1
        | EFFECT_KIND := EFFECT_KIND[?] next LW_EFFECT_SLOT : LW_NAME
        | EFFECT_RESOURCE := EFFECT_RESOURCE[?] next LW_EFFECT_SLOT : FX_TYPE0
        | EFFECT_PARAM := EFFECT_PARAM[?] next LW_EFFECT_SLOT
                          : (if FX_IS_SYSCALL then long(-1) else if FX_IS_INSTRUCTION then FX_WORD else long(FX_TYPE1))
        | EFFECT_COUNT := EFFECT_COUNT[?] + integer(LW_EFFECT_SLOT >= 0)
        | LW_FX_PREVIOUS := if FX_EMITS_ARG then LW_ROW else if LW_IS_EFFECT then FX_PREVIOUS else -1
        | LW_FX_STEP := if LW_IS_EFFECT and not FX_EMITS_EFFECT then FX_STEP + 1 else 0
        | LW_NEW_TABLE_SLOT := if LW_INDICES_REWRITES and LW_IOTA_TABLE < 0 then NEW_TABLE_COUNT[?] else -1
        | NEW_TABLE_TYPE := NEW_TABLE_TYPE[?] next LW_NEW_TABLE_SLOT : LW_INTERNED
        | NEW_TABLE_COUNT := NEW_TABLE_COUNT[?] + integer(LW_NEW_TABLE_SLOT >= 0)
        | NEW_TABLE_ELEMENTS := NEW_TABLE_ELEMENTS[?] + (if LW_NEW_TABLE_SLOT >= 0 then LW_LEFT_VALUE else long(0))
        | LW_IOTA := LW_IOTA[?] next (if LW_TABLE_IOTA then LW_TABLE_TYPE else if LW_NEW_TABLE_SLOT >= 0 then LW_INTERNED else -1)
                     : (if LW_TABLE_IOTA then LW_I + 1 else LW_NEW_TABLE + 1)
        | LOOP_INDEX := LOOP_INDEX[?] next (if LW_LOOP_LIVE then LW_I else -1) : LW_LOOP_SIGNAL
        | LOOP_SIZE := LOOP_SIZE[?] next (if LW_LOOP_LIVE then LW_I else -1) : TYPE_SIZE[LW_LOOP_TYPE]
        | LW_EQ_SIGNAL := LW_EQ_SIGNAL[?] next (if LW_EQ_STEP = 0 then LW_I else -1) : LK_VALUE + 1
        | SIGNAL_LOOP_MARK := SIGNAL_LOOP_MARK[?] next (if LW_EQ_STEP = 0 and LW_LOOP_DEFINES and LK_FOUND then LK_VALUE else -1)
                              : LW_EQ_LOOP + 1
        | LW_GUARD_MARK := LW_GUARD_MARK[?] next (if LW_EQ_STEP = 2 then LW_I else -1) : LK_VALUE + 1
        | LW_GROUP_GUARD := LW_GROUP_GUARD[?] next (if LW_GROUP_LIVE then LW_I else -1) : (if LW_HAS_GUARD then LK_VALUE + 1 else 0)
        | LW_END_WRITES := LW_END_DEFINES and LW_GOES
        | SIGNAL_TOP := SIGNAL_TOP[?] next (if LW_END_WRITES then LW_SIGNAL_NOW else -1) : LW_END_TOP + 1
        | SIGNAL_DEF_TOKEN := SIGNAL_DEF_TOKEN[?] next (if LW_END_WRITES then LW_SIGNAL_NOW else -1) : LW_START_TOKEN + 1
        | SIGNAL_DEF_GUARD := SIGNAL_DEF_GUARD[?] next (if LW_END_WRITES then LW_SIGNAL_NOW else -1) : LW_FL_GUARD[?] + 1
        | DEF_START := DEF_START[?] next (if LW_END_WRITES then LW_SIGNAL_NOW else -1) : LW_FL_ROW_START[?]
        | DEF_END := DEF_END[?] next (if LW_END_WRITES then LW_SIGNAL_NOW else -1) : LW_ROW
        | LW_EQ_CLOSES := LW_FINISHING and not LW_MEMBER_NOW and LW_GOES
        | EQ_ROW_START := EQ_ROW_START[?] next (if LW_EQ_CLOSES then LW_I else -1) : LW_FL_ROW_START[?]
        | EQ_ROW_END := EQ_ROW_END[?] next (if LW_EQ_CLOSES then LW_I else -1) : ROW_COUNT
        | EQ_ROW_SIGNAL := EQ_ROW_SIGNAL[?] next (if LW_EQ_CLOSES then LW_I else -1) : LW_SIGNAL_NOW
        | LW_MEMBER_CLOSES := LW_FINISHING and LW_MEMBER_NOW and LW_GOES
        | GROUP_MEMBER_ROW := GROUP_MEMBER_ROW[?] next (if LW_MEMBER_CLOSES then LW_MEMBER_INDEX else -1) : LW_END_TOP
        | LW_GROUP_ARRAY := if LW_MEMBERS_CLOSE then false
                            else LW_GROUP_ARRAY[?] or LW_MEMBER_CLOSES
                                 and (LW_END_TOP_OP = OP_GATHER or LW_END_TOP_OP = OP_NEXT or LW_END_TOP_OP = OP_RANGE)
        | LW_STACK_SLOT := if LW_PUSHES and LW_GOES then LW_TOP_NOW
                           else if LW_OPERATOR and not LW_IS_INDICES and LW_GOES then LW_TOP_NOW - (if LW_UNARY then 1 else 2)
                           else if FX_EMITS_EFFECT and LW_GOES then FX_BASE else -1
        | LW_STACK := LW_STACK[?] next LW_STACK_SLOT : (if LW_SIGNAL_FOUND then LK_VALUE else LW_ROW)
        | LW_TOP := if AT_LS_START or AT_LS_MEMBERS then 0 else if LW_STACK_SLOT >= 0 then LW_STACK_SLOT + 1 else LW_TOP_NOW
        | LW_CUR_TOKEN := if LW_START_LIVE then LW_EQ_TOKEN else if LW_MEMBER_STARTS then FLAT_GROUP_TOKEN[LW_I]
                          else if LW_ENTRY_LIVE and not LW_IS_CONST and not LW_IS_ENUM then LW_ENTRY_TOKEN else LW_CARRIED_TOKEN
        | LW_FL_TOKEN := if LW_START_LIVE then LW_EQ_TOKEN else if LW_MEMBER_STARTS then FLAT_GROUP_TOKEN[LW_I] else LW_START_TOKEN
        | LW_FL_START := if LW_START_LIVE then FLAT_EQUATION_START[LW_I] else LW_FL_START[?]
        | LW_FL_END := if LW_START_LIVE then FLAT_EQUATION_END[LW_I] else if LW_MEMBER_STARTS then FLAT_MEMBER_END[LW_MEMBER_INDEX]
                       else LW_END_NOW
        | LW_FL_LOOP := if LW_START_LIVE then (if LW_EQ_SEED then -1 else LW_EQ_LOOP) else if LW_MEMBER_STARTS then -1 else LW_LOOP_NOW
        | LW_FL_OWNER := if LW_START_LIVE then (if LW_EQ_TARGET >= 0 then LW_START_SIGNAL else -1)
                         else if LW_MEMBER_STARTS then -1 else LW_SIGNAL_NOW
        | LW_FL_GUARD := if LW_START_LIVE then LW_GUARD_MARK[?][LW_I] - 1
                         else if LW_MEMBER_STARTS then LW_GROUP_GUARD[?][LW_I] - 1 else LW_FL_GUARD[?]
        | LW_FL_MEMBER := if LW_START_LIVE then false else if LW_MEMBER_STARTS then true else LW_MEMBER_NOW
        | LW_FL_ROW_START := if LW_START_LIVE or LW_MEMBER_STARTS then LW_ROW else LW_FL_ROW_START[?]
        | LW_ENTRY := if LW_START_LIVE then FLAT_EQUATION_START[LW_I]
                      else if LW_MEMBER_STARTS then FLAT_MEMBER_START[LW_MEMBER_INDEX]
                      else if LW_SCAN_LIVE then LW_E + 1
                      else if AT_LS_SCAN then LW_FL_START[?]
                      else if LW_IS_EFFECT and not FX_EMITS_EFFECT then LW_E
                      else if LW_ENTRY_LIVE then LW_E + 1 else LW_E
        | LW_STATE := if LW_FAILS then LS_FAILED
                      else if AT_LS_SIGNAL then (if LW_SIGNAL_LIVE then LS_SIGNAL else LS_LABEL)
                      else if AT_LS_LABEL then (if LW_LABEL_LIVE then LS_LABEL else LS_VALUE)
                      else if AT_LS_VALUE then (if LW_VALUE_TYPE_LIVE then LS_VALUE else LS_ARRAY)
                      else if AT_LS_ARRAY then (if LW_I < TYPE_COUNT then LS_ARRAY else LS_TABLE)
                      else if AT_LS_TABLE then (if LW_TABLE_LIVE then LS_TABLE else LS_LOOP)
                      else if AT_LS_LOOP then (if LW_LOOP_LIVE then LS_LOOP else LS_EQUATION)
                      else if AT_LS_EQUATION then (if LW_EQUATION_LIVE then LS_EQUATION else LS_GROUP)
                      else if AT_LS_GROUP then (if LW_I < FLAT_GROUP_COUNT then LS_GROUP else LS_START)
                      else if AT_LS_START then (if not LW_START_LIVE then LS_NEVER else if LW_EQ_SEED then LS_SCAN else LS_ENTRY)
                      else if AT_LS_SCAN then (if LW_SCAN_LIVE then LS_SCAN else LS_ENTRY)
                      else if AT_LS_ENTRY then (if not LW_FINISHING then LS_ENTRY else if LW_MEMBER_NOW then LS_MEMBERS else LS_START)
                      else if AT_LS_NEVER then (if LW_NEVER_LIVE then LS_NEVER else LS_MEMBERS)
                      else if AT_LS_MEMBERS then
                        (if LW_MEMBER_STARTS then LS_ENTRY else if LW_MEMBERS_LIVE then LS_MEMBERS else LS_DONE)
                      else LW_NOW
        | LW_CURSOR := if AT_LS_SIGNAL then (if LW_SIGNAL_LIVE then LW_I + 1 else 0)
                       else if AT_LS_LABEL then (if LW_LABEL_LIVE then LW_I + 1 else 0)
                       else if AT_LS_VALUE then (if not LW_VALUE_TYPE_LIVE then 0 else LW_I + integer(not LW_VALUE_LIVE))
                       else if AT_LS_ARRAY then (if LW_I < TYPE_COUNT then LW_I + 1 else 0)
                       else if AT_LS_TABLE then (if not LW_TABLE_LIVE then 0 else LW_I + integer(not LW_TABLE_WALKS))
                       else if AT_LS_LOOP then (if LW_LOOP_LIVE then LW_I + 1 else 0)
                       else if AT_LS_EQUATION then (if not LW_EQUATION_LIVE then 0 else LW_I + integer(not LW_EQ_MORE))
                       else if AT_LS_GROUP then (if LW_I < FLAT_GROUP_COUNT then LW_I + 1 else 0)
                       else if AT_LS_START then (if LW_START_LIVE then LW_I else 0)
                       else if AT_LS_ENTRY then LW_I + integer(LW_FINISHING and not LW_MEMBER_NOW)
                       else if AT_LS_NEVER then (if LW_NEVER_LIVE then LW_I + 1 else 0)
                       else if AT_LS_MEMBERS then LW_I + integer(LW_MEMBERS_CLOSE)
                       else LW_I
        | LW_SUB := if AT_LS_VALUE then (if LW_VALUE_LIVE then LW_K + 1 else 0)
                    else if AT_LS_TABLE then (if LW_TABLE_WALKS then LW_K + 1 else 0)
                    else if AT_LS_EQUATION then (if LW_EQ_MORE then LW_EQ_STEP + 1 else 0)
                    else if AT_LS_ENTRY then LW_K + integer(LW_FINISHING and LW_MEMBER_NOW)
                    else if AT_LS_MEMBERS then (if LW_MEMBERS_CLOSE then 0 else LW_K)
                    else if AT_LS_NEVER then 0
                    else LW_K
        |)
     with (| LW_STATE := LS_SIGNAL | LW_CURSOR := 0 | LW_SUB := 0 | LW_ENTRY := 0 | LW_FL_END := 0 | LW_FL_START := 0
           | LW_FL_LOOP := -1 | LW_FL_OWNER := -1 | LW_FL_GUARD := -1 | LW_FL_MEMBER := false | LW_FL_ROW_START := 0
           | LW_FL_TOKEN := 0 | LW_TOP := 0 | LW_CUR_TOKEN := 0 | LW_TABLE_OK := false | LW_GROUP_ARRAY := false
           | LW_FX_STEP := 0 | LW_FX_PREVIOUS := -1 | HN_COUNT := 0 | ROW_COUNT := 0 | EFFECT_COUNT := 0
           | NEW_TYPE_COUNT := 0 | NEW_TABLE_COUNT := 0 | NEW_TABLE_ELEMENTS := long(0) | LW_MESSAGE := 0 | LW_TOKEN := 0 | LW_ARGUMENT0 := 0
           | LW_ARGUMENT1 := 0 | LW_ARGUMENT2 := 0 | LW_INSTANCE := 0 | LW_LONG0 := long(0) | LW_LONG0_UNSIGNED := false
           | LW_LONG1 := long(0) |)
     end
   | LOWER_FAILED := LOWERS and LW_STATE = LS_FAILED
   | LOWER_INCOMPLETE := LOWERS and LW_STATE /= LS_DONE and LW_STATE /= LS_FAILED
   | LOWER_READY := LOWERS and LW_STATE = LS_DONE
   | POST_BOUND := long(64) + long(5) * long(FLAT_DEPENDENCE_COUNT) + long(ROW_COUNT) + long(2) * long(FLAT_LOOP_COUNT)
                   + long(FLAT_SIGNAL_COUNT) + long(FLAT_EQUATION_COUNT) + long(FLAT_LIST_TOTAL) + long(FLAT_LABEL_COUNT)
   | POST_INDEX := 0 .. (if LOWER_READY then POST_BOUND else long(-1))
   | iterate POST_INDEX of
       (| PO_NOW := PO_STATE[?]
        | PO_I := PO_CURSOR[?]
        | PO_K := PO_SUB[?]
        | AT_PS_DEPENDENCE := PO_NOW = PS_DEPENDENCE
        | AT_PS_ROWS := PO_NOW = PS_ROWS
        | AT_PS_PREFIX := PO_NOW = PS_PREFIX
        | AT_PS_PLACE := PO_NOW = PS_PLACE
        | AT_PS_WALK := PO_NOW = PS_WALK
        | AT_PS_LABELSUM := PO_NOW = PS_LABELSUM
        | AT_PS_SIZE := PO_NOW = PS_SIZE
        | PO_DEPENDENCE_LIVE := AT_PS_DEPENDENCE and PO_I < FLAT_DEPENDENCE_COUNT
        | PO_TO_END := PO_K >= 2
        | PO_END_KEY := if PO_TO_END then FLAT_DEPENDENCE_TO_KEY[PO_I] else FLAT_DEPENDENCE_FROM_KEY[PO_I]
        | PO_END_INSTANCE := FLAT_DEPENDENCE_INSTANCE[PO_I]
        | PO_END_SIGNAL := if PO_TO_END then PO_TO_SIGNAL[?][PO_I] else PO_FROM_SIGNAL[?][PO_I]
        | PO_LOOKS_LABEL := PO_K = 1 or PO_K = 3
        | PO_ROWS_LIVE := AT_PS_ROWS and PO_I < ROW_COUNT
        | PO_ROW_OP := ROWS_OP[PO_I]
        | PO_ROW_LEFT := ROWS_LEFT[PO_I]
        | PO_ROW_RIGHT := ROWS_RIGHT[PO_I]
        | PO_LEFT_RANGE := PO_ROW_LEFT >= 0 and PO_ROW_LEFT < FLAT_SIGNAL_COUNT and ROWS_LEFT[PO_ROW_LEFT] >= 0
                           and ROWS_OP[ROWS_LEFT[PO_ROW_LEFT]] = OP_RANGE
        | PO_RIGHT_RANGE := PO_ROW_RIGHT >= 0 and PO_ROW_RIGHT < FLAT_SIGNAL_COUNT and ROWS_LEFT[PO_ROW_RIGHT] >= 0
                            and ROWS_OP[ROWS_LEFT[PO_ROW_RIGHT]] = OP_RANGE
        | PO_RANGE_FAILS := PO_ROWS_LIVE and PO_ROW_OP /= OP_ITER and (PO_LEFT_RANGE or PO_RIGHT_RANGE)
        | PO_LEFT_PREV := PO_ROWS_LIVE and PO_ROW_LEFT >= 0 and ROWS_OP[PO_ROW_LEFT] = OP_PREV
        | PO_RIGHT_PREV := PO_ROWS_LIVE and PO_ROW_RIGHT >= 0 and PO_ROW_RIGHT /= PO_ROW_LEFT and ROWS_OP[PO_ROW_RIGHT] = OP_PREV
        | PO_LEFT_TAIL := LEFT_TAIL[?][PO_ROW_LEFT]
        | PO_RIGHT_TAIL := RIGHT_TAIL[?][PO_ROW_RIGHT]
        | LEFT_HEAD := LEFT_HEAD[?] next (if PO_LEFT_PREV and PO_LEFT_TAIL = 0 then PO_ROW_LEFT else -1) : PO_I + 1
        | LEFT_NEXT := LEFT_NEXT[?] next (if PO_LEFT_PREV and PO_LEFT_TAIL > 0 then PO_LEFT_TAIL - 1 else -1) : PO_I + 1
        | LEFT_TAIL := LEFT_TAIL[?] next (if PO_LEFT_PREV then PO_ROW_LEFT else -1) : PO_I + 1
        | RIGHT_HEAD := RIGHT_HEAD[?] next (if PO_RIGHT_PREV and PO_RIGHT_TAIL = 0 then PO_ROW_RIGHT else -1) : PO_I + 1
        | RIGHT_NEXT := RIGHT_NEXT[?] next (if PO_RIGHT_PREV and PO_RIGHT_TAIL > 0 then PO_RIGHT_TAIL - 1 else -1) : PO_I + 1
        | RIGHT_TAIL := RIGHT_TAIL[?] next (if PO_RIGHT_PREV then PO_ROW_RIGHT else -1) : PO_I + 1
        | PO_PREV_SLOT := if PO_ROWS_LIVE and PO_ROW_OP = OP_PREV then PREV_COUNT[?] else -1
        | PREV_LIST := PREV_LIST[?] next PO_PREV_SLOT : PO_I
        | PREV_COUNT := PREV_COUNT[?] + integer(PO_PREV_SLOT >= 0)
        | PO_SIGNAL_LOOP := ROWS_LOOP[PO_I]
        | PO_COUNTS := PO_ROWS_LIVE and PO_I < FLAT_SIGNAL_COUNT and PO_SIGNAL_LOOP >= 0
        | LOOP_DEF_TOTAL := LOOP_DEF_TOTAL[?] next (if PO_COUNTS then PO_SIGNAL_LOOP else -1) : LOOP_DEF_TOTAL[?][PO_SIGNAL_LOOP] + 1
        | PO_PREFIX_LIVE := AT_PS_PREFIX and PO_I < FLAT_LOOP_COUNT
        | LOOP_DEF_START := LOOP_DEF_START[?] next (if PO_PREFIX_LIVE then PO_I else -1) : PO_RUNNING[?]
        | PO_PLACE_LIVE := AT_PS_PLACE and PO_I < FLAT_SIGNAL_COUNT
        | PO_PLACES := PO_PLACE_LIVE and PO_SIGNAL_LOOP >= 0
        | PO_PLACE_FILL := LOOP_DEF_FILL[?][PO_SIGNAL_LOOP]
        | DEFINED_LIST := DEFINED_LIST[?] next (if PO_PLACES then LOOP_DEF_START[?][PO_SIGNAL_LOOP] + PO_PLACE_FILL else -1) : PO_I
        | LOOP_DEF_FILL := LOOP_DEF_FILL[?] next (if PO_PLACES then PO_SIGNAL_LOOP else -1) : PO_PLACE_FILL + 1
        | PO_WALK_LIVE := AT_PS_WALK and PO_I < FLAT_EQUATION_COUNT and PO_NEEDS_LABELS[?]
        | PO_WALK_CONTEXT := FLAT_EQUATION_CONTEXT[PO_I]
        | PO_WALK_NODE := FLAT_EQUATION_LABELS[PO_I]
        | PO_INHERITED := INSTANCE_LABEL_LENGTH[PO_WALK_CONTEXT]
        | PO_PATH_LENGTH := PO_INHERITED + (if PO_WALK_NODE < 0 then 0 else USE_PATH_LENGTH[PO_WALK_NODE])
        | PO_WALK_STEP := PO_WALK_LIVE and PO_K < PO_PATH_LENGTH
        | PO_WALK_AT := INSTANCE_LABEL_START[PO_WALK_CONTEXT] + PO_K
        | PO_FROM_INHERITED := PO_K < PO_INHERITED
        | PO_WALK_KEY := if PO_FROM_INHERITED then FLAT_PATH_KEY[PO_WALK_AT]
                         else PATH_VALUE[USE_PATH_START[PO_WALK_NODE] + PO_K - PO_INHERITED]
        | PO_WALK_INSTANCE := if PO_FROM_INHERITED then FLAT_PATH_INSTANCE[PO_WALK_AT] else PO_WALK_CONTEXT
        | PO_WALK_CALL := PO_FROM_INHERITED and FLAT_PATH_CALL[PO_WALK_AT]
        | PO_LIVE := PO_DEPENDENCE_LIVE or PO_WALK_STEP
        | PO_A := long(if PO_DEPENDENCE_LIVE then PO_END_KEY else PO_WALK_KEY)
        | PO_B := if PO_DEPENDENCE_LIVE then
                    long(PO_END_INSTANCE) * long(KEY_STRIDE)
                    + long(if not PO_LOOKS_LABEL then KEY_SIGNAL else if PO_END_SIGNAL >= 0 then KEY_CALL_LABEL else KEY_LABEL)
                  else long(PO_WALK_INSTANCE) * long(KEY_STRIDE) + long(if PO_WALK_CALL then KEY_CALL_LABEL else KEY_LABEL)
        | PO_HASH := integer((ulong(PO_A) * HASH_K1 + ulong(PO_B) * HASH_K2) shr HASH_SHIFT)
        | PO_N0 := HASH_HEAD[PO_HASH] - 1
        | PO_M0 := PO_N0 >= 0 and HN_A[PO_N0] = PO_A and HN_B[PO_N0] = PO_B
        | PO_N1 := if PO_N0 >= 0 then HN_NEXT[PO_N0] - 1 else -1
        | PO_M1 := PO_N1 >= 0 and HN_A[PO_N1] = PO_A and HN_B[PO_N1] = PO_B
        | PO_N2 := if PO_N1 >= 0 then HN_NEXT[PO_N1] - 1 else -1
        | PO_M2 := PO_N2 >= 0 and HN_A[PO_N2] = PO_A and HN_B[PO_N2] = PO_B
        | PO_N3 := if PO_N2 >= 0 then HN_NEXT[PO_N2] - 1 else -1
        | PO_M3 := PO_N3 >= 0 and HN_A[PO_N3] = PO_A and HN_B[PO_N3] = PO_B
        | PO_N4 := if PO_N3 >= 0 then HN_NEXT[PO_N3] - 1 else -1
        | PO_M4 := PO_N4 >= 0 and HN_A[PO_N4] = PO_A and HN_B[PO_N4] = PO_B
        | PO_N5 := if PO_N4 >= 0 then HN_NEXT[PO_N4] - 1 else -1
        | PO_M5 := PO_N5 >= 0 and HN_A[PO_N5] = PO_A and HN_B[PO_N5] = PO_B
        | PO_N6 := if PO_N5 >= 0 then HN_NEXT[PO_N5] - 1 else -1
        | PO_M6 := PO_N6 >= 0 and HN_A[PO_N6] = PO_A and HN_B[PO_N6] = PO_B
        | PO_N7 := if PO_N6 >= 0 then HN_NEXT[PO_N6] - 1 else -1
        | PO_M7 := PO_N7 >= 0 and HN_A[PO_N7] = PO_A and HN_B[PO_N7] = PO_B
        | PO_NODE := if PO_M0 then PO_N0 else if PO_M1 then PO_N1 else if PO_M2 then PO_N2 else if PO_M3 then PO_N3
                     else if PO_M4 then PO_N4 else if PO_M5 then PO_N5 else if PO_M6 then PO_N6 else if PO_M7 then PO_N7 else -1
        | PO_FOUND := PO_NODE >= 0
        | PO_VALUE := if PO_FOUND then HN_VALUE[PO_NODE] else -1
        | PO_UNSURE := PO_LIVE and not PO_FOUND and PO_N7 >= 0 and HN_NEXT[PO_N7] > 0
        | PO_END_FAILS := PO_DEPENDENCE_LIVE and PO_LOOKS_LABEL and PO_END_SIGNAL < 0 and not PO_FOUND
        | PO_WALK_LABEL := if PO_WALK_STEP and PO_FOUND and LABEL_NEEDED[?][PO_VALUE] then PO_VALUE else -1
        | PO_WALK_EQUATION := PO_I
        | PO_SEGMENT_SIZE := EQ_ROW_END[PO_I] - EQ_ROW_START[PO_I] + integer(EQ_ROW_SIGNAL[PO_I] >= 0)
        | PO_SEGMENT_FULL := PO_WALK_LABEL >= 0 and SEGMENT_COUNT[?] >= SEGMENT_CAP
        | PO_LABELSUM_LIVE := AT_PS_LABELSUM and PO_I < FLAT_LABEL_COUNT
        | PO_SIZE_LIVE := AT_PS_SIZE and PO_I < FLAT_DEPENDENCE_COUNT
        | PO_FROM_SIGNAL_NOW := PO_FROM_SIGNAL[?][PO_I]
        | PO_TO_SIGNAL_NOW := PO_TO_SIGNAL[?][PO_I]
        | PO_FROM_LIST := (if PO_FROM_SIGNAL_NOW >= 0 then long(1) else long(0)) + long(LABEL_ROW_TOTAL[?][PO_FROM_LABEL[?][PO_I]])
        | PO_TO_LIST := (if PO_TO_SIGNAL_NOW >= 0 then long(1 + DEF_END[PO_TO_SIGNAL_NOW] - DEF_START[PO_TO_SIGNAL_NOW]) else long(0))
                        + long(LABEL_ROW_TOTAL[?][PO_TO_LABEL[?][PO_I]])
        | PO_PAIR_TOTAL := PO_PAIR_TOTAL[?] + (if PO_SIZE_LIVE then PO_FROM_LIST * PO_TO_LIST else long(0))
        | PO_SIZE_FAILS := PO_SIZE_LIVE and PO_PAIR_TOTAL > long(ROW_DEPENDENCE_CAP)
        | PO_LABELS_FULL := PO_LABELSUM_LIVE and PO_RUNNING[?] + LABEL_ROW_TOTAL[?][PO_I] > ROW_DEPENDENCE_CAP
        | PO_MESSAGE_NOW := if PO_END_FAILS then T_FLAT_UNDECLARED else if PO_RANGE_FAILS then T_RANGE_INDEX
                            else if PO_UNSURE or PO_SEGMENT_FULL or PO_LABELS_FULL or PO_SIZE_FAILS then T_CAPACITY else 0
        | PO_FAILS := PO_MESSAGE_NOW /= 0
        | PO_MESSAGE := if PO_FAILS then PO_MESSAGE_NOW else PO_MESSAGE[?]
        | PO_TOKEN := if PO_FAILS then
                        (if PO_RANGE_FAILS then ROWS_TOKEN[PO_I]
                         else if PO_TO_END then FLAT_DEPENDENCE_TO_TOKEN[PO_I] else FLAT_DEPENDENCE_FROM_TOKEN[PO_I])
                      else PO_TOKEN[?]
        | PO_ARGUMENT0 := if PO_FAILS then
                            (if PO_UNSURE then F_CAP_LOOKUPS else if PO_SEGMENT_FULL or PO_LABELS_FULL then F_CAP_SEGMENTS
                             else if PO_SIZE_FAILS then F_CAP_ROW_DEPENDENCES else PO_END_KEY)
                          else PO_ARGUMENT0[?]
        | PO_INSTANCE := if PO_FAILS then PO_END_INSTANCE else PO_INSTANCE[?]
        | PO_GOES := not PO_FAILS
        | PO_FROM_SIGNAL := PO_FROM_SIGNAL[?] next (if PO_DEPENDENCE_LIVE and PO_K = 0 then PO_I else -1) : PO_VALUE
        | PO_FROM_LABEL := PO_FROM_LABEL[?] next (if PO_DEPENDENCE_LIVE and PO_K = 1 then PO_I else -1) : PO_VALUE
        | PO_TO_SIGNAL := PO_TO_SIGNAL[?] next (if PO_DEPENDENCE_LIVE and PO_K = 2 then PO_I else -1) : PO_VALUE
        | PO_TO_LABEL := PO_TO_LABEL[?] next (if PO_DEPENDENCE_LIVE and PO_K = 3 then PO_I else -1) : PO_VALUE
        | PO_MARKS := PO_DEPENDENCE_LIVE and PO_LOOKS_LABEL and PO_FOUND
        | LABEL_NEEDED := LABEL_NEEDED[?] next (if PO_MARKS then PO_VALUE else -1) : true
        | PO_NEEDS_LABELS := PO_NEEDS_LABELS[?] or PO_MARKS
        | PO_SEGMENT_SLOT := if PO_WALK_LABEL >= 0 and PO_GOES then SEGMENT_COUNT[?] else -1
        | SEGMENT_LABEL := SEGMENT_LABEL[?] next PO_SEGMENT_SLOT : PO_WALK_LABEL
        | SEGMENT_EQUATION := SEGMENT_EQUATION[?] next PO_SEGMENT_SLOT : PO_WALK_EQUATION
        | SEGMENT_COUNT := SEGMENT_COUNT[?] + integer(PO_SEGMENT_SLOT >= 0)
        | LABEL_ROW_TOTAL := LABEL_ROW_TOTAL[?] next (if PO_SEGMENT_SLOT >= 0 then PO_WALK_LABEL else -1)
                             : LABEL_ROW_TOTAL[?][PO_WALK_LABEL] + PO_SEGMENT_SIZE
        | LABEL_START := LABEL_START[?] next (if PO_LABELSUM_LIVE then PO_I else -1) : PO_RUNNING[?]
        | PO_RUNNING := if AT_PS_PREFIX then (if PO_PREFIX_LIVE then PO_RUNNING[?] + LOOP_DEF_TOTAL[?][PO_I] else 0)
                        else if AT_PS_LABELSUM then PO_RUNNING[?] + (if PO_LABELSUM_LIVE then LABEL_ROW_TOTAL[?][PO_I] else 0)
                        else PO_RUNNING[?]
        | PO_STATE := if PO_FAILS then PS_FAILED
                      else if AT_PS_DEPENDENCE then (if PO_DEPENDENCE_LIVE then PS_DEPENDENCE else PS_ROWS)
                      else if AT_PS_ROWS then (if PO_ROWS_LIVE then PS_ROWS else PS_PREFIX)
                      else if AT_PS_PREFIX then (if PO_PREFIX_LIVE then PS_PREFIX else PS_PLACE)
                      else if AT_PS_PLACE then (if PO_PLACE_LIVE then PS_PLACE else PS_WALK)
                      else if AT_PS_WALK then (if PO_WALK_LIVE then PS_WALK else PS_LABELSUM)
                      else if AT_PS_LABELSUM then (if PO_LABELSUM_LIVE then PS_LABELSUM else PS_SIZE)
                      else if AT_PS_SIZE then (if PO_SIZE_LIVE then PS_SIZE else PS_DONE)
                      else PO_NOW
        | PO_CURSOR := if AT_PS_DEPENDENCE then (if not PO_DEPENDENCE_LIVE then 0 else PO_I + integer(PO_K = 3))
                       else if AT_PS_WALK then (if not PO_WALK_LIVE then 0 else PO_I + integer(not PO_WALK_STEP))
                       else if AT_PS_ROWS then (if PO_ROWS_LIVE then PO_I + 1 else 0)
                       else if AT_PS_PREFIX then (if PO_PREFIX_LIVE then PO_I + 1 else 0)
                       else if AT_PS_PLACE then (if PO_PLACE_LIVE then PO_I + 1 else 0)
                       else if AT_PS_LABELSUM then (if PO_LABELSUM_LIVE then PO_I + 1 else 0)
                       else if AT_PS_SIZE then (if PO_SIZE_LIVE then PO_I + 1 else 0)
                       else PO_I
        | PO_SUB := if AT_PS_DEPENDENCE then (if PO_DEPENDENCE_LIVE and PO_K < 3 then PO_K + 1 else 0)
                    else if AT_PS_WALK then (if PO_WALK_STEP then PO_K + 1 else 0)
                    else 0
        |)
     with (| PO_STATE := PS_DEPENDENCE | PO_CURSOR := 0 | PO_SUB := 0 | PREV_COUNT := 0 | PO_RUNNING := 0
           | PO_NEEDS_LABELS := false | SEGMENT_COUNT := 0 | PO_PAIR_TOTAL := long(0) | PO_MESSAGE := 0 | PO_TOKEN := 0
           | PO_ARGUMENT0 := 0 | PO_INSTANCE := 0 |)
     end
   | POST_FAILED := LOWER_READY and PO_STATE = PS_FAILED
   | POST_INCOMPLETE := LOWER_READY and PO_STATE /= PS_DONE and PO_STATE /= PS_FAILED
   | POST_READY := LOWER_READY and PO_STATE = PS_DONE
   | EXPAND_BOUND := long(64) + long(PO_RUNNING) + long(SEGMENT_COUNT) + PO_PAIR_TOTAL + long(FLAT_DEPENDENCE_COUNT)
                     + long(PREV_COUNT) + long(2) * long(ROW_COUNT)
   | EXPAND_INDEX := 0 .. (if POST_READY then EXPAND_BOUND else long(-1))
   | iterate EXPAND_INDEX of
       (| XP_NOW := XP_STATE[?]
        | XP_I := XP_CURSOR[?]
        | XP_J := XP_INNER[?]
        | XP_K := XP_SUB[?]
        | AT_XS_PLACE := XP_NOW = XS_PLACE
        | AT_XS_PAIRS := XP_NOW = XS_PAIRS
        | AT_XS_PREV := XP_NOW = XS_PREV
        | XP_PLACE_LIVE := AT_XS_PLACE and XP_I < SEGMENT_COUNT
        | XP_LABEL := SEGMENT_LABEL[XP_I]
        | XP_EQUATION := SEGMENT_EQUATION[XP_I]
        | XP_RANGE_LENGTH := EQ_ROW_END[XP_EQUATION] - EQ_ROW_START[XP_EQUATION]
        | XP_SEGMENT_SIZE := XP_RANGE_LENGTH + integer(EQ_ROW_SIGNAL[XP_EQUATION] >= 0)
        | XP_PLACES := XP_PLACE_LIVE and XP_K < XP_SEGMENT_SIZE
        | XP_PLACE_FILL := LABEL_FILL[?][XP_LABEL]
        | LABEL_ROWS := LABEL_ROWS[?] next (if XP_PLACES then LABEL_START[XP_LABEL] + XP_PLACE_FILL else -1)
                        : (if XP_K < XP_RANGE_LENGTH then EQ_ROW_START[XP_EQUATION] + XP_K else EQ_ROW_SIGNAL[XP_EQUATION])
        | LABEL_FILL := LABEL_FILL[?] next (if XP_PLACES then XP_LABEL else -1) : XP_PLACE_FILL + 1
        | XP_PLACE_ENDS := XP_PLACE_LIVE and XP_K + 1 >= XP_SEGMENT_SIZE
        | XP_PAIRS_LIVE := AT_XS_PAIRS and XP_I < FLAT_DEPENDENCE_COUNT
        | XP_FROM_SIGNAL := PO_FROM_SIGNAL[XP_I]
        | XP_FROM_LABEL := PO_FROM_LABEL[XP_I]
        | XP_TO_SIGNAL := PO_TO_SIGNAL[XP_I]
        | XP_TO_LABEL := PO_TO_LABEL[XP_I]
        | XP_FROM_HEAD := integer(XP_FROM_SIGNAL >= 0)
        | XP_DEF_LENGTH := if XP_TO_SIGNAL >= 0 then DEF_END[XP_TO_SIGNAL] - DEF_START[XP_TO_SIGNAL] else 0
        | XP_TO_HEAD := integer(XP_TO_SIGNAL >= 0) + XP_DEF_LENGTH
        | XP_FROM_LENGTH := XP_FROM_HEAD + LABEL_ROW_TOTAL[XP_FROM_LABEL]
        | XP_TO_LENGTH := XP_TO_HEAD + LABEL_ROW_TOTAL[XP_TO_LABEL]
        | XP_EMITS_PAIR := XP_PAIRS_LIVE and XP_J < XP_FROM_LENGTH and XP_K < XP_TO_LENGTH
        | XP_FROM_ROW := if XP_J < XP_FROM_HEAD then XP_FROM_SIGNAL
                         else LABEL_ROWS[?][LABEL_START[XP_FROM_LABEL] + XP_J - XP_FROM_HEAD]
        | XP_TO_ROW := if XP_TO_SIGNAL >= 0 and XP_K = 0 then XP_TO_SIGNAL
                       else if XP_K < XP_TO_HEAD then DEF_START[XP_TO_SIGNAL] + XP_K - 1
                       else LABEL_ROWS[?][LABEL_START[XP_TO_LABEL] + XP_K - XP_TO_HEAD]
        | XP_PAIR_ROW_ENDS := XP_K + 1 >= XP_TO_LENGTH
        | XP_PAIR_ENDS := XP_PAIRS_LIVE and (not XP_EMITS_PAIR or XP_PAIR_ROW_ENDS and XP_J + 1 >= XP_FROM_LENGTH)
        | XP_PREV_LIVE := AT_XS_PREV and XP_I < PREV_COUNT
        | XP_PREVIOUS := PREV_LIST[XP_I]
        | XP_SIGNAL := ROWS_LEFT[XP_PREVIOUS]
        | XP_WRITER := ROWS_LEFT[XP_SIGNAL]
        | XP_SCALAR := TYPE_KIND[ROWS_TYPE[XP_SIGNAL]] /= TK_ARRAY
        | XP_STARTED := XP_PREV_STARTED[?]
        | XP_A := if XP_STARTED then XP_LEFT_AT[?] else LEFT_HEAD[XP_PREVIOUS] - 1
        | XP_B := if XP_STARTED then XP_RIGHT_AT[?] else RIGHT_HEAD[XP_PREVIOUS] - 1
        | XP_TAKES_A := XP_A >= 0 and (XP_B < 0 or XP_A < XP_B)
        | XP_TAKES_B := XP_B >= 0 and not XP_TAKES_A
        | XP_READER := if XP_TAKES_A then XP_A else XP_B
        | XP_PREV_SCALAR := XP_PREV_LIVE and XP_SCALAR
        | XP_EMITS_WAR := XP_PREV_LIVE and not XP_SCALAR and (XP_TAKES_A or XP_TAKES_B) and XP_READER /= XP_WRITER
        | XP_PREV_ENDS := XP_PREV_SCALAR or XP_PREV_LIVE and not XP_TAKES_A and not XP_TAKES_B
        | XP_DEPENDENCE_WANTED := XP_EMITS_PAIR or XP_PREV_SCALAR
        | XP_FAILS := XP_DEPENDENCE_WANTED and DEPENDENCE_TOTAL[?] >= ROW_DEPENDENCE_CAP
                      or XP_EMITS_WAR and WAR_COUNT[?] >= ROW_DEPENDENCE_CAP
        | XP_DEPENDENCE_SLOT := if XP_DEPENDENCE_WANTED and not XP_FAILS then DEPENDENCE_TOTAL[?] else -1
        | DEPENDENCE_FROM_ROW := DEPENDENCE_FROM_ROW[?] next XP_DEPENDENCE_SLOT : (if XP_PREV_SCALAR then XP_PREVIOUS else XP_FROM_ROW)
        | DEPENDENCE_TO_ROW := DEPENDENCE_TO_ROW[?] next XP_DEPENDENCE_SLOT : (if XP_PREV_SCALAR then XP_SIGNAL else XP_TO_ROW)
        | DEPENDENCE_TOTAL := DEPENDENCE_TOTAL[?] + integer(XP_DEPENDENCE_SLOT >= 0)
        | XP_WAR_SLOT := if XP_EMITS_WAR and not XP_FAILS then WAR_COUNT[?] else -1
        | WAR_READER := WAR_READER[?] next XP_WAR_SLOT : XP_READER
        | WAR_WRITER := WAR_WRITER[?] next XP_WAR_SLOT : XP_WRITER
        | WAR_SIGNAL := WAR_SIGNAL[?] next XP_WAR_SLOT : XP_SIGNAL
        | WAR_COUNT := WAR_COUNT[?] + integer(XP_WAR_SLOT >= 0)
        | XP_LEFT_AT := if XP_TAKES_A then LEFT_NEXT[XP_A] - 1 else XP_A
        | XP_RIGHT_AT := if XP_TAKES_B then RIGHT_NEXT[XP_B] - 1 else XP_B
        | XP_PREV_STARTED := XP_PREV_LIVE and not XP_PREV_ENDS
        | XP_STATE := if XP_FAILS then XS_FAILED
                      else if AT_XS_PLACE then (if XP_PLACE_LIVE then XS_PLACE else XS_PAIRS)
                      else if AT_XS_PAIRS then (if XP_PAIRS_LIVE then XS_PAIRS else XS_PREV)
                      else if AT_XS_PREV then (if XP_PREV_LIVE then XS_PREV else XS_DONE)
                      else XP_NOW
        | XP_CURSOR := if AT_XS_PLACE then (if not XP_PLACE_LIVE then 0 else XP_I + integer(XP_PLACE_ENDS))
                       else if AT_XS_PAIRS then (if not XP_PAIRS_LIVE then 0 else XP_I + integer(XP_PAIR_ENDS))
                       else XP_I + integer(XP_PREV_ENDS)
        | XP_INNER := if AT_XS_PAIRS and XP_EMITS_PAIR and not XP_PAIR_ENDS then XP_J + integer(XP_PAIR_ROW_ENDS) else 0
        | XP_SUB := if XP_PLACE_LIVE and not XP_PLACE_ENDS then XP_K + 1
                    else if XP_EMITS_PAIR and not XP_PAIR_ENDS then (if XP_PAIR_ROW_ENDS then 0 else XP_K + 1) else 0
        |)
     with (| XP_STATE := XS_PLACE | XP_CURSOR := 0 | XP_INNER := 0 | XP_SUB := 0 | XP_PREV_STARTED := false
           | XP_LEFT_AT := -1 | XP_RIGHT_AT := -1 | DEPENDENCE_TOTAL := 0 | WAR_COUNT := 0 |)
     end
   | EXPAND_FAILED := POST_READY and XP_STATE = XS_FAILED
   | EXPAND_INCOMPLETE := POST_READY and XP_STATE /= XS_DONE and XP_STATE /= XS_FAILED
   | ROWS_READY := POST_READY and XP_STATE = XS_DONE
   | CLOCKS_DUMP := DUMP_PASS = 5
   | CLOCKS_RUN := ROWS_READY and (DUMP_PASS = 0 or CLOCKS_DUMP or SCHEDULE_DUMP or CODE_DUMP)
   | CP_INDEX := 0 .. (if CLOCKS_RUN then long(ROW_COUNT) - long(1) else long(-1))
   | iterate CP_INDEX of
       (| CP_OP := ROWS_OP[CP_INDEX]
        | CP_LEFT_CTX := ROWS_CTX[ROWS_LEFT[CP_INDEX]]
        | CP_RIGHT_CTX := ROWS_CTX[ROWS_RIGHT[CP_INDEX]]
        | CP_SAMPLES := CP_OP = OP_WHEN or CP_OP = OP_UWHEN
        | CP_OP_UNIONS := if CP_OP = OP_COPY or CP_OP = OP_SEED or CP_OP = OP_EFFECT or OP_MONOCHRONOUS[CP_OP] = 1 then 1 + integer(ROWS_RIGHT[CP_INDEX] >= 0)
                        else if CP_OP = OP_DELAY or CP_OP = OP_CLOCK or CP_OP = OP_UWHEN then 1
                        else if CP_OP = OP_WHEN then (if CP_LEFT_CTX then 2 else 0)
                        else if CP_OP = OP_DEFAULT then (if CP_LEFT_CTX then 1 + integer(CP_RIGHT_CTX) else integer(CP_RIGHT_CTX))
                        else 0
        | CP_UNIONS := CP_OP_UNIONS + integer(ROWS_LOOP[CP_INDEX] >= 0)
        | CP_STEPS := CP_STEPS[?] + long(if CP_UNIONS > 1 then CP_UNIONS else 1)
        | CP_SAMPLE_BOUND := CP_SAMPLE_BOUND[?] + integer(CP_SAMPLES)
        | CP_DEF_BOUND := CP_DEF_BOUND[?] + integer(CP_SAMPLES or CP_OP = OP_DEFAULT)
        | CP_GUARDED := CP_GUARDED[?] + integer(ROWS_GUARD[CP_INDEX] >= 0)
        |)
     with (| CP_STEPS := long(0) | CP_SAMPLE_BOUND := 0 | CP_DEF_BOUND := 0 | CP_GUARDED := 0 |)
     end
   | CK_TOTAL_BOUND := long(ROW_COUNT) + long(CP_SAMPLE_BOUND)
   | CK_DEF_BOUND := long(CP_DEF_BOUND) + long(CP_SAMPLE_BOUND)
   | CK_ROUND_BOUND := long(3) * CK_DEF_BOUND + long(2) * long(CP_GUARDED) + long(4)
   | CK_BOUND := long(32) + CP_STEPS + long(CP_SAMPLE_BOUND) + long(FLAT_MEMBER_COUNT) + long(FLAT_GROUP_COUNT)
                 + long(3) * CK_DEF_BOUND + long(2) * long(CP_GUARDED) + CK_TOTAL_BOUND
                 + long(CK_ROUND_LIMIT - 1) * CK_ROUND_BOUND
   | CK_ROUND_LIMIT := integer(CK_DEF_BOUND + long(CP_GUARDED) + long(2))
   | CK_INDEX := 0 .. (if CLOCKS_RUN then CK_BOUND else long(-1))
   | iterate CK_INDEX of
       (| KS_NOW := CK_STATE[?]
        | AT_KS_ROWS := KS_NOW = KS_ROWS
        | AT_KS_SAMPLES := KS_NOW = KS_SAMPLES
        | AT_KS_GROUPS := KS_NOW = KS_GROUPS
        | AT_KS_REWRITE := KS_NOW = KS_REWRITE
        | AT_KS_TARGETS := KS_NOW = KS_TARGETS
        | AT_KS_GUARDS := KS_NOW = KS_GUARDS
        | AT_KS_SCAN := KS_NOW = KS_SCAN
        | AT_KS_DEFS := KS_NOW = KS_DEFS
        | AT_KS_WAIT := KS_NOW = KS_WAIT
        | KC := CK_CURSOR[?]
        | KK := CK_SUB[?]
        | KRN := CK_ROUND[?]
        | K_FIRST_ROUND := KRN = 1
        | K_SAMPLES_NOW := K_SAMPLE_COUNT[?]
        | K_DEFS_NOW := DEF_COUNT[?]
        | K_OBS_NOW := OB_COUNT[?]
        | KR_LIVE := AT_KS_ROWS and KC < ROW_COUNT
        | KR_TOO_MANY := AT_KS_ROWS and ROW_COUNT > CLOCK_CAP
        | KR_OP := ROWS_OP[KC]
        | KR_LEFT := ROWS_LEFT[KC]
        | KR_RIGHT := ROWS_RIGHT[KC]
        | KR_LEFT_CTX := ROWS_CTX[KR_LEFT]
        | KR_RIGHT_CTX := ROWS_CTX[KR_RIGHT]
        | KR_IS_WHEN := KR_OP = OP_WHEN
        | KR_SAMPLES := KR_IS_WHEN or KR_OP = OP_UWHEN
        | KR_CONDITION := if KR_IS_WHEN then KR_RIGHT else KR_LEFT
        | KR_FIRST := KR_LIVE and KK = 0
        | KR_NO_CLOCK := KR_FIRST and (KR_SAMPLES and ROWS_CTX[KR_CONDITION] or KR_OP = OP_CLOCK and KR_LEFT_CTX)
        | KR_DELAY_CONSTANT := KR_FIRST and KR_OP = OP_DELAY and KR_LEFT_CTX
        | KR_EXISTING := SAMPLE_OF[?][KR_CONDITION] - 1
        | KR_EVENT := ROWS_TYPE[KR_CONDITION] = BUILTIN_EVENT
        | KR_NEW_SAMPLE := ROW_COUNT + K_SAMPLES_NOW
        | KR_CREATES := KR_FIRST and KR_SAMPLES and not KR_EVENT and KR_EXISTING < 0
        | KR_CLOCKS_FULL := KR_CREATES and KR_NEW_SAMPLE >= CLOCK_CAP
        | KR_SAMPLE := if KR_EVENT then KR_CONDITION else if KR_EXISTING >= 0 then KR_EXISTING else KR_NEW_SAMPLE
        | KR_MONO := KR_OP = OP_COPY or KR_OP = OP_SEED or KR_OP = OP_EFFECT or OP_MONOCHRONOUS[KR_OP] = 1
        | KR_ONE := KR_OP = OP_DELAY or KR_OP = OP_CLOCK
        | KR_X0 := if KR_MONO or KR_ONE then KR_LEFT else if KR_OP = OP_UWHEN then KR_SAMPLE
                 else if KR_IS_WHEN or KR_LEFT_CTX then KR_LEFT else KR_RIGHT
        | KR_X1 := if KR_IS_WHEN then KR_SAMPLE else KR_RIGHT
        | KR_OP_UNIONS := if KR_MONO then 1 + integer(KR_RIGHT >= 0) else if KR_ONE or KR_OP = OP_UWHEN then 1
                        else if KR_IS_WHEN then (if KR_LEFT_CTX then 2 else 0)
                        else if KR_OP = OP_DEFAULT then (if KR_LEFT_CTX then 1 + integer(KR_RIGHT_CTX) else integer(KR_RIGHT_CTX))
                        else 0
        | KR_LOOP := ROWS_LOOP[KC]
        | KR_HAS_LOOP := KR_LOOP >= 0
        | KR_UNIONS := KR_OP_UNIONS + integer(KR_HAS_LOOP)
        | KR_X := if KR_HAS_LOOP and KK = 0 then LOOP_INDEX[KR_LOOP] else if KK - integer(KR_HAS_LOOP) = 0 then KR_X0 else KR_X1
        | KR_UNITES := KR_LIVE and KK < KR_UNIONS
        | KR_ENDS := KK + 1 >= KR_UNIONS
        | KR_DEFINES := KR_FIRST and (KR_IS_WHEN and not KR_LEFT_CTX or KR_OP = OP_DEFAULT and not KR_LEFT_CTX and not KR_RIGHT_CTX)
        | KR_OBLIGES := KR_FIRST and KR_OP = OP_DEFAULT and not KR_LEFT_CTX and KR_RIGHT_CTX
        | KR_GUARDED := KR_FIRST and ROWS_GUARD[KC] >= 0
        | KM_LIVE := AT_KS_SAMPLES and KC < K_SAMPLES_NOW
        | KM_CONDITION := SAMPLE_ROW[?][KC]
        | KG_LIVE := AT_KS_GROUPS and KC < FLAT_GROUP_COUNT
        | KG_TOTAL := FLAT_GROUP_MEMBER_TOTAL[KC]
        | KG_AT := FLAT_GROUP_MEMBER_FIRST[KC]
        | KG_MEMBER := GROUP_MEMBER_ROW[KG_AT + KK]
        | KG_HEAD := GROUP_MEMBER_ROW[KG_AT]
        | KG_STEPS := KG_LIVE and KK < KG_TOTAL
        | KG_NO_CLOCK := KG_STEPS and ROWS_CTX[KG_MEMBER]
        | KG_UNITES := KG_STEPS and KK > 0
        | KG_ENDS := KK + 1 >= KG_TOTAL
        | KW_LIVE := AT_KS_REWRITE and KC < K_DEFS_NOW
        | KW_MERGED := DEF_TARGET[?][KC]
        | KW_A := ROWS_LEFT[KW_MERGED]
        | KW_B := ROWS_RIGHT[KW_MERGED]
        | KW_FIRST := ROWS_RIGHT[KW_A]
        | KW_SECOND := ROWS_RIGHT[KW_B]
        | KW_SECOND_NEGATES := ROWS_OP[KW_SECOND] = OP_NOT and ROWS_LEFT[KW_SECOND] = KW_FIRST
        | KW_FIRST_NEGATES := ROWS_OP[KW_FIRST] = OP_NOT and ROWS_LEFT[KW_FIRST] = KW_SECOND
        | KW_SHAPED := KW_LIVE and DEF_KIND[?][KC] = CLK_SUM and ROWS_OP[KW_A] = OP_WHEN and ROWS_OP[KW_B] = OP_WHEN
                     and (KW_SECOND_NEGATES or KW_FIRST_NEGATES)
        | KW_CONDITION := if KW_SECOND_NEGATES then KW_FIRST else KW_SECOND
        | KW_V0 := ROWS_LEFT[KW_A]
        | KW_V1 := ROWS_LEFT[KW_B]
        | KW_BOTH_CTX := ROWS_CTX[KW_V0] and ROWS_CTX[KW_V1]
        | KW_UNITES := KW_SHAPED and KW_BOTH_CTX
        | KW_PRODUCT := KW_SHAPED and not ROWS_CTX[KW_V0] and not ROWS_CTX[KW_V1] and KF1 = KF2
        | K_DEF_LIMIT := CK_DEF_LIMIT[?]
        | KT_LIVE := AT_KS_TARGETS and KC < K_DEF_LIMIT
        | K_LISTED_DEF := if K_FIRST_ROUND then KC else PEND[?][KC]
        | KT_MARKS := KT_LIVE and not DEF_DONE[?][K_LISTED_DEF]
        | KU_LIVE := AT_KS_GUARDS and KC < GUARDED_COUNT[?]
        | KU_ROW := GUARDED[?][KC]
        | KU_SETS := KU_LIVE and CGSTAMP[?][KF1] /= KRN
        | KS_LIVE := AT_KS_SCAN and KC < CK_SCAN_LIMIT[?]
        | KS_CLOCK := if K_FIRST_ROUND then KC else CAND[?][KC]
        | KS_OPEN := KS_LIVE and KF1 = KS_CLOCK and NODE_KIND[?][KS_CLOCK] = CLK_NONE
        | KS_ELIGIBLE := KS_OPEN and TSTAMP[?][KS_CLOCK] /= KRN
        | KS_GUARD_SOURCE := if CGSTAMP[?][KS_CLOCK] = KRN then CGUARD[?][KS_CLOCK] else KS_CLOCK
        | KS_GUARDED := KF2 /= KS_CLOCK
        | KS_ATTACHES := KS_ELIGIBLE and KS_GUARDED and NODE_KIND[?][KF2] /= CLK_NONE
        | KS_ROOTS := KS_ELIGIBLE and not KS_GUARDED
        | KS_KEEPS := KS_OPEN and not KS_ATTACHES and not KS_ROOTS
        | KD_LIVE := AT_KS_DEFS and KC < K_DEF_LIMIT
        | KD_DEF := K_LISTED_DEF
        | KD_ACTS := KD_LIVE and not DEF_DONE[?][KD_DEF]
        | KD_KIND := DEF_KIND[?][KD_DEF]
        | KD_SAMPLE := KD_KIND = CLK_SAMPLE
        | KD_PRODUCT := KD_KIND = CLK_PRODUCT
        | KD_T := KF1
        | KD_L := KF2
        | KD_R := KF3
        | KD_HITS := KD_ACTS and not KD_SAMPLE and (KD_L = KD_T or KD_R = KD_T)
        | KD_OTHER := if KD_L = KD_T then KD_R else KD_L
        | KD_OBLIGES := KD_HITS and KD_OTHER /= KD_T
        | KD_TARGET_KIND := NODE_KIND[?][KD_T]
        | KD_EQUAL := KD_ACTS and not KD_HITS and not KD_SAMPLE and KD_L = KD_R and KD_TARGET_KIND = CLK_NONE
        | KD_WAITS := KD_ACTS and not KD_HITS and not KD_EQUAL
                   and (NODE_KIND[?][KD_L] = CLK_NONE or not KD_SAMPLE and NODE_KIND[?][KD_R] = CLK_NONE)
        | KD_SETTLES := KD_ACTS and not KD_HITS and not KD_EQUAL and not KD_WAITS
        | KD_ROOT_L := NODE_ROOT1[?][KD_L] - 1
        | KD_ROOT_R := NODE_ROOT1[?][KD_R] - 1
        | KD_FITS_NO_TREE := KD_SETTLES and not KD_SAMPLE and KD_ROOT_L /= KD_ROOT_R
        | KD_DEPTH_L := NODE_DEPTH[?][KD_L]
        | KD_DEPTH_R := NODE_DEPTH[?][KD_R]
        | KD_R_DEEPER := KD_DEPTH_R >= KD_DEPTH_L
        | KD_HIGH := if KD_R_DEEPER then KD_L else KD_R
        | KD_DIFF := if KD_R_DEEPER then KD_DEPTH_R - KD_DEPTH_L else KD_DEPTH_L - KD_DEPTH_R
        | KZ_0 := if KD_R_DEEPER then KD_R else KD_L
        | KZ_1 := KZ_0 + (if KD_DIFF / 1 modulo 2 = 1 then UP_0[?][KZ_0] else 0)
        | KZ_2 := KZ_1 + (if KD_DIFF / 2 modulo 2 = 1 then UP_1[?][KZ_1] else 0)
        | KZ_3 := KZ_2 + (if KD_DIFF / 4 modulo 2 = 1 then UP_2[?][KZ_2] else 0)
        | KZ_4 := KZ_3 + (if KD_DIFF / 8 modulo 2 = 1 then UP_3[?][KZ_3] else 0)
        | KZ_5 := KZ_4 + (if KD_DIFF / 16 modulo 2 = 1 then UP_4[?][KZ_4] else 0)
        | KZ_6 := KZ_5 + (if KD_DIFF / 32 modulo 2 = 1 then UP_5[?][KZ_5] else 0)
        | KZ_7 := KZ_6 + (if KD_DIFF / 64 modulo 2 = 1 then UP_6[?][KZ_6] else 0)
        | KZ_8 := KZ_7 + (if KD_DIFF / 128 modulo 2 = 1 then UP_7[?][KZ_7] else 0)
        | KZ_9 := KZ_8 + (if KD_DIFF / 256 modulo 2 = 1 then UP_8[?][KZ_8] else 0)
        | KZ_10 := KZ_9 + (if KD_DIFF / 512 modulo 2 = 1 then UP_9[?][KZ_9] else 0)
        | KZ_11 := KZ_10 + (if KD_DIFF / 1024 modulo 2 = 1 then UP_10[?][KZ_10] else 0)
        | KZ_12 := KZ_11 + (if KD_DIFF / 2048 modulo 2 = 1 then UP_11[?][KZ_11] else 0)
        | KZ_13 := KZ_12 + (if KD_DIFF / 4096 modulo 2 = 1 then UP_12[?][KZ_12] else 0)
        | KZ_14 := KZ_13 + (if KD_DIFF / 8192 modulo 2 = 1 then UP_13[?][KZ_13] else 0)
        | KZ_15 := KZ_14 + (if KD_DIFF / 16384 modulo 2 = 1 then UP_14[?][KZ_14] else 0)
        | KZ_16 := KZ_15 + (if KD_DIFF / 32768 modulo 2 = 1 then UP_15[?][KZ_15] else 0)
        | KZ_17 := KZ_16 + (if KD_DIFF / 65536 modulo 2 = 1 then UP_16[?][KZ_16] else 0)
        | KZ_18 := KZ_17 + (if KD_DIFF / 131072 modulo 2 = 1 then UP_17[?][KZ_17] else 0)
        | KZ_19 := KZ_18 + (if KD_DIFF / 262144 modulo 2 = 1 then UP_18[?][KZ_18] else 0)
        | KZ_20 := KZ_19 + (if KD_DIFF / 524288 modulo 2 = 1 then UP_19[?][KZ_19] else 0)
        | KD_LIFTED := KZ_20
        | KD_ANCESTOR_LR := KD_R_DEEPER and KD_LIFTED = KD_L
        | KD_ANCESTOR_RL := not KD_R_DEEPER and KD_LIFTED = KD_R
        | KA_20 := KD_LIFTED
        | KB_20 := KD_HIGH
        | KA_UP_19 := KA_20 + UP_19[?][KA_20]
        | KB_UP_19 := KB_20 + UP_19[?][KB_20]
        | KA_19 := if KA_UP_19 /= KB_UP_19 then KA_UP_19 else KA_20
        | KB_19 := if KA_UP_19 /= KB_UP_19 then KB_UP_19 else KB_20
        | KA_UP_18 := KA_19 + UP_18[?][KA_19]
        | KB_UP_18 := KB_19 + UP_18[?][KB_19]
        | KA_18 := if KA_UP_18 /= KB_UP_18 then KA_UP_18 else KA_19
        | KB_18 := if KA_UP_18 /= KB_UP_18 then KB_UP_18 else KB_19
        | KA_UP_17 := KA_18 + UP_17[?][KA_18]
        | KB_UP_17 := KB_18 + UP_17[?][KB_18]
        | KA_17 := if KA_UP_17 /= KB_UP_17 then KA_UP_17 else KA_18
        | KB_17 := if KA_UP_17 /= KB_UP_17 then KB_UP_17 else KB_18
        | KA_UP_16 := KA_17 + UP_16[?][KA_17]
        | KB_UP_16 := KB_17 + UP_16[?][KB_17]
        | KA_16 := if KA_UP_16 /= KB_UP_16 then KA_UP_16 else KA_17
        | KB_16 := if KA_UP_16 /= KB_UP_16 then KB_UP_16 else KB_17
        | KA_UP_15 := KA_16 + UP_15[?][KA_16]
        | KB_UP_15 := KB_16 + UP_15[?][KB_16]
        | KA_15 := if KA_UP_15 /= KB_UP_15 then KA_UP_15 else KA_16
        | KB_15 := if KA_UP_15 /= KB_UP_15 then KB_UP_15 else KB_16
        | KA_UP_14 := KA_15 + UP_14[?][KA_15]
        | KB_UP_14 := KB_15 + UP_14[?][KB_15]
        | KA_14 := if KA_UP_14 /= KB_UP_14 then KA_UP_14 else KA_15
        | KB_14 := if KA_UP_14 /= KB_UP_14 then KB_UP_14 else KB_15
        | KA_UP_13 := KA_14 + UP_13[?][KA_14]
        | KB_UP_13 := KB_14 + UP_13[?][KB_14]
        | KA_13 := if KA_UP_13 /= KB_UP_13 then KA_UP_13 else KA_14
        | KB_13 := if KA_UP_13 /= KB_UP_13 then KB_UP_13 else KB_14
        | KA_UP_12 := KA_13 + UP_12[?][KA_13]
        | KB_UP_12 := KB_13 + UP_12[?][KB_13]
        | KA_12 := if KA_UP_12 /= KB_UP_12 then KA_UP_12 else KA_13
        | KB_12 := if KA_UP_12 /= KB_UP_12 then KB_UP_12 else KB_13
        | KA_UP_11 := KA_12 + UP_11[?][KA_12]
        | KB_UP_11 := KB_12 + UP_11[?][KB_12]
        | KA_11 := if KA_UP_11 /= KB_UP_11 then KA_UP_11 else KA_12
        | KB_11 := if KA_UP_11 /= KB_UP_11 then KB_UP_11 else KB_12
        | KA_UP_10 := KA_11 + UP_10[?][KA_11]
        | KB_UP_10 := KB_11 + UP_10[?][KB_11]
        | KA_10 := if KA_UP_10 /= KB_UP_10 then KA_UP_10 else KA_11
        | KB_10 := if KA_UP_10 /= KB_UP_10 then KB_UP_10 else KB_11
        | KA_UP_9 := KA_10 + UP_9[?][KA_10]
        | KB_UP_9 := KB_10 + UP_9[?][KB_10]
        | KA_9 := if KA_UP_9 /= KB_UP_9 then KA_UP_9 else KA_10
        | KB_9 := if KA_UP_9 /= KB_UP_9 then KB_UP_9 else KB_10
        | KA_UP_8 := KA_9 + UP_8[?][KA_9]
        | KB_UP_8 := KB_9 + UP_8[?][KB_9]
        | KA_8 := if KA_UP_8 /= KB_UP_8 then KA_UP_8 else KA_9
        | KB_8 := if KA_UP_8 /= KB_UP_8 then KB_UP_8 else KB_9
        | KA_UP_7 := KA_8 + UP_7[?][KA_8]
        | KB_UP_7 := KB_8 + UP_7[?][KB_8]
        | KA_7 := if KA_UP_7 /= KB_UP_7 then KA_UP_7 else KA_8
        | KB_7 := if KA_UP_7 /= KB_UP_7 then KB_UP_7 else KB_8
        | KA_UP_6 := KA_7 + UP_6[?][KA_7]
        | KB_UP_6 := KB_7 + UP_6[?][KB_7]
        | KA_6 := if KA_UP_6 /= KB_UP_6 then KA_UP_6 else KA_7
        | KB_6 := if KA_UP_6 /= KB_UP_6 then KB_UP_6 else KB_7
        | KA_UP_5 := KA_6 + UP_5[?][KA_6]
        | KB_UP_5 := KB_6 + UP_5[?][KB_6]
        | KA_5 := if KA_UP_5 /= KB_UP_5 then KA_UP_5 else KA_6
        | KB_5 := if KA_UP_5 /= KB_UP_5 then KB_UP_5 else KB_6
        | KA_UP_4 := KA_5 + UP_4[?][KA_5]
        | KB_UP_4 := KB_5 + UP_4[?][KB_5]
        | KA_4 := if KA_UP_4 /= KB_UP_4 then KA_UP_4 else KA_5
        | KB_4 := if KA_UP_4 /= KB_UP_4 then KB_UP_4 else KB_5
        | KA_UP_3 := KA_4 + UP_3[?][KA_4]
        | KB_UP_3 := KB_4 + UP_3[?][KB_4]
        | KA_3 := if KA_UP_3 /= KB_UP_3 then KA_UP_3 else KA_4
        | KB_3 := if KA_UP_3 /= KB_UP_3 then KB_UP_3 else KB_4
        | KA_UP_2 := KA_3 + UP_2[?][KA_3]
        | KB_UP_2 := KB_3 + UP_2[?][KB_3]
        | KA_2 := if KA_UP_2 /= KB_UP_2 then KA_UP_2 else KA_3
        | KB_2 := if KA_UP_2 /= KB_UP_2 then KB_UP_2 else KB_3
        | KA_UP_1 := KA_2 + UP_1[?][KA_2]
        | KB_UP_1 := KB_2 + UP_1[?][KB_2]
        | KA_1 := if KA_UP_1 /= KB_UP_1 then KA_UP_1 else KA_2
        | KB_1 := if KA_UP_1 /= KB_UP_1 then KB_UP_1 else KB_2
        | KA_UP_0 := KA_1 + UP_0[?][KA_1]
        | KB_UP_0 := KB_1 + UP_0[?][KB_1]
        | KA_0 := if KA_UP_0 /= KB_UP_0 then KA_UP_0 else KA_1
        | KB_0 := if KA_UP_0 /= KB_UP_0 then KB_UP_0 else KB_1
        | KD_COMMON := KA_0 + UP_0[?][KA_0]
        | KD_ALIAS := if KD_SAMPLE then -1 else if KD_ANCESTOR_LR then (if KD_PRODUCT then KD_R else KD_L)
                   else if KD_ANCESTOR_RL then (if KD_PRODUCT then KD_L else KD_R) else -1
        | KD_PARENT := if KD_SAMPLE then KD_L else if KD_PRODUCT then (if KD_DEPTH_R > KD_DEPTH_L then KD_R else KD_L) else KD_COMMON
        | KD_NODE_LEFT := if KD_SAMPLE then DEF_LEFT[?][KD_DEF] else KD_L
        | KD_NODE_RIGHT := if KD_SAMPLE then -1 else KD_R
        | KD_PLACED := KD_TARGET_KIND /= CLK_NONE
        | KD_RESOLVES := KD_SETTLES and not KD_FITS_NO_TREE
        | KD_ALIASES := KD_RESOLVES and not KD_PLACED and KD_ALIAS >= 0
        | KD_CREATES := KD_RESOLVES and not KD_PLACED and KD_ALIAS < 0
        | KD_OLD_LEFT := NODE_LEFT1[?][KD_T] - 1
        | KD_OLD_RIGHT := NODE_RIGHT1[?][KD_T] - 1
        | KD_SAME := KD_TARGET_KIND = KD_KIND and (KD_OLD_LEFT = KD_NODE_LEFT and KD_OLD_RIGHT = KD_NODE_RIGHT
                                                or KD_OLD_LEFT = KD_NODE_RIGHT and KD_OLD_RIGHT = KD_NODE_LEFT)
        | KD_TWO_DEFINITIONS := KD_RESOLVES and KD_PLACED and (KD_ALIAS >= 0 or not KD_SAME)
        | KD_DONE := KD_HITS or KD_EQUAL or KD_RESOLVES and not KD_TWO_DEFINITIONS
        | KV_LIVE := AT_KS_WAIT and KC < GUARDED_COUNT[?]
        | KV_WAITS := KV_LIVE and NODE_KIND[?][KF1] = CLK_NONE
        | KF1_SOURCE := if AT_KS_ROWS then KC else if AT_KS_GROUPS then KG_HEAD
                     else if AT_KS_REWRITE then (if KW_BOTH_CTX then KW_MERGED else KW_V0)
                     else if AT_KS_TARGETS or AT_KS_DEFS then DEF_TARGET[?][K_LISTED_DEF]
                     else if AT_KS_GUARDS or AT_KS_WAIT then GUARDED[?][KC]
                     else KS_CLOCK
        | KF2_SOURCE := if AT_KS_ROWS then KR_X else if AT_KS_GROUPS then KG_MEMBER
                     else if AT_KS_REWRITE then (if KW_BOTH_CTX then KW_CONDITION else KW_V1)
                     else if AT_KS_DEFS then DEF_LEFT[?][KD_DEF]
                     else KS_GUARD_SOURCE
        | KF3_SOURCE := if KD_SAMPLE then -1 else DEF_RIGHT[?][KD_DEF]
        | KF1_0 := KF1_SOURCE
        | KF1_1 := KF1_0 + CK_LINK[?][KF1_0]
        | KF1_2 := KF1_1 + CK_LINK[?][KF1_1]
        | KF1_3 := KF1_2 + CK_LINK[?][KF1_2]
        | KF1_4 := KF1_3 + CK_LINK[?][KF1_3]
        | KF1_5 := KF1_4 + CK_LINK[?][KF1_4]
        | KF1_6 := KF1_5 + CK_LINK[?][KF1_5]
        | KF1_7 := KF1_6 + CK_LINK[?][KF1_6]
        | KF1_8 := KF1_7 + CK_LINK[?][KF1_7]
        | KF1_9 := KF1_8 + CK_LINK[?][KF1_8]
        | KF1_10 := KF1_9 + CK_LINK[?][KF1_9]
        | KF1_11 := KF1_10 + CK_LINK[?][KF1_10]
        | KF1_12 := KF1_11 + CK_LINK[?][KF1_11]
        | KF1_13 := KF1_12 + CK_LINK[?][KF1_12]
        | KF1_14 := KF1_13 + CK_LINK[?][KF1_13]
        | KF1_15 := KF1_14 + CK_LINK[?][KF1_14]
        | KF1_16 := KF1_15 + CK_LINK[?][KF1_15]
        | KF1_17 := KF1_16 + CK_LINK[?][KF1_16]
        | KF1_18 := KF1_17 + CK_LINK[?][KF1_17]
        | KF1_19 := KF1_18 + CK_LINK[?][KF1_18]
        | KF1_20 := KF1_19 + CK_LINK[?][KF1_19]
        | KF1_ROOT := KF1_20
        | KF1 := KF1_ROOT + CK_OFFICIAL[?][KF1_ROOT]
        | KF2_0 := KF2_SOURCE
        | KF2_1 := KF2_0 + CK_LINK[?][KF2_0]
        | KF2_2 := KF2_1 + CK_LINK[?][KF2_1]
        | KF2_3 := KF2_2 + CK_LINK[?][KF2_2]
        | KF2_4 := KF2_3 + CK_LINK[?][KF2_3]
        | KF2_5 := KF2_4 + CK_LINK[?][KF2_4]
        | KF2_6 := KF2_5 + CK_LINK[?][KF2_5]
        | KF2_7 := KF2_6 + CK_LINK[?][KF2_6]
        | KF2_8 := KF2_7 + CK_LINK[?][KF2_7]
        | KF2_9 := KF2_8 + CK_LINK[?][KF2_8]
        | KF2_10 := KF2_9 + CK_LINK[?][KF2_9]
        | KF2_11 := KF2_10 + CK_LINK[?][KF2_10]
        | KF2_12 := KF2_11 + CK_LINK[?][KF2_11]
        | KF2_13 := KF2_12 + CK_LINK[?][KF2_12]
        | KF2_14 := KF2_13 + CK_LINK[?][KF2_13]
        | KF2_15 := KF2_14 + CK_LINK[?][KF2_14]
        | KF2_16 := KF2_15 + CK_LINK[?][KF2_15]
        | KF2_17 := KF2_16 + CK_LINK[?][KF2_16]
        | KF2_18 := KF2_17 + CK_LINK[?][KF2_17]
        | KF2_19 := KF2_18 + CK_LINK[?][KF2_18]
        | KF2_20 := KF2_19 + CK_LINK[?][KF2_19]
        | KF2_ROOT := KF2_20
        | KF2 := KF2_ROOT + CK_OFFICIAL[?][KF2_ROOT]
        | KF3_0 := KF3_SOURCE
        | KF3_1 := KF3_0 + CK_LINK[?][KF3_0]
        | KF3_2 := KF3_1 + CK_LINK[?][KF3_1]
        | KF3_3 := KF3_2 + CK_LINK[?][KF3_2]
        | KF3_4 := KF3_3 + CK_LINK[?][KF3_3]
        | KF3_5 := KF3_4 + CK_LINK[?][KF3_4]
        | KF3_6 := KF3_5 + CK_LINK[?][KF3_5]
        | KF3_7 := KF3_6 + CK_LINK[?][KF3_6]
        | KF3_8 := KF3_7 + CK_LINK[?][KF3_7]
        | KF3_9 := KF3_8 + CK_LINK[?][KF3_8]
        | KF3_10 := KF3_9 + CK_LINK[?][KF3_9]
        | KF3_11 := KF3_10 + CK_LINK[?][KF3_10]
        | KF3_12 := KF3_11 + CK_LINK[?][KF3_11]
        | KF3_13 := KF3_12 + CK_LINK[?][KF3_12]
        | KF3_14 := KF3_13 + CK_LINK[?][KF3_13]
        | KF3_15 := KF3_14 + CK_LINK[?][KF3_14]
        | KF3_16 := KF3_15 + CK_LINK[?][KF3_15]
        | KF3_17 := KF3_16 + CK_LINK[?][KF3_16]
        | KF3_18 := KF3_17 + CK_LINK[?][KF3_17]
        | KF3_19 := KF3_18 + CK_LINK[?][KF3_18]
        | KF3_20 := KF3_19 + CK_LINK[?][KF3_19]
        | KF3_ROOT := KF3_20
        | KF3 := KF3_ROOT + CK_OFFICIAL[?][KF3_ROOT]
        | KN_ALIAS_ROOT := if KD_ALIAS = KD_L then KF2_ROOT else KF3_ROOT
        | KN_UNITES := KR_UNITES or KG_UNITES or KW_UNITES or KS_ATTACHES or KD_EQUAL or KD_ALIASES
        | KN_A := KF1_ROOT
        | KN_B := if KD_ALIASES then KN_ALIAS_ROOT else KF2_ROOT
        | KN_OFFICIAL := if KD_ALIASES then KD_ALIAS else KF2
        | KN_LINKS := KN_UNITES and KN_A /= KN_B
        | KN_SIZE_A := CK_SIZE[?][KN_A]
        | KN_SIZE_B := CK_SIZE[?][KN_B]
        | KN_A_ON_TOP := KN_SIZE_A > KN_SIZE_B
        | KN_TOP := if KN_A_ON_TOP then KN_A else KN_B
        | KN_CHILD := if KN_A_ON_TOP then KN_B else KN_A
        | CK_LINK := CK_LINK[?] next (if KN_LINKS then KN_CHILD else -1) : KN_TOP - KN_CHILD
        | CK_SIZE := CK_SIZE[?] next (if KN_LINKS then KN_TOP else -1) : KN_SIZE_A + KN_SIZE_B + 1
        | CK_OFFICIAL := CK_OFFICIAL[?] next (if KN_LINKS then KN_TOP else -1) : KN_OFFICIAL - KN_TOP
        | SAMPLE_OF := SAMPLE_OF[?] next (if KR_CREATES then KR_CONDITION else -1) : KR_NEW_SAMPLE + 1
        | SAMPLE_ROW := SAMPLE_ROW[?] next (if KR_CREATES then K_SAMPLES_NOW else -1) : KR_CONDITION
        | K_SAMPLE_COUNT := K_SAMPLES_NOW + integer(KR_CREATES)
        | KQ_APPENDS := KR_DEFINES or KM_LIVE
        | KQ_DEFS_FULL := KQ_APPENDS and K_DEFS_NOW >= DEF_CAP
        | KQ_SLOT := if KQ_APPENDS and not KQ_DEFS_FULL then K_DEFS_NOW else -1
        | KQ_REWRITE_SLOT := if KQ_SLOT >= 0 then KQ_SLOT else if KW_PRODUCT then KC else -1
        | DEF_KIND := DEF_KIND[?] next KQ_REWRITE_SLOT
                    : (if KW_PRODUCT or KR_IS_WHEN and not KM_LIVE then CLK_PRODUCT else if KM_LIVE then CLK_SAMPLE else CLK_SUM)
        | DEF_TARGET := DEF_TARGET[?] next KQ_SLOT : (if KM_LIVE then ROW_COUNT + KC else KC)
        | DEF_LEFT := DEF_LEFT[?] next KQ_REWRITE_SLOT : (if KW_PRODUCT then KW_V0 else if KM_LIVE then KM_CONDITION else KR_LEFT)
        | DEF_RIGHT := DEF_RIGHT[?] next KQ_REWRITE_SLOT
                     : (if KW_PRODUCT then KW_CONDITION else if KM_LIVE then -1 else if KR_IS_WHEN then KR_SAMPLE else KR_RIGHT)
        | DEF_TOKEN := DEF_TOKEN[?] next KQ_SLOT : ROWS_TOKEN[if KM_LIVE then KM_CONDITION else KC]
        | DEF_DONE := DEF_DONE[?] next (if KQ_SLOT >= 0 then KQ_SLOT else if KW_UNITES then KC else if KD_DONE then KD_DEF else -1)
                    : KQ_SLOT < 0
        | DEF_COUNT := K_DEFS_NOW + integer(KQ_SLOT >= 0)
        | KO_APPENDS := KR_OBLIGES or KD_OBLIGES
        | KO_FULL := KO_APPENDS and K_OBS_NOW >= OB_CAP
        | KO_SLOT := if KO_APPENDS and not KO_FULL then K_OBS_NOW else -1
        | OB_SMALL := OB_SMALL[?] next KO_SLOT : (if KR_OBLIGES then KR_LEFT else if KD_KIND = CLK_SUM then KD_OTHER else KD_T)
        | OB_BIG := OB_BIG[?] next KO_SLOT : (if KR_OBLIGES then KC else if KD_KIND = CLK_SUM then KD_T else KD_OTHER)
        | OB_TOKEN := OB_TOKEN[?] next KO_SLOT : (if KR_OBLIGES then ROWS_TOKEN[KC] else DEF_TOKEN[?][KD_DEF])
        | OB_COUNT := K_OBS_NOW + integer(KO_SLOT >= 0)
        | GUARDED := GUARDED[?] next (if KR_GUARDED then GUARDED_COUNT[?] else -1) : KC
        | GUARDED_COUNT := GUARDED_COUNT[?] + integer(KR_GUARDED)
        | TSTAMP := TSTAMP[?] next (if KT_MARKS then KF1 else -1) : KRN
        | CGSTAMP := CGSTAMP[?] next (if KU_SETS then KF1 else -1) : KRN
        | CGUARD := CGUARD[?] next (if KU_SETS then KF1 else -1) : ROWS_GUARD[KU_ROW]
        | CAND := CAND[?] next (if KS_KEEPS then CK_CAND_W[?] else -1) : KS_CLOCK
        | PEND := PEND[?] next (if KD_WAITS then CK_PEND_W[?] else -1) : KD_DEF
        | KP_SLOT := if KS_ROOTS then KS_CLOCK else if KD_CREATES then KD_T else -1
        | NODE_KIND := NODE_KIND[?] next KP_SLOT : (if KS_ROOTS then CLK_ROOT else KD_KIND)
        | NODE_PARENT1 := NODE_PARENT1[?] next KP_SLOT : (if KS_ROOTS then 0 else KD_PARENT + 1)
        | NODE_DEPTH := NODE_DEPTH[?] next KP_SLOT : (if KS_ROOTS then 0 else NODE_DEPTH[?][KD_PARENT] + 1)
        | NODE_ROOT1 := NODE_ROOT1[?] next KP_SLOT : (if KS_ROOTS then KS_CLOCK + 1 else NODE_ROOT1[?][KD_PARENT])
        | NODE_LEFT1 := NODE_LEFT1[?] next KP_SLOT : (if KS_ROOTS then 0 else KD_NODE_LEFT + 1)
        | NODE_RIGHT1 := NODE_RIGHT1[?] next KP_SLOT : (if KS_ROOTS then 0 else KD_NODE_RIGHT + 1)
        | KY_0 := KD_PARENT
        | KY_1 := KY_0 + UP_0[?][KY_0]
        | KY_2 := KY_1 + UP_1[?][KY_1]
        | KY_3 := KY_2 + UP_2[?][KY_2]
        | KY_4 := KY_3 + UP_3[?][KY_3]
        | KY_5 := KY_4 + UP_4[?][KY_4]
        | KY_6 := KY_5 + UP_5[?][KY_5]
        | KY_7 := KY_6 + UP_6[?][KY_6]
        | KY_8 := KY_7 + UP_7[?][KY_7]
        | KY_9 := KY_8 + UP_8[?][KY_8]
        | KY_10 := KY_9 + UP_9[?][KY_9]
        | KY_11 := KY_10 + UP_10[?][KY_10]
        | KY_12 := KY_11 + UP_11[?][KY_11]
        | KY_13 := KY_12 + UP_12[?][KY_12]
        | KY_14 := KY_13 + UP_13[?][KY_13]
        | KY_15 := KY_14 + UP_14[?][KY_14]
        | KY_16 := KY_15 + UP_15[?][KY_15]
        | KY_17 := KY_16 + UP_16[?][KY_16]
        | KY_18 := KY_17 + UP_17[?][KY_17]
        | KY_19 := KY_18 + UP_18[?][KY_18]
        | UP_0 := UP_0[?] next (if KD_CREATES then KD_T else -1) : KY_0 - KD_T
        | UP_1 := UP_1[?] next (if KD_CREATES then KD_T else -1) : KY_1 - KD_T
        | UP_2 := UP_2[?] next (if KD_CREATES then KD_T else -1) : KY_2 - KD_T
        | UP_3 := UP_3[?] next (if KD_CREATES then KD_T else -1) : KY_3 - KD_T
        | UP_4 := UP_4[?] next (if KD_CREATES then KD_T else -1) : KY_4 - KD_T
        | UP_5 := UP_5[?] next (if KD_CREATES then KD_T else -1) : KY_5 - KD_T
        | UP_6 := UP_6[?] next (if KD_CREATES then KD_T else -1) : KY_6 - KD_T
        | UP_7 := UP_7[?] next (if KD_CREATES then KD_T else -1) : KY_7 - KD_T
        | UP_8 := UP_8[?] next (if KD_CREATES then KD_T else -1) : KY_8 - KD_T
        | UP_9 := UP_9[?] next (if KD_CREATES then KD_T else -1) : KY_9 - KD_T
        | UP_10 := UP_10[?] next (if KD_CREATES then KD_T else -1) : KY_10 - KD_T
        | UP_11 := UP_11[?] next (if KD_CREATES then KD_T else -1) : KY_11 - KD_T
        | UP_12 := UP_12[?] next (if KD_CREATES then KD_T else -1) : KY_12 - KD_T
        | UP_13 := UP_13[?] next (if KD_CREATES then KD_T else -1) : KY_13 - KD_T
        | UP_14 := UP_14[?] next (if KD_CREATES then KD_T else -1) : KY_14 - KD_T
        | UP_15 := UP_15[?] next (if KD_CREATES then KD_T else -1) : KY_15 - KD_T
        | UP_16 := UP_16[?] next (if KD_CREATES then KD_T else -1) : KY_16 - KD_T
        | UP_17 := UP_17[?] next (if KD_CREATES then KD_T else -1) : KY_17 - KD_T
        | UP_18 := UP_18[?] next (if KD_CREATES then KD_T else -1) : KY_18 - KD_T
        | UP_19 := UP_19[?] next (if KD_CREATES then KD_T else -1) : KY_19 - KD_T
        | K_CAPACITY := if KR_TOO_MANY or KR_CLOCKS_FULL then F_CAP_CLOCKS else if KQ_DEFS_FULL then F_CAP_DEFINITIONS
                     else if KO_FULL then F_CAP_OBLIGATIONS else 0
        | KD_ENDS_ROUND := AT_KS_DEFS and not KD_LIVE
        | K_PROGRESS_NOW := CK_PROGRESS[?] or KS_ATTACHES or KS_ROOTS or KD_DONE
        | K_STALLS := KD_ENDS_ROUND and not K_PROGRESS_NOW and CK_PEND_W[?] > 0
        | K_MESSAGE_NOW := if KR_NO_CLOCK or KG_NO_CLOCK then T_NO_CLOCK else if KR_DELAY_CONSTANT then T_DELAY_CONSTANT
                        else if K_CAPACITY /= 0 then T_CAPACITY
                        else if KD_FITS_NO_TREE then T_FITS_NO_TREE else if KD_TWO_DEFINITIONS then T_TWO_DEFINITIONS
                        else if K_STALLS then T_CLOCK_CYCLE else if KV_WAITS then T_GUARD_CYCLE else 0
        | K_FAILS := K_MESSAGE_NOW /= 0
        | CK_MESSAGE := if K_FAILS then K_MESSAGE_NOW else CK_MESSAGE[?]
        | CK_TOKEN := if not K_FAILS then CK_TOKEN[?] else if KG_NO_CLOCK then FLAT_GROUP_TOKEN[KC]
                     else if K_STALLS then DEF_TOKEN[?][PEND[?][0]] else if KD_FITS_NO_TREE or KD_TWO_DEFINITIONS then DEF_TOKEN[?][KD_DEF]
                     else if AT_KS_ROWS and not KR_TOO_MANY then ROWS_TOKEN[KC] else -1
        | CK_ARGUMENT0 := if not K_FAILS then CK_ARGUMENT0[?] else K_CAPACITY
        | CK_CLOCK0 := if K_FAILS then KD_T else CK_CLOCK0[?]
        | CK_CLOCK1 := if K_FAILS then KD_ROOT_L else CK_CLOCK1[?]
        | CK_CLOCK2 := if K_FAILS then KD_ROOT_R else CK_CLOCK2[?]
        | KX_ROUND_START := AT_KS_REWRITE and not KW_LIVE or KD_ENDS_ROUND and K_PROGRESS_NOW
        | CK_STATE := if K_FAILS then KS_FAILED
                    else if AT_KS_ROWS then (if KR_LIVE then KS_ROWS else KS_SAMPLES)
                    else if AT_KS_SAMPLES then (if KM_LIVE then KS_SAMPLES else KS_GROUPS)
                    else if AT_KS_GROUPS then (if KG_LIVE then KS_GROUPS else KS_REWRITE)
                    else if AT_KS_REWRITE then (if KW_LIVE then KS_REWRITE else KS_TARGETS)
                    else if AT_KS_TARGETS then (if KT_LIVE then KS_TARGETS else KS_GUARDS)
                    else if AT_KS_GUARDS then (if KU_LIVE then KS_GUARDS else KS_SCAN)
                    else if AT_KS_SCAN then (if KS_LIVE then KS_SCAN else KS_DEFS)
                    else if AT_KS_DEFS then (if KD_LIVE then KS_DEFS else if K_PROGRESS_NOW then KS_TARGETS else KS_WAIT)
                    else if AT_KS_WAIT then (if KV_LIVE then KS_WAIT else KS_DONE)
                    else KS_NOW
        | K_STEPS_ON := KR_LIVE and not KR_ENDS or KG_LIVE and not KG_ENDS
        | CK_SUB := if K_STEPS_ON then KK + 1 else 0
        | CK_CURSOR := if CK_STATE /= KS_NOW then 0 else if K_STEPS_ON then KC else KC + 1
        | CK_ROUND := KRN + integer(KD_ENDS_ROUND and K_PROGRESS_NOW)
        | CK_PROGRESS := not KX_ROUND_START and K_PROGRESS_NOW
        | CK_DEF_LIMIT := if AT_KS_REWRITE and not KW_LIVE then K_DEFS_NOW else if KX_ROUND_START then CK_PEND_W[?] else K_DEF_LIMIT
        | CK_SCAN_LIMIT := if AT_KS_REWRITE and not KW_LIVE then ROW_COUNT + K_SAMPLES_NOW
                         else if KX_ROUND_START then CK_CAND_W[?] else CK_SCAN_LIMIT[?]
        | CK_CAND_W := if AT_KS_GUARDS then 0 else CK_CAND_W[?] + integer(KS_KEEPS)
        | CK_PEND_W := if AT_KS_SCAN then 0 else CK_PEND_W[?] + integer(KD_WAITS)
        |)
     with (| CK_STATE := KS_ROWS | CK_CURSOR := 0 | CK_SUB := 0 | CK_ROUND := 1 | CK_PROGRESS := false
           | CK_DEF_LIMIT := 0 | CK_SCAN_LIMIT := 0 | CK_CAND_W := 0 | CK_PEND_W := 0 | K_SAMPLE_COUNT := 0
           | DEF_COUNT := 0 | OB_COUNT := 0 | GUARDED_COUNT := 0 | CK_MESSAGE := 0 | CK_TOKEN := -1
           | CK_ARGUMENT0 := 0 | CK_CLOCK0 := -1 | CK_CLOCK1 := -1 | CK_CLOCK2 := -1 |)
     end
   | CK_DONE := CLOCKS_RUN and CK_STATE = KS_DONE
   | CLOCK_TOTAL := ROW_COUNT + K_SAMPLE_COUNT
   | OW_INDEX := 0 .. (if CK_DONE then long(2) * long(OB_COUNT) * (long(4) * long(CLOCK_TOTAL) + long(1)) else long(-1))
   | iterate OW_INDEX of
       (| OV_NOW := OW_STATE[?]
        | OV_O := OW_O[?]
        | OV_SIDE := OW_SIDE[?]
        | OV_STARTS := OV_NOW = OS_START and OV_O < OB_COUNT
        | OV_WALKS := OV_NOW = OS_WALK
        | OV_F_0 := if OV_SIDE = 0 then OB_SMALL[OV_O] else OB_BIG[OV_O]
        | OV_F_1 := OV_F_0 + CK_LINK[OV_F_0]
        | OV_F_2 := OV_F_1 + CK_LINK[OV_F_1]
        | OV_F_3 := OV_F_2 + CK_LINK[OV_F_2]
        | OV_F_4 := OV_F_3 + CK_LINK[OV_F_3]
        | OV_F_5 := OV_F_4 + CK_LINK[OV_F_4]
        | OV_F_6 := OV_F_5 + CK_LINK[OV_F_5]
        | OV_F_7 := OV_F_6 + CK_LINK[OV_F_6]
        | OV_F_8 := OV_F_7 + CK_LINK[OV_F_7]
        | OV_F_9 := OV_F_8 + CK_LINK[OV_F_8]
        | OV_F_10 := OV_F_9 + CK_LINK[OV_F_9]
        | OV_F_11 := OV_F_10 + CK_LINK[OV_F_10]
        | OV_F_12 := OV_F_11 + CK_LINK[OV_F_11]
        | OV_F_13 := OV_F_12 + CK_LINK[OV_F_12]
        | OV_F_14 := OV_F_13 + CK_LINK[OV_F_13]
        | OV_F_15 := OV_F_14 + CK_LINK[OV_F_14]
        | OV_F_16 := OV_F_15 + CK_LINK[OV_F_15]
        | OV_F_17 := OV_F_16 + CK_LINK[OV_F_16]
        | OV_F_18 := OV_F_17 + CK_LINK[OV_F_17]
        | OV_F_19 := OV_F_18 + CK_LINK[OV_F_18]
        | OV_F_20 := OV_F_19 + CK_LINK[OV_F_19]
        | OV_FIRST := OV_F_20 + CK_OFFICIAL[OV_F_20]
        | OV_N := OW_NODE[?]
        | OV_S := OW_SLOT[?]
        | OV_DEPTH := OW_DEPTH[?]
        | OV_KIND := NODE_KIND[OV_N]
        | OV_SPLITS := OV_KIND = CLK_SUM or OV_KIND = CLK_PRODUCT
        | OV_POPS := OV_WALKS and OV_S >= 3
        | OV_SLOT_LIVE := OV_WALKS and not OV_POPS
        | OV_APPLIES := OV_SLOT_LIVE and (if OV_S = 0 then OV_SIDE = 0 and OV_KIND /= CLK_ROOT else OV_SPLITS)
        | OV_NEXT := if OV_S = 0 then NODE_PARENT1[OV_N] - 1 else if OV_S = 1 then NODE_LEFT1[OV_N] - 1 else NODE_RIGHT1[OV_N] - 1
        | OV_CAND := if OV_STARTS then OV_FIRST else OV_NEXT
        | OV_LOOK := if OV_CAND < 0 then 0 else OV_CAND
        | OV_STAMP := 2 * OV_O + OV_SIDE + 1
        | OV_PUSHES := OV_APPLIES and OV_CAND >= 0 and OW_STAMP[?][OV_LOOK] /= OV_STAMP
        | OV_ENTERS := OV_STARTS or OV_PUSHES
        | OW_STAMP := OW_STAMP[?] next (if OV_ENTERS then OV_CAND else -1) : OV_STAMP
        | OW_STACK_NODE := OW_STACK_NODE[?] next (if OV_PUSHES then OV_DEPTH - 1 else -1) : OV_N
        | OW_STACK_SLOT := OW_STACK_SLOT[?] next (if OV_PUSHES then OV_DEPTH - 1 else -1) : OV_S + 1
        | OV_BELOW := if OV_DEPTH >= 2 then OV_DEPTH - 2 else 0
        | OV_FINISHES := OV_POPS and OV_DEPTH = 1
        | OW_COUNT := if OV_STARTS then 1 else OW_COUNT[?] + integer(OV_PUSHES)
        | OW_CLOCKS := if OV_FINISHES and OV_SIDE = 0 then OW_COUNT[?] else OW_CLOCKS[?]
        | OW_BOUND := OW_BOUND[?] + (if OV_FINISHES and OV_SIDE = 1 then long(OW_CLOCKS[?]) * long(OW_COUNT[?]) else long(0))
        | OW_STATE := if OV_STARTS then OS_WALK else if OV_NOW = OS_START then OS_DONE else if OV_FINISHES then OS_START else OV_NOW
        | OW_SIDE := if OV_FINISHES then 1 - OV_SIDE else OV_SIDE
        | OW_O := OV_O + integer(OV_FINISHES and OV_SIDE = 1)
        | OW_NODE := if OV_ENTERS then OV_CAND else if OV_POPS then OW_STACK_NODE[?][OV_BELOW] else OV_N
        | OW_SLOT := if OV_ENTERS then 0 else if OV_POPS then OW_STACK_SLOT[?][OV_BELOW] else if OV_WALKS then OV_S + 1 else OV_S
        | OW_DEPTH := if OV_STARTS then 1 else OV_DEPTH + integer(OV_PUSHES) - integer(OV_POPS)
        |)
     with (| OW_STATE := OS_START | OW_O := 0 | OW_SIDE := 0 | OW_NODE := 0 | OW_SLOT := 0 | OW_DEPTH := 0
           | OW_COUNT := 0 | OW_CLOCKS := 0 | OW_BOUND := long(0) |)
     end
   | OW_DONE := CK_DONE and OW_STATE = OS_DONE
   | CO_INDEX := 0 .. (if OW_DONE then long(2) * long(OB_COUNT) + long(6) * OW_BOUND + long(2) else long(-1))
   | iterate CO_INDEX of
       (| OG_NOW := CO_STATE[?]
        | OG_O := CO_OBLIGATION[?]
        | OG_STAMP := OG_O + 1
        | OG_STARTS := OG_NOW = OS_START and OG_O < OB_COUNT
        | OG_WALKS := OG_NOW = OS_WALK
        | OF1_0 := OB_SMALL[OG_O]
        | OF1_1 := OF1_0 + CK_LINK[OF1_0]
        | OF1_2 := OF1_1 + CK_LINK[OF1_1]
        | OF1_3 := OF1_2 + CK_LINK[OF1_2]
        | OF1_4 := OF1_3 + CK_LINK[OF1_3]
        | OF1_5 := OF1_4 + CK_LINK[OF1_4]
        | OF1_6 := OF1_5 + CK_LINK[OF1_5]
        | OF1_7 := OF1_6 + CK_LINK[OF1_6]
        | OF1_8 := OF1_7 + CK_LINK[OF1_7]
        | OF1_9 := OF1_8 + CK_LINK[OF1_8]
        | OF1_10 := OF1_9 + CK_LINK[OF1_9]
        | OF1_11 := OF1_10 + CK_LINK[OF1_10]
        | OF1_12 := OF1_11 + CK_LINK[OF1_11]
        | OF1_13 := OF1_12 + CK_LINK[OF1_12]
        | OF1_14 := OF1_13 + CK_LINK[OF1_13]
        | OF1_15 := OF1_14 + CK_LINK[OF1_14]
        | OF1_16 := OF1_15 + CK_LINK[OF1_15]
        | OF1_17 := OF1_16 + CK_LINK[OF1_16]
        | OF1_18 := OF1_17 + CK_LINK[OF1_17]
        | OF1_19 := OF1_18 + CK_LINK[OF1_18]
        | OF1_20 := OF1_19 + CK_LINK[OF1_19]
        | OF1_ROOT := OF1_20
        | OF1 := OF1_ROOT + CK_OFFICIAL[OF1_ROOT]
        | OF2_0 := OB_BIG[OG_O]
        | OF2_1 := OF2_0 + CK_LINK[OF2_0]
        | OF2_2 := OF2_1 + CK_LINK[OF2_1]
        | OF2_3 := OF2_2 + CK_LINK[OF2_2]
        | OF2_4 := OF2_3 + CK_LINK[OF2_3]
        | OF2_5 := OF2_4 + CK_LINK[OF2_4]
        | OF2_6 := OF2_5 + CK_LINK[OF2_5]
        | OF2_7 := OF2_6 + CK_LINK[OF2_6]
        | OF2_8 := OF2_7 + CK_LINK[OF2_7]
        | OF2_9 := OF2_8 + CK_LINK[OF2_8]
        | OF2_10 := OF2_9 + CK_LINK[OF2_9]
        | OF2_11 := OF2_10 + CK_LINK[OF2_10]
        | OF2_12 := OF2_11 + CK_LINK[OF2_11]
        | OF2_13 := OF2_12 + CK_LINK[OF2_12]
        | OF2_14 := OF2_13 + CK_LINK[OF2_13]
        | OF2_15 := OF2_14 + CK_LINK[OF2_14]
        | OF2_16 := OF2_15 + CK_LINK[OF2_15]
        | OF2_17 := OF2_16 + CK_LINK[OF2_16]
        | OF2_18 := OF2_17 + CK_LINK[OF2_17]
        | OF2_19 := OF2_18 + CK_LINK[OF2_18]
        | OF2_20 := OF2_19 + CK_LINK[OF2_19]
        | OF2_ROOT := OF2_20
        | OF2 := OF2_ROOT + CK_OFFICIAL[OF2_ROOT]
        | OG_SMALL_ROOT := NODE_ROOT1[OF1] - 1
        | OG_BIG_ROOT := NODE_ROOT1[OF2] - 1
        | OG_FITS_NO_TREE := OG_STARTS and OG_SMALL_ROOT /= OG_BIG_ROOT
        | OG_OPENS := OG_STARTS and not OG_FITS_NO_TREE
        | OG_P := CO_TOP[?]
        | OG_S := CO_TOP_SLOT[?]
        | OG_DEPTH := CO_DEPTH[?]
        | OG_C := PAIR_CLOCK[?][OG_P]
        | OG_K := PAIR_CONTAINER[?][OG_P]
        | OG_KIND_C := NODE_KIND[OG_C]
        | OG_KIND_K := NODE_KIND[OG_K]
        | OG_DIFF := NODE_DEPTH[OG_C] - NODE_DEPTH[OG_K]
        | OZ_0 := OG_C
        | OZ_1 := OZ_0 + (if OG_DIFF / 1 modulo 2 = 1 then UP_0[OZ_0] else 0)
        | OZ_2 := OZ_1 + (if OG_DIFF / 2 modulo 2 = 1 then UP_1[OZ_1] else 0)
        | OZ_3 := OZ_2 + (if OG_DIFF / 4 modulo 2 = 1 then UP_2[OZ_2] else 0)
        | OZ_4 := OZ_3 + (if OG_DIFF / 8 modulo 2 = 1 then UP_3[OZ_3] else 0)
        | OZ_5 := OZ_4 + (if OG_DIFF / 16 modulo 2 = 1 then UP_4[OZ_4] else 0)
        | OZ_6 := OZ_5 + (if OG_DIFF / 32 modulo 2 = 1 then UP_5[OZ_5] else 0)
        | OZ_7 := OZ_6 + (if OG_DIFF / 64 modulo 2 = 1 then UP_6[OZ_6] else 0)
        | OZ_8 := OZ_7 + (if OG_DIFF / 128 modulo 2 = 1 then UP_7[OZ_7] else 0)
        | OZ_9 := OZ_8 + (if OG_DIFF / 256 modulo 2 = 1 then UP_8[OZ_8] else 0)
        | OZ_10 := OZ_9 + (if OG_DIFF / 512 modulo 2 = 1 then UP_9[OZ_9] else 0)
        | OZ_11 := OZ_10 + (if OG_DIFF / 1024 modulo 2 = 1 then UP_10[OZ_10] else 0)
        | OZ_12 := OZ_11 + (if OG_DIFF / 2048 modulo 2 = 1 then UP_11[OZ_11] else 0)
        | OZ_13 := OZ_12 + (if OG_DIFF / 4096 modulo 2 = 1 then UP_12[OZ_12] else 0)
        | OZ_14 := OZ_13 + (if OG_DIFF / 8192 modulo 2 = 1 then UP_13[OZ_13] else 0)
        | OZ_15 := OZ_14 + (if OG_DIFF / 16384 modulo 2 = 1 then UP_14[OZ_14] else 0)
        | OZ_16 := OZ_15 + (if OG_DIFF / 32768 modulo 2 = 1 then UP_15[OZ_15] else 0)
        | OZ_17 := OZ_16 + (if OG_DIFF / 65536 modulo 2 = 1 then UP_16[OZ_16] else 0)
        | OZ_18 := OZ_17 + (if OG_DIFF / 131072 modulo 2 = 1 then UP_17[OZ_17] else 0)
        | OZ_19 := OZ_18 + (if OG_DIFF / 262144 modulo 2 = 1 then UP_18[OZ_18] else 0)
        | OZ_20 := OZ_19 + (if OG_DIFF / 524288 modulo 2 = 1 then UP_19[OZ_19] else 0)
        | OG_INSIDE := OG_DIFF >= 0 and OZ_20 = OG_K
        | OG_C_SPLITS := OG_KIND_C = CLK_SUM or OG_KIND_C = CLK_PRODUCT
        | OG_K_SPLITS := OG_KIND_K = CLK_SUM or OG_KIND_K = CLK_PRODUCT
        | OG_POPS := OG_WALKS and (OG_S >= 5 or OG_INSIDE)
        | OG_SLOT_LIVE := OG_WALKS and not OG_POPS
        | OG_APPLIES := OG_SLOT_LIVE and (if OG_S = 0 then OG_KIND_C /= CLK_ROOT else if OG_S <= 2 then OG_C_SPLITS else OG_K_SPLITS)
        | OG_NEXT_CLOCK := if OG_S = 0 then NODE_PARENT1[OG_C] - 1 else if OG_S = 1 then NODE_LEFT1[OG_C] - 1
                       else if OG_S = 2 then NODE_RIGHT1[OG_C] - 1 else OG_C
        | OG_NEXT_CONTAINER := if OG_S <= 2 then OG_K else if OG_S = 3 then NODE_LEFT1[OG_K] - 1 else NODE_RIGHT1[OG_K] - 1
        | OG_PAIR_CLOCK := if OG_STARTS then OF1 else OG_NEXT_CLOCK
        | OG_PAIR_CONTAINER := if OG_STARTS then OF2 else OG_NEXT_CONTAINER
        | OG_CLOCK_LOCAL := if CLOCK_STAMP[?][OG_PAIR_CLOCK] = OG_STAMP then CLOCK_LOCAL[?][OG_PAIR_CLOCK] else -1
        | OG_CONTAINER_LOCAL := if CONTAINER_STAMP[?][OG_PAIR_CONTAINER] = OG_STAMP then CONTAINER_LOCAL[?][OG_PAIR_CONTAINER] else -1
        | OG_CLOCK_COUNT := if OG_STARTS then 0 else CO_CLOCK_COUNT[?]
        | OG_CONTAINER_COUNT := if OG_STARTS then 0 else CO_CONTAINER_COUNT[?]
        | OG_PAIR_COUNT := if OG_STARTS then 0 else CO_PAIR_COUNT[?]
        | OG_CLOCK_AT := if OG_CLOCK_LOCAL >= 0 then OG_CLOCK_LOCAL else OG_CLOCK_COUNT
        | OG_CONTAINER_AT := if OG_CONTAINER_LOCAL >= 0 then OG_CONTAINER_LOCAL else OG_CONTAINER_COUNT
        | OG_CELL := OG_CLOCK_AT * PAIR_STRIDE + OG_CONTAINER_AT
        | OG_FOUND := OG_CLOCK_LOCAL >= 0 and OG_CONTAINER_LOCAL >= 0 and GRID_STAMP[?][OG_CELL] = OG_STAMP
        | OG_ADDS := OG_OPENS or OG_APPLIES and not OG_FOUND
        | OG_PAIRS_FULL := OG_ADDS and (OG_PAIR_COUNT >= PAIR_CAP
                                        or OG_CLOCK_LOCAL < 0 and OG_CLOCK_COUNT >= PAIR_STRIDE
                                        or OG_CONTAINER_LOCAL < 0 and OG_CONTAINER_COUNT >= PAIR_STRIDE)
        | OG_NEW := OG_ADDS and not OG_PAIRS_FULL
        | OG_Q := if OG_FOUND then GRID_PAIR[?][OG_CELL] else OG_PAIR_COUNT
        | CLOCK_STAMP := CLOCK_STAMP[?] next (if OG_NEW and OG_CLOCK_LOCAL < 0 then OG_PAIR_CLOCK else -1) : OG_STAMP
        | CLOCK_LOCAL := CLOCK_LOCAL[?] next (if OG_NEW and OG_CLOCK_LOCAL < 0 then OG_PAIR_CLOCK else -1) : OG_CLOCK_COUNT
        | CONTAINER_STAMP := CONTAINER_STAMP[?] next (if OG_NEW and OG_CONTAINER_LOCAL < 0 then OG_PAIR_CONTAINER else -1) : OG_STAMP
        | CONTAINER_LOCAL := CONTAINER_LOCAL[?] next (if OG_NEW and OG_CONTAINER_LOCAL < 0 then OG_PAIR_CONTAINER else -1)
                           : OG_CONTAINER_COUNT
        | GRID_STAMP := GRID_STAMP[?] next (if OG_NEW then OG_CELL else -1) : OG_STAMP
        | GRID_PAIR := GRID_PAIR[?] next (if OG_NEW then OG_CELL else -1) : OG_PAIR_COUNT
        | PAIR_CLOCK := PAIR_CLOCK[?] next (if OG_NEW then OG_PAIR_COUNT else -1) : OG_PAIR_CLOCK
        | PAIR_CONTAINER := PAIR_CONTAINER[?] next (if OG_NEW then OG_PAIR_COUNT else -1) : OG_PAIR_CONTAINER
        | CO_CLOCK_COUNT := OG_CLOCK_COUNT + integer(OG_NEW and OG_CLOCK_LOCAL < 0)
        | CO_CONTAINER_COUNT := OG_CONTAINER_COUNT + integer(OG_NEW and OG_CONTAINER_LOCAL < 0)
        | CO_PAIR_COUNT := OG_PAIR_COUNT + integer(OG_NEW)
        | OG_LINKS := OG_APPLIES and not OG_PAIRS_FULL
        | PAIR_NEXT := PAIR_NEXT[?] next (if OG_LINKS then OG_P * 5 + OG_S else -1) : OG_Q + 1
        | OG_PUSHES := OG_LINKS and not OG_FOUND
        | STACK_PAIR := STACK_PAIR[?] next (if OG_PUSHES then OG_DEPTH - 1 else -1) : OG_P
        | STACK_SLOT := STACK_SLOT[?] next (if OG_PUSHES then OG_DEPTH - 1 else -1) : OG_S + 1
        | OG_H0 := PAIR_HOLDS[?][PAIR_NEXT[?][OG_P * 5 + 0] - 1]
        | OG_H1 := PAIR_HOLDS[?][PAIR_NEXT[?][OG_P * 5 + 1] - 1]
        | OG_H2 := PAIR_HOLDS[?][PAIR_NEXT[?][OG_P * 5 + 2] - 1]
        | OG_H3 := PAIR_HOLDS[?][PAIR_NEXT[?][OG_P * 5 + 3] - 1]
        | OG_H4 := PAIR_HOLDS[?][PAIR_NEXT[?][OG_P * 5 + 4] - 1]
        | OG_HOLDS := OG_INSIDE or OG_KIND_C /= CLK_ROOT and OG_H0 or OG_KIND_C = CLK_SUM and OG_H1 and OG_H2
                 or OG_KIND_C = CLK_PRODUCT and (OG_H1 or OG_H2) or OG_KIND_K = CLK_SUM and (OG_H3 or OG_H4)
                 or OG_KIND_K = CLK_PRODUCT and OG_H3 and OG_H4
        | PAIR_HOLDS := PAIR_HOLDS[?] next (if OG_POPS then OG_P else -1) : OG_HOLDS
        | OG_FINISHES := OG_POPS and OG_DEPTH = 1
        | OG_NOT_INSIDE := OG_FINISHES and not OG_HOLDS
        | OG_MESSAGE := if OG_FITS_NO_TREE then T_FITS_NO_TREE else if OG_PAIRS_FULL then T_CAPACITY else if OG_NOT_INSIDE then T_NOT_INSIDE else 0
        | OG_FAILS := OG_MESSAGE /= 0
        | CO_MESSAGE := if OG_FAILS then OG_MESSAGE else CO_MESSAGE[?]
        | CO_TOKEN := if OG_FAILS then OB_TOKEN[OG_O] else CO_TOKEN[?]
        | CO_CLOCK0 := if not OG_FAILS then CO_CLOCK0[?] else if OG_FITS_NO_TREE then OF2 else PAIR_CLOCK[?][0]
        | CO_CLOCK1 := if not OG_FAILS then CO_CLOCK1[?] else if OG_FITS_NO_TREE then OG_SMALL_ROOT else PAIR_CONTAINER[?][0]
        | CO_CLOCK2 := if OG_FAILS then OG_BIG_ROOT else CO_CLOCK2[?]
        | CO_STATE := if OG_FAILS then OS_FAILED else if OG_OPENS then OS_WALK else if OG_NOW = OS_START then OS_DONE
                    else if OG_FINISHES then OS_START else OG_NOW
        | CO_OBLIGATION := OG_O + integer(OG_FINISHES)
        | CO_TOP := if OG_OPENS or OG_PUSHES then OG_Q else if OG_POPS then STACK_PAIR[?][OG_DEPTH - 2] else OG_P
        | CO_TOP_SLOT := if OG_OPENS or OG_PUSHES then 0 else if OG_POPS then STACK_SLOT[?][OG_DEPTH - 2]
                       else if OG_SLOT_LIVE then OG_S + 1 else OG_S
        | CO_DEPTH := if OG_OPENS then 1 else OG_DEPTH + integer(OG_PUSHES) - integer(OG_POPS)
        |)
     with (| CO_STATE := OS_START | CO_OBLIGATION := 0 | CO_TOP := 0 | CO_TOP_SLOT := 0 | CO_DEPTH := 0
           | CO_CLOCK_COUNT := 0 | CO_CONTAINER_COUNT := 0 | CO_PAIR_COUNT := 0 | CO_MESSAGE := 0 | CO_TOKEN := -1
           | CO_CLOCK0 := -1 | CO_CLOCK1 := -1 | CO_CLOCK2 := -1 |)
     end
   | CO_DONE := CK_DONE and CO_STATE = OS_DONE
   | CF_INDEX := 0 .. (if CO_DONE then long(FLAT_SIGNAL_COUNT) + long(CLOCK_TOTAL) - long(1) else long(-1))
   | iterate CF_INDEX of
       (| CF_I := integer(CF_INDEX)
        | CF_SIGNALS := CF_I < FLAT_SIGNAL_COUNT
        | CF_CLOCK := if CF_SIGNALS then CF_I else CF_I - FLAT_SIGNAL_COUNT
        | FF_0 := CF_CLOCK
        | FF_1 := FF_0 + CK_LINK[FF_0]
        | FF_2 := FF_1 + CK_LINK[FF_1]
        | FF_3 := FF_2 + CK_LINK[FF_2]
        | FF_4 := FF_3 + CK_LINK[FF_3]
        | FF_5 := FF_4 + CK_LINK[FF_4]
        | FF_6 := FF_5 + CK_LINK[FF_5]
        | FF_7 := FF_6 + CK_LINK[FF_6]
        | FF_8 := FF_7 + CK_LINK[FF_7]
        | FF_9 := FF_8 + CK_LINK[FF_8]
        | FF_10 := FF_9 + CK_LINK[FF_9]
        | FF_11 := FF_10 + CK_LINK[FF_10]
        | FF_12 := FF_11 + CK_LINK[FF_11]
        | FF_13 := FF_12 + CK_LINK[FF_12]
        | FF_14 := FF_13 + CK_LINK[FF_13]
        | FF_15 := FF_14 + CK_LINK[FF_14]
        | FF_16 := FF_15 + CK_LINK[FF_15]
        | FF_17 := FF_16 + CK_LINK[FF_16]
        | FF_18 := FF_17 + CK_LINK[FF_17]
        | FF_19 := FF_18 + CK_LINK[FF_18]
        | FF_20 := FF_19 + CK_LINK[FF_19]
        | FF_ROOT := FF_20
        | FF := FF_ROOT + CK_OFFICIAL[FF_ROOT]
        | CF_GOING := not CF_FAILED[?]
        | CF_SOURCE := FLAT_SIGNAL_SOURCE[CF_CLOCK]
        | CF_INPUT := CF_SIGNALS and CF_SOURCE >= 0 and FLAT_SIGNAL_INSTANCE[CF_CLOCK] = 0 and SIGNAL_ROLE[CF_SOURCE] = ROLE_INPUT
        | CF_NOT_ROOT := CF_GOING and CF_INPUT and NODE_KIND[FF] /= CLK_ROOT
        | CF_ROOT := if CF_SIGNALS then NODE_ROOT1[FF] - 1 else CF_CLOCK
        | CF_LISTS := CF_GOING and (if CF_SIGNALS then NODE_KIND[FF] /= CLK_NONE else NODE_KIND[CF_CLOCK] = CLK_ROOT)
                 and not ROOT_LISTED[?][CF_ROOT]
        | ROOT_LISTED := ROOT_LISTED[?] next (if CF_LISTS then CF_ROOT else -1) : true
        | ROOT_LIST := ROOT_LIST[?] next (if CF_LISTS then ROOT_COUNT[?] else -1) : CF_ROOT
        | ROOT_COUNT := ROOT_COUNT[?] + integer(CF_LISTS)
        | CLOCK_REP := CLOCK_REP[?] next (if CF_SIGNALS then -1 else CF_CLOCK) : FF
        | CF_ROOT_IRQ1 := if PLATFORM /= PLATFORM_MACOS and CF_INPUT then SIGNAL_IRQ1[CF_SOURCE] else 0
        | CF_SHARED := CF_GOING and CF_ROOT_IRQ1 > 0 and ROOT_IRQ1[?][CF_ROOT] > 0
        | ROOT_IRQ1 := ROOT_IRQ1[?] next (if CF_GOING and CF_ROOT_IRQ1 > 0 then CF_ROOT else -1) : CF_ROOT_IRQ1
        | ROOT_INPUT1 := ROOT_INPUT1[?] next (if CF_GOING and CF_ROOT_IRQ1 > 0 then CF_ROOT else -1) : CF_CLOCK + 1
        | CF_PARTNER := if CF_SHARED then ROOT_INPUT1[?][CF_ROOT] - 1 else CF_PARTNER[?]
        | CF_SHARED_ROOT := CF_SHARED_ROOT[?] or CF_SHARED
        | CF_FREE := PLATFORM /= PLATFORM_MACOS and CF_GOING and not CF_SIGNALS and NODE_KIND[FF] = CLK_ROOT and ROOT_IRQ1[?][NODE_ROOT1[FF] - 1] = 0
        | CF_FAILED := not CF_GOING or CF_NOT_ROOT or CF_FREE or CF_SHARED
        | CF_SIGNAL := if CF_NOT_ROOT or CF_SHARED then CF_CLOCK else if CF_FREE then CF_CLOCK else CF_SIGNAL[?]
        | CF_VIRT_ROOT := CF_VIRT_ROOT[?] or CF_FREE
        |)
     with (| ROOT_COUNT := 0 | CF_FAILED := false | CF_SIGNAL := 0 | CF_VIRT_ROOT := false | CF_PARTNER := 0
           | CF_SHARED_ROOT := false |)
     end
   | RF_INDEX := 0 .. (if CE_ROOTS then CLOCK_TOTAL - 1 else -1)
   | iterate RF_INDEX of
       (| RF_CLOCK := CLOCK_TOTAL - 1 - RF_INDEX
        | RF_REP := CLOCK_REP[RF_CLOCK]
        | ROOT_FIRST := ROOT_FIRST[?] next (if NODE_KIND[RF_REP] = CLK_ROOT then RF_REP else -1) : RF_CLOCK
        |)
     end
   | CLOCK_MESSAGE_RAW := if CLOCKS_RUN and CK_STATE = KS_FAILED then CK_MESSAGE else if CK_DONE and CO_STATE = OS_FAILED then CO_MESSAGE
                          else if CO_DONE and CF_FAILED then
                            (if CF_SHARED_ROOT then T_INPUT_SHARED else if CF_VIRT_ROOT then T_VIRT_ROOT else T_INPUT_ROOT)
                          else if CLOCK_INCOMPLETE then T_CAPACITY else 0
   | CE_STALL := CLOCK_MESSAGE_RAW = T_CLOCK_CYCLE
   | CE_GUARDS := CLOCK_MESSAGE_RAW = T_GUARD_CYCLE
   | SCHED_LIST := CLOCK_MESSAGE_RAW = 0 and (SCHEDULE_MESSAGE = T_SIGNAL_CYCLE or SCHEDULE_MESSAGE = T_EFFECT_CYCLE)
   | SCHED_PAIR := CLOCK_MESSAGE_RAW = 0 and SCHEDULE_MESSAGE = T_EFFECTS_UNORDERED
   | CE_ROOTS := DUMP_PASS = 0 and EMIT_READY and EMIT_MESSAGE = 0 and ROOT_COUNT >= 2
   | CE_LIST := CE_STALL or CE_GUARDS or SCHED_LIST or CE_ROOTS
   | TX_ARGS := if SCHED_PAIR then 2 else if CLOCK_MESSAGE_RAW = T_VIRT_ROOT then 1 else CE_ARGS
   | CE_FITS := CLOCK_MESSAGE_RAW = T_FITS_NO_TREE
   | CE_ARGS := if CE_FITS then 3 else if CLOCK_MESSAGE_RAW = T_NOT_INSIDE then 2
                else if CLOCK_MESSAGE_RAW = T_TWO_DEFINITIONS then 1 else 0
   | CE_FROM_CK := CLOCKS_RUN and CK_STATE = KS_FAILED
   | CE_Q0 := if CE_FROM_CK then CK_CLOCK0 else CO_CLOCK0
   | CE_Q1 := if CE_FROM_CK then CK_CLOCK1 else CO_CLOCK1
   | CE_Q2 := if CE_FROM_CK then CK_CLOCK2 else CO_CLOCK2
   | CE0_INDEX := 0 .. (if CE_STALL then CK_PEND_W - 1 else -1)
   | iterate CE0_INDEX of
       (| E0_0 := DEF_TARGET[PEND[CE0_INDEX]]
        | E0_1 := E0_0 + CK_LINK[E0_0]
        | E0_2 := E0_1 + CK_LINK[E0_1]
        | E0_3 := E0_2 + CK_LINK[E0_2]
        | E0_4 := E0_3 + CK_LINK[E0_3]
        | E0_5 := E0_4 + CK_LINK[E0_4]
        | E0_6 := E0_5 + CK_LINK[E0_5]
        | E0_7 := E0_6 + CK_LINK[E0_6]
        | E0_8 := E0_7 + CK_LINK[E0_7]
        | E0_9 := E0_8 + CK_LINK[E0_8]
        | E0_10 := E0_9 + CK_LINK[E0_9]
        | E0_11 := E0_10 + CK_LINK[E0_10]
        | E0_12 := E0_11 + CK_LINK[E0_11]
        | E0_13 := E0_12 + CK_LINK[E0_12]
        | E0_14 := E0_13 + CK_LINK[E0_13]
        | E0_15 := E0_14 + CK_LINK[E0_14]
        | E0_16 := E0_15 + CK_LINK[E0_15]
        | E0_17 := E0_16 + CK_LINK[E0_16]
        | E0_18 := E0_17 + CK_LINK[E0_17]
        | E0_19 := E0_18 + CK_LINK[E0_18]
        | E0_20 := E0_19 + CK_LINK[E0_19]
        | E0 := E0_20 + CK_OFFICIAL[E0_20]
        | CE_STALLED := CE_STALLED[?] next E0 : true
        |)
     end
   | CE1_INDEX := 0 .. (if CE_GUARDS then GUARDED_COUNT - 1 else if CE_STALL or CE_ARGS > 0 then CLOCK_TOTAL - 1 else -1)
   | iterate CE1_INDEX of
       (| E1_X := if CE_GUARDS then GUARDED[CE1_INDEX] else CE1_INDEX
        | E1_0 := E1_X
        | E1_1 := E1_0 + CK_LINK[E1_0]
        | E1_2 := E1_1 + CK_LINK[E1_1]
        | E1_3 := E1_2 + CK_LINK[E1_2]
        | E1_4 := E1_3 + CK_LINK[E1_3]
        | E1_5 := E1_4 + CK_LINK[E1_4]
        | E1_6 := E1_5 + CK_LINK[E1_5]
        | E1_7 := E1_6 + CK_LINK[E1_6]
        | E1_8 := E1_7 + CK_LINK[E1_7]
        | E1_9 := E1_8 + CK_LINK[E1_8]
        | E1_10 := E1_9 + CK_LINK[E1_9]
        | E1_11 := E1_10 + CK_LINK[E1_10]
        | E1_12 := E1_11 + CK_LINK[E1_11]
        | E1_13 := E1_12 + CK_LINK[E1_12]
        | E1_14 := E1_13 + CK_LINK[E1_13]
        | E1_15 := E1_14 + CK_LINK[E1_14]
        | E1_16 := E1_15 + CK_LINK[E1_15]
        | E1_17 := E1_16 + CK_LINK[E1_16]
        | E1_18 := E1_17 + CK_LINK[E1_17]
        | E1_19 := E1_18 + CK_LINK[E1_18]
        | E1_20 := E1_19 + CK_LINK[E1_19]
        | E1 := E1_20 + CK_OFFICIAL[E1_20]
        | E1_SIGNAL := E1_X < FLAT_SIGNAL_COUNT
        | E1_GUARD := ROWS_GUARD[E1_X]
        | E1_WAITS := CE_GUARDS and NODE_KIND[E1] = CLK_NONE and E1_GUARD >= 0
        | E1_STALLED := CE_STALL and CE_STALLED[E1]
        | E1_MARK := if E1_WAITS then E1_GUARD else if E1_STALLED then E1 else -1
        | E1_NEW := E1_MARK >= 0 and not CE_SEEN[?][E1_MARK]
        | CE_SEEN := CE_SEEN[?] next E1_MARK : true
        | E1_APPENDS := E1_WAITS and E1_NEW or E1_STALLED and E1_SIGNAL
        | E1_OTHER := E1_STALLED and not E1_SIGNAL and E1_NEW
        | E1_SLOT := if E1_APPENDS and CE_COUNT[?] < CLOCK_NAME_CAP then CE_COUNT[?] else -1
        | E1_OTHER_SLOT := if E1_OTHER and CE_OTHER_COUNT[?] < CLOCK_NAME_CAP then CE_OTHER_COUNT[?] else -1
        | E1_MEMBER := if CE_GUARDS then E1_GUARD else E1_X
        | E1_TOKEN := ROWS_TOKEN[E1_GUARD]
        | E1_KEY := if not CE_GUARDS then long(0) else if E1_TOKEN < 0 then long(16777217)
                  else long(TOKEN_LINE[E1_TOKEN]) * long(16777216) + long(TOKEN_COLUMN[E1_TOKEN])
        | CE_ITEM_MEMBER := CE_ITEM_MEMBER[?] next E1_SLOT : E1_MEMBER
        | CE_ITEM_KEY := CE_ITEM_KEY[?] next E1_SLOT : E1_KEY
        | CE_OTHER_MEMBER := CE_OTHER_MEMBER[?] next E1_OTHER_SLOT : E1_X
        | CE_COUNT := CE_COUNT[?] + integer(E1_APPENDS)
        | CE_OTHER_COUNT := CE_OTHER_COUNT[?] + integer(E1_OTHER)
        | CE_MIN0 := if CE_MIN0[?] < 0 and E1 = CE_Q0 then E1_X else CE_MIN0[?]
        | CE_MIN1 := if CE_MIN1[?] < 0 and E1 = CE_Q1 then E1_X else CE_MIN1[?]
        | CE_MIN2 := if CE_MIN2[?] < 0 and E1 = CE_Q2 then E1_X else CE_MIN2[?]
        | E1_PLACED := E1_SIGNAL and NODE_KIND[E1] /= CLK_NONE
        | E1_ROOT := NODE_ROOT1[E1] - 1
        | CE_FS1 := if CE_FS1[?] < 0 and E1_PLACED and E1_ROOT = CE_Q1 then E1_X else CE_FS1[?]
        | CE_FS2 := if CE_FS2[?] < 0 and E1_PLACED and E1_ROOT = CE_Q2 then E1_X else CE_FS2[?]
        |)
     with (| CE_COUNT := 0 | CE_OTHER_COUNT := 0 | CE_MIN0 := -1 | CE_MIN1 := -1 | CE_MIN2 := -1 | CE_FS1 := -1 | CE_FS2 := -1 |)
     end
   | CE_KEY1 := if CE_FS1 >= 0 then CE_FS1 else FLAT_SIGNAL_COUNT + CE_Q1
   | CE_KEY2 := if CE_FS2 >= 0 then CE_FS2 else FLAT_SIGNAL_COUNT + CE_Q2
   | CE_SWAP := CE_FITS and CE_KEY2 < CE_KEY1
   | CE_OTHERS := CE_COUNT = 0
   | SM_OWNED := SM_OWNERS > 0
   | CE_ITEMS_WANTED := if CE_ROOTS then ROOT_COUNT else if TX_ARGS > 0 then TX_ARGS else if SCHED_LIST then (if SM_OWNED then SM_OWNERS else SM_EFFECTS)
                        else if CE_OTHERS then CE_OTHER_COUNT else CE_COUNT
   | CE_ITEMS := if CE_ITEMS_WANTED > CLOCK_NAME_CAP then CLOCK_NAME_CAP else CE_ITEMS_WANTED
   | CL_INDEX := 0 .. CE_ITEMS - 1
   | iterate CL_INDEX of
       (| L_EFFECT := SCHED_PAIR
        | L_POSITION := SCHED_LIST and not SM_OWNED
        | L_PLAIN := L_EFFECT or L_POSITION
        | L_M := if CE_ROOTS then ROOT_FIRST[ROOT_LIST[CL_INDEX]] else if SCHED_LIST then (if SM_OWNED then SM_OWNER_ITEM_ROW[CL_INDEX] else SM_EFFECT_ITEM_ROW[CL_INDEX])
                 else if SCHED_PAIR then (if CL_INDEX = 0 then EF_FIRST_ROW else EF_SECOND_ROW)
                 else if CLOCK_MESSAGE_RAW = T_VIRT_ROOT then CF_SIGNAL
                 else if CE_ARGS = 0 then (if CE_OTHERS then CE_OTHER_MEMBER[CL_INDEX] else CE_ITEM_MEMBER[CL_INDEX])
                 else if CL_INDEX = 0 then CE_MIN0
                 else if CL_INDEX = 1 and not CE_SWAP or CL_INDEX = 2 and CE_SWAP then CE_MIN1 else CE_MIN2
        | L_SIGNAL := not L_PLAIN and L_M < FLAT_SIGNAL_COUNT
        | L_SAMPLE := not L_PLAIN and L_M >= ROW_COUNT
        | L_ROW := if L_SAMPLE then SAMPLE_ROW[L_M - ROW_COUNT] else L_M
        | L_FRESH := L_BASE >= N_FRESH_FIRST and L_BASE <= N_FRESH_LAST
        | L_FLAT := (L_SIGNAL or L_SAMPLE and L_ROW < FLAT_SIGNAL_COUNT) and not L_FRESH
        | L_BRACKET := L_FLAT and not L_SIGNAL
        | L_SOURCE := FLAT_SIGNAL_SOURCE[L_ROW]
        | L_NAME_KEY := if L_SOURCE < 0 then FINISH_SIGNAL_NAME[-L_SOURCE - 1] else SIGNAL_NAME[L_SOURCE]
        | L_INSTANCE := FLAT_SIGNAL_INSTANCE[L_ROW]
        | L_PREFIXED := L_FLAT and L_INSTANCE > 0
        | L_BASE := L_NAME_KEY modulo NAME_CAP
        | L_SUFFIX := L_NAME_KEY / NAME_CAP
        | L_TOKEN := ROWS_TOKEN[L_ROW]
        | L_P := if L_PLAIN then 0 else if L_BRACKET then F_OPEN else if L_FLAT then 0 else F_EXPRESSION_AT
        | L_A := if L_EFFECT then EFFECT_KIND[integer(ROWS_VALUE[L_M])] modulo NAME_CAP
                 else if L_PREFIXED then MODEL_NAME[INSTANCE_MODEL[L_INSTANCE]] else -1
        | L_F1 := if L_EFFECT then F_AT else if L_PREFIXED then F_HASH else 0
        | L_N1 := if L_PREFIXED then INSTANCE_ORDINAL[L_INSTANCE] else if L_TOKEN < 0 then 1 else TOKEN_LINE[L_TOKEN]
        | L_F2 := if L_PREFIXED then F_DOT else if L_FLAT then 0 else F_COLON
        | L_B := if L_FLAT then L_BASE else -1
        | L_F3 := if L_FLAT and L_SUFFIX > 0 and L_BASE /= N_ON_MARK and (L_BASE < N_FRESH_FIRST or L_BASE > N_FRESH_LAST) then F_QUOTE else 0
        | L_N2 := if L_FLAT then L_SUFFIX else if L_TOKEN < 0 then 1 else TOKEN_COLUMN[L_TOKEN]
        | L_S := if L_PLAIN or L_FLAT and not L_BRACKET then 0 else F_CLOSE
        | L_D1_ALL := 1 + integer(L_N1 >= 10) + integer(L_N1 >= 100) + integer(L_N1 >= 1000) + integer(L_N1 >= 10000) + integer(L_N1 >= 100000) + integer(L_N1 >= 1000000) + integer(L_N1 >= 10000000) + integer(L_N1 >= 100000000) + integer(L_N1 >= 1000000000)
        | L_D2_ALL := 1 + integer(L_N2 >= 10) + integer(L_N2 >= 100) + integer(L_N2 >= 1000) + integer(L_N2 >= 10000) + integer(L_N2 >= 100000) + integer(L_N2 >= 1000000) + integer(L_N2 >= 10000000) + integer(L_N2 >= 100000000) + integer(L_N2 >= 1000000000)
        | L_D1 := if L_PREFIXED or not L_FLAT then L_D1_ALL else 0
        | L_D2 := if not L_FLAT or L_SUFFIX > 0 then L_D2_ALL else 0
        | L_A_LENGTH := if L_A >= 0 then NAME_LENGTH[L_A] else 0
        | L_B_LENGTH := if L_B >= 0 then NAME_LENGTH[L_B] else 0
        | L_LENGTH := FRAGMENT_LENGTH[L_P] + L_A_LENGTH + FRAGMENT_LENGTH[L_F1] + L_D1 + FRAGMENT_LENGTH[L_F2] + L_B_LENGTH
                    + FRAGMENT_LENGTH[L_F3] + L_D2 + FRAGMENT_LENGTH[L_S]
        | CL_TOTAL := CL_TOTAL[?] + L_LENGTH
        | CL_LONGEST := if L_LENGTH > CL_LONGEST[?] then L_LENGTH else CL_LONGEST[?]
        | CI_P := CI_P[?] next CL_INDEX : L_P
        | CI_A_AT := CI_A_AT[?] next CL_INDEX : if L_A >= 0 then NAME_AT[L_A] else 0
        | CI_A_LENGTH := CI_A_LENGTH[?] next CL_INDEX : L_A_LENGTH
        | CI_F1 := CI_F1[?] next CL_INDEX : L_F1
        | CI_N1 := CI_N1[?] next CL_INDEX : L_N1
        | CI_D1 := CI_D1[?] next CL_INDEX : L_D1
        | CI_F2 := CI_F2[?] next CL_INDEX : L_F2
        | CI_B_AT := CI_B_AT[?] next CL_INDEX : if L_B >= 0 then NAME_AT[L_B] else 0
        | CI_B_LENGTH := CI_B_LENGTH[?] next CL_INDEX : L_B_LENGTH
        | CI_F3 := CI_F3[?] next CL_INDEX : L_F3
        | CI_N2 := CI_N2[?] next CL_INDEX : L_N2
        | CI_D2 := CI_D2[?] next CL_INDEX : L_D2
        | CI_S := CI_S[?] next CL_INDEX : L_S
        | CI_END := CI_END[?] next CL_INDEX : CL_TOTAL
        | CI_KEY := CI_KEY[?] next CL_INDEX : if TX_ARGS > 0 then long(CL_INDEX)
                                            else if SCHED_LIST then (if SM_OWNED then long(0) else SM_EFFECT_ITEM_KEY[CL_INDEX])
                                            else if CE_OTHERS then long(0) else CE_ITEM_KEY[CL_INDEX]
        |)
     with (| CL_TOTAL := 0 | CL_LONGEST := 0 |)
     end
   | CE_OVERFLOW := CE_ITEMS_WANTED > CLOCK_NAME_CAP
                  or CL_TOTAL + (if CE_LIST and CE_ITEMS > 0 then 2 * (CE_ITEMS - 1) else 0) > CLOCK_TEXT_CAP
   | CR_INDEX := 0 .. (if CE_OVERFLOW then -1 else CL_TOTAL - 1)
   | iterate CR_INDEX of
       (| CR_ITEM := if CR_INDEX >= CI_END[CR_ITEM[?]] then CR_ITEM[?] + 1 else CR_ITEM[?]
        | CR_OFFSET := CR_INDEX - (if CR_ITEM = 0 then 0 else CI_END[CR_ITEM - 1])
        | CR_P_END := FRAGMENT_LENGTH[CI_P[CR_ITEM]]
        | CR_A_END := CR_P_END + CI_A_LENGTH[CR_ITEM]
        | CR_F1_END := CR_A_END + FRAGMENT_LENGTH[CI_F1[CR_ITEM]]
        | CR_N1_END := CR_F1_END + CI_D1[CR_ITEM]
        | CR_F2_END := CR_N1_END + FRAGMENT_LENGTH[CI_F2[CR_ITEM]]
        | CR_B_END := CR_F2_END + CI_B_LENGTH[CR_ITEM]
        | CR_F3_END := CR_B_END + FRAGMENT_LENGTH[CI_F3[CR_ITEM]]
        | CR_N2_END := CR_F3_END + CI_D2[CR_ITEM]
        | CR_NAME_AT := if CR_OFFSET < CR_A_END then CI_A_AT[CR_ITEM] + CR_OFFSET - CR_P_END
                      else CI_B_AT[CR_ITEM] + CR_OFFSET - CR_F2_END
        | CR_NAME_BYTE := if CR_NAME_AT < SEED_LENGTH then SEED[CR_NAME_AT] else SRC[CR_NAME_AT - SEED_LENGTH]
        | CR_FRAGMENT := if CR_OFFSET < CR_P_END then FRAGMENT_START[CI_P[CR_ITEM]] + CR_OFFSET
                       else if CR_OFFSET < CR_F1_END then FRAGMENT_START[CI_F1[CR_ITEM]] + CR_OFFSET - CR_A_END
                       else if CR_OFFSET < CR_F2_END then FRAGMENT_START[CI_F2[CR_ITEM]] + CR_OFFSET - CR_N1_END
                       else if CR_OFFSET < CR_F3_END then FRAGMENT_START[CI_F3[CR_ITEM]] + CR_OFFSET - CR_B_END
                       else FRAGMENT_START[CI_S[CR_ITEM]] + CR_OFFSET - CR_N2_END
        | CR_DIGIT := if CR_OFFSET < CR_N1_END then ulong(CI_N1[CR_ITEM]) / POWERS_OF_TEN[CR_N1_END - 1 - CR_OFFSET] modulo ulong(10)
                    else ulong(CI_N2[CR_ITEM]) / POWERS_OF_TEN[CR_N2_END - 1 - CR_OFFSET] modulo ulong(10)
        | CR_BYTE := if CR_OFFSET < CR_P_END then FRAGMENTS[CR_FRAGMENT]
                   else if CR_OFFSET < CR_A_END then CR_NAME_BYTE
                   else if CR_OFFSET < CR_F1_END then FRAGMENTS[CR_FRAGMENT]
                   else if CR_OFFSET < CR_N1_END then ubyte(CR_DIGIT + ulong(48))
                   else if CR_OFFSET < CR_F2_END then FRAGMENTS[CR_FRAGMENT]
                   else if CR_OFFSET < CR_B_END then CR_NAME_BYTE
                   else if CR_OFFSET < CR_F3_END then FRAGMENTS[CR_FRAGMENT]
                   else if CR_OFFSET < CR_N2_END then ubyte(CR_DIGIT + ulong(48))
                   else FRAGMENTS[CR_FRAGMENT]
        | CE_TEXT := CE_TEXT[?] next CR_INDEX : CR_BYTE
        |)
     with CR_ITEM := 0
     end
   | CS_INDEX := 0 .. (if CE_OVERFLOW or CE_ROOTS or CE_ITEMS = 0 then long(-1)
                      else long(CE_ITEMS) * long(CE_ITEMS) * long(CL_LONGEST + 1) - long(1))
   | iterate CS_INDEX of
       (| S_I := CS_I[?]
        | S_J := CS_J[?]
        | S_K := CS_K[?]
        | S_LIVE := S_I < CE_ITEMS
        | S_SKIPS := S_I = S_J
        | S_I_START := if S_I = 0 then 0 else CI_END[S_I - 1]
        | S_J_START := if S_J = 0 then 0 else CI_END[S_J - 1]
        | S_I_BYTE := if S_K < CI_END[S_I] - S_I_START then integer(CE_TEXT[S_I_START + S_K]) else -1
        | S_J_BYTE := if S_K < CI_END[S_J] - S_J_START then integer(CE_TEXT[S_J_START + S_K]) else -1
        | S_KEYS_DIFFER := CI_KEY[S_I] /= CI_KEY[S_J]
        | S_EQUAL := not S_KEYS_DIFFER and S_I_BYTE < 0 and S_J_BYTE < 0
        | S_DECIDED := S_LIVE and (S_SKIPS or S_KEYS_DIFFER or S_I_BYTE /= S_J_BYTE or S_EQUAL)
        | S_LESS := not S_SKIPS and (if S_KEYS_DIFFER then CI_KEY[S_J] < CI_KEY[S_I]
                                    else if S_EQUAL then S_J < S_I else S_J_BYTE < S_I_BYTE)
        | S_ROW_ENDS := S_DECIDED and S_J = CE_ITEMS - 1
        | S_RANK := CS_LESS[?] + integer(S_DECIDED and S_LESS)
        | S_DUPLICATE := CS_DUPLICATE[?] or S_DECIDED and not S_SKIPS and S_EQUAL and S_J < S_I
        | CE_ORDER := CE_ORDER[?] next (if S_ROW_ENDS then S_RANK else -1) : S_I
        | CE_DUPLICATE := CE_DUPLICATE[?] next (if S_ROW_ENDS then S_I else -1) : S_DUPLICATE
        | CS_LESS := if S_ROW_ENDS then 0 else S_RANK
        | CS_DUPLICATE := not S_ROW_ENDS and S_DUPLICATE
        | CS_I := S_I + integer(S_ROW_ENDS)
        | CS_J := if S_ROW_ENDS then 0 else S_J + integer(S_DECIDED)
        | CS_K := if S_DECIDED then 0 else S_K + 1
        |)
     with (| CS_I := 0 | CS_J := 0 | CS_K := 0 | CS_LESS := 0 | CS_DUPLICATE := false |)
     end
   | CS_UNFINISHED := not CE_OVERFLOW and not CE_ROOTS and CS_I < CE_ITEMS
   | CE_FAILS := CE_OVERFLOW or CS_UNFINISHED
   | CJ_INDEX := 0 .. (if CE_FAILS then -1 else CL_TOTAL + 3 * CE_ITEMS)
   | iterate CJ_INDEX of
       (| J_R := CJ_R[?]
        | J_O := CJ_O[?]
        | J_LIVE := J_R < CE_ITEMS
        | J_ITEM := if CE_ROOTS then J_R else CE_ORDER[J_R]
        | J_SKIPS := CE_DUPLICATE[J_ITEM] and not SCHED_LIST and not CE_ROOTS
        | J_START := if J_ITEM = 0 then 0 else CI_END[J_ITEM - 1]
        | J_SEPARATOR := if CE_LIST and CJ_EMITTED[?] > 0 then 2 else 0
        | J_EMITS := J_LIVE and not J_SKIPS and J_O < J_SEPARATOR + CI_END[J_ITEM] - J_START
        | J_ADVANCES := J_LIVE and not J_EMITS
        | J_BYTE := if J_O >= J_SEPARATOR then CE_TEXT[J_START + J_O - J_SEPARATOR] else if J_O = 0 then ubyte(44) else ubyte(32)
        | CLOCK_TEXT := CLOCK_TEXT[?] next (if J_EMITS then CJ_POSITION[?] else -1) : J_BYTE
        | CJ_POSITION := CJ_POSITION[?] + integer(J_EMITS)
        | CJ_EMITTED := CJ_EMITTED[?] + integer(J_ADVANCES and not J_SKIPS)
        | CJ_R := J_R + integer(J_ADVANCES)
        | CJ_O := if J_ADVANCES then 0 else J_O + integer(J_EMITS)
        |)
     with (| CJ_R := 0 | CJ_O := 0 | CJ_POSITION := 0 | CJ_EMITTED := 0 |)
     end
   | CE_GUARD_TOKEN := ROWS_TOKEN[CE_ITEM_MEMBER[CE_ORDER[0]]]
   | CLOCK_FAILED := CLOCKS_RUN and CK_STATE = KS_FAILED or CK_DONE and CO_STATE = OS_FAILED or CO_DONE and CF_FAILED
   | CLOCK_INCOMPLETE := CLOCKS_RUN and CK_STATE /= KS_DONE and CK_STATE /= KS_FAILED
                         or CK_DONE and CO_STATE /= OS_DONE and CO_STATE /= OS_FAILED
   | CLOCKS_READY := CO_DONE and not CF_FAILED
   | CF_SIGNAL_SOURCE := FLAT_SIGNAL_SOURCE[CF_SIGNAL]
   | SCHEDULE_ARGUMENT2 := if SCHED_PAIR then EFFECT_RESOURCE[integer(ROWS_VALUE[EF_FIRST_ROW])] else 0
   | CLOCK_MESSAGE := if CE_FAILS then T_CAPACITY else if CLOCK_MESSAGE_RAW /= 0 then CLOCK_MESSAGE_RAW
                    else if SCHEDULE_MESSAGE /= 0 then SCHEDULE_MESSAGE else EMIT_MESSAGE
   | CLOCK_TOKEN := if CE_GUARDS then CE_GUARD_TOKEN else if CLOCKS_RUN and CK_STATE = KS_FAILED then CK_TOKEN else if CK_DONE and CO_STATE = OS_FAILED then CO_TOKEN
                    else if CLOCK_MESSAGE_RAW = T_VIRT_ROOT and CF_SIGNAL >= FLAT_SIGNAL_COUNT then
                      ROWS_TOKEN[if CF_SIGNAL >= ROW_COUNT then SAMPLE_ROW[CF_SIGNAL - ROW_COUNT] else CF_SIGNAL]
                    else if CO_DONE and CF_FAILED then
                      (if CF_SIGNAL_SOURCE < 0 then FINISH_SIGNAL_TOKEN[-CF_SIGNAL_SOURCE - 1] else SIGNAL_TOKEN[CF_SIGNAL_SOURCE])
                    else if SCHEDULE_MESSAGE /= 0 then SCHEDULE_TOKEN else EMIT_ERROR_TOKEN
   | CLOCK_ARGUMENT0 := if CE_ITEMS_WANTED > CLOCK_NAME_CAP then F_CAP_CLOCK_NAMES else if CE_OVERFLOW then F_CAP_CLOCK_TEXT
                        else if CS_UNFINISHED then F_CAP_CLOCK_SORT else if CLOCKS_RUN and CK_STATE = KS_FAILED then CK_ARGUMENT0 else if CK_DONE and CO_STATE = OS_FAILED then F_CAP_PAIRS
                        else if CO_DONE and CF_FAILED and CF_SHARED_ROOT then SIGNAL_NAME[FLAT_SIGNAL_SOURCE[CF_PARTNER]]
                        else if CO_DONE and CF_FAILED then
                          (if CF_SIGNAL_SOURCE < 0 then FINISH_SIGNAL_NAME[-CF_SIGNAL_SOURCE - 1] else SIGNAL_NAME[CF_SIGNAL_SOURCE])
                        else if CLOCK_MESSAGE_RAW = 0 and SCHEDULE_MESSAGE /= 0 then SCHEDULE_ARGUMENT0
                        else if CLOCK_MESSAGE_RAW = 0 and EMIT_MESSAGE /= 0 then EMIT_CAPACITY else F_CAP_CLOCKS
   | SCHEDULE_DUMP := DUMP_PASS = 6
   | SCHEDULE_RUN := CLOCKS_READY and (DUMP_PASS = 0 or SCHEDULE_DUMP or CODE_DUMP)
   | SCHED_LOOP_BASE := ROW_COUNT + CLOCK_TOTAL
   | SCHED_NODES := SCHED_LOOP_BASE + FLAT_LOOP_COUNT
   | SE_CLOCK_END := 3 * ROW_COUNT + 2 * CLOCK_TOTAL
   | SE_DEP_END := SE_CLOCK_END + DEPENDENCE_TOTAL
   | SE_INDEX := 0 .. (if SCHEDULE_RUN and SCHED_NODES < SCHED_NODE_CAP then SE_DEP_END + FLAT_LOOP_COUNT - 1 else -1)
   | iterate SE_INDEX of
       (| E_IN_ROWS := SE_INDEX < 3 * ROW_COUNT
        | E_IN_CLOCKS := not E_IN_ROWS and SE_INDEX < SE_CLOCK_END
        | E_IN_DEPS := SE_INDEX >= SE_CLOCK_END and SE_INDEX < SE_DEP_END
        | E_IN_LOOPS := SE_INDEX >= SE_DEP_END
        | E_ROW := SE_INDEX / 3
        | E_SUB := SE_INDEX modulo 3
        | E_CLOCK := (SE_INDEX - 3 * ROW_COUNT) / 2
        | E_CSUB := (SE_INDEX - 3 * ROW_COUNT) modulo 2
        | E_D := SE_INDEX - SE_CLOCK_END
        | E_L := SE_INDEX - SE_DEP_END
        | E_ROW_OP := ROWS_OP[E_ROW]
        | E_LEFT := ROWS_LEFT[E_ROW]
        | E_RIGHT := ROWS_RIGHT[E_ROW]
        | E_SEED := E_ROW_OP = OP_SEED
        | E_MONO := OP_MONOCHRONOUS[E_ROW_OP] = 1
        | E_LEFT_EDGE := E_SEED or E_ROW_OP /= OP_PREV and (E_ROW_OP = OP_COPY or E_ROW_OP = OP_EFFECT or E_MONO or E_ROW_OP = OP_WHEN or E_ROW_OP = OP_DEFAULT)
        | E_RIGHT_EDGE := E_SEED or E_RIGHT >= 0 and (E_MONO or E_ROW_OP = OP_DEFAULT and not ROWS_CTX[E_LEFT])
        | E_KIND := NODE_KIND[E_CLOCK]
        | E_SAMPLE := E_KIND = CLK_SAMPLE
        | E_BINARY := E_KIND = CLK_PRODUCT or E_KIND = CLK_SUM
        | E_HAS := if E_IN_ROWS then E_SUB = 0 or E_SUB = 1 and E_LEFT_EDGE or E_SUB = 2 and E_RIGHT_EDGE
                 else if E_IN_CLOCKS then E_SAMPLE or E_BINARY else E_IN_DEPS
        | E_FROM := if E_IN_ROWS then (if E_SUB = 0 then ROW_COUNT + CLOCK_REP[E_ROW] else if E_SUB = 1 then E_LEFT
                                      else if E_SEED then E_ROW else E_RIGHT)
                  else if E_IN_CLOCKS then
                    (if E_CSUB = 0 then ROW_COUNT + (if E_SAMPLE then NODE_PARENT1[E_CLOCK] else NODE_LEFT1[E_CLOCK]) - 1
                     else if E_SAMPLE then NODE_LEFT1[E_CLOCK] - 1 else ROW_COUNT + NODE_RIGHT1[E_CLOCK] - 1)
                  else if E_IN_DEPS then DEPENDENCE_FROM_ROW[E_D] else LOOP_INDEX[E_L]
        | E_TO := if E_IN_ROWS then (if E_SUB = 2 and E_SEED then E_RIGHT else E_ROW)
                else if E_IN_CLOCKS then ROW_COUNT + E_CLOCK else if E_IN_DEPS then DEPENDENCE_TO_ROW[E_D]
                else SCHED_LOOP_BASE + E_L
        | E_GLOBAL := E_HAS and not E_IN_LOOPS
        | E_SFROM := (if E_FROM < ROW_COUNT and ROWS_LOOP[E_FROM] >= 0 then SCHED_LOOP_BASE + ROWS_LOOP[E_FROM] else E_FROM)
        | E_STO := (if E_TO < ROW_COUNT and ROWS_LOOP[E_TO] >= 0 then SCHED_LOOP_BASE + ROWS_LOOP[E_TO] else E_TO)
        | E_OUTER := E_GLOBAL and (E_FROM = E_TO or E_SFROM /= E_STO)
                   or E_IN_LOOPS and ROWS_OP[ROWS_LEFT[LOOP_INDEX[E_L]]] = OP_RANGE
        | E_OFROM := if E_IN_LOOPS then E_FROM else E_SFROM
        | E_OTO := if E_IN_LOOPS then E_TO else E_STO
        | E_INNER := E_GLOBAL and (E_FROM < ROW_COUNT and ROWS_LOOP[E_FROM] >= 0 and ROWS_OP[E_FROM] /= OP_SEED) and (E_TO < ROW_COUNT and ROWS_LOOP[E_TO] >= 0 and ROWS_OP[E_TO] /= OP_SEED) and ROWS_LOOP[E_FROM] = ROWS_LOOP[E_TO]
        | E_GSLOT := if E_GLOBAL and SG_COUNT[?] < EDGE_CAP then SG_COUNT[?] else -1
        | E_OSLOT := if E_OUTER and SO_COUNT[?] < EDGE_CAP then SO_COUNT[?] else -1
        | SG_FROM := SG_FROM[?] next E_GSLOT : E_FROM
        | SG_TO := SG_TO[?] next E_GSLOT : E_TO
        | SG_COUNT := SG_COUNT[?] + integer(E_GLOBAL)
        | SO_FROM := SO_FROM[?] next E_OSLOT : E_OFROM
        | SO_TO := SO_TO[?] next E_OSLOT : E_OTO
        | SO_COUNT := SO_COUNT[?] + integer(E_OUTER)
        | SG_OUT := SG_OUT[?] next (if E_GLOBAL then E_FROM else -1) : SG_OUT[?][E_FROM] + 1
        | SG_IN := SG_IN[?] next (if E_GLOBAL then E_TO else -1) : SG_IN[?][E_TO] + 1
        | SO_OUT := SO_OUT[?] next (if E_OUTER then E_OFROM else -1) : SO_OUT[?][E_OFROM] + 1
        | SO_IN := SO_IN[?] next (if E_OUTER then E_OTO else -1) : SO_IN[?][E_OTO] + 1
        | SI_IN := SI_IN[?] next (if E_INNER then E_TO else -1) : SI_IN[?][E_TO] + 1
        | E_ROW0 := E_IN_ROWS and E_SUB = 0
        | E_MEMBER := (E_ROW < ROW_COUNT and ROWS_LOOP[E_ROW] >= 0 and ROWS_OP[E_ROW] /= OP_SEED)
        | E_LOOP := ROWS_LOOP[E_ROW]
        | LOOP_MEMBERS := LOOP_MEMBERS[?] next (if E_ROW0 and E_MEMBER then E_LOOP else -1) : LOOP_MEMBERS[?][E_LOOP] + 1
        | E_GATHERS := E_ROW0 and E_MEMBER and E_ROW_OP = OP_GATHER and ROWS_OP[E_LEFT] = OP_PREV and ROWS_LEFT[E_LEFT] = ROWS_OWNER[E_ROW]
        | SNAP_GATHER1 := SNAP_GATHER1[?] next (if E_GATHERS then ROWS_OWNER[E_ROW] else -1) : E_LOOP + 1
        | E_EFFECT := E_ROW0 and E_ROW_OP = OP_EFFECT
        | E_RESOURCE := EFFECT_RESOURCE[integer(ROWS_VALUE[E_ROW])]
        | SE_EROW := SE_EROW[?] next (if E_EFFECT and SE_ECOUNT[?] < EFFECT_ORDER_CAP then SE_ECOUNT[?] else -1) : E_ROW
        | SE_ECOUNT := SE_ECOUNT[?] + integer(E_EFFECT)
        | RES_COUNT := RES_COUNT[?] next (if E_EFFECT then E_RESOURCE else -1) : RES_COUNT[?][E_RESOURCE] + 1
        |)
     with (| SG_COUNT := 0 | SO_COUNT := 0 | SE_ECOUNT := 0 |)
     end
   | SCHED_OVERFLOW := SCHEDULE_RUN and (SCHED_NODES >= SCHED_NODE_CAP or SG_COUNT > EDGE_CAP or SO_COUNT > EDGE_CAP
                                       or SE_ECOUNT > EFFECT_ORDER_CAP)
   | SCHED_GO := SCHEDULE_RUN and not SCHED_OVERFLOW
   | SWC_INDEX := 0 .. (if SCHED_GO then WAR_COUNT - 1 else -1)
   | iterate SWC_INDEX of
       (| W_READER := WAR_READER[SWC_INDEX]
        | W_WRITER := WAR_WRITER[SWC_INDEX]
        | W_KEPT := (W_READER < ROW_COUNT and ROWS_LOOP[W_READER] >= 0 and ROWS_OP[W_READER] /= OP_SEED) and SNAP_GATHER1[WAR_SIGNAL[SWC_INDEX]] /= ROWS_LOOP[W_READER] + 1
        | SW_OUT := SW_OUT[?] next (if W_KEPT then W_READER else -1) : SW_OUT[?][W_READER] + 1
        | SW_IN := SW_IN[?] next (if W_KEPT then W_WRITER else -1) : SW_IN[?][W_WRITER] + 1
        |)
     end
   | SN_INDEX := 0 .. (if SCHED_GO then SCHED_NODES else -1)
   | iterate SN_INDEX of
       (| SG_START := SG_START[?] next SN_INDEX : SN_G[?]
        | SN_G := SN_G[?] + SG_OUT[SN_INDEX]
        | SG_PSTART := SG_PSTART[?] next SN_INDEX : SN_GP[?]
        | SN_GP := SN_GP[?] + SG_IN[SN_INDEX]
        | SO_START := SO_START[?] next SN_INDEX : SN_O[?]
        | SN_O := SN_O[?] + SO_OUT[SN_INDEX]
        | SO_PSTART := SO_PSTART[?] next SN_INDEX : SN_OP[?]
        | SN_OP := SN_OP[?] + SO_IN[SN_INDEX]
        | SW_START := SW_START[?] next SN_INDEX : SN_W[?]
        | SN_W := SN_W[?] + SW_OUT[SN_INDEX]
        |)
     with (| SN_G := 0 | SN_GP := 0 | SN_O := 0 | SN_OP := 0 | SN_W := 0 |)
     end
   | SPL_MAX := if SG_COUNT > WAR_COUNT then SG_COUNT else WAR_COUNT
   | SPL_INDEX := 0 .. (if SCHED_GO then SPL_MAX - 1 else -1)
   | iterate SPL_INDEX of
       (| P_G := SPL_INDEX < SG_COUNT
        | P_GF := SG_FROM[SPL_INDEX]
        | P_GT := SG_TO[SPL_INDEX]
        | SG_SUCC := SG_SUCC[?] next (if P_G then SG_START[P_GF] + SG_SFILL[?][P_GF] else -1) : P_GT
        | SG_SFILL := SG_SFILL[?] next (if P_G then P_GF else -1) : SG_SFILL[?][P_GF] + 1
        | SG_PRED := SG_PRED[?] next (if P_G then SG_PSTART[P_GT] + SG_PFILL[?][P_GT] else -1) : P_GF
        | SG_PFILL := SG_PFILL[?] next (if P_G then P_GT else -1) : SG_PFILL[?][P_GT] + 1
        | P_O := SPL_INDEX < SO_COUNT
        | P_OF := SO_FROM[SPL_INDEX]
        | P_OT := SO_TO[SPL_INDEX]
        | SO_SUCC := SO_SUCC[?] next (if P_O then SO_START[P_OF] + SO_SFILL[?][P_OF] else -1) : P_OT
        | SO_SFILL := SO_SFILL[?] next (if P_O then P_OF else -1) : SO_SFILL[?][P_OF] + 1
        | SO_PRED := SO_PRED[?] next (if P_O then SO_PSTART[P_OT] + SO_PFILL[?][P_OT] else -1) : P_OF
        | SO_PFILL := SO_PFILL[?] next (if P_O then P_OT else -1) : SO_PFILL[?][P_OT] + 1
        | P_WR := WAR_READER[SPL_INDEX]
        | P_W := SPL_INDEX < WAR_COUNT and (P_WR < ROW_COUNT and ROWS_LOOP[P_WR] >= 0 and ROWS_OP[P_WR] /= OP_SEED) and SNAP_GATHER1[WAR_SIGNAL[SPL_INDEX]] /= ROWS_LOOP[P_WR] + 1
        | SW_SUCC := SW_SUCC[?] next (if P_W then SW_START[P_WR] + SW_FILL[?][P_WR] else -1) : WAR_WRITER[SPL_INDEX]
        | SW_FILL := SW_FILL[?] next (if P_W then P_WR else -1) : SW_FILL[?][P_WR] + 1
        |)
     end
   | SKO_INDEX := 0 .. (if SCHED_GO then 2 * (SCHED_NODES) + (SO_COUNT) + 1 else -1)
   | iterate SKO_INDEX of
       (| SKO_IN_INIT := SKO_CURSOR[?] < SCHED_NODES
        | SKO_INIT_NODE := SKO_CURSOR[?]
        | SKO_INIT_PRESENT := SKO_IN_INIT and (if SKO_INIT_NODE < ROW_COUNT then ROWS_LOOP[SKO_INIT_NODE] < 0 else if SKO_INIT_NODE < SCHED_LOOP_BASE then NODE_KIND[SKO_INIT_NODE - ROW_COUNT] /= CLK_NONE else true)
        | SKO_INIT_PUSH := SKO_INIT_PRESENT and SO_IN[SKO_INIT_NODE] = 0
        | SKO_NODE_NOW := SKO_NODE[?]
        | SKO_K := SKO_STEP[?]
        | SKO_LEN0 := if SKO_NODE_NOW >= 0 then SO_START[SKO_NODE_NOW + 1] - SO_START[SKO_NODE_NOW] else 0
        | SKO_EXPANDING := not SKO_IN_INIT and SKO_K < SKO_LEN0
        | SKO_S := SO_SUCC[SO_START[SKO_NODE_NOW] + SKO_K]
        | SKO_COUNTS := SKO_EXPANDING and true
        | SKO_NEW_DEC := SKO_DEC[?][SKO_S] + 1
        | SKO_DEC := SKO_DEC[?] next (if SKO_COUNTS then SKO_S else -1) : SKO_NEW_DEC
        | SKO_SUCC_PUSH := SKO_COUNTS and SO_IN[SKO_S] = SKO_NEW_DEC
        | SKO_POPS := not SKO_IN_INIT and not SKO_EXPANDING and SKO_TOP[?] > 0
        | SKO_POPPED := SKO_STACK[?][SKO_TOP[?] - 1]
        | SKO_PUSH := SKO_INIT_PUSH or SKO_SUCC_PUSH
        | SKO_STACK := SKO_STACK[?] next (if SKO_PUSH then SKO_TOP[?] else -1) : (if SKO_IN_INIT then SKO_INIT_NODE else SKO_S)
        | SKO_TOP := SKO_TOP[?] + integer(SKO_PUSH) - integer(SKO_POPS)
        | SKO_ORDER := SKO_ORDER[?] next (if SKO_POPS then SKO_COUNT[?] else -1) : SKO_POPPED
        | SKO_COUNT := SKO_COUNT[?] + integer(SKO_POPS)
        | SKO_PRESENT := SKO_PRESENT[?] + integer(SKO_INIT_PRESENT)
        | SKO_MARK := SKO_MARK[?] next (if SKO_POPS then SKO_POPPED else -1) : true
        | SKO_NODE := if SKO_POPS then SKO_POPPED else SKO_NODE_NOW
        | SKO_STEP := if SKO_POPS then 0 else SKO_K + integer(SKO_EXPANDING)
        | SKO_CURSOR := SKO_CURSOR[?] + integer(SKO_IN_INIT)
        |)
     with (| SKO_CURSOR := 0 | SKO_NODE := -1 | SKO_STEP := 0 | SKO_TOP := 0 | SKO_COUNT := 0 | SKO_PRESENT := 0 |)
     end
   | SKO_FAILED := SCHED_GO and SKO_COUNT < SKO_PRESENT
   | SKA_RUN := SCHED_GO and not SKO_FAILED and FLAT_LOOP_COUNT > 0
   | SKA_INDEX := 0 .. (if SKA_RUN then 2 * (ROW_COUNT) + (SG_COUNT + WAR_COUNT) + 1 else -1)
   | iterate SKA_INDEX of
       (| SKA_IN_INIT := SKA_CURSOR[?] < ROW_COUNT
        | SKA_INIT_NODE := SKA_CURSOR[?]
        | SKA_INIT_PRESENT := SKA_IN_INIT and (SKA_INIT_NODE < ROW_COUNT and ROWS_LOOP[SKA_INIT_NODE] >= 0 and ROWS_OP[SKA_INIT_NODE] /= OP_SEED)
        | SKA_INIT_PUSH := SKA_INIT_PRESENT and (SI_IN[SKA_INIT_NODE] + SW_IN[SKA_INIT_NODE]) = 0
        | SKA_NODE_NOW := SKA_NODE[?]
        | SKA_K := SKA_STEP[?]
        | SKA_LEN0 := if SKA_NODE_NOW >= 0 then SG_START[SKA_NODE_NOW + 1] - SG_START[SKA_NODE_NOW] else 0
        | SKA_LEN1 := if SKA_NODE_NOW >= 0 then (if SKA_NODE_NOW < ROW_COUNT then SW_START[SKA_NODE_NOW + 1] - SW_START[SKA_NODE_NOW] else 0) else 0
        | SKA_EXPANDING := not SKA_IN_INIT and SKA_K < SKA_LEN0 + SKA_LEN1
        | SKA_IN_SEG0 := SKA_K < SKA_LEN0
        | SKA_S := if SKA_IN_SEG0 then SG_SUCC[SG_START[SKA_NODE_NOW] + SKA_K]
                  else SW_SUCC[SW_START[SKA_NODE_NOW] + SKA_K - SKA_LEN0]
        | SKA_COUNTS := SKA_EXPANDING and (if SKA_IN_SEG0 then ((SKA_NODE_NOW < ROW_COUNT and ROWS_LOOP[SKA_NODE_NOW] >= 0 and ROWS_OP[SKA_NODE_NOW] /= OP_SEED) and (SKA_S < ROW_COUNT and ROWS_LOOP[SKA_S] >= 0 and ROWS_OP[SKA_S] /= OP_SEED) and ROWS_LOOP[SKA_S] = ROWS_LOOP[SKA_NODE_NOW]) else true)
        | SKA_NEW_DEC := SKA_DEC[?][SKA_S] + 1
        | SKA_DEC := SKA_DEC[?] next (if SKA_COUNTS then SKA_S else -1) : SKA_NEW_DEC
        | SKA_SUCC_PUSH := SKA_COUNTS and (SI_IN[SKA_S] + SW_IN[SKA_S]) = SKA_NEW_DEC
        | SKA_POPS := not SKA_IN_INIT and not SKA_EXPANDING and SKA_TOP[?] > 0
        | SKA_POPPED := SKA_STACK[?][SKA_TOP[?] - 1]
        | SKA_PUSH := SKA_INIT_PUSH or SKA_SUCC_PUSH
        | SKA_STACK := SKA_STACK[?] next (if SKA_PUSH then SKA_TOP[?] else -1) : (if SKA_IN_INIT then SKA_INIT_NODE else SKA_S)
        | SKA_TOP := SKA_TOP[?] + integer(SKA_PUSH) - integer(SKA_POPS)
        | SKA_ORDER := SKA_ORDER[?] next (if SKA_POPS then SKA_COUNT[?] else -1) : SKA_POPPED
        | SKA_COUNT := SKA_COUNT[?] + integer(SKA_POPS)
        | SKA_PRESENT := SKA_PRESENT[?] + integer(SKA_INIT_PRESENT)
        | SKA_POP_LOOP := if SKA_POPS and SKA_POPPED < ROW_COUNT then ROWS_LOOP[SKA_POPPED] else -1
        | SKA_LOOP_POPS := SKA_LOOP_POPS[?] next SKA_POP_LOOP : SKA_LOOP_POPS[?][SKA_POP_LOOP] + 1
        | SKA_NODE := if SKA_POPS then SKA_POPPED else SKA_NODE_NOW
        | SKA_STEP := if SKA_POPS then 0 else SKA_K + integer(SKA_EXPANDING)
        | SKA_CURSOR := SKA_CURSOR[?] + integer(SKA_IN_INIT)
        |)
     with (| SKA_CURSOR := 0 | SKA_NODE := -1 | SKA_STEP := 0 | SKA_TOP := 0 | SKA_COUNT := 0 | SKA_PRESENT := 0 |)
     end
   | SKB_RUN := SKA_RUN and SKA_COUNT < SKA_PRESENT
   | SKB_INDEX := 0 .. (if SKB_RUN then 2 * (ROW_COUNT) + (SG_COUNT) + 1 else -1)
   | iterate SKB_INDEX of
       (| SKB_IN_INIT := SKB_CURSOR[?] < ROW_COUNT
        | SKB_INIT_NODE := SKB_CURSOR[?]
        | SKB_INIT_PRESENT := SKB_IN_INIT and ((SKB_INIT_NODE < ROW_COUNT and ROWS_LOOP[SKB_INIT_NODE] >= 0 and ROWS_OP[SKB_INIT_NODE] /= OP_SEED) and (SKA_LOOP_POPS[ROWS_LOOP[SKB_INIT_NODE]] < LOOP_MEMBERS[ROWS_LOOP[SKB_INIT_NODE]]))
        | SKB_INIT_PUSH := SKB_INIT_PRESENT and SI_IN[SKB_INIT_NODE] = 0
        | SKB_NODE_NOW := SKB_NODE[?]
        | SKB_K := SKB_STEP[?]
        | SKB_LEN0 := if SKB_NODE_NOW >= 0 then SG_START[SKB_NODE_NOW + 1] - SG_START[SKB_NODE_NOW] else 0
        | SKB_EXPANDING := not SKB_IN_INIT and SKB_K < SKB_LEN0
        | SKB_S := SG_SUCC[SG_START[SKB_NODE_NOW] + SKB_K]
        | SKB_COUNTS := SKB_EXPANDING and ((SKB_NODE_NOW < ROW_COUNT and ROWS_LOOP[SKB_NODE_NOW] >= 0 and ROWS_OP[SKB_NODE_NOW] /= OP_SEED) and (SKB_S < ROW_COUNT and ROWS_LOOP[SKB_S] >= 0 and ROWS_OP[SKB_S] /= OP_SEED) and ROWS_LOOP[SKB_S] = ROWS_LOOP[SKB_NODE_NOW])
        | SKB_NEW_DEC := SKB_DEC[?][SKB_S] + 1
        | SKB_DEC := SKB_DEC[?] next (if SKB_COUNTS then SKB_S else -1) : SKB_NEW_DEC
        | SKB_SUCC_PUSH := SKB_COUNTS and SI_IN[SKB_S] = SKB_NEW_DEC
        | SKB_POPS := not SKB_IN_INIT and not SKB_EXPANDING and SKB_TOP[?] > 0
        | SKB_POPPED := SKB_STACK[?][SKB_TOP[?] - 1]
        | SKB_PUSH := SKB_INIT_PUSH or SKB_SUCC_PUSH
        | SKB_STACK := SKB_STACK[?] next (if SKB_PUSH then SKB_TOP[?] else -1) : (if SKB_IN_INIT then SKB_INIT_NODE else SKB_S)
        | SKB_TOP := SKB_TOP[?] + integer(SKB_PUSH) - integer(SKB_POPS)
        | SKB_ORDER := SKB_ORDER[?] next (if SKB_POPS then SKB_COUNT[?] else -1) : SKB_POPPED
        | SKB_COUNT := SKB_COUNT[?] + integer(SKB_POPS)
        | SKB_PRESENT := SKB_PRESENT[?] + integer(SKB_INIT_PRESENT)
        | SKB_MARK := SKB_MARK[?] next (if SKB_POPS then SKB_POPPED else -1) : true
        | SKB_POP_LOOP := if SKB_POPS and SKB_POPPED < ROW_COUNT then ROWS_LOOP[SKB_POPPED] else -1
        | SKB_LOOP_POPS := SKB_LOOP_POPS[?] next SKB_POP_LOOP : SKB_LOOP_POPS[?][SKB_POP_LOOP] + 1
        | SKB_NODE := if SKB_POPS then SKB_POPPED else SKB_NODE_NOW
        | SKB_STEP := if SKB_POPS then 0 else SKB_K + integer(SKB_EXPANDING)
        | SKB_CURSOR := SKB_CURSOR[?] + integer(SKB_IN_INIT)
        |)
     with (| SKB_CURSOR := 0 | SKB_NODE := -1 | SKB_STEP := 0 | SKB_TOP := 0 | SKB_COUNT := 0 | SKB_PRESENT := 0 |)
     end
   | SKB_FAILED := SKB_RUN and SKB_COUNT < SKB_PRESENT
   | SL_INDEX := 0 .. (if SKA_RUN then FLAT_LOOP_COUNT - 1 else -1)
   | iterate SL_INDEX of
       (| L_FAILED1 := (SKA_LOOP_POPS[SL_INDEX] < LOOP_MEMBERS[SL_INDEX])
        | L_FAILED2 := L_FAILED1 and SKB_LOOP_POPS[SL_INDEX] < LOOP_MEMBERS[SL_INDEX]
        | SL_ERROR_LOOP := if SL_ERROR_LOOP[?] < 0 and L_FAILED2 then SL_INDEX else SL_ERROR_LOOP[?]
        | L_POPS := if L_FAILED1 then SKB_LOOP_POPS[SL_INDEX] else SKA_LOOP_POPS[SL_INDEX]
        | LO_START := LO_START[?] next SL_INDEX : LO_SUM[?]
        | LO_LENGTH := LO_LENGTH[?] next SL_INDEX : L_POPS
        | LO_SUM := LO_SUM[?] + L_POPS
        |)
     with (| SL_ERROR_LOOP := -1 | LO_SUM := 0 |)
     end
   | SC_OUTER := SKO_FAILED
   | SC_INNER := SKB_FAILED
   | SC_RUN := SC_OUTER or SC_INNER
   | SC_N := if SC_OUTER then SCHED_NODES else ROW_COUNT
   | SCA_INDEX := 0 .. (if SC_RUN then SC_N + (if SC_OUTER then SO_COUNT else SG_COUNT) - 1 else -1)
   | iterate SCA_INDEX of
       (| A_NODE := SCA_NODE[?]
        | A_K := SCA_K[?]
        | A_LEN := if SC_OUTER then SO_START[A_NODE + 1] - SO_START[A_NODE] else SG_START[A_NODE + 1] - SG_START[A_NODE]
        | A_EXPANDING := A_K < A_LEN
        | A_S := if SC_OUTER then SO_SUCC[SO_START[A_NODE] + A_K] else SG_SUCC[SG_START[A_NODE] + A_K]
        | A_HIT := A_EXPANDING and (SC_OUTER or ((A_NODE < ROW_COUNT and ROWS_LOOP[A_NODE] >= 0 and ROWS_OP[A_NODE] /= OP_SEED) and (A_S < ROW_COUNT and ROWS_LOOP[A_S] >= 0 and ROWS_OP[A_S] /= OP_SEED) and ROWS_LOOP[A_S] = ROWS_LOOP[A_NODE])) and (if SC_OUTER then ((if A_S < ROW_COUNT then ROWS_LOOP[A_S] < 0 else if A_S < SCHED_LOOP_BASE then NODE_KIND[A_S - ROW_COUNT] /= CLK_NONE else true) and not SKO_MARK[A_S]) else (((A_S < ROW_COUNT and ROWS_LOOP[A_S] >= 0 and ROWS_OP[A_S] /= OP_SEED) and (SKA_LOOP_POPS[ROWS_LOOP[A_S]] < LOOP_MEMBERS[ROWS_LOOP[A_S]])) and not SKB_MARK[A_S]))
        | A_ACC := SCA_ACC[?] + integer(A_HIT)
        | SC_OUTC := SC_OUTC[?] next (if A_EXPANDING then -1 else A_NODE) : A_ACC
        | SCA_NODE := A_NODE + integer(not A_EXPANDING)
        | SCA_K := if A_EXPANDING then A_K + 1 else 0
        | SCA_ACC := if A_EXPANDING then A_ACC else 0
        |)
     with (| SCA_NODE := 0 | SCA_K := 0 | SCA_ACC := 0 |)
     end
   | SCB_INDEX := 0 .. (if SC_RUN then 2 * (SC_N) + ((if SC_OUTER then SO_COUNT else SG_COUNT)) + 1 else -1)
   | iterate SCB_INDEX of
       (| SCB_IN_INIT := SCB_CURSOR[?] < SC_N
        | SCB_INIT_NODE := SCB_CURSOR[?]
        | SCB_INIT_PRESENT := SCB_IN_INIT and (if SC_OUTER then ((if SCB_INIT_NODE < ROW_COUNT then ROWS_LOOP[SCB_INIT_NODE] < 0 else if SCB_INIT_NODE < SCHED_LOOP_BASE then NODE_KIND[SCB_INIT_NODE - ROW_COUNT] /= CLK_NONE else true) and not SKO_MARK[SCB_INIT_NODE]) else (((SCB_INIT_NODE < ROW_COUNT and ROWS_LOOP[SCB_INIT_NODE] >= 0 and ROWS_OP[SCB_INIT_NODE] /= OP_SEED) and (SKA_LOOP_POPS[ROWS_LOOP[SCB_INIT_NODE]] < LOOP_MEMBERS[ROWS_LOOP[SCB_INIT_NODE]])) and not SKB_MARK[SCB_INIT_NODE]))
        | SCB_INIT_PUSH := SCB_INIT_PRESENT and SC_OUTC[SCB_INIT_NODE] = 0
        | SCB_NODE_NOW := SCB_NODE[?]
        | SCB_K := SCB_STEP[?]
        | SCB_LEN0 := if SCB_NODE_NOW >= 0 then (if SC_OUTER then SO_PSTART[SCB_NODE_NOW + 1] - SO_PSTART[SCB_NODE_NOW] else SG_PSTART[SCB_NODE_NOW + 1] - SG_PSTART[SCB_NODE_NOW]) else 0
        | SCB_EXPANDING := not SCB_IN_INIT and SCB_K < SCB_LEN0
        | SCB_S := (if SC_OUTER then SO_PRED[SO_PSTART[SCB_NODE_NOW] + SCB_K] else SG_PRED[SG_PSTART[SCB_NODE_NOW] + SCB_K])
        | SCB_COUNTS := SCB_EXPANDING and ((SC_OUTER or ((SCB_NODE_NOW < ROW_COUNT and ROWS_LOOP[SCB_NODE_NOW] >= 0 and ROWS_OP[SCB_NODE_NOW] /= OP_SEED) and (SCB_S < ROW_COUNT and ROWS_LOOP[SCB_S] >= 0 and ROWS_OP[SCB_S] /= OP_SEED) and ROWS_LOOP[SCB_S] = ROWS_LOOP[SCB_NODE_NOW])) and (if SC_OUTER then ((if SCB_S < ROW_COUNT then ROWS_LOOP[SCB_S] < 0 else if SCB_S < SCHED_LOOP_BASE then NODE_KIND[SCB_S - ROW_COUNT] /= CLK_NONE else true) and not SKO_MARK[SCB_S]) else (((SCB_S < ROW_COUNT and ROWS_LOOP[SCB_S] >= 0 and ROWS_OP[SCB_S] /= OP_SEED) and (SKA_LOOP_POPS[ROWS_LOOP[SCB_S]] < LOOP_MEMBERS[ROWS_LOOP[SCB_S]])) and not SKB_MARK[SCB_S])))
        | SCB_NEW_DEC := SCB_DEC[?][SCB_S] + 1
        | SCB_DEC := SCB_DEC[?] next (if SCB_COUNTS then SCB_S else -1) : SCB_NEW_DEC
        | SCB_SUCC_PUSH := SCB_COUNTS and SC_OUTC[SCB_S] = SCB_NEW_DEC
        | SCB_POPS := not SCB_IN_INIT and not SCB_EXPANDING and SCB_TOP[?] > 0
        | SCB_POPPED := SCB_STACK[?][SCB_TOP[?] - 1]
        | SCB_PUSH := SCB_INIT_PUSH or SCB_SUCC_PUSH
        | SCB_STACK := SCB_STACK[?] next (if SCB_PUSH then SCB_TOP[?] else -1) : (if SCB_IN_INIT then SCB_INIT_NODE else SCB_S)
        | SCB_TOP := SCB_TOP[?] + integer(SCB_PUSH) - integer(SCB_POPS)
        | SCB_ORDER := SCB_ORDER[?] next (if SCB_POPS then SCB_COUNT[?] else -1) : SCB_POPPED
        | SCB_COUNT := SCB_COUNT[?] + integer(SCB_POPS)
        | SCB_PRESENT := SCB_PRESENT[?] + integer(SCB_INIT_PRESENT)
        | SCB_MARK := SCB_MARK[?] next (if SCB_POPS then SCB_POPPED else -1) : true
        | SCB_NODE := if SCB_POPS then SCB_POPPED else SCB_NODE_NOW
        | SCB_STEP := if SCB_POPS then 0 else SCB_K + integer(SCB_EXPANDING)
        | SCB_CURSOR := SCB_CURSOR[?] + integer(SCB_IN_INIT)
        |)
     with (| SCB_CURSOR := 0 | SCB_NODE := -1 | SCB_STEP := 0 | SCB_TOP := 0 | SCB_COUNT := 0 | SCB_PRESENT := 0 |)
     end
   | SM_INDEX := 0 .. (if SC_RUN then ROW_COUNT - 1 else -1)
   | iterate SM_INDEX of
       (| M_NODE := if SC_OUTER then (if SM_INDEX < ROW_COUNT and ROWS_LOOP[SM_INDEX] >= 0 then SCHED_LOOP_BASE + ROWS_LOOP[SM_INDEX] else SM_INDEX) else SM_INDEX
        | M_IN := (if SC_OUTER then ((if M_NODE < ROW_COUNT then ROWS_LOOP[M_NODE] < 0 else if M_NODE < SCHED_LOOP_BASE then NODE_KIND[M_NODE - ROW_COUNT] /= CLK_NONE else true) and not SKO_MARK[M_NODE]) else (((M_NODE < ROW_COUNT and ROWS_LOOP[M_NODE] >= 0 and ROWS_OP[M_NODE] /= OP_SEED) and (SKA_LOOP_POPS[ROWS_LOOP[M_NODE]] < LOOP_MEMBERS[ROWS_LOOP[M_NODE]])) and not SKB_MARK[M_NODE])) and not SCB_MARK[M_NODE] and (SC_OUTER or ROWS_LOOP[SM_INDEX] = SL_ERROR_LOOP)
        | M_OWNER := ROWS_OWNER[SM_INDEX]
        | M_OWNS := M_IN and M_OWNER >= 0
        | M_NEW := M_OWNS and not SM_SEEN[?][M_OWNER]
        | SM_SEEN := SM_SEEN[?] next (if M_OWNS then M_OWNER else -1) : true
        | M_EFFECT := M_IN and not M_OWNS and ROWS_OP[SM_INDEX] = OP_EFFECT
        | M_OWNER_SLOT := if M_NEW and SM_OWNERS[?] < CLOCK_NAME_CAP then SM_OWNERS[?] else -1
        | M_EFFECT_SLOT := if M_EFFECT and SM_EFFECTS[?] < CLOCK_NAME_CAP then SM_EFFECTS[?] else -1
        | M_ROW := if M_NEW then M_OWNER else SM_INDEX
        | M_KEY := (if ROWS_TOKEN[M_ROW] < 0 then long(16777217) else long(TOKEN_LINE[ROWS_TOKEN[M_ROW]]) * long(16777216) + long(TOKEN_COLUMN[ROWS_TOKEN[M_ROW]]))
        | SM_OWNER_ITEM_ROW := SM_OWNER_ITEM_ROW[?] next M_OWNER_SLOT : M_OWNER
        | SM_EFFECT_ITEM_ROW := SM_EFFECT_ITEM_ROW[?] next M_EFFECT_SLOT : SM_INDEX
        | SM_EFFECT_ITEM_KEY := SM_EFFECT_ITEM_KEY[?] next M_EFFECT_SLOT : M_KEY
        | SM_EFFECTS := SM_EFFECTS[?] + integer(M_EFFECT)
        | SM_OWNERS := SM_OWNERS[?] + integer(M_NEW)
        | M_SELF_KEY := (if ROWS_TOKEN[SM_INDEX] < 0 then long(16777217) else long(TOKEN_LINE[ROWS_TOKEN[SM_INDEX]]) * long(16777216) + long(TOKEN_COLUMN[ROWS_TOKEN[SM_INDEX]]))
        | M_OWNER_BETTER := M_NEW and M_KEY < SM_OWNER_KEY[?]
        | SM_OWNER_KEY := if M_OWNER_BETTER then M_KEY else SM_OWNER_KEY[?]
        | SM_OWNER_TOKEN := if M_OWNER_BETTER then ROWS_TOKEN[M_ROW] else SM_OWNER_TOKEN[?]
        | M_EFFECT_BETTER := M_EFFECT and M_KEY < SM_EFFECT_KEY[?]
        | SM_EFFECT_KEY := if M_EFFECT_BETTER then M_KEY else SM_EFFECT_KEY[?]
        | SM_EFFECT_TOKEN := if M_EFFECT_BETTER then ROWS_TOKEN[M_ROW] else SM_EFFECT_TOKEN[?]
        | M_ROW_BETTER := M_IN and M_SELF_KEY < SM_ROW_KEY[?]
        | SM_ROW_KEY := if M_ROW_BETTER then M_SELF_KEY else SM_ROW_KEY[?]
        | SM_ROW_TOKEN := if M_ROW_BETTER then ROWS_TOKEN[SM_INDEX] else SM_ROW_TOKEN[?]
        |)
     with (| SM_EFFECTS := 0 | SM_OWNERS := 0 | SM_OWNER_KEY := long(9223372036854775807) | SM_OWNER_TOKEN := -1
           | SM_EFFECT_KEY := long(9223372036854775807) | SM_EFFECT_TOKEN := -1
           | SM_ROW_KEY := long(9223372036854775807) | SM_ROW_TOKEN := -1 |)
     end
   | EF_E := SE_ECOUNT
   | EF_RUN := SCHED_GO and not SKO_FAILED and not SKB_FAILED and EF_E >= 2
   | EF_BOUND := long(EF_E) * long(SCHED_LOOP_BASE + SG_COUNT + SCHED_NODES + SO_COUNT + EF_E + 8) + long(EF_E) * long(EF_E) + long(2)
   | EF_INDEX := 0 .. (if EF_RUN then EF_BOUND else long(-1))
   | iterate EF_INDEX of
       (| F_I := EF_I[?]
        | F_PH := EF_PH[?]
        | F_ROW := SE_EROW[F_I]
        | F_RES := EFFECT_RESOURCE[integer(ROWS_VALUE[F_ROW])]
        | F_ACTIVE := RES_COUNT[F_RES] >= 2
        | F_STAMP := F_I + 1
        | F_SUP := (if F_ROW < ROW_COUNT and ROWS_LOOP[F_ROW] >= 0 then SCHED_LOOP_BASE + ROWS_LOOP[F_ROW] else F_ROW)
        | F_START1 := F_PH = 0 and F_I < EF_E and F_ACTIVE
        | F_SKIP := F_PH = 0 and F_I < EF_E and not F_ACTIVE
        | F_TO_PAIRS := F_PH = 0 and F_I >= EF_E
        | F_START2 := F_PH = 2
        | F_DFS := F_PH = 1 or F_PH = 3
        | F_NODE := EF_NODE[?]
        | F_K := EF_K[?]
        | F_LEN := if F_NODE < 0 then 0 else if F_PH = 1 then SG_START[F_NODE + 1] - SG_START[F_NODE]
                 else SO_START[F_NODE + 1] - SO_START[F_NODE]
        | F_EXPANDING := F_DFS and F_K < F_LEN
        | F_S := if F_PH = 1 then SG_SUCC[SG_START[F_NODE] + F_K] else SO_SUCC[SO_START[F_NODE] + F_K]
        | F_VISITS := F_EXPANDING and (if F_PH = 1 then VIS1[?][F_S] else VIS2[?][F_S]) /= F_STAMP
        | F_POPS := F_DFS and not F_EXPANDING and EF_TOP[?] > 0
        | F_DFS_ENDS := F_DFS and not F_EXPANDING and EF_TOP[?] = 0
        | F_PUSH := F_START1 or F_START2 or F_VISITS
        | F_PUSHED := if F_START1 then F_ROW else if F_START2 then F_SUP else F_S
        | VIS1 := VIS1[?] next (if F_START1 or F_VISITS and F_PH = 1 then F_PUSHED else -1) : F_STAMP
        | VIS2 := VIS2[?] next (if F_START2 or F_VISITS and F_PH = 3 then F_PUSHED else -1) : F_STAMP
        | EF_STACK := EF_STACK[?] next (if F_PUSH then EF_TOP[?] else -1) : F_PUSHED
        | EF_TOP := EF_TOP[?] + integer(F_PUSH) - integer(F_POPS)
        | F_SCAN := F_PH = 4
        | F_J := EF_J[?]
        | F_JROW := SE_EROW[F_J]
        | F_JSUP := (if F_JROW < ROW_COUNT and ROWS_LOOP[F_JROW] >= 0 then SCHED_LOOP_BASE + ROWS_LOOP[F_JROW] else F_JROW)
        | F_REACHED := VIS1[?][F_JROW] = F_STAMP or F_JSUP /= F_SUP and VIS2[?][F_JSUP] = F_STAMP
        | EF_ORDERED := EF_ORDERED[?] next (if F_SCAN then F_I * EF_E + F_J else -1) : F_REACHED
        | F_SCAN_ENDS := F_SCAN and F_J = EF_E - 1
        | F_PAIRS := F_PH = 5
        | F_PI := F_J / EF_E
        | F_PJ := F_J modulo EF_E
        | F_PAIR_FAILS := F_PAIRS and F_PI < F_PJ
                        and EFFECT_RESOURCE[integer(ROWS_VALUE[SE_EROW[F_PI]])] = EFFECT_RESOURCE[integer(ROWS_VALUE[SE_EROW[F_PJ]])]
                        and not EF_ORDERED[?][F_PI * EF_E + F_PJ] and not EF_ORDERED[?][F_PJ * EF_E + F_PI]
        | F_PAIRS_END := F_PAIRS and (F_PAIR_FAILS or F_J = EF_E * EF_E - 1)
        | EF_FIRST := if F_PAIR_FAILS then F_PI else EF_FIRST[?]
        | EF_SECOND := if F_PAIR_FAILS then F_PJ else EF_SECOND[?]
        | EF_PH := if F_START1 then 1 else if F_SKIP then 0 else if F_TO_PAIRS then 5 else if F_START2 then 3
                 else if F_DFS_ENDS then F_PH + 1 else if F_SCAN_ENDS then 0 else if F_PAIRS_END then 6 else F_PH
        | EF_I := F_I + integer(F_SKIP or F_SCAN_ENDS)
        | EF_J := if F_SCAN or F_PAIRS then F_J + 1 else 0
        | EF_NODE := if F_POPS then EF_STACK[?][EF_TOP[?] - 1] else if F_DFS_ENDS or F_START1 or F_START2 then -1 else F_NODE
        | EF_K := if F_POPS then 0 else F_K + integer(F_EXPANDING)
        |)
     with (| EF_I := 0 | EF_PH := 0 | EF_J := 0 | EF_NODE := -1 | EF_K := 0 | EF_TOP := 0 | EF_FIRST := -1 | EF_SECOND := -1 |)
     end
   | EF_FAILED := EF_RUN and EF_FIRST >= 0
   | EF_UNFINISHED := EF_RUN and EF_PH /= 6
   | EF_FIRST_ROW := SE_EROW[EF_FIRST]
   | EF_SECOND_ROW := SE_EROW[EF_SECOND]
   | SCHEDULE_MESSAGE := if not SCHEDULE_RUN then 0 else if SCHED_OVERFLOW then T_CAPACITY
                       else if SC_RUN then (if SM_OWNERS > 0 then T_SIGNAL_CYCLE else if SM_EFFECTS > 0 then T_EFFECT_CYCLE
                                            else T_CLOCK_CAUSALITY)
                       else if EF_FAILED then T_EFFECTS_UNORDERED else if EF_UNFINISHED then T_CAPACITY else 0
   | SCHEDULE_TOKEN := if SCHEDULE_MESSAGE = T_SIGNAL_CYCLE then SM_OWNER_TOKEN
                     else if SCHEDULE_MESSAGE = T_EFFECT_CYCLE then SM_EFFECT_TOKEN
                     else if SCHEDULE_MESSAGE = T_CLOCK_CAUSALITY then SM_ROW_TOKEN
                     else if SCHEDULE_MESSAGE = T_EFFECTS_UNORDERED then ROWS_TOKEN[EF_SECOND_ROW] else -1
   | SCHEDULE_ARGUMENT0 := if SCHED_NODES >= SCHED_NODE_CAP then F_CAP_SCHEDULE_NODES
                         else if SE_ECOUNT > EFFECT_ORDER_CAP then F_CAP_EFFECTS
                         else if EF_UNFINISHED then F_CAP_EFFECT_ORDER else F_CAP_EDGES
   | SCHEDULE_READY := SCHEDULE_RUN and SCHEDULE_MESSAGE = 0
   | SWS_INDEX := 0 .. (if SCHEDULE_READY and SKB_RUN then WAR_COUNT - 1 else -1)
   | iterate SWS_INDEX of
       (| WS_READER := WAR_READER[SWS_INDEX]
        | WS_MARKS := (WS_READER < ROW_COUNT and ROWS_LOOP[WS_READER] >= 0 and ROWS_OP[WS_READER] /= OP_SEED) and (SKA_LOOP_POPS[ROWS_LOOP[WS_READER]] < LOOP_MEMBERS[ROWS_LOOP[WS_READER]])
        | WAR_SNAP1 := WAR_SNAP1[?] next (if WS_MARKS then WAR_SIGNAL[SWS_INDEX] else -1) : ROWS_LOOP[WS_READER] + 1
        |)
     end
   | SSC_INDEX := 0 .. (if SCHEDULE_READY then FLAT_SIGNAL_COUNT - 1 else -1)
   | iterate SSC_INDEX of
       (| C_L1 := if SNAP_GATHER1[SSC_INDEX] > 0 then SNAP_GATHER1[SSC_INDEX] else WAR_SNAP1[SSC_INDEX]
        | SNAP_LOOP_COUNT := SNAP_LOOP_COUNT[?] next C_L1 - 1 : SNAP_LOOP_COUNT[?][C_L1 - 1] + 1
        | SNAPPED_ALL := SNAPPED_ALL[?] next (if C_L1 > 0 then SNAP_TOTAL[?] else -1) : SSC_INDEX
        | SNAP_TOTAL := SNAP_TOTAL[?] + integer(C_L1 > 0)
        |)
     with SNAP_TOTAL := 0
     end
   | SNS_INDEX := 0 .. (if SCHEDULE_READY then FLAT_LOOP_COUNT - 1 else -1)
   | iterate SNS_INDEX of
       (| SNAP_START := SNAP_START[?] next SNS_INDEX : SNS_SUM[?]
        | SNS_SUM := SNS_SUM[?] + SNAP_LOOP_COUNT[SNS_INDEX]
        |)
     with SNS_SUM := 0
     end
   | SNP_INDEX := 0 .. (if SCHEDULE_READY then FLAT_SIGNAL_COUNT - 1 else -1)
   | iterate SNP_INDEX of
       (| N_L := (if SNAP_GATHER1[SNP_INDEX] > 0 then SNAP_GATHER1[SNP_INDEX] else WAR_SNAP1[SNP_INDEX]) - 1
        | SNAP_LIST := SNAP_LIST[?] next (if N_L >= 0 then SNAP_START[N_L] + SNAP_FILL[?][N_L] else -1) : SNP_INDEX
        | SNAP_FILL := SNAP_FILL[?] next N_L : SNAP_FILL[?][N_L] + 1
        |)
     end
   | LOP_INDEX := 0 .. (if SCHEDULE_READY and SKA_RUN then SKA_COUNT + SKB_COUNT - 1 else -1)
   | iterate LOP_INDEX of
       (| O_FIRST_RUN := LOP_INDEX < SKA_COUNT
        | O_NODE := if O_FIRST_RUN then SKA_ORDER[LOP_INDEX] else SKB_ORDER[LOP_INDEX - SKA_COUNT]
        | O_LOOP := ROWS_LOOP[O_NODE]
        | O_TAKES := O_LOOP >= 0 and (not O_FIRST_RUN or not (SKA_LOOP_POPS[O_LOOP] < LOOP_MEMBERS[O_LOOP]))
        | LO_LIST := LO_LIST[?] next (if O_TAKES then LO_START[O_LOOP] + LO_FILL[?][O_LOOP] else -1) : O_NODE
        | LO_FILL := LO_FILL[?] next (if O_TAKES then O_LOOP else -1) : LO_FILL[?][O_LOOP] + 1
        |)
     end
   | CODE_DUMP := DUMP_PASS = 7
   | EMIT_RUN := SCHEDULE_READY and (DUMP_PASS = 0 or CODE_DUMP)
   | XT_TOTAL := TYPE_COUNT + NEW_TYPE_COUNT
   | XT_INDEX := 0 .. (if EMIT_RUN then XT_TOTAL - 1 else -1)
   | iterate XT_INDEX of
       (| XT_NEW := XT_INDEX >= TYPE_COUNT
        | XT_NEW_SLOT := if XT_NEW then XT_INDEX - TYPE_COUNT else 0
        | XT_OLD_SLOT := if XT_NEW then 0 else XT_INDEX
        | XT_ELEMENT_NOW := if XT_NEW then NEW_TYPE_ELEMENT[XT_NEW_SLOT] else TYPE_ELEMENT[XT_OLD_SLOT]
        | XT_EB_NOW := if XT_ELEMENT_NOW >= 0 and XT_ELEMENT_NOW < TYPE_COUNT then TYPE_BYTES[XT_ELEMENT_NOW] else 8
        | XT_SIZE_NOW := if XT_NEW then NEW_TYPE_SIZE[XT_NEW_SLOT] else TYPE_SIZE[XT_OLD_SLOT]
        | XT_PER := ulong(if XT_EB_NOW > 0 and XT_EB_NOW <= 8 then 8 / XT_EB_NOW else 1)
        | XT_KIND := XT_KIND[?] next XT_INDEX : (if XT_NEW then TK_ARRAY else TYPE_KIND[XT_OLD_SLOT])
        | XT_BYTES := XT_BYTES[?] next XT_INDEX : (if XT_NEW then 8 else TYPE_BYTES[XT_OLD_SLOT])
        | XT_SIGNED := XT_SIGNED[?] next XT_INDEX : not XT_NEW and TYPE_SIGNED[XT_OLD_SLOT]
        | XT_ELEMENT := XT_ELEMENT[?] next XT_INDEX : (if XT_ELEMENT_NOW >= 0 then XT_ELEMENT_NOW else 0)
        | XT_EB := XT_EB[?] next XT_INDEX : XT_EB_NOW
        | XT_SIZE := XT_SIZE[?] next XT_INDEX : XT_SIZE_NOW
        | XT_WORDS := XT_WORDS[?] next XT_INDEX : XT_SIZE_NOW / XT_PER + ulong(integer(XT_SIZE_NOW modulo XT_PER /= ulong(0)))
        |)
     end
   | XT_LAST_SIGNED := XT_SIGNED[XT_TOTAL - 1]
   | EA_INDEX := 0 .. (if EMIT_RUN then FLAT_SIGNAL_COUNT - 1 else -1)
   | iterate EA_INDEX of
       (| EA_SOURCE := FLAT_SIGNAL_SOURCE[EA_INDEX]
        | EA_ROLE := if EA_SOURCE < 0 or FLAT_SIGNAL_INSTANCE[EA_INDEX] > 0 then ROLE_LOCAL else SIGNAL_ROLE[EA_SOURCE]
        | EA_EVENT := XT_KIND[ROWS_TYPE[EA_INDEX]] = TK_EVENT
        | EA_LEFT := ROWS_LEFT[EA_INDEX]
        | EA_LEFT_OP := ROWS_OP[if EA_LEFT >= 0 then EA_LEFT else 0]
        | EA_WINDOW := ROWS_OP[EA_INDEX] = OP_COPY and EA_LEFT >= 0 and (EA_LEFT_OP = OP_GATHER or EA_LEFT_OP = OP_NEXT)
        | EA_INPUT := EA_ROLE = ROLE_INPUT
        | EA_VALUE_INPUT := EA_INPUT and not EA_EVENT
        | EA_OUTPUT := EA_ROLE = ROLE_OUTPUT
        | WIN_A1 := WIN_A1[?] next (if EA_WINDOW then EA_INDEX else -1) : WIN_A_COUNT[?] + 1
        | WIN_SIGNAL := WIN_SIGNAL[?] next (if EA_WINDOW then WIN_A_COUNT[?] else -1) : EA_INDEX
        | WIN_A_COUNT := WIN_A_COUNT[?] + integer(EA_WINDOW)
        | VI_LIST := VI_LIST[?] next (if EA_VALUE_INPUT then VI_COUNT[?] else -1) : EA_INDEX
        | VI_COUNT := VI_COUNT[?] + integer(EA_VALUE_INPUT)
        | EMIT_INPUT_COUNT := EMIT_INPUT_COUNT[?] + integer(EA_INPUT)
        | OUT_LIST := OUT_LIST[?] next (if EA_OUTPUT then OUT_COUNT[?] else -1) : EA_INDEX
        | OUT_COUNT := OUT_COUNT[?] + integer(EA_OUTPUT)
        | SIG_ONE := SIG_ONE[?] next (if EA_INPUT and EA_EVENT then EA_INDEX else -1) : true
        |)
     with (| WIN_A_COUNT := 0 | VI_COUNT := 0 | EMIT_INPUT_COUNT := 0 | OUT_COUNT := 0 |)
     end
   | EMIT_WINDOWS := WIN_A_COUNT + SNAP_TOTAL
   | EW_INDEX := 0 .. (if EMIT_RUN then EMIT_WINDOWS - 1 else -1)
   | iterate EW_INDEX of
       (| EW_SNAPPED := EW_INDEX >= WIN_A_COUNT
        | EW_SIGNAL := if EW_SNAPPED then SNAPPED_ALL[EW_INDEX - WIN_A_COUNT] else WIN_SIGNAL[EW_INDEX]
        | EW_WORDS := XT_WORDS[ROWS_TYPE[EW_SIGNAL]]
        | EW_PAGES := long(EW_WORDS / ulong(2048) + ulong(integer(EW_WORDS modulo ulong(2048) /= ulong(0))))
        | EW_FAILS := not EW_FAILED[?] and EW_PAGES_TOTAL[?] + EW_PAGES + long(1) >= EMIT_PAGE_LIMIT
        | PAGES_BEFORE := PAGES_BEFORE[?] next EW_INDEX : EW_PAGES_TOTAL[?]
        | PAGES_OF := PAGES_OF[?] next EW_INDEX : EW_PAGES
        | EW_PAGES_TOTAL := if EW_FAILED[?] then EW_PAGES_TOTAL[?] else EW_PAGES_TOTAL[?] + EW_PAGES + long(1)
        | EW_FAILED := EW_FAILED[?] or EW_FAILS
        | EW_FAIL_SIGNAL := if EW_FAILS then EW_SIGNAL else EW_FAIL_SIGNAL[?]
        | WIN_P1 := WIN_P1[?] next (if EW_SNAPPED then EW_SIGNAL else -1) : EW_INDEX + 1
        |)
     with (| EW_PAGES_TOTAL := long(0) | EW_FAILED := false | EW_FAIL_SIGNAL := 0 |)
     end
   | ER_INDEX := 0 .. (if EMIT_RUN then ROW_COUNT - 1 else -1)
   | iterate ER_INDEX of
       (| ER_DELAY := ROWS_OP[ER_INDEX] = OP_DELAY
        | ER_SEED := ROWS_OP[ER_INDEX] = OP_SEED
        | ER_LOOP := if ER_SEED then ROWS_LOOP[ER_INDEX] else 0
        | ER_TAIL := SEED_TAIL1[?][ER_LOOP]
        | DELAY_INDEX := DELAY_INDEX[?] next (if ER_DELAY then ER_INDEX else -1) : DELAY_COUNT[?]
        | DELAY_LIST := DELAY_LIST[?] next (if ER_DELAY then DELAY_COUNT[?] else -1) : ER_INDEX
        | DELAY_COUNT := DELAY_COUNT[?] + integer(ER_DELAY)
        | SEED_HEAD1 := SEED_HEAD1[?] next (if ER_SEED and ER_TAIL = 0 then ER_LOOP else -1) : ER_INDEX + 1
        | SEED_NEXT1 := SEED_NEXT1[?] next (if ER_SEED and ER_TAIL > 0 then ER_TAIL - 1 else -1) : ER_INDEX + 1
        | SEED_TAIL1 := SEED_TAIL1[?] next (if ER_SEED then ER_LOOP else -1) : ER_INDEX + 1
        | SEED_TOTAL := SEED_TOTAL[?] + integer(ER_SEED)
        |)
     with (| DELAY_COUNT := 0 | SEED_TOTAL := 0 |)
     end
   | EC_INDEX := 0 .. (if EMIT_RUN then CLOCK_TOTAL - 1 else -1)
   | iterate EC_INDEX of
       (| EC_LIVE := NODE_KIND[EC_INDEX] /= CLK_NONE
        | CLK_INDEX := CLK_INDEX[?] next (if EC_LIVE then EC_INDEX else -1) : CLK_COUNT[?]
        | CLK_COUNT := CLK_COUNT[?] + integer(EC_LIVE)
        | ROOT_POSITION := ROOT_POSITION[?] next (if EC_INDEX < ROOT_COUNT then ROOT_LIST[EC_INDEX] else -1) : EC_INDEX
        |)
     with CLK_COUNT := 0
     end
   | EMIT_TABLE_COUNT := TABLE_COUNT + NEW_TABLE_COUNT
   | ETB_INDEX := 0 .. (if EMIT_RUN then EMIT_TABLE_COUNT - 1 else -1)
   | iterate ETB_INDEX of
       (| ETB_NEW := ETB_INDEX >= TABLE_COUNT
        | ETB_TYPE := if ETB_NEW then NEW_TABLE_TYPE[ETB_INDEX - TABLE_COUNT] else TABLE_TYPE[ETB_INDEX]
        | ETB_LENGTH := if ETB_NEW then long(XT_SIZE[ETB_TYPE]) else long(TABLE_LENGTH[ETB_INDEX])
        | ETB_EB := XT_EB[ETB_TYPE]
        | ETB_OFFSET := (ETB_END[?] + long(7)) / long(8) * long(8)
        | TABLE_OFFSET := TABLE_OFFSET[?] next ETB_INDEX : ETB_OFFSET
        | TABLE_EB := TABLE_EB[?] next ETB_INDEX : ETB_EB
        | TABLE_BYTES := TABLE_BYTES[?] next ETB_INDEX : ETB_LENGTH * long(ETB_EB)
        | TABLE_LIVE := TABLE_LIVE[?] next (if ETB_LENGTH > long(0) then TABLE_LIVE_COUNT[?] else -1) : ETB_INDEX
        | TABLE_LIVE_COUNT := TABLE_LIVE_COUNT[?] + integer(ETB_LENGTH > long(0))
        | ETB_END := ETB_OFFSET + ETB_LENGTH * long(ETB_EB)
        |)
     with (| ETB_END := long(0) | TABLE_LIVE_COUNT := 0 |)
     end
   | WIN_BASE := (ETB_END + long(7)) / long(8) * long(8)
   | SIG_BASE := WIN_BASE + long(8) * long(EMIT_WINDOWS)
   | MEM_BASE := SIG_BASE + long(8) * long(ROW_COUNT)
   | CLK_BASE := MEM_BASE + long(8) * long(DELAY_COUNT)
   | IN_BASE := CLK_BASE + long(4) * long(CLK_COUNT)
   | READS_LINE := PLATFORM = PLATFORM_MACOS and (ROOT_COUNT >= 2 or EMIT_INPUT_COUNT > 0)
   | RESERVES := EMIT_WINDOWS > 0 and PLATFORM = PLATFORM_MACOS
   | LINE_CAPACITY := ROOT_COUNT + 22 * VI_COUNT
   | OUT_BASE := IN_BASE + long(LINE_CAPACITY + 1)
   | MAL_BASE := OUT_BASE + long(24) * long(OUT_COUNT + 1)
   | RES_BASE := MAL_BASE + long(MALFORMED_TEXT_LENGTH * integer(READS_LINE))
   | DATA_END := RES_BASE + long(26 * integer(RESERVES))
   | ITEM_TOTAL := EMIT_TABLE_COUNT + EMIT_WINDOWS + ROW_COUNT + DELAY_COUNT + CLK_COUNT + 2 + integer(READS_LINE)
                   + integer(RESERVES)
   | SK_INDEX := 0 .. (if EMIT_RUN then 3 * ROW_COUNT - 1 else -1)
   | iterate SK_INDEX of
       (| SK_STARTS := SK_TOP[?] = 0
        | SK_X := if SK_STARTS then SK_CURSOR[?] else SK_STACK[?][if SK_STARTS then 0 else SK_TOP[?] - 1]
        | SK_LIVE := SK_X < ROW_COUNT
        | SK_ROW := if SK_LIVE then SK_X else 0
        | SK_OP := ROWS_OP[SK_ROW]
        | SK_LEFT := ROWS_LEFT[SK_ROW]
        | SK_LEFT_ROW := if SK_LEFT >= 0 then SK_LEFT else 0
        | SK_SNAPSHOT := SK_OP = OP_PREV and WIN_P1[SK_LEFT_ROW] > 0
        | SK_CHAINS := (SK_OP = OP_COPY or SK_OP = OP_PREV) and not SK_SNAPSHOT and SK_LEFT >= 0
        | SK_ALREADY := SK_DONE[?][SK_ROW]
        | SK_READY := not SK_CHAINS or SK_DONE[?][SK_LEFT_ROW]
        | SK_RESOLVES := SK_LIVE and not SK_ALREADY and SK_READY
        | SK_PUSHES := SK_LIVE and not SK_ALREADY and not SK_READY and SK_TOP[?] < ROW_COUNT
        | SK_OWNER := ROWS_OWNER[SK_ROW]
        | SK_VALUE := if SK_CHAINS then SK_KEY[?][SK_LEFT_ROW] else if SK_SNAPSHOT then WIN_P1[SK_LEFT_ROW] - 1
                      else if SK_OP = OP_TABLE then -1 - integer(ROWS_VALUE[SK_ROW])
                      else if SK_OWNER >= 0 then WIN_A1[SK_OWNER] - 1 else -1
        | SK_KEY := SK_KEY[?] next (if SK_RESOLVES then SK_ROW else -1) : SK_VALUE
        | SK_DONE := SK_DONE[?] next (if SK_RESOLVES then SK_ROW else -1) : true
        | SK_STACK := SK_STACK[?] next (if SK_PUSHES then SK_TOP[?] else -1) : (if SK_STARTS then SK_ROW else SK_LEFT_ROW)
        | SK_TOP := if SK_PUSHES then SK_TOP[?] + 1 else if SK_RESOLVES and not SK_STARTS then SK_TOP[?] - 1 else SK_TOP[?]
        | SK_CURSOR := if SK_STARTS and SK_LIVE and (SK_ALREADY or SK_RESOLVES) then SK_CURSOR[?] + 1 else SK_CURSOR[?]
        |)
     with (| SK_TOP := 0 | SK_CURSOR := 0 |)
     end
   | EMIT_PREPARED := EMIT_RUN and not EW_FAILED
   | UNIT_BOUND := long(30) + long(EMIT_WINDOWS) + long(VI_COUNT) + long(DELAY_COUNT) + long(OUT_COUNT) + long(SKO_COUNT)
                   + long(2) * long(FLAT_LOOP_COUNT) + long(SEED_TOTAL) + long(SNAP_TOTAL) + long(LO_SUM) + long(PRAGMA_COUNT)
   | UNIT_RUN := EMIT_PREPARED and UNIT_BOUND < long(PARSE_CAP)
   | UN_INDEX := 0 .. (if UNIT_RUN then integer(UNIT_BOUND) - 1 else -1)
   | iterate UN_INDEX of
       (| UN_PH := UN_NEXT_PH[?]
        | UN_J := UN_NEXT_J[?]
        | UN_LS := UN_NEXT_LS[?]
        | UN_K := UN_NEXT_K[?]
        | UN_ORDER := UN_PH = UPH_ORDER
        | UN_PHASE_LENGTH := if UN_PH = UPH_PROLOGUE or UN_PH = UPH_STEP or UN_PH = UPH_FINISH then 1
                             else if UN_PH = UPH_RESERVE or UN_PH = UPH_RESERVE_FAILED then integer(RESERVES)
                             else if UN_PH = UPH_WINDOW then EMIT_WINDOWS
                             else if UN_PH = UPH_JUMP_STEP then integer(PLATFORM = PLATFORM_MACOS and (EMIT_WINDOWS > 0 or VI_COUNT > 0))
                             else if UN_PH = UPH_BOOT then integer(PRAGMA_HAS_BOOT)
                             else if UN_PH = UPH_WAIT or UN_PH = UPH_WAIT_TAIL then integer(PLATFORM /= PLATFORM_MACOS)
                             else if UN_PH = UPH_DISPATCH then PRAGMA_COUNT
                             else if UN_PH = UPH_READ_VALUE then integer(VI_COUNT > 0)
                             else if UN_PH = UPH_READ_LINE or UN_PH = UPH_READ_TAIL then integer(READS_LINE)
                             else if UN_PH = UPH_VALUE_INPUT then (if READS_LINE then VI_COUNT else 0)
                             else if UN_PH = UPH_ORDER then SKO_COUNT
                             else if UN_PH = UPH_DELAY then DELAY_COUNT
                             else if UN_PH = UPH_OUTPUT_HEAD or UN_PH = UPH_OUTPUT_TAIL then integer(OUT_COUNT > 0)
                             else if UN_PH = UPH_OUTPUT then OUT_COUNT else 0
        | UN_IN_PHASE := UN_PH < UPH_DONE and UN_J < UN_PHASE_LENGTH
        | UN_NODE := SKO_ORDER[if UN_ORDER and UN_IN_PHASE then UN_J else 0]
        | UN_LOOP_NODE := UN_ORDER and UN_NODE >= SCHED_LOOP_BASE
        | UN_CLOCK_NODE := UN_ORDER and UN_NODE >= ROW_COUNT and UN_NODE < SCHED_LOOP_BASE
        | UN_L := if UN_LOOP_NODE then UN_NODE - SCHED_LOOP_BASE else 0
        | UN_C := if UN_CLOCK_NODE then UN_NODE - ROW_COUNT else 0
        | UN_SNAP_COUNT := SNAP_LOOP_COUNT[UN_L]
        | UN_LO_LENGTH := LO_LENGTH[UN_L]
        | UN_LOOP_ROW := if UN_LS = 1 then UN_K - 1 else LO_LIST[LO_START[UN_L] + (if UN_LS = 4 then UN_K else 0)]
        | UN_ROW_LIKE := UN_ORDER and (if UN_LOOP_NODE then UN_LS = 1 or UN_LS = 4 else not UN_CLOCK_NODE)
        | UN_X := if UN_LOOP_NODE then UN_LOOP_ROW else UN_NODE
        | TP_ROW := if UN_ROW_LIKE and UN_X >= 0 and UN_X < ROW_COUNT then UN_X else 0
        | TP_OP := ROWS_OP[TP_ROW]
        | TP_TYPE := ROWS_TYPE[TP_ROW]
        | TP_KIND := XT_KIND[TP_TYPE]
        | TP_LEFT := ROWS_LEFT[TP_ROW]
        | TP_RIGHT := ROWS_RIGHT[TP_ROW]
        | TP_LEFT_ROW := if TP_LEFT >= 0 then TP_LEFT else 0
        | TP_RIGHT_ROW := if TP_RIGHT >= 0 then TP_RIGHT else 0
        | TP_LEFT_LEFT := ROWS_LEFT[TP_LEFT_ROW]
        | TP_EFFECT := EFFECT_KIND[if TP_OP = OP_EFFECT then integer(ROWS_VALUE[TP_ROW]) else 0] modulo NAME_CAP
        | TP_LT := ROWS_TYPE[TP_LEFT_ROW]
        | TP_RT := ROWS_TYPE[TP_RIGHT_ROW]
        | TP_L_LOGICAL := XT_KIND[TP_LT] = TK_EVENT or XT_KIND[TP_LT] = TK_BOOLEAN
        | TP_R_LOGICAL := XT_KIND[TP_RT] = TK_EVENT or XT_KIND[TP_RT] = TK_BOOLEAN
        | TP_BOTH_INT := XT_KIND[TP_LT] = TK_INT and XT_KIND[TP_RT] = TK_INT
        | TP_L_SIGNED := XT_SIGNED[TP_LT]
        | TP_R_SIGNED := XT_SIGNED[TP_RT]
        | TP_SIGNED_BYTES := if TP_L_SIGNED then XT_BYTES[TP_LT] else XT_BYTES[TP_RT]
        | TP_UNSIGNED_BYTES := if TP_L_SIGNED then XT_BYTES[TP_RT] else XT_BYTES[TP_LT]
        | TP_SIGNED := TP_RIGHT >= 0
                       and (if TP_LT = TP_RT then TP_L_SIGNED else if TP_L_LOGICAL and TP_R_LOGICAL then false
                            else if not TP_BOTH_INT then XT_LAST_SIGNED else if TP_L_SIGNED = TP_R_SIGNED then TP_L_SIGNED
                            else TP_SIGNED_BYTES > TP_UNSIGNED_BYTES or TP_UNSIGNED_BYTES <= 4 or XT_LAST_SIGNED)
        | TP_SKIPS := TP_OP = OP_TABLE or TP_OP = OP_PAIR or TP_OP = OP_BRANCH or TP_OP = OP_INPUT or TP_OP = OP_ARG
                      or TP_OP = OP_RANGE or (TP_OP = OP_COPY or TP_OP = OP_PREV) and TP_KIND = TK_ARRAY
        | TP_TEMPLATE := if TP_SKIPS then -1
                         else if TP_OP = OP_SEED then (if TP_KIND = TK_ARRAY then ET_ROW_SEED_ARRAY else ET_ROW_SEED)
                         else if TP_OP = OP_EFFECT then
                           (if TP_EFFECT = N_LOAD then ET_ROW_LOAD else if TP_EFFECT = N_STORE then ET_ROW_STORE
                            else if TP_EFFECT = N_SYSCALL then ET_ROW_SYSCALL else ET_ROW_INSTRUCTION)
                         else if TP_OP = OP_ITER then
                           (if ROWS_OP[if TP_LEFT_LEFT >= 0 then TP_LEFT_LEFT else 0] = OP_RANGE then ET_ROW_ITER_RANGE else ET_ROW_ITER)
                         else if TP_OP = OP_PREV then ET_ROW_PREV else if TP_OP = OP_ELEMENT then ET_ROW_ELEMENT
                         else if TP_OP = OP_GATHER then ET_ROW_GATHER else if TP_OP = OP_NEXT then ET_ROW_NEXT
                         else if TP_OP = OP_CONST then ET_ROW_CONST else if TP_OP = OP_DELAY then ET_ROW_DELAY
                         else if TP_OP = OP_UWHEN or TP_OP = OP_CLOCK then ET_ROW_ONE else if TP_OP = OP_IF then ET_ROW_IF
                         else if TP_OP = OP_DEFAULT and not ROWS_CTX[TP_LEFT_ROW] then ET_ROW_DEFAULT
                         else if TP_OP = OP_NEG then ET_ROW_NEG
                         else if TP_OP = OP_NOT then
                           (if TP_KIND = TK_EVENT or TP_KIND = TK_BOOLEAN then ET_ROW_NOT_LOGICAL else ET_ROW_NOT)
                         else if OP_INSTRUCTION_FORM[TP_OP] >= 0 then ET_ROW_BINARY
                         else if TP_OP = OP_DIV then (if TP_SIGNED then ET_ROW_DIV_SIGNED else ET_ROW_DIV)
                         else if OP_SIGNED_CONDITION[TP_OP] >= 0 then (if TP_SIGNED then ET_ROW_COMPARE_SIGNED else ET_ROW_COMPARE)
                         else if TP_OP = OP_MOD then (if TP_SIGNED then ET_ROW_MOD_SIGNED else ET_ROW_MOD)
                         else if OP_SHIFT_FORM[TP_OP] >= 0 then ET_ROW_SHIFT else ET_ROW_PLAIN
        | UN_CLOCK_KIND := NODE_KIND[UN_C]
        | UN_BASE_TEMPLATE := if not UN_IN_PHASE then -1
                         else if not UN_ORDER then
                           (if PLATFORM /= PLATFORM_MACOS then UNIT_PHASE_TEMPLATE_VIRT[UN_PH] else UNIT_PHASE_TEMPLATE[UN_PH])
                         else if UN_LOOP_NODE then
                           (if UN_LS = 0 then ET_LOOP_HEAD else if UN_LS = 2 then ET_LOOP_MID else if UN_LS = 3 then ET_SNAPSHOT
                            else if UN_LS = 5 then ET_LOOP_TAIL else TP_TEMPLATE)
                         else if UN_CLOCK_NODE then
                           (if UN_CLOCK_KIND = CLK_ROOT then
                              (if PLATFORM /= PLATFORM_MACOS then ET_CLOCK_ROOT_VIRT else if READS_LINE then ET_CLOCK_ROOT_READ
                               else ET_CLOCK_ROOT)
                            else if UN_CLOCK_KIND = CLK_SAMPLE then ET_CLOCK_SAMPLE else ET_CLOCK_PAIR)
                         else TP_TEMPLATE
        | UN_TEMPLATE := if PLATFORM = PLATFORM_MPS2 and UN_BASE_TEMPLATE >= 0 then THUMB_TEMPLATE[UN_BASE_TEMPLATE]
                         else UN_BASE_TEMPLATE
        | UN_P := if not UN_ORDER then
                    (if UN_PH = UPH_WINDOW then UN_J else if UN_PH = UPH_VALUE_INPUT then VI_LIST[UN_J]
                     else if UN_PH = UPH_DELAY then DELAY_LIST[UN_J] else if UN_PH = UPH_OUTPUT then OUT_LIST[UN_J]
                     else if UN_PH = UPH_DISPATCH then PRAGMA_IRQ[UN_J] else 0)
                  else if UN_LOOP_NODE then
                    (if UN_LS = 3 then SNAP_LIST[SNAP_START[UN_L] + UN_K] else if UN_LS = 1 or UN_LS = 4 then UN_LOOP_ROW else UN_L)
                  else if UN_CLOCK_NODE then UN_C else UN_NODE
        | UN_FLAG := if UN_ORDER then not UN_LOOP_NODE and not UN_CLOCK_NODE
                     else if UN_PH = UPH_DISPATCH then PRAGMA_IRQ[UN_J] < BOOT_ID else UN_PH = UPH_OUTPUT and UN_J > 0
        | UN_STEPS_LOOP := UN_LOOP_NODE and UN_IN_PHASE
        | UN_SEED_NEXT := if UN_LS = 0 then SEED_HEAD1[UN_L] else SEED_NEXT1[if UN_K > 0 then UN_K - 1 else 0]
        | UN_AFTER_SNAPS := if UN_LO_LENGTH > 0 then 4 else 5
        | UN_LS_AFTER := if UN_LS <= 1 then (if UN_SEED_NEXT > 0 then 1 else 2)
                         else if UN_LS = 2 then (if UN_SNAP_COUNT > 0 then 3 else UN_AFTER_SNAPS)
                         else if UN_LS = 3 then (if UN_K + 1 < UN_SNAP_COUNT then 3 else UN_AFTER_SNAPS)
                         else if UN_LS = 4 then (if UN_K + 1 < UN_LO_LENGTH then 4 else 5)
                         else 0
        | UN_K_AFTER := if UN_LS_AFTER = 1 then UN_SEED_NEXT else if UN_LS_AFTER = UN_LS and UN_LS >= 3 then UN_K + 1 else 0
        | UN_ADVANCES := UN_IN_PHASE and (not UN_LOOP_NODE or UN_LS = 5)
        | UN_NEXT_PH := if UN_PH < UPH_DONE and not UN_IN_PHASE then UN_PH + 1 else UN_PH
        | UN_NEXT_J := if not UN_IN_PHASE then 0 else if UN_ADVANCES then UN_J + 1 else UN_J
        | UN_NEXT_LS := if UN_STEPS_LOOP then UN_LS_AFTER else 0
        | UN_NEXT_K := if UN_STEPS_LOOP then UN_K_AFTER else 0
        | UN_EMITS := UN_TEMPLATE >= 0
        | UN_SLOT := if UN_EMITS and UNIT_COUNT[?] < UNIT_CAP then UNIT_COUNT[?] else -1
        | UN_TEMPLATE_ROW := if UN_EMITS then UN_TEMPLATE else 0
        | UNIT_TEMPLATE := UNIT_TEMPLATE[?] next UN_SLOT : UN_TEMPLATE
        | UNIT_P := UNIT_P[?] next UN_SLOT : UN_P
        | UNIT_FLAG := UNIT_FLAG[?] next UN_SLOT : UN_FLAG
        | UNIT_LABEL := UNIT_LABEL[?] next UN_SLOT : UNIT_LABEL_TOTAL[?]
        | UNIT_COUNT := UNIT_COUNT[?] + integer(UN_EMITS)
        | UNIT_LABEL_TOTAL := UNIT_LABEL_TOTAL[?] + (if UN_EMITS then ET_LABELS[UN_TEMPLATE_ROW] else 0)
        | UNIT_STEP_TOTAL := UNIT_STEP_TOTAL[?] + long(if UN_EMITS then ET_LENGTH[UN_TEMPLATE_ROW] else 0)
        |)
     with (| UN_NEXT_PH := 0 | UN_NEXT_J := 0 | UN_NEXT_LS := 0 | UN_NEXT_K := 0 | UNIT_COUNT := 0
           | UNIT_LABEL_TOTAL := GLOBAL_LABEL_COUNT + 2 * FLAT_LOOP_COUNT | UNIT_STEP_TOTAL := long(0) |)
     end
   | UNIT_READY := UNIT_RUN and UN_NEXT_PH = UPH_DONE and UNIT_COUNT <= UNIT_CAP
   | PLAN_RUN := UNIT_READY and UNIT_STEP_TOTAL < long(PARSE_CAP)
   | PL_INDEX := 0 .. (if PLAN_RUN then integer(UNIT_STEP_TOTAL) - 1 else -1)
   | iterate PL_INDEX of
       (| PL_U := PL_NEXT_U[?]
        | PL_K := PL_NEXT_K[?]
        | PL_T := UNIT_TEMPLATE[PL_U]
        | PL_P := UNIT_P[PL_U]
        | PL_FLAG := UNIT_FLAG[PL_U]
        | PL_LOCAL := UNIT_LABEL[PL_U]
        | PL_STEP := ET_START[PL_T] + PL_K
        | PL_LAST := PL_K + 1 >= ET_LENGTH[PL_T]
        | PL_NEXT_U := if PL_LAST then PL_U + 1 else PL_U
        | PL_NEXT_K := if PL_LAST then 0 else PL_K + 1
        | PL_KIND := STEP_KIND[PL_STEP]
        | PL_WHEN := STEP_WHEN[PL_STEP]
        | PL_SOURCE0 := STEP_SOURCE0[PL_STEP]
        | PL_SOURCE1 := STEP_SOURCE1[PL_STEP]
        | PL_ROW := if PL_P >= 0 and PL_P < ROW_COUNT then PL_P else 0
        | PL_CLOCK := if PL_P >= 0 and PL_P < CLOCK_TOTAL then PL_P else 0
        | PL_LOOP := if PL_P >= 0 and PL_P < FLAT_LOOP_COUNT then PL_P else 0
        | PL_WINDOW := if PL_P >= 0 and PL_P < EMIT_WINDOWS then PL_P else 0
        | PL_OP := ROWS_OP[PL_ROW]
        | PL_TYPE := ROWS_TYPE[PL_ROW]
        | PL_LEFT := ROWS_LEFT[PL_ROW]
        | PL_RIGHT := ROWS_RIGHT[PL_ROW]
        | PL_LEFT_ROW := if PL_LEFT >= 0 then PL_LEFT else 0
        | PL_RIGHT_ROW := if PL_RIGHT >= 0 then PL_RIGHT else 0
        | PL_OWNER := ROWS_OWNER[PL_ROW]
        | PL_OWNER_KEY := WIN_A1[if PL_OWNER >= 0 then PL_OWNER else 0] - 1
        | PL_C1 := if PL_LEFT >= 0 then ROWS_RIGHT[PL_LEFT] else -1
        | PL_C2 := if PL_C1 >= 0 then ROWS_RIGHT[PL_C1] else -1
        | PL_C3 := if PL_C2 >= 0 then ROWS_RIGHT[PL_C2] else -1
        | PL_C4 := if PL_C3 >= 0 then ROWS_RIGHT[PL_C3] else -1
        | PL_C5 := if PL_C4 >= 0 then ROWS_RIGHT[PL_C4] else -1
        | PL_C6 := if PL_C5 >= 0 then ROWS_RIGHT[PL_C5] else -1
        | PL_PARAM := EFFECT_PARAM[if PL_OP = OP_EFFECT then integer(ROWS_VALUE[PL_ROW]) else 0]
        | PL_PARAM_TYPE := if PL_PARAM >= long(0) and PL_PARAM < long(XT_TOTAL) then integer(PL_PARAM) else 0
        | PL_ELEMENT := XT_ELEMENT[PL_TYPE]
        | PL_INDEX_ELEMENT := XT_ELEMENT[ROWS_TYPE[PL_RIGHT_ROW]]
        | PL_LOOP_LEFT := ROWS_LEFT[LOOP_INDEX[PL_LOOP]]
        | PL_LOOP_LEFT_ROW := if PL_LOOP_LEFT >= 0 then PL_LOOP_LEFT else 0
        | PL_COUNT_ROW := if PL_LOOP_LEFT >= 0 and ROWS_OP[PL_LOOP_LEFT_ROW] = OP_RANGE then ROWS_RIGHT[PL_LOOP_LEFT_ROW] else -1
        | PL_INPUT_ROOT1 := NODE_ROOT1[CLOCK_REP[PL_ROW]]
        | PL_INPUT_ROOT := if PL_INPUT_ROOT1 > 0 then PL_INPUT_ROOT1 - 1 else 0
        | PL_ROOT_IRQ := ROOT_IRQ1[PL_CLOCK] - 1
        | PL_V0 := if PL_SOURCE0 = ES_ROW then long(PL_P)
                      else if PL_SOURCE0 = ES_LEFT then long(PL_LEFT)
                      else if PL_SOURCE0 = ES_RIGHT then long(PL_RIGHT)
                      else if PL_SOURCE0 = ES_RIGHT_LEFT then long(ROWS_LEFT[PL_RIGHT_ROW])
                      else if PL_SOURCE0 = ES_RIGHT_RIGHT then long(ROWS_RIGHT[PL_RIGHT_ROW])
                      else if PL_SOURCE0 = ES_PARAM then PL_PARAM
                      else if PL_SOURCE0 = ES_VALUE_ROW then ROWS_VALUE[PL_ROW]
                      else if PL_SOURCE0 = ES_ARG0 then long(ROWS_LEFT[PL_LEFT_ROW])
                      else if PL_SOURCE0 = ES_ARG1 then long(if PL_C1 >= 0 then ROWS_LEFT[PL_C1] else -1)
                      else if PL_SOURCE0 = ES_ARG2 then long(if PL_C2 >= 0 then ROWS_LEFT[PL_C2] else -1)
                      else if PL_SOURCE0 = ES_ARG3 then long(if PL_C3 >= 0 then ROWS_LEFT[PL_C3] else -1)
                      else if PL_SOURCE0 = ES_ARG4 then long(if PL_C4 >= 0 then ROWS_LEFT[PL_C4] else -1)
                      else if PL_SOURCE0 = ES_ARG5 then long(if PL_C5 >= 0 then ROWS_LEFT[PL_C5] else -1)
                      else if PL_SOURCE0 = ES_ARG6 then long(if PL_C6 >= 0 then ROWS_LEFT[PL_C6] else -1)
                      else if PL_SOURCE0 = ES_TYPE_ROW then long(PL_TYPE)
                      else if PL_SOURCE0 = ES_SIZE_LEFT then long(XT_SIZE[ROWS_TYPE[PL_LEFT_ROW]])
                      else if PL_SOURCE0 = ES_SIZE_ROW then long(XT_SIZE[PL_TYPE])
                      else if PL_SOURCE0 = ES_WORDS_ROW then long(XT_WORDS[PL_TYPE])
                      else if PL_SOURCE0 = ES_KEY_LEFT then long(SK_KEY[PL_LEFT_ROW])
                      else if PL_SOURCE0 = ES_KEY_RIGHT then long(SK_KEY[PL_RIGHT_ROW])
                      else if PL_SOURCE0 = ES_KEY_OWNER then long(PL_OWNER_KEY)
                      else if PL_SOURCE0 = ES_KEY_A_RIGHT then long(WIN_A1[PL_RIGHT_ROW] - 1)
                      else if PL_SOURCE0 = ES_KEY_A_ROW then long(WIN_A1[PL_ROW] - 1)
                      else if PL_SOURCE0 = ES_KEY_P_ROW then long(WIN_P1[PL_ROW] - 1)
                      else if PL_SOURCE0 = ES_CLOCK_ROW then long(CLOCK_REP[PL_ROW])
                      else if PL_SOURCE0 = ES_CLOCK_LEFT then long(CLOCK_REP[PL_LEFT_ROW])
                      else if PL_SOURCE0 = ES_CLOCK_LOOP then long(CLOCK_REP[LOOP_INDEX[PL_LOOP]])
                      else if PL_SOURCE0 = ES_NODE_PARENT then long(NODE_PARENT1[PL_CLOCK] - 1)
                      else if PL_SOURCE0 = ES_NODE_LEFT then long(NODE_LEFT1[PL_CLOCK] - 1)
                      else if PL_SOURCE0 = ES_NODE_RIGHT then long(NODE_RIGHT1[PL_CLOCK] - 1)
                      else if PL_SOURCE0 = ES_ROOT_POSITION then long(ROOT_POSITION[PL_CLOCK])
                      else if PL_SOURCE0 = ES_INPUT_ROOT_POSITION then long(ROOT_POSITION[PL_INPUT_ROOT])
                      else if PL_SOURCE0 = ES_INPUT_BOUND then long(if XT_KIND[PL_TYPE] = TK_BOOLEAN then 2 else TYPE_VALUE_COUNT[if PL_TYPE < TYPE_COUNT then PL_TYPE else 0])
                      else if PL_SOURCE0 = ES_LOOP_COUNT then long(PL_COUNT_ROW)
                      else if PL_SOURCE0 = ES_LOOP_SIZE then long(LOOP_SIZE[PL_LOOP])
                      else if PL_SOURCE0 = ES_LOOP_SIZE_LESS_ONE then long(LOOP_SIZE[PL_LOOP]) - long(1)
                      else if PL_SOURCE0 = ES_LOOP_CONDITION then long(if XT_SIGNED[ROWS_TYPE[if PL_COUNT_ROW >= 0 then PL_COUNT_ROW else 0]] then CC_LT else CC_LO)
                      else if PL_SOURCE0 = ES_WINDOW_OFFSET then PAGES_BEFORE[PL_WINDOW] * long(16384)
                      else if PL_SOURCE0 = ES_WINDOW_BYTES then PAGES_OF[PL_WINDOW] * long(16384)
                      else if PL_SOURCE0 = ES_RESERVATION then EW_PAGES_TOTAL * long(16384)
                      else if PL_SOURCE0 = ES_LINE_CAPACITY then long(LINE_CAPACITY)
                      else if PL_SOURCE0 = ES_ROOT_COUNT then long(ROOT_COUNT)
                      else if PL_SOURCE0 = ES_LOAD_PARAM then long(LOAD_OFFSET_FORM[XT_BYTES[PL_PARAM_TYPE] * 2 + integer(XT_SIGNED[PL_PARAM_TYPE])])
                      else if PL_SOURCE0 = ES_STORE_PARAM then long(STORE_OFFSET_FORM[XT_BYTES[PL_PARAM_TYPE]])
                      else if PL_SOURCE0 = ES_LOAD_INDEXED_ROW then long(LOAD_INDEXED_FORM[XT_BYTES[PL_TYPE] * 2 + integer(XT_SIGNED[PL_TYPE])])
                      else if PL_SOURCE0 = ES_LOAD_INDEXED_INDEX then long(LOAD_INDEXED_FORM[XT_BYTES[PL_INDEX_ELEMENT] * 2 + integer(XT_SIGNED[PL_INDEX_ELEMENT])])
                      else if PL_SOURCE0 = ES_LOAD_INDEXED_ELEMENT then long(LOAD_INDEXED_FORM[XT_BYTES[PL_ELEMENT] * 2 + integer(XT_SIGNED[PL_ELEMENT])])
                      else if PL_SOURCE0 = ES_STORE_INDEXED_ELEMENT then long(STORE_INDEXED_FORM[XT_BYTES[PL_ELEMENT]])
                      else if PL_SOURCE0 = ES_INSTRUCTION_OP then long(OP_INSTRUCTION_FORM[PL_OP])
                      else if PL_SOURCE0 = ES_SHIFT_OP then long(OP_SHIFT_FORM[PL_OP])
                      else if PL_SOURCE0 = ES_PAIR_FORM then long(if NODE_KIND[PL_CLOCK] = CLK_PRODUCT then FORM_AND_W else FORM_ORR_W)
                      else if PL_SOURCE0 = ES_SIGNED_CONDITION then long(OP_SIGNED_CONDITION[PL_OP])
                      else if PL_SOURCE0 = ES_UNSIGNED_CONDITION then long(OP_UNSIGNED_CONDITION[PL_OP])
                      else if PL_SOURCE0 = ES_LOOP_START then long(GLOBAL_LABEL_COUNT + 2 * PL_P)
                      else if PL_SOURCE0 = ES_LOOP_END then long(GLOBAL_LABEL_COUNT + 2 * PL_P + 1)
                      else if PL_SOURCE0 = ES_LOCAL0 then long(PL_LOCAL + 0)
                      else if PL_SOURCE0 = ES_LOCAL1 then long(PL_LOCAL + 1)
                      else if PL_SOURCE0 = ES_LOCAL2 then long(PL_LOCAL + 2)
                      else if PL_SOURCE0 = ES_LOCAL3 then long(PL_LOCAL + 3)
                      else if PL_SOURCE0 = ES_LOCAL4 then long(PL_LOCAL + 4)
                      else if PL_SOURCE0 = ES_PUT_OUTPUT then long(if XT_KIND[PL_TYPE] = TK_EVENT or XT_KIND[PL_TYPE] = TK_BOOLEAN then GL_PUT_BOOL else if XT_SIGNED[PL_TYPE] then GL_PUT_INT else GL_PUT_UINT)
                      else if PL_SOURCE0 = ES_MALFORMED then long(GL_MALFORMED)
                      else if PL_SOURCE0 = ES_RESERVE_FAILED then long(GL_RESERVE_FAILED)
                      else if PL_SOURCE0 = ES_READ_VALUE then long(GL_READ_VALUE)
                      else if PL_SOURCE0 = ES_PUT_INT then long(GL_PUT_INT)
                      else if PL_SOURCE0 = ES_PUT_UINT then long(GL_PUT_UINT)
                      else if PL_SOURCE0 = ES_PUT_BOOL then long(GL_PUT_BOOL)
                      else if PL_SOURCE0 = ES_STEP then long(GL_STEP)
                      else if PL_SOURCE0 = ES_WAIT then long(GL_WAIT)
                      else if PL_SOURCE0 = ES_COMPLETE then long(GL_COMPLETE)
                      else if PL_SOURCE0 = ES_ROOT_IRQ then long(PL_ROOT_IRQ)
                      else if PL_SOURCE0 = ES_BINARY_LO then long(THUMB_BINARY_LO[PL_OP])
                      else if PL_SOURCE0 = ES_BINARY_HI then long(THUMB_BINARY_HI[PL_OP])
                      else if PL_SOURCE0 = ES_PAIR_FORM_THUMB then long(if NODE_KIND[PL_CLOCK] = CLK_PRODUCT then FORM_AND_T else FORM_ORR_T)
                      else if PL_SOURCE0 = ES_SIGNED_CONDITION_THUMB then long(THUMB_SIGNED_SKIP[PL_OP])
                      else if PL_SOURCE0 = ES_UNSIGNED_CONDITION_THUMB then long(THUMB_UNSIGNED_SKIP[PL_OP])
                      else if PL_SOURCE0 = ES_ELEMENT_ROW then long(PL_ELEMENT)
                      else if PL_SOURCE0 = ES_INDEX_ELEMENT then long(PL_INDEX_ELEMENT)
                      else if PL_SOURCE0 = ES_DIVIDE then long(GL_DIVIDE)
                      else long(GL_READ_DONE)
        | PL_V1 := if PL_SOURCE1 = ES_ROW then long(PL_P)
                      else if PL_SOURCE1 = ES_LEFT then long(PL_LEFT)
                      else if PL_SOURCE1 = ES_RIGHT then long(PL_RIGHT)
                      else if PL_SOURCE1 = ES_RIGHT_LEFT then long(ROWS_LEFT[PL_RIGHT_ROW])
                      else if PL_SOURCE1 = ES_RIGHT_RIGHT then long(ROWS_RIGHT[PL_RIGHT_ROW])
                      else if PL_SOURCE1 = ES_PARAM then PL_PARAM
                      else if PL_SOURCE1 = ES_VALUE_ROW then ROWS_VALUE[PL_ROW]
                      else if PL_SOURCE1 = ES_ARG0 then long(ROWS_LEFT[PL_LEFT_ROW])
                      else if PL_SOURCE1 = ES_ARG1 then long(if PL_C1 >= 0 then ROWS_LEFT[PL_C1] else -1)
                      else if PL_SOURCE1 = ES_ARG2 then long(if PL_C2 >= 0 then ROWS_LEFT[PL_C2] else -1)
                      else if PL_SOURCE1 = ES_ARG3 then long(if PL_C3 >= 0 then ROWS_LEFT[PL_C3] else -1)
                      else if PL_SOURCE1 = ES_ARG4 then long(if PL_C4 >= 0 then ROWS_LEFT[PL_C4] else -1)
                      else if PL_SOURCE1 = ES_ARG5 then long(if PL_C5 >= 0 then ROWS_LEFT[PL_C5] else -1)
                      else if PL_SOURCE1 = ES_ARG6 then long(if PL_C6 >= 0 then ROWS_LEFT[PL_C6] else -1)
                      else if PL_SOURCE1 = ES_TYPE_ROW then long(PL_TYPE)
                      else if PL_SOURCE1 = ES_SIZE_LEFT then long(XT_SIZE[ROWS_TYPE[PL_LEFT_ROW]])
                      else if PL_SOURCE1 = ES_SIZE_ROW then long(XT_SIZE[PL_TYPE])
                      else if PL_SOURCE1 = ES_WORDS_ROW then long(XT_WORDS[PL_TYPE])
                      else if PL_SOURCE1 = ES_KEY_LEFT then long(SK_KEY[PL_LEFT_ROW])
                      else if PL_SOURCE1 = ES_KEY_RIGHT then long(SK_KEY[PL_RIGHT_ROW])
                      else if PL_SOURCE1 = ES_KEY_OWNER then long(PL_OWNER_KEY)
                      else if PL_SOURCE1 = ES_KEY_A_RIGHT then long(WIN_A1[PL_RIGHT_ROW] - 1)
                      else if PL_SOURCE1 = ES_KEY_A_ROW then long(WIN_A1[PL_ROW] - 1)
                      else if PL_SOURCE1 = ES_KEY_P_ROW then long(WIN_P1[PL_ROW] - 1)
                      else if PL_SOURCE1 = ES_CLOCK_ROW then long(CLOCK_REP[PL_ROW])
                      else if PL_SOURCE1 = ES_CLOCK_LEFT then long(CLOCK_REP[PL_LEFT_ROW])
                      else if PL_SOURCE1 = ES_CLOCK_LOOP then long(CLOCK_REP[LOOP_INDEX[PL_LOOP]])
                      else if PL_SOURCE1 = ES_NODE_PARENT then long(NODE_PARENT1[PL_CLOCK] - 1)
                      else if PL_SOURCE1 = ES_NODE_LEFT then long(NODE_LEFT1[PL_CLOCK] - 1)
                      else if PL_SOURCE1 = ES_NODE_RIGHT then long(NODE_RIGHT1[PL_CLOCK] - 1)
                      else if PL_SOURCE1 = ES_ROOT_POSITION then long(ROOT_POSITION[PL_CLOCK])
                      else if PL_SOURCE1 = ES_INPUT_ROOT_POSITION then long(ROOT_POSITION[PL_INPUT_ROOT])
                      else if PL_SOURCE1 = ES_INPUT_BOUND then long(if XT_KIND[PL_TYPE] = TK_BOOLEAN then 2 else TYPE_VALUE_COUNT[if PL_TYPE < TYPE_COUNT then PL_TYPE else 0])
                      else if PL_SOURCE1 = ES_LOOP_COUNT then long(PL_COUNT_ROW)
                      else if PL_SOURCE1 = ES_LOOP_SIZE then long(LOOP_SIZE[PL_LOOP])
                      else if PL_SOURCE1 = ES_LOOP_SIZE_LESS_ONE then long(LOOP_SIZE[PL_LOOP]) - long(1)
                      else if PL_SOURCE1 = ES_LOOP_CONDITION then long(if XT_SIGNED[ROWS_TYPE[if PL_COUNT_ROW >= 0 then PL_COUNT_ROW else 0]] then CC_LT else CC_LO)
                      else if PL_SOURCE1 = ES_WINDOW_OFFSET then PAGES_BEFORE[PL_WINDOW] * long(16384)
                      else if PL_SOURCE1 = ES_WINDOW_BYTES then PAGES_OF[PL_WINDOW] * long(16384)
                      else if PL_SOURCE1 = ES_RESERVATION then EW_PAGES_TOTAL * long(16384)
                      else if PL_SOURCE1 = ES_LINE_CAPACITY then long(LINE_CAPACITY)
                      else if PL_SOURCE1 = ES_ROOT_COUNT then long(ROOT_COUNT)
                      else if PL_SOURCE1 = ES_LOAD_PARAM then long(LOAD_OFFSET_FORM[XT_BYTES[PL_PARAM_TYPE] * 2 + integer(XT_SIGNED[PL_PARAM_TYPE])])
                      else if PL_SOURCE1 = ES_STORE_PARAM then long(STORE_OFFSET_FORM[XT_BYTES[PL_PARAM_TYPE]])
                      else if PL_SOURCE1 = ES_LOAD_INDEXED_ROW then long(LOAD_INDEXED_FORM[XT_BYTES[PL_TYPE] * 2 + integer(XT_SIGNED[PL_TYPE])])
                      else if PL_SOURCE1 = ES_LOAD_INDEXED_INDEX then long(LOAD_INDEXED_FORM[XT_BYTES[PL_INDEX_ELEMENT] * 2 + integer(XT_SIGNED[PL_INDEX_ELEMENT])])
                      else if PL_SOURCE1 = ES_LOAD_INDEXED_ELEMENT then long(LOAD_INDEXED_FORM[XT_BYTES[PL_ELEMENT] * 2 + integer(XT_SIGNED[PL_ELEMENT])])
                      else if PL_SOURCE1 = ES_STORE_INDEXED_ELEMENT then long(STORE_INDEXED_FORM[XT_BYTES[PL_ELEMENT]])
                      else if PL_SOURCE1 = ES_INSTRUCTION_OP then long(OP_INSTRUCTION_FORM[PL_OP])
                      else if PL_SOURCE1 = ES_SHIFT_OP then long(OP_SHIFT_FORM[PL_OP])
                      else if PL_SOURCE1 = ES_PAIR_FORM then long(if NODE_KIND[PL_CLOCK] = CLK_PRODUCT then FORM_AND_W else FORM_ORR_W)
                      else if PL_SOURCE1 = ES_SIGNED_CONDITION then long(OP_SIGNED_CONDITION[PL_OP])
                      else if PL_SOURCE1 = ES_UNSIGNED_CONDITION then long(OP_UNSIGNED_CONDITION[PL_OP])
                      else if PL_SOURCE1 = ES_LOOP_START then long(GLOBAL_LABEL_COUNT + 2 * PL_P)
                      else if PL_SOURCE1 = ES_LOOP_END then long(GLOBAL_LABEL_COUNT + 2 * PL_P + 1)
                      else if PL_SOURCE1 = ES_LOCAL0 then long(PL_LOCAL + 0)
                      else if PL_SOURCE1 = ES_LOCAL1 then long(PL_LOCAL + 1)
                      else if PL_SOURCE1 = ES_LOCAL2 then long(PL_LOCAL + 2)
                      else if PL_SOURCE1 = ES_LOCAL3 then long(PL_LOCAL + 3)
                      else if PL_SOURCE1 = ES_LOCAL4 then long(PL_LOCAL + 4)
                      else if PL_SOURCE1 = ES_PUT_OUTPUT then long(if XT_KIND[PL_TYPE] = TK_EVENT or XT_KIND[PL_TYPE] = TK_BOOLEAN then GL_PUT_BOOL else if XT_SIGNED[PL_TYPE] then GL_PUT_INT else GL_PUT_UINT)
                      else if PL_SOURCE1 = ES_MALFORMED then long(GL_MALFORMED)
                      else if PL_SOURCE1 = ES_RESERVE_FAILED then long(GL_RESERVE_FAILED)
                      else if PL_SOURCE1 = ES_READ_VALUE then long(GL_READ_VALUE)
                      else if PL_SOURCE1 = ES_PUT_INT then long(GL_PUT_INT)
                      else if PL_SOURCE1 = ES_PUT_UINT then long(GL_PUT_UINT)
                      else if PL_SOURCE1 = ES_PUT_BOOL then long(GL_PUT_BOOL)
                      else if PL_SOURCE1 = ES_STEP then long(GL_STEP)
                      else if PL_SOURCE1 = ES_WAIT then long(GL_WAIT)
                      else if PL_SOURCE1 = ES_COMPLETE then long(GL_COMPLETE)
                      else if PL_SOURCE1 = ES_ROOT_IRQ then long(PL_ROOT_IRQ)
                      else if PL_SOURCE1 = ES_BINARY_LO then long(THUMB_BINARY_LO[PL_OP])
                      else if PL_SOURCE1 = ES_BINARY_HI then long(THUMB_BINARY_HI[PL_OP])
                      else if PL_SOURCE1 = ES_PAIR_FORM_THUMB then long(if NODE_KIND[PL_CLOCK] = CLK_PRODUCT then FORM_AND_T else FORM_ORR_T)
                      else if PL_SOURCE1 = ES_SIGNED_CONDITION_THUMB then long(THUMB_SIGNED_SKIP[PL_OP])
                      else if PL_SOURCE1 = ES_UNSIGNED_CONDITION_THUMB then long(THUMB_UNSIGNED_SKIP[PL_OP])
                      else if PL_SOURCE1 = ES_ELEMENT_ROW then long(PL_ELEMENT)
                      else if PL_SOURCE1 = ES_INDEX_ELEMENT then long(PL_INDEX_ELEMENT)
                      else if PL_SOURCE1 = ES_DIVIDE then long(GL_DIVIDE)
                      else long(GL_READ_DONE)
        | PL_ACTIVE := if PL_WHEN = EP_ALWAYS then (true)
                      else if PL_WHEN = EP_FLAG then (PL_FLAG)
                      else if PL_WHEN = EP_HAS_ARG1 then (PL_C1 >= 0)
                      else if PL_WHEN = EP_HAS_ARG2 then (PL_C2 >= 0)
                      else if PL_WHEN = EP_HAS_ARG3 then (PL_C3 >= 0)
                      else if PL_WHEN = EP_HAS_ARG4 then (PL_C4 >= 0)
                      else if PL_WHEN = EP_HAS_ARG5 then (PL_C5 >= 0)
                      else if PL_WHEN = EP_HAS_ARG6 then (PL_C6 >= 0)
                      else if PL_WHEN = EP_RIGHT_LOADS then (PL_RIGHT >= 0 and PL_OP /= OP_WHEN and PL_OP /= OP_DEFAULT)
                      else if PL_WHEN = EP_COUNTED then (PL_COUNT_ROW >= 0)
                      else if PL_WHEN = EP_UNCOUNTED then (PL_COUNT_ROW < 0)
                      else if PL_WHEN = EP_BOUNDED then (XT_KIND[PL_TYPE] = TK_BOOLEAN or XT_KIND[PL_TYPE] = TK_ENUM)
                      else if PL_WHEN = EP_MUL then (PL_OP = OP_MUL)
                      else if PL_WHEN = EP_NOT_MUL then (PL_OP /= OP_MUL)
                      else if PL_WHEN = EP_COMPARE_EQUAL then (PL_OP = OP_EQ or PL_OP = OP_NE)
                      else if PL_WHEN = EP_COMPARE_DIRECT then (PL_OP = OP_LT or PL_OP = OP_GE)
                      else if PL_WHEN = EP_COMPARE_SWAPPED then (PL_OP = OP_GT or PL_OP = OP_LE)
                      else if PL_WHEN = EP_SHIFT_LEFT then (PL_OP = OP_SHL)
                      else if PL_WHEN = EP_SHIFT_RIGHT then (PL_OP = OP_SHR)
                      else (SK_KEY[PL_LEFT_ROW] /= PL_OWNER_KEY)
        | PL_FORM_SPEC := STEP_FORM[PL_STEP]
        | PL_A0_SPEC := STEP_A0[PL_STEP]
        | PL_A1_SPEC := STEP_A1[PL_STEP]
        | PL_A2_SPEC := STEP_A2[PL_STEP]
        | PL_A3_SPEC := STEP_A3[PL_STEP]
        | PL_TARGET_SPEC := STEP_TARGET[PL_STEP]
        | PL_FORM := if PL_FORM_SPEC < STEP_SOURCE_BASE then PL_FORM_SPEC
                     else integer(if PL_FORM_SPEC = STEP_SOURCE_BASE then PL_V0 else PL_V1)
        | PL_A0 := if PL_A0_SPEC < STEP_SOURCE_BASE then PL_A0_SPEC else integer(if PL_A0_SPEC = STEP_SOURCE_BASE then PL_V0 else PL_V1)
        | PL_A1 := if PL_A1_SPEC < STEP_SOURCE_BASE then long(PL_A1_SPEC) else if PL_A1_SPEC = STEP_SOURCE_BASE then PL_V0 else PL_V1
        | PL_A2 := if PL_A2_SPEC < STEP_SOURCE_BASE then long(PL_A2_SPEC) else if PL_A2_SPEC = STEP_SOURCE_BASE then PL_V0 else PL_V1
        | PL_A3 := if PL_A3_SPEC < STEP_SOURCE_BASE then PL_A3_SPEC else integer(if PL_A3_SPEC = STEP_SOURCE_BASE then PL_V0 else PL_V1)
        | PL_TARGET := if PL_TARGET_SPEC < STEP_SOURCE_BASE then PL_TARGET_SPEC
                       else integer(if PL_TARGET_SPEC = STEP_SOURCE_BASE then PL_V0 else PL_V1)
        | PL_OPERAND := PL_KIND = MK_OPERAND
        | PL_OPERAND_ROW := if PL_A1 >= long(0) and PL_A1 < long(ROW_COUNT) then integer(PL_A1) else 0
        | PL_CONSTANT := PL_OPERAND and ROWS_OP[PL_OPERAND_ROW] = OP_CONST
        | PL_MICRO := if PL_OPERAND then (if PL_CONSTANT then MK_LI else MK_LOAD) else PL_KIND
        | PL_VALUE := if PL_CONSTANT then ROWS_VALUE[PL_OPERAND_ROW] else if PL_KIND = MK_LI then PL_A1 else PL_A2
        | PL_TYPE_OR_KEY := if PL_OPERAND then ROWS_TYPE[PL_OPERAND_ROW] else integer(PL_A1)
        | PL_TARGET_KIND := if PL_OPERAND then TG_SIG else STEP_TARGET_KIND[PL_STEP]
        | PL_TARGET_ID := if PL_OPERAND then PL_OPERAND_ROW else if PL_TARGET_KIND = TG_NONE then 0 else PL_TARGET
        | PL_BITS := ulong(PL_VALUE)
        | PL_CHUNKS := integer((PL_BITS shr 16) modulo ulong(65536) /= ulong(0)) + integer((PL_BITS shr 32) modulo ulong(65536) /= ulong(0))
                       + integer(PL_BITS shr 48 /= ulong(0))
        | PL_PAIR := PL_FORM = 1
        | PL_EXTENDS := PL_PAIR and XT_BYTES[if PL_TYPE_OR_KEY >= 0 and PL_TYPE_OR_KEY < XT_TOTAL then PL_TYPE_OR_KEY else 0] < 8
        | PL_INDEXED := PL_A3 >= 0
        | PL_THUMB_INSTRUCTIONS := if PL_MICRO = MK_PLACE then 0 else if PL_MICRO = MK_EMIT then 1
                                   else if PL_MICRO = MK_LI then
                                     1 + integer((PL_BITS shr 16) modulo ulong(65536) /= ulong(0))
                                     + (if PL_PAIR then 1 + integer(PL_BITS shr 48 /= ulong(0)) else 0)
                                   else if PL_MICRO = MK_LOAD then 3 + integer(PL_EXTENDS)
                                   else if PL_MICRO = MK_STORE then 3
                                   else if PL_MICRO = MK_ADDRESS then (if PL_TYPE_OR_KEY < 0 then 2 else 3)
                                   else if PL_MICRO = MK_LOAD_AT then integer(PL_INDEXED) + 1 + integer(PL_EXTENDS)
                                   else integer(PL_INDEXED) + 1
        | PL_INSTRUCTIONS := if PLATFORM = PLATFORM_MPS2 then PL_THUMB_INSTRUCTIONS
                             else if PL_MICRO = MK_PLACE then 0 else if PL_MICRO = MK_EMIT then 1
                             else if PL_MICRO = MK_LI then 1 + PL_CHUNKS else 2
        | PL_SLOT := if PL_ACTIVE and MO_COUNT[?] < MICRO_CAP then MO_COUNT[?] else -1
        | MO_KIND := MO_KIND[?] next PL_SLOT : PL_MICRO
        | MO_FORM := MO_FORM[?] next PL_SLOT : PL_FORM
        | MO_A0 := MO_A0[?] next PL_SLOT : PL_A0
        | MO_A1 := MO_A1[?] next PL_SLOT : PL_TYPE_OR_KEY
        | MO_A2 := MO_A2[?] next PL_SLOT : PL_VALUE
        | MO_A3 := MO_A3[?] next PL_SLOT : PL_A3
        | MO_TK := MO_TK[?] next PL_SLOT : PL_TARGET_KIND
        | MO_TID := MO_TID[?] next PL_SLOT : PL_TARGET_ID
        | MO_COUNT := MO_COUNT[?] + integer(PL_ACTIVE)
        | MO_CODE_TOTAL := MO_CODE_TOTAL[?] + long(if PL_ACTIVE then PL_INSTRUCTIONS else 0)
        | MO_PLACE_TOTAL := MO_PLACE_TOTAL[?] + long(integer(PL_ACTIVE and PL_MICRO = MK_PLACE))
        |)
     with (| PL_NEXT_U := 0 | PL_NEXT_K := 0 | MO_COUNT := 0 | MO_CODE_TOTAL := long(0) | MO_PLACE_TOTAL := long(0) |)
     end
   | MICRO_READY := PLAN_RUN and MO_COUNT <= MICRO_CAP
   | EXPAND_TOTAL := MO_CODE_TOTAL + MO_PLACE_TOTAL
   | CODE_FITS := MO_CODE_TOTAL <= long(CODE_CAP) and EXPAND_TOTAL < long(PARSE_CAP)
   | CODE_LABELS_FIT := UNIT_LABEL_TOTAL <= CODE_LABEL_CAP
   | CODE_RUN := MICRO_READY and CODE_FITS and CODE_LABELS_FIT
   | EX_INDEX := 0 .. (if CODE_RUN then integer(EXPAND_TOTAL) - 1 else -1)
   | iterate EX_INDEX of
       (| EX_M := EX_NEXT_M[?]
        | EX_S := EX_NEXT_S[?]
        | EX_KIND := MO_KIND[EX_M]
        | EX_A0 := MO_A0[EX_M]
        | EX_A1 := MO_A1[EX_M]
        | EX_A2 := MO_A2[EX_M]
        | EX_BITS := ulong(EX_A2)
        | EX_NZ1 := (EX_BITS shr 16) modulo ulong(65536) /= ulong(0)
        | EX_NZ2 := (EX_BITS shr 32) modulo ulong(65536) /= ulong(0)
        | EX_NZ3 := EX_BITS shr 48 /= ulong(0)
        | EX_PLACES := EX_KIND = MK_PLACE
        | EX_TYPE := if EX_A1 >= 0 and EX_A1 < XT_TOTAL then EX_A1 else 0
        | EX_PAIR := MO_FORM[EX_M] = 1
        | EX_BYTES := XT_BYTES[EX_TYPE]
        | EX_SIGNED := XT_SIGNED[EX_TYPE]
        | EX_EXTENDS := EX_PAIR and EX_BYTES < 8
        | EX_INDEX_REGISTER := MO_A3[EX_M]
        | EX_INDEXED := EX_INDEX_REGISTER >= 0
        | EX_AT := EX_KIND = MK_LOAD_AT or EX_KIND = MK_STORE_AT
        | EX_TABLE_KEY := EX_KIND = MK_ADDRESS and EX_A1 < 0
        | EX_THUMB_COUNT := if EX_PLACES then 0 else if EX_KIND = MK_EMIT then 1
                            else if EX_KIND = MK_LI then 1 + integer(EX_NZ1) + (if EX_PAIR then 1 + integer(EX_NZ3) else 0)
                            else if EX_KIND = MK_LOAD then 3 + integer(EX_EXTENDS)
                            else if EX_KIND = MK_STORE then 3
                            else if EX_KIND = MK_ADDRESS then (if EX_TABLE_KEY then 2 else 3)
                            else if EX_KIND = MK_LOAD_AT then integer(EX_INDEXED) + 1 + integer(EX_EXTENDS)
                            else integer(EX_INDEXED) + 1
        | EX_COUNT := if PLATFORM = PLATFORM_MPS2 then EX_THUMB_COUNT
                      else if EX_PLACES then 0 else if EX_KIND = MK_EMIT then 1
                      else if EX_KIND = MK_LI then 1 + integer(EX_NZ1) + integer(EX_NZ2) + integer(EX_NZ3) else 2
        | EX_LAST := EX_PLACES or EX_S + 1 >= EX_COUNT
        | EX_NEXT_M := if EX_LAST then EX_M + 1 else EX_M
        | EX_NEXT_S := if EX_LAST then 0 else EX_S + 1
        | EX_THUMB_CHUNK := if EX_S = 0 then 0 else if EX_S = 1 then (if EX_NZ1 then 1 else 2)
                            else if EX_S = 2 then (if EX_NZ1 then 2 else 3) else 3
        | EX_CHUNK := if PLATFORM = PLATFORM_MPS2 then EX_THUMB_CHUNK
                      else if EX_S = 0 then 0 else if EX_NZ1 and EX_S = 1 then 1 else if EX_NZ2 and EX_S = 1 + integer(EX_NZ1) then 2 else 3
        | EX_CHUNK_VALUE := long((EX_BITS shr (16 * EX_CHUNK)) modulo ulong(65536))
        | EX_ROLE := if EX_AT and not EX_INDEXED then EX_S + 1 else EX_S
        | EX_DUAL := EX_PAIR and EX_BYTES = 8
        | EX_LOAD_FORM := if EX_BYTES = 8 and not EX_PAIR then FORM_LDR_T else THUMB_LOAD_FORM[EX_BYTES * 2 + integer(EX_SIGNED)]
        | EX_STORE_FORM := if EX_BYTES = 8 and not EX_PAIR then FORM_STR_T else THUMB_STORE_FORM[EX_BYTES]
        | EX_EXTEND_STEP := EX_AT and EX_ROLE = 2 or EX_KIND = MK_LOAD and EX_S = 3
        | EX_ABSOLUTE_STEP := not EX_AT and EX_KIND /= MK_EMIT and EX_KIND /= MK_LI and EX_S <= 1
        | EX_MEMORY_STEP := EX_AT and EX_ROLE = 1 or not EX_AT and EX_KIND /= MK_EMIT and EX_KIND /= MK_LI and EX_S = 2
        | EX_ADDRESS_REGISTER := if EX_KIND = MK_STORE then 14 else EX_A0
        | EX_THUMB_FORM := if EX_KIND = MK_EMIT then MO_FORM[EX_M]
                           else if EX_KIND = MK_LI then (if EX_THUMB_CHUNK modulo 2 = 0 then FORM_MOVW_T else FORM_MOVT_T)
                           else if EX_AT and EX_ROLE = 0 then FORM_ADD_SHIFT_T
                           else if EX_EXTEND_STEP then (if EX_SIGNED then FORM_ASR_IMM_T else FORM_LSR_IMM_T)
                           else if EX_ABSOLUTE_STEP then (if EX_S = 0 then FORM_MOVW_ABS_T else FORM_MOVT_ABS_T)
                           else if EX_KIND = MK_LOAD or EX_KIND = MK_LOAD_AT then EX_LOAD_FORM
                           else if EX_KIND = MK_STORE or EX_KIND = MK_STORE_AT then EX_STORE_FORM else FORM_LDR_T
        | EX_THUMB_OP0 := if EX_KIND = MK_EMIT then EX_A0 else if EX_KIND = MK_LI then EX_A0 + integer(EX_THUMB_CHUNK >= 2)
                          else if EX_AT and EX_ROLE = 0 then 14 else if EX_EXTEND_STEP then EX_A0 + 1
                          else if EX_ABSOLUTE_STEP then EX_ADDRESS_REGISTER else EX_A0
        | EX_THUMB_OP1 := if EX_KIND = MK_EMIT then EX_A1 else if EX_KIND = MK_LI or EX_ABSOLUTE_STEP then 0
                          else if EX_AT and EX_ROLE = 0 then integer(EX_A2) else if EX_EXTEND_STEP then EX_A0
                          else if EX_AT then (if EX_INDEXED then 14 else integer(EX_A2)) else EX_ADDRESS_REGISTER
        | EX_THUMB_OP2 := if EX_KIND = MK_EMIT then EX_A2 else if EX_KIND = MK_LI then EX_CHUNK_VALUE
                          else if EX_AT and EX_ROLE = 0 then long(EX_INDEX_REGISTER) else long(0)
        | EX_THUMB_OP3 := if EX_KIND = MK_EMIT then MO_A3[EX_M]
                          else if EX_AT and EX_ROLE = 0 then integer(EX_BYTES >= 2) + integer(EX_BYTES >= 4) + integer(EX_BYTES >= 8)
                          else if EX_MEMORY_STEP and EX_DUAL then EX_A0 + 1 else 0
        | EX_THUMB_TK := if EX_KIND = MK_EMIT then MO_TK[EX_M] else if not EX_ABSOLUTE_STEP then TG_NONE
                         else if EX_KIND = MK_ADDRESS then (if EX_TABLE_KEY then TG_TABLE else TG_WINDOW) else MO_TK[EX_M]
        | EX_THUMB_TID := if EX_KIND = MK_EMIT then MO_TID[EX_M] else if not EX_ABSOLUTE_STEP then 0
                          else if EX_KIND = MK_ADDRESS then (if EX_TABLE_KEY then -1 - EX_A1 else EX_A1) else MO_TID[EX_M]
        | EX_FORM := if PLATFORM = PLATFORM_MPS2 then EX_THUMB_FORM
                     else if EX_KIND = MK_EMIT then MO_FORM[EX_M]
                     else if EX_KIND = MK_LI then (if EX_S = 0 then FORM_MOVZ_X else FORM_MOVK_X)
                     else if EX_S = 0 then FORM_ADRP
                     else if EX_KIND = MK_LOAD then LOAD_OFFSET_FORM[XT_BYTES[EX_TYPE] * 2 + integer(XT_SIGNED[EX_TYPE])]
                     else if EX_KIND = MK_STORE then STORE_OFFSET_FORM[XT_BYTES[EX_TYPE]]
                     else if EX_TABLE_KEY then FORM_ADD_X_IMM else FORM_LDR_X
        | EX_OP0 := if PLATFORM = PLATFORM_MPS2 then EX_THUMB_OP0 else if EX_KIND = MK_EMIT or EX_KIND = MK_LI or EX_S = 1 or EX_TABLE_KEY then EX_A0 else 8
        | EX_OP1 := if PLATFORM = PLATFORM_MPS2 then EX_THUMB_OP1 else if EX_KIND = MK_EMIT then EX_A1 else if EX_KIND = MK_LI or EX_S = 0 then 0 else if EX_TABLE_KEY then EX_A0 else 8
        | EX_OP2 := if PLATFORM = PLATFORM_MPS2 then EX_THUMB_OP2 else if EX_KIND = MK_EMIT then EX_A2 else if EX_KIND = MK_LI then EX_CHUNK_VALUE else long(0)
        | EX_OP3 := if PLATFORM = PLATFORM_MPS2 then EX_THUMB_OP3 else if EX_KIND = MK_EMIT then MO_A3[EX_M] else if EX_KIND = MK_LI then EX_CHUNK else 0
        | EX_TK := if PLATFORM = PLATFORM_MPS2 then EX_THUMB_TK else if EX_KIND = MK_ADDRESS then (if EX_TABLE_KEY then TG_TABLE else TG_WINDOW)
                   else if EX_KIND = MK_LI then TG_NONE else MO_TK[EX_M]
        | EX_TID := if PLATFORM = PLATFORM_MPS2 then EX_THUMB_TID else if EX_KIND = MK_ADDRESS then (if EX_TABLE_KEY then -1 - EX_A1 else EX_A1)
                    else if EX_KIND = MK_LI then 0 else MO_TID[EX_M]
        | EX_SLOT := if EX_PLACES then -1 else EX_CODE_COUNT[?]
        | CODE_FORM := CODE_FORM[?] next EX_SLOT : EX_FORM
        | CODE_OP0 := CODE_OP0[?] next EX_SLOT : EX_OP0
        | CODE_OP1 := CODE_OP1[?] next EX_SLOT : EX_OP1
        | CODE_OP2 := CODE_OP2[?] next EX_SLOT : EX_OP2
        | CODE_OP3 := CODE_OP3[?] next EX_SLOT : EX_OP3
        | CODE_TK := CODE_TK[?] next EX_SLOT : EX_TK
        | CODE_TID := CODE_TID[?] next EX_SLOT : EX_TID
        | LABEL_AT1 := LABEL_AT1[?] next (if EX_PLACES then EX_A0 else -1) : EX_CODE_COUNT[?] + 1
        | EX_CODE_COUNT := EX_CODE_COUNT[?] + integer(not EX_PLACES)
        |)
     with (| EX_NEXT_M := 0 | EX_NEXT_S := 0 | EX_CODE_COUNT := 0 |)
     end
   | DATA_FITS := DATA_END <= long(DATA_CAP)
   | DATA_RUN := CODE_RUN and DATA_FITS
   | DB_INDEX := 0 .. (if DATA_RUN then integer(DATA_END) - 1 else -1)
   | iterate DB_INDEX of
       (| DB_POSITION := long(DB_INDEX)
        | DB_NEXT_TABLE := DB_CURSOR[?] + 1
        | DB_CURSOR := if DB_NEXT_TABLE < TABLE_LIVE_COUNT and DB_POSITION >= TABLE_OFFSET[TABLE_LIVE[DB_NEXT_TABLE]] then DB_NEXT_TABLE
                       else DB_CURSOR[?]
        | DB_TABLE := TABLE_LIVE[if DB_CURSOR >= 0 then DB_CURSOR else 0]
        | DB_EB := long(if TABLE_EB[DB_TABLE] > 0 then TABLE_EB[DB_TABLE] else 1)
        | DB_REL := DB_POSITION - TABLE_OFFSET[DB_TABLE]
        | DB_IN_TABLE := DB_CURSOR >= 0 and DB_REL >= long(0) and DB_REL < TABLE_BYTES[DB_TABLE]
        | DB_ELEMENT := if DB_IN_TABLE then integer(DB_REL / DB_EB) else 0
        | DB_TABLE_SHIFT := integer(DB_REL modulo DB_EB) * 8
        | DB_OLD := DB_IN_TABLE and DB_TABLE < TABLE_COUNT
        | DB_AT := if DB_OLD then TABLE_START[DB_TABLE] + DB_ELEMENT else 0
        | DB_VALUE := if DB_TABLE >= TABLE_COUNT then long(DB_ELEMENT)
                      else if TABLE_FROM_STRING[DB_TABLE] then long(STRING_TEXT[DB_AT]) else POOL_VALUE[DB_AT]
        | DB_IN_SIG := DB_POSITION >= SIG_BASE and DB_POSITION < MEM_BASE
        | DB_IN_MEM := DB_POSITION >= MEM_BASE and DB_POSITION < CLK_BASE
        | DB_SIG := if DB_IN_SIG then DB_POSITION - SIG_BASE else long(1)
        | DB_MEM := if DB_IN_MEM then DB_POSITION - MEM_BASE else long(0)
        | DB_DELAY_VALUE := ROWS_VALUE[DELAY_LIST[integer(DB_MEM / long(8))]]
        | DB_TEXT := if DB_POSITION < MAL_BASE then 0 else if DB_POSITION < RES_BASE then integer(DB_POSITION - MAL_BASE)
                     else integer(DB_POSITION - RES_BASE) + MALFORMED_TEXT_LENGTH
        | DATA_BYTE := DATA_BYTE[?] next DB_INDEX :
            (if DB_POSITION < WIN_BASE then
               (if DB_IN_TABLE then ubyte((ulong(DB_VALUE) shr DB_TABLE_SHIFT) modulo ulong(256)) else ubyte(0))
             else if DB_IN_SIG then ubyte(integer(DB_SIG modulo long(8) = long(0) and SIG_ONE[integer(DB_SIG / long(8))]))
             else if DB_IN_MEM then ubyte((ulong(DB_DELAY_VALUE) shr (integer(DB_MEM modulo long(8)) * 8)) modulo ulong(256))
             else if DB_POSITION < MAL_BASE then ubyte(0)
             else if DB_TEXT < 58 then EMIT_TEXT[DB_TEXT] else ubyte(10))
        |)
     with DB_CURSOR := -1
     end
   | EMIT_READY := DATA_RUN
   | CODE_COUNT := EX_CODE_COUNT
   | HEADER_BYTES := if PLATFORM = PLATFORM_MPS2 then MPS2_HEADER_BYTES else if PLATFORM = PLATFORM_VIRT then VIRT_TEXT_OFFSET
                     else TEXT_OFFSET
   | UNLOADED_BYTES := if PLATFORM = PLATFORM_MPS2 then MPS2_UNLOADED else 0
   | TEXT_BYTES := UNLOADED_BYTES
                   + (HEADER_BYTES - UNLOADED_BYTES + 4 * CODE_COUNT + SEGMENT_BYTES - 1) / SEGMENT_BYTES * SEGMENT_BYTES
   | TAIL_BYTES := (EW_PAGES_TOTAL - long(EMIT_WINDOWS)) * long(16384)
                   + long(if PLATFORM = PLATFORM_MPS2 then MPS2_STACK_BYTES else VIRT_STACK_BYTES)
   | MEMORY_BYTES := long(SIGNED_BYTES) + TAIL_BYTES
   | DATA_BYTES := integer((DATA_END + long(SEGMENT_BYTES - 1)) / long(SEGMENT_BYTES)) * SEGMENT_BYTES
   | SIGNED_BYTES := TEXT_BYTES + DATA_BYTES
   | PAGES := SIGNED_BYTES / SEGMENT_BYTES
   | DIRECTORY_BYTES := CODE_DIRECTORY_HEADER_BYTES + 1 + HASH_BYTES * PAGES
   | SIGNATURE_BYTES := SUPERBLOB_HEADER_BYTES + DIRECTORY_BYTES
   | LINKEDIT_BYTES := (SIGNATURE_BYTES + SEGMENT_BYTES - 1) / SEGMENT_BYTES * SEGMENT_BYTES
   | FILE_BYTES := SIGNED_BYTES + (if PLATFORM = PLATFORM_MACOS then SIGNATURE_BYTES else 0)
   | STAGED_AT := (FILE_BYTES + 7) / 8 * 8
   | IMAGE_TEXT_AT := STAGED_AT + ARG_CAP + 16
   | IMAGE_TOO_BIG := DUMP_PASS = 0 and EMIT_READY and IMAGE_TEXT_AT > NAMES_AT
   | IMAGE_BASE := if PLATFORM = PLATFORM_MPS2 then long(-MPS2_UNLOADED) else if PLATFORM = PLATFORM_VIRT then VIRT_BASE
                   else MACHO_BASE
   | TEXT_BASE := IMAGE_BASE + long(HEADER_BYTES)
   | DATA_BASE := IMAGE_BASE + long(TEXT_BYTES)
   | EN_INDEX := 0 .. (if EMIT_READY then CODE_COUNT - 1 else -1)
   | iterate EN_INDEX of
       (| EN_TK := CODE_TK[EN_INDEX]
        | EN_TID := CODE_TID[EN_INDEX]
        | EN_LABEL_AT := LABEL_AT1[if EN_TK = TG_LABEL and EN_TID >= 0 then EN_TID else 0]
        | EN_SECTION := if EN_TK = TG_NONE or EN_TK = TG_LABEL and EN_LABEL_AT = 0 then -1 else if EN_TK = TG_LABEL then 0 else 1
        | EN_TID_ROW := if EN_TID >= 0 and EN_TID < ROW_COUNT then EN_TID else 0
        | EN_OFFSET := if EN_SECTION < 0 then long(0) else if EN_TK = TG_LABEL then long(EN_LABEL_AT - 1)
                              else if EN_TK = TG_TABLE then TABLE_OFFSET[if EN_TID >= 0 and EN_TID < EMIT_TABLE_COUNT then EN_TID else 0]
                              else if EN_TK = TG_WINDOW then WIN_BASE + long(8) * long(EN_TID)
                              else if EN_TK = TG_SIG then SIG_BASE + long(8) * long(EN_TID)
                              else if EN_TK = TG_MEM then MEM_BASE + long(8) * long(DELAY_INDEX[EN_TID_ROW])
                              else if EN_TK = TG_CLK then CLK_BASE + long(4) * long(CLK_INDEX[if EN_TID >= 0 and EN_TID < CLOCK_TOTAL then EN_TID else 0])
                              else if EN_TK = TG_IN then IN_BASE else if EN_TK = TG_OUT then OUT_BASE
                              else if EN_TK = TG_TAIL then long(DATA_BYTES) + (PAGES_BEFORE[EN_TID] - long(EN_TID)) * long(16384)
                              else if EN_TK = TG_STACK then long(DATA_BYTES) + TAIL_BYTES
                              else if EN_TK = TG_MALFORMED_TEXT then MAL_BASE else RES_BASE
        | CODE_SECTION := CODE_SECTION[?] next EN_INDEX : EN_SECTION
        | CODE_TARGET := CODE_TARGET[?] next EN_INDEX : EN_OFFSET
        | EN_FORM := CODE_FORM[EN_INDEX]
        | EN_KIND := FORM_KIND[EN_FORM]
        | EN_PC := TEXT_BASE + long(4) * long(EN_INDEX)
        | EN_ADDRESS := if EN_SECTION = 0 then TEXT_BASE + long(4) * EN_OFFSET else DATA_BASE + EN_OFFSET
        | EN_OP0 := long(CODE_OP0[EN_INDEX])
        | EN_OP1 := long(CODE_OP1[EN_INDEX])
        | EN_OP2 := if EN_SECTION < 0 then CODE_OP2[EN_INDEX]
                    else if EN_KIND = FIELD_PCREL then EN_ADDRESS - EN_PC
                    else if EN_KIND = FIELD_PAGE then EN_ADDRESS / long(4096) * long(4096) - EN_PC / long(4096) * long(4096)
                    else if EN_KIND = FIELD_PAGEOFF then EN_ADDRESS modulo long(4096)
                    else if EN_KIND = FIELD_THUMB_PCREL then EN_ADDRESS - EN_PC - long(4)
                    else if EN_KIND = FIELD_ABS_LO then EN_ADDRESS modulo long(65536)
                    else if EN_KIND = FIELD_ABS_HI then EN_ADDRESS / long(65536) else CODE_OP2[EN_INDEX]
        | EN_OP3 := long(CODE_OP3[EN_INDEX])
        | EN_F := FORM_FIELD_SLOTS * EN_FORM
        | EN_S0 := FORM_FIELD_SLOT[EN_F + 0]
        | EN_L0 := FORM_FIELD_LOW[EN_F + 0]
        | EN_W0 := FORM_FIELD_WIDTH[EN_F + 0]
        | EN_A0 := FORM_FIELD_AT[EN_F + 0]
        | EN_V0 := ulong(if EN_S0 = 0 then EN_OP0 else if EN_S0 = 1 then EN_OP1 else if EN_S0 = 2 then EN_OP2 else EN_OP3)
        | EN_B0 := (EN_V0 shr EN_L0) modulo (ulong(1) shl EN_W0)
        | EN_S1 := FORM_FIELD_SLOT[EN_F + 1]
        | EN_L1 := FORM_FIELD_LOW[EN_F + 1]
        | EN_W1 := FORM_FIELD_WIDTH[EN_F + 1]
        | EN_A1 := FORM_FIELD_AT[EN_F + 1]
        | EN_V1 := ulong(if EN_S1 = 0 then EN_OP0 else if EN_S1 = 1 then EN_OP1 else if EN_S1 = 2 then EN_OP2 else EN_OP3)
        | EN_B1 := (EN_V1 shr EN_L1) modulo (ulong(1) shl EN_W1)
        | EN_S2 := FORM_FIELD_SLOT[EN_F + 2]
        | EN_L2 := FORM_FIELD_LOW[EN_F + 2]
        | EN_W2 := FORM_FIELD_WIDTH[EN_F + 2]
        | EN_A2 := FORM_FIELD_AT[EN_F + 2]
        | EN_V2 := ulong(if EN_S2 = 0 then EN_OP0 else if EN_S2 = 1 then EN_OP1 else if EN_S2 = 2 then EN_OP2 else EN_OP3)
        | EN_B2 := (EN_V2 shr EN_L2) modulo (ulong(1) shl EN_W2)
        | EN_S3 := FORM_FIELD_SLOT[EN_F + 3]
        | EN_L3 := FORM_FIELD_LOW[EN_F + 3]
        | EN_W3 := FORM_FIELD_WIDTH[EN_F + 3]
        | EN_A3 := FORM_FIELD_AT[EN_F + 3]
        | EN_V3 := ulong(if EN_S3 = 0 then EN_OP0 else if EN_S3 = 1 then EN_OP1 else if EN_S3 = 2 then EN_OP2 else EN_OP3)
        | EN_B3 := (EN_V3 shr EN_L3) modulo (ulong(1) shl EN_W3)
        | EN_S4 := FORM_FIELD_SLOT[EN_F + 4]
        | EN_L4 := FORM_FIELD_LOW[EN_F + 4]
        | EN_W4 := FORM_FIELD_WIDTH[EN_F + 4]
        | EN_A4 := FORM_FIELD_AT[EN_F + 4]
        | EN_V4 := ulong(if EN_S4 = 0 then EN_OP0 else if EN_S4 = 1 then EN_OP1 else if EN_S4 = 2 then EN_OP2 else EN_OP3)
        | EN_B4 := (EN_V4 shr EN_L4) modulo (ulong(1) shl EN_W4)
        | EN_WORD := ulong(FORM_BASE[EN_FORM]) or (EN_B0 shl EN_A0) or (EN_B1 shl EN_A1) or (EN_B2 shl EN_A2) or (EN_B3 shl EN_A3)
                     or (EN_B4 shl EN_A4)
        | EN_R0 := (if EN_S0 = 0 then EN_B0 shl EN_L0 else ulong(0)) or (if EN_S1 = 0 then EN_B1 shl EN_L1 else ulong(0)) or (if EN_S2 = 0 then EN_B2 shl EN_L2 else ulong(0)) or (if EN_S3 = 0 then EN_B3 shl EN_L3 else ulong(0))
                  or (if EN_S4 = 0 then EN_B4 shl EN_L4 else ulong(0))
        | EN_R1 := (if EN_S0 = 1 then EN_B0 shl EN_L0 else ulong(0)) or (if EN_S1 = 1 then EN_B1 shl EN_L1 else ulong(0)) or (if EN_S2 = 1 then EN_B2 shl EN_L2 else ulong(0)) or (if EN_S3 = 1 then EN_B3 shl EN_L3 else ulong(0))
                  or (if EN_S4 = 1 then EN_B4 shl EN_L4 else ulong(0))
        | EN_R2 := (if EN_S0 = 2 then EN_B0 shl EN_L0 else ulong(0)) or (if EN_S1 = 2 then EN_B1 shl EN_L1 else ulong(0)) or (if EN_S2 = 2 then EN_B2 shl EN_L2 else ulong(0)) or (if EN_S3 = 2 then EN_B3 shl EN_L3 else ulong(0))
                  or (if EN_S4 = 2 then EN_B4 shl EN_L4 else ulong(0))
        | EN_R3 := (if EN_S0 = 3 then EN_B0 shl EN_L0 else ulong(0)) or (if EN_S1 = 3 then EN_B1 shl EN_L1 else ulong(0)) or (if EN_S2 = 3 then EN_B2 shl EN_L2 else ulong(0)) or (if EN_S3 = 3 then EN_B3 shl EN_L3 else ulong(0))
                  or (if EN_S4 = 3 then EN_B4 shl EN_L4 else ulong(0))
        | EN_TOP2 := FORM_TOP2[EN_FORM]
        | EN_NEGATIVE := FORM_SIGNED[EN_FORM] = 1 and (EN_R2 shr (EN_TOP2 - 1)) modulo ulong(2) = ulong(1)
        | EN_R2_VALUE := long(EN_R2) - (if EN_NEGATIVE then long(ulong(1) shl EN_TOP2) else long(0))
        | EN_FITS := long(EN_R0) = EN_OP0 and long(EN_R1) = EN_OP1 and EN_R2_VALUE = EN_OP2 and long(EN_R3) = EN_OP3
        | EN_FIRST_FAIL := EN_FAIL_AT[?] < 0 and not EN_FITS
        | EN_FAIL_AT := if EN_FIRST_FAIL then EN_INDEX else EN_FAIL_AT[?]
        | EN_FAIL_FORM := if EN_FIRST_FAIL then EN_FORM else EN_FAIL_FORM[?]
        | EN_FAIL_OP0 := if EN_FIRST_FAIL then EN_OP0 else EN_FAIL_OP0[?]
        | EN_FAIL_OP1 := if EN_FIRST_FAIL then EN_OP1 else EN_FAIL_OP1[?]
        | EN_FAIL_OP2 := if EN_FIRST_FAIL then EN_OP2 else EN_FAIL_OP2[?]
        | EN_FAIL_OP3 := if EN_FIRST_FAIL then EN_OP3 else EN_FAIL_OP3[?]
        | CODE_WORD := CODE_WORD[?] next EN_INDEX : uinteger(EN_WORD)
        |)
     with (| EN_FAIL_AT := -1 | EN_FAIL_FORM := 0 | EN_FAIL_OP0 := long(0) | EN_FAIL_OP1 := long(0) | EN_FAIL_OP2 := long(0)
           | EN_FAIL_OP3 := long(0) |)
     end
   | CW_LINES := long(CODE_COLUMN_COUNT) + long(7) * long(CODE_COUNT) + long(2) * long(ITEM_TOTAL) + DATA_END
   | CW_RUN := CODE_DUMP and EMIT_READY and CW_LINES < long(PARSE_CAP)
   | CW_INDEX := 0 .. (if CW_RUN then integer(CW_LINES) - 1 else -1)
   | iterate CW_INDEX of
       (| CW_C := CW_NEXT_C[?]
        | CW_I := CW_NEXT_I[?]
        | CW_COLUMN_LENGTH := if CW_C < 7 then CODE_COUNT else if CW_C < 9 then ITEM_TOTAL else integer(DATA_END)
        | CW_NEXT_C := if CW_I + 1 >= CW_COLUMN_LENGTH then CW_C + 1 else CW_C
        | CW_NEXT_I := if CW_I + 1 >= CW_COLUMN_LENGTH then -1 else CW_I + 1
        | CW_HEADER := CW_I < 0
        | CW_COLUMN := if CW_C < CODE_COLUMN_COUNT then CW_C else 0
        | CW_CODE_ROW := if CW_C < 7 and not CW_HEADER then CW_I else 0
        | CW_SECTION := CODE_SECTION[CW_CODE_ROW]
        | CW_TARGET_OFFSET := CODE_TARGET[CW_CODE_ROW]
        | CW_ITEM := if (CW_C = 7 or CW_C = 8) and not CW_HEADER then CW_I else 0
        | CW_ITEM_WINDOW := CW_ITEM - EMIT_TABLE_COUNT
        | CW_ITEM_SIG := CW_ITEM_WINDOW - EMIT_WINDOWS
        | CW_ITEM_MEM := CW_ITEM_SIG - ROW_COUNT
        | CW_ITEM_CLK := CW_ITEM_MEM - DELAY_COUNT
        | CW_ITEM_TAIL := CW_ITEM_CLK - CLK_COUNT
        | CW_ITEM_OFFSET := if CW_ITEM_WINDOW < 0 then TABLE_OFFSET[if CW_ITEM_WINDOW < 0 then CW_ITEM else 0]
                            else if CW_ITEM_SIG < 0 then WIN_BASE + long(8) * long(CW_ITEM_WINDOW)
                            else if CW_ITEM_MEM < 0 then SIG_BASE + long(8) * long(CW_ITEM_SIG)
                            else if CW_ITEM_CLK < 0 then MEM_BASE + long(8) * long(CW_ITEM_MEM)
                            else if CW_ITEM_TAIL < 0 then CLK_BASE + long(4) * long(CW_ITEM_CLK)
                            else if CW_ITEM_TAIL = 0 then IN_BASE else if CW_ITEM_TAIL = 1 then OUT_BASE
                            else if CW_ITEM_TAIL = 2 and READS_LINE then MAL_BASE else RES_BASE
        | CW_ITEM_ALIGNMENT := if CW_ITEM_CLK < 0 then 8 else if CW_ITEM_TAIL < 0 then 4 else 1
        | CW_VALUE := if CW_C = 0 then long(CODE_FORM[CW_CODE_ROW]) else if CW_C = 1 then long(CODE_OP0[CW_CODE_ROW])
                      else if CW_C = 2 then long(CODE_OP1[CW_CODE_ROW]) else if CW_C = 3 then CODE_OP2[CW_CODE_ROW]
                      else if CW_C = 4 then long(CODE_OP3[CW_CODE_ROW]) else if CW_C = 5 then long(CW_SECTION)
                      else if CW_C = 6 then CW_TARGET_OFFSET else if CW_C = 7 then CW_ITEM_OFFSET
                      else if CW_C = 8 then long(CW_ITEM_ALIGNMENT)
                      else long(DATA_BYTE[if CW_C = 9 and not CW_HEADER then CW_I else 0])
        | CW_NUMBER := if CW_HEADER then long(CW_COLUMN_LENGTH) else CW_VALUE
        | CW_NEGATIVE := CW_NUMBER < long(0)
        | CW_MAGNITUDE := if CW_NEGATIVE then ulong(-CW_NUMBER) else ulong(CW_NUMBER)
        | CW_DIGITS := 1 + integer(CW_MAGNITUDE >= POWERS_OF_TEN[1]) + integer(CW_MAGNITUDE >= POWERS_OF_TEN[2]) + integer(CW_MAGNITUDE >= POWERS_OF_TEN[3]) + integer(CW_MAGNITUDE >= POWERS_OF_TEN[4]) + integer(CW_MAGNITUDE >= POWERS_OF_TEN[5]) + integer(CW_MAGNITUDE >= POWERS_OF_TEN[6]) + integer(CW_MAGNITUDE >= POWERS_OF_TEN[7]) + integer(CW_MAGNITUDE >= POWERS_OF_TEN[8]) + integer(CW_MAGNITUDE >= POWERS_OF_TEN[9]) + integer(CW_MAGNITUDE >= POWERS_OF_TEN[10]) + integer(CW_MAGNITUDE >= POWERS_OF_TEN[11]) + integer(CW_MAGNITUDE >= POWERS_OF_TEN[12]) + integer(CW_MAGNITUDE >= POWERS_OF_TEN[13]) + integer(CW_MAGNITUDE >= POWERS_OF_TEN[14]) + integer(CW_MAGNITUDE >= POWERS_OF_TEN[15]) + integer(CW_MAGNITUDE >= POWERS_OF_TEN[16]) + integer(CW_MAGNITUDE >= POWERS_OF_TEN[17]) + integer(CW_MAGNITUDE >= POWERS_OF_TEN[18]) + integer(CW_MAGNITUDE >= POWERS_OF_TEN[19])
        | CW_D0 := CW_MAGNITUDE / POWERS_OF_TEN[0] modulo ulong(10)
        | CW_D1 := CW_MAGNITUDE / POWERS_OF_TEN[1] modulo ulong(10)
        | CW_D2 := CW_MAGNITUDE / POWERS_OF_TEN[2] modulo ulong(10)
        | CW_D3 := CW_MAGNITUDE / POWERS_OF_TEN[3] modulo ulong(10)
        | CW_D4 := CW_MAGNITUDE / POWERS_OF_TEN[4] modulo ulong(10)
        | CW_D5 := CW_MAGNITUDE / POWERS_OF_TEN[5] modulo ulong(10)
        | CW_D6 := CW_MAGNITUDE / POWERS_OF_TEN[6] modulo ulong(10)
        | CW_D7 := CW_MAGNITUDE / POWERS_OF_TEN[7] modulo ulong(10)
        | CW_D8 := CW_MAGNITUDE / POWERS_OF_TEN[8] modulo ulong(10)
        | CW_D9 := CW_MAGNITUDE / POWERS_OF_TEN[9] modulo ulong(10)
        | CW_D10 := CW_MAGNITUDE / POWERS_OF_TEN[10] modulo ulong(10)
        | CW_D11 := CW_MAGNITUDE / POWERS_OF_TEN[11] modulo ulong(10)
        | CW_D12 := CW_MAGNITUDE / POWERS_OF_TEN[12] modulo ulong(10)
        | CW_D13 := CW_MAGNITUDE / POWERS_OF_TEN[13] modulo ulong(10)
        | CW_D14 := CW_MAGNITUDE / POWERS_OF_TEN[14] modulo ulong(10)
        | CW_D15 := CW_MAGNITUDE / POWERS_OF_TEN[15] modulo ulong(10)
        | CW_D16 := CW_MAGNITUDE / POWERS_OF_TEN[16] modulo ulong(10)
        | CW_D17 := CW_MAGNITUDE / POWERS_OF_TEN[17] modulo ulong(10)
        | CW_D18 := CW_MAGNITUDE / POWERS_OF_TEN[18] modulo ulong(10)
        | CW_D19 := CW_MAGNITUDE / POWERS_OF_TEN[19] modulo ulong(10)
        | CW_S0 := (if CW_DIGITS >= 20 then (CW_D19 + ulong(48)) shl 0 else ulong(0))
                  or (if CW_DIGITS >= 19 then (CW_D18 + ulong(48)) shl 8 else ulong(0))
                  or (if CW_DIGITS >= 18 then (CW_D17 + ulong(48)) shl 16 else ulong(0))
                  or (if CW_DIGITS >= 17 then (CW_D16 + ulong(48)) shl 24 else ulong(0))
                  or (if CW_DIGITS >= 16 then (CW_D15 + ulong(48)) shl 32 else ulong(0))
                  or (if CW_DIGITS >= 15 then (CW_D14 + ulong(48)) shl 40 else ulong(0))
                  or (if CW_DIGITS >= 14 then (CW_D13 + ulong(48)) shl 48 else ulong(0))
                  or (if CW_DIGITS >= 13 then (CW_D12 + ulong(48)) shl 56 else ulong(0))
        | CW_S1 := (if CW_DIGITS >= 12 then (CW_D11 + ulong(48)) shl 0 else ulong(0))
                  or (if CW_DIGITS >= 11 then (CW_D10 + ulong(48)) shl 8 else ulong(0))
                  or (if CW_DIGITS >= 10 then (CW_D9 + ulong(48)) shl 16 else ulong(0))
                  or (if CW_DIGITS >= 9 then (CW_D8 + ulong(48)) shl 24 else ulong(0))
                  or (if CW_DIGITS >= 8 then (CW_D7 + ulong(48)) shl 32 else ulong(0))
                  or (if CW_DIGITS >= 7 then (CW_D6 + ulong(48)) shl 40 else ulong(0))
                  or (if CW_DIGITS >= 6 then (CW_D5 + ulong(48)) shl 48 else ulong(0))
                  or (if CW_DIGITS >= 5 then (CW_D4 + ulong(48)) shl 56 else ulong(0))
        | CW_S2 := (if CW_DIGITS >= 4 then (CW_D3 + ulong(48)) shl 0 else ulong(0))
                  or (if CW_DIGITS >= 3 then (CW_D2 + ulong(48)) shl 8 else ulong(0))
                  or (if CW_DIGITS >= 2 then (CW_D1 + ulong(48)) shl 16 else ulong(0))
                  or (if CW_DIGITS >= 1 then (CW_D0 + ulong(48)) shl 24 else ulong(0))
        | CW_PREFIX := if CW_HEADER then CODE_HEADER_LENGTH[CW_COLUMN] else integer(CW_NEGATIVE)
        | CW_SHIFT_BYTES := 20 - CW_DIGITS - CW_PREFIX + 16
        | CW_SHIFT_WORD := CW_SHIFT_BYTES / 8 - 2
        | CW_SHIFT_BITS := 8 * (CW_SHIFT_BYTES modulo 8)
        | CW_SPILL_BITS := 64 - CW_SHIFT_BITS
        | CW_P0 := if CW_SHIFT_WORD = 0 then CW_S0 else if CW_SHIFT_WORD = 1 then CW_S1 else if CW_SHIFT_WORD = 2 then CW_S2 else ulong(0)
        | CW_P1 := if CW_SHIFT_WORD = -1 then CW_S0 else if CW_SHIFT_WORD = 0 then CW_S1 else if CW_SHIFT_WORD = 1 then CW_S2 else ulong(0)
        | CW_P2 := if CW_SHIFT_WORD = -2 then CW_S0 else if CW_SHIFT_WORD = -1 then CW_S1 else if CW_SHIFT_WORD = 0 then CW_S2 else ulong(0)
        | CW_P3 := if CW_SHIFT_WORD = -2 then CW_S1 else if CW_SHIFT_WORD = -1 then CW_S2 else ulong(0)
        | CW_P4 := if CW_SHIFT_WORD = -2 then CW_S2 else ulong(0)
        | CW_NEWLINE_AT := CW_PREFIX + CW_DIGITS
        | CW_NEWLINE_WORD := CW_NEWLINE_AT / 8
        | CW_NEWLINE := ulong(10) shl (8 * (CW_NEWLINE_AT modulo 8))
        | CW_W0 := (CW_P0 shr CW_SHIFT_BITS) or (CW_P1 shl CW_SPILL_BITS)
                   or (if CW_HEADER then CODE_HEADER_WORD0[CW_COLUMN] else if CW_NEGATIVE then ulong(45) else ulong(0))
                   or (if CW_NEWLINE_WORD = 0 then CW_NEWLINE else ulong(0))
        | CW_W1 := (CW_P1 shr CW_SHIFT_BITS) or (CW_P2 shl CW_SPILL_BITS)
                   or (if CW_HEADER then CODE_HEADER_WORD1[CW_COLUMN] else ulong(0))
                   or (if CW_NEWLINE_WORD = 1 then CW_NEWLINE else ulong(0))
        | CW_W2 := (CW_P2 shr CW_SHIFT_BITS) or (CW_P3 shl CW_SPILL_BITS) or (if CW_NEWLINE_WORD = 2 then CW_NEWLINE else ulong(0))
        | CW_W3 := (CW_P3 shr CW_SHIFT_BITS) or (CW_P4 shl CW_SPILL_BITS) or (if CW_NEWLINE_WORD = 3 then CW_NEWLINE else ulong(0))
        | CW_FITS := long(CW_TOTAL[?]) + long(32) <= OUTPUT_CAP
        | CW_AT := if CW_FITS then CW_TOTAL[?] else integer(OUTPUT_CAP) - 32
        | store{CODE_OUT0, ulong}(OUTPUT_BASE + CW_AT, CW_W0)
        | store{CODE_OUT1, ulong}(OUTPUT_BASE + CW_AT + 8, CW_W1)
        | store{CODE_OUT2, ulong}(OUTPUT_BASE + CW_AT + 16, CW_W2)
        | store{CODE_OUT3, ulong}(OUTPUT_BASE + CW_AT + 24, CW_W3)
        | CW_TOTAL := if CW_FITS then CW_TOTAL[?] + CW_NEWLINE_AT + 1 else CW_TOTAL[?]
        | CW_OVERFLOW := CW_OVERFLOW[?] or not CW_FITS
        |)
     with (| CW_NEXT_C := 0 | CW_NEXT_I := -1 | CW_TOTAL := 0 | CW_OVERFLOW := false |)
     end
   | IMAGE_RUN := DUMP_PASS = 0 and EMIT_READY and MESSAGE = 0
   | EN_FAILED := IMAGE_RUN and EN_FAIL_AT >= 0
   | IMAGE_GO := IMAGE_RUN and not EN_FAILED
   | IM_INDEX := 0 .. (if IMAGE_GO then SIGNED_BYTES / 4 - 1 else -1)
   | iterate IM_INDEX of
       (| IM_OFFSET := 4 * IM_INDEX
        | IM_FIELD := HEADER_FIELD[IM_INDEX]
        | IM_ELF_FIELD := ELF_FIELD[IM_INDEX]
        | IM_ELF32_FIELD := ELF32_FIELD[IM_INDEX]
        | IM_HEADER := if PLATFORM = PLATFORM_MPS2 then
                         (if IM_ELF32_FIELD = EV_CONSTANT then ELF32_WORD[IM_INDEX]
                          else uinteger(if IM_ELF32_FIELD = EV_SIGNED_BYTES then long(SIGNED_BYTES - MPS2_UNLOADED)
                                        else MEMORY_BYTES - long(MPS2_UNLOADED)))
                       else if PLATFORM = PLATFORM_VIRT then
                         (if IM_ELF_FIELD = EV_CONSTANT then ELF_WORD[IM_INDEX]
                          else uinteger(if IM_ELF_FIELD = EV_SIGNED_BYTES then long(SIGNED_BYTES) else MEMORY_BYTES))
                       else if IM_FIELD = HV_CONSTANT then HEADER_WORD[IM_INDEX]
                       else uinteger(if IM_FIELD = HV_TEXT_BYTES then TEXT_BYTES else if IM_FIELD = HV_DATA_BYTES then DATA_BYTES
                                     else if IM_FIELD = HV_SIGNED_BYTES then SIGNED_BYTES
                                     else if IM_FIELD = HV_LINKEDIT_BYTES then LINKEDIT_BYTES else SIGNATURE_BYTES)
        | IM_CODE := IM_INDEX - HEADER_BYTES / 4
        | IM_DATA := IM_OFFSET - TEXT_BYTES
        | IM_WORD := if IM_CODE < 0 then IM_HEADER else if IM_CODE < CODE_COUNT then CODE_WORD[IM_CODE]
                     else if IM_DATA < 0 then uinteger(0)
                     else uinteger(DATA_BYTE[IM_DATA]) or (uinteger(DATA_BYTE[IM_DATA + 1]) shl 8)
                          or (uinteger(DATA_BYTE[IM_DATA + 2]) shl 16) or (uinteger(DATA_BYTE[IM_DATA + 3]) shl 24)
        | IMAGE_WORD := IMAGE_WORD[?] next IM_INDEX : IM_WORD
        | store{IMAGE, uinteger}(OUTPUT_BASE + IM_OFFSET, IM_WORD)
        |)
     end
   | SH_INDEX := 0 .. (if IMAGE_GO and PLATFORM = PLATFORM_MACOS then PAGES * 16448 - 1 else -1)
   | iterate SH_INDEX of
       (| SH_T := SH_INDEX modulo 64
        | SH_BLOCK := SH_INDEX / 64
        | SH_B := SH_BLOCK modulo 257
        | SH_P := SH_BLOCK / 257
        | SH_LE := IMAGE_WORD[4096 * SH_P + 16 * SH_B + SH_T]
        | SH_M := if SH_B = 256 then (if SH_T = 0 then uinteger(2147483648) else if SH_T = 15 then uinteger(131072) else uinteger(0))
                  else (SH_LE shl 24) or ((SH_LE shl 8) and uinteger(16711680)) or ((SH_LE shr 8) and uinteger(65280)) or (SH_LE shr 24)
        | SH_X1 := SH_Q1[?]
        | SH_X14 := SH_Q14[?]
        | SH_SMALL0 := ((SH_X1 shr 7) or (SH_X1 shl 25)) xor ((SH_X1 shr 18) or (SH_X1 shl 14)) xor (SH_X1 shr 3)
        | SH_SMALL1 := ((SH_X14 shr 17) or (SH_X14 shl 15)) xor ((SH_X14 shr 19) or (SH_X14 shl 13)) xor (SH_X14 shr 10)
        | SH_W := if SH_T < 16 then SH_M else SH_SMALL1 + SH_Q9[?] + SH_SMALL0 + SH_Q0[?]
        | SH_Q0 := SH_Q1[?]
        | SH_Q1 := SH_Q2[?]
        | SH_Q2 := SH_Q3[?]
        | SH_Q3 := SH_Q4[?]
        | SH_Q4 := SH_Q5[?]
        | SH_Q5 := SH_Q6[?]
        | SH_Q6 := SH_Q7[?]
        | SH_Q7 := SH_Q8[?]
        | SH_Q8 := SH_Q9[?]
        | SH_Q9 := SH_Q10[?]
        | SH_Q10 := SH_Q11[?]
        | SH_Q11 := SH_Q12[?]
        | SH_Q12 := SH_Q13[?]
        | SH_Q13 := SH_Q14[?]
        | SH_Q14 := SH_Q15[?]
        | SH_Q15 := SH_W
        | SH_START := SH_B = 0 and SH_T = 0
        | SH_H0_IN := if SH_START then SHA_IV[0] else SH_H0[?]
        | SH_H1_IN := if SH_START then SHA_IV[1] else SH_H1[?]
        | SH_H2_IN := if SH_START then SHA_IV[2] else SH_H2[?]
        | SH_H3_IN := if SH_START then SHA_IV[3] else SH_H3[?]
        | SH_H4_IN := if SH_START then SHA_IV[4] else SH_H4[?]
        | SH_H5_IN := if SH_START then SHA_IV[5] else SH_H5[?]
        | SH_H6_IN := if SH_START then SHA_IV[6] else SH_H6[?]
        | SH_H7_IN := if SH_START then SHA_IV[7] else SH_H7[?]
        | SH_IA := if SH_T = 0 then SH_H0_IN else SH_VA[?]
        | SH_IB := if SH_T = 0 then SH_H1_IN else SH_VB[?]
        | SH_IC := if SH_T = 0 then SH_H2_IN else SH_VC[?]
        | SH_ID := if SH_T = 0 then SH_H3_IN else SH_VD[?]
        | SH_IE := if SH_T = 0 then SH_H4_IN else SH_VE[?]
        | SH_IF := if SH_T = 0 then SH_H5_IN else SH_VF[?]
        | SH_IG := if SH_T = 0 then SH_H6_IN else SH_VG[?]
        | SH_IH := if SH_T = 0 then SH_H7_IN else SH_VH[?]
        | SH_BIG1 := ((SH_IE shr 6) or (SH_IE shl 26)) xor ((SH_IE shr 11) or (SH_IE shl 21)) xor ((SH_IE shr 25) or (SH_IE shl 7))
        | SH_CH := SH_IG xor (SH_IE and (SH_IF xor SH_IG))
        | SH_T1 := SH_IH + SH_BIG1 + SH_CH + SHA_K[SH_T] + SH_W
        | SH_BIG0 := ((SH_IA shr 2) or (SH_IA shl 30)) xor ((SH_IA shr 13) or (SH_IA shl 19)) xor ((SH_IA shr 22) or (SH_IA shl 10))
        | SH_MAJ := (SH_IA and SH_IB) or (SH_IC and (SH_IA or SH_IB))
        | SH_VA := SH_T1 + SH_BIG0 + SH_MAJ
        | SH_VB := SH_IA
        | SH_VC := SH_IB
        | SH_VD := SH_IC
        | SH_VE := SH_ID + SH_T1
        | SH_VF := SH_IE
        | SH_VG := SH_IF
        | SH_VH := SH_IG
        | SH_END := SH_T = 63
        | SH_H0 := if SH_END then SH_H0_IN + SH_VA else SH_H0_IN
        | SH_H1 := if SH_END then SH_H1_IN + SH_VB else SH_H1_IN
        | SH_H2 := if SH_END then SH_H2_IN + SH_VC else SH_H2_IN
        | SH_H3 := if SH_END then SH_H3_IN + SH_VD else SH_H3_IN
        | SH_H4 := if SH_END then SH_H4_IN + SH_VE else SH_H4_IN
        | SH_H5 := if SH_END then SH_H5_IN + SH_VF else SH_H5_IN
        | SH_H6 := if SH_END then SH_H6_IN + SH_VG else SH_H6_IN
        | SH_H7 := if SH_END then SH_H7_IN + SH_VH else SH_H7_IN
        | SH_PAGE_END := SH_END and SH_B = 256
        | PAGE_HASH0 := PAGE_HASH0[?] next (if SH_PAGE_END then SH_P else -1) : SH_H0
        | PAGE_HASH1 := PAGE_HASH1[?] next (if SH_PAGE_END then SH_P else -1) : SH_H1
        | PAGE_HASH2 := PAGE_HASH2[?] next (if SH_PAGE_END then SH_P else -1) : SH_H2
        | PAGE_HASH3 := PAGE_HASH3[?] next (if SH_PAGE_END then SH_P else -1) : SH_H3
        | PAGE_HASH4 := PAGE_HASH4[?] next (if SH_PAGE_END then SH_P else -1) : SH_H4
        | PAGE_HASH5 := PAGE_HASH5[?] next (if SH_PAGE_END then SH_P else -1) : SH_H5
        | PAGE_HASH6 := PAGE_HASH6[?] next (if SH_PAGE_END then SH_P else -1) : SH_H6
        | PAGE_HASH7 := PAGE_HASH7[?] next (if SH_PAGE_END then SH_P else -1) : SH_H7
        |)
     end
   | SG_INDEX := 0 .. (if IMAGE_GO and PLATFORM = PLATFORM_MACOS then SIGNATURE_BYTES - 1 else -1)
   | iterate SG_INDEX of
       (| SG_IN_HEADER := SG_INDEX < SIGNATURE_HEADER_BYTES
        | SG_FIELD := SIGNATURE_FIELD[SG_INDEX / 4]
        | SG_HEADER := if SG_FIELD = SV_CONSTANT then SIGNATURE_WORD[SG_INDEX / 4]
                       else uinteger(if SG_FIELD = SV_SIGNATURE_BYTES then SIGNATURE_BYTES else if SG_FIELD = SV_DIRECTORY_BYTES then DIRECTORY_BYTES
                                     else if SG_FIELD = SV_PAGES then PAGES else SIGNED_BYTES)
        | SG_HASH_AT := SG_INDEX - SIGNATURE_HEADER_BYTES - 1
        | SG_PAGE := SG_HASH_AT / HASH_BYTES
        | SG_HASH_WORD := SG_HASH_AT modulo HASH_BYTES / 4
        | SG_VALUE := if SG_IN_HEADER then SG_HEADER else if SG_HASH_WORD = 0 then PAGE_HASH0[SG_PAGE] else if SG_HASH_WORD = 1 then PAGE_HASH1[SG_PAGE] else if SG_HASH_WORD = 2 then PAGE_HASH2[SG_PAGE] else if SG_HASH_WORD = 3 then PAGE_HASH3[SG_PAGE] else if SG_HASH_WORD = 4 then PAGE_HASH4[SG_PAGE] else if SG_HASH_WORD = 5 then PAGE_HASH5[SG_PAGE] else if SG_HASH_WORD = 6 then PAGE_HASH6[SG_PAGE] else PAGE_HASH7[SG_PAGE]
        | SG_SHIFT := 24 - 8 * (if SG_IN_HEADER then SG_INDEX modulo 4 else SG_HASH_AT modulo 4)
        | SG_BYTE := if SG_INDEX = SIGNATURE_HEADER_BYTES then ubyte(0) else ubyte(SG_VALUE shr SG_SHIFT)
        | store{SIGNATURE, ubyte}(OUTPUT_BASE + SIGNED_BYTES + SG_INDEX, SG_BYTE)
        |)
     end
   | PID := syscall{OS}(20, 0, 0, 0, 0, 0, 0)
   | SOURCE_CLOSED --> PID
   | STAGE_GO := IMAGE_GO and OUT_PATH_ENDED
   | STAGED_DIR := OUTPUT_NAME_SLASH + 1
   | SP_INDEX := 0 .. (if STAGE_GO then OUTPUT_NAME_LENGTH + 10 else -1)
   | iterate SP_INDEX of
       (| SP_NIBBLE := (ulong(PID) shr (4 * (OUTPUT_NAME_LENGTH + 9 - SP_INDEX))) modulo ulong(16)
        | SP_BYTE := if SP_INDEX < STAGED_DIR then OUTPUT_NAME[SP_INDEX]
                     else if SP_INDEX = STAGED_DIR or SP_INDEX = OUTPUT_NAME_LENGTH + 1 then ubyte(46)
                     else if SP_INDEX <= OUTPUT_NAME_LENGTH then OUTPUT_NAME[SP_INDEX - 1]
                     else if SP_INDEX < OUTPUT_NAME_LENGTH + 10 then ubyte(SP_NIBBLE + (if SP_NIBBLE < ulong(10) then ulong(48) else ulong(87)))
                     else ubyte(0)
        | store{STAGE, ubyte}(OUTPUT_BASE + STAGED_AT + SP_INDEX, SP_BYTE)
        |)
     end
   | STAGED_ADDRESS := OUTPUT_BASE + STAGED_AT
   | STAGED_FD := syscall{OS}(if STAGE_GO then 5 else 20, STAGED_ADDRESS, 2561, 384, 0, 0, 0)
   | SP_BYTE --> STAGED_FD
   | STAGED_OPEN := STAGE_GO and STAGED_FD >= long(0)
   | IMAGE_WRITTEN := syscall{OS}(if STAGED_OPEN then 4 else 20, STAGED_FD, BUFFER_ADDRESS, FILE_BYTES, 0, 0, 0)
   | IM_WORD --> IMAGE_WRITTEN
   | SG_BYTE --> IMAGE_WRITTEN
   | IMAGE_WRITE_OK := STAGED_OPEN and IMAGE_WRITTEN = long(FILE_BYTES)
   | STAGED_MODE := syscall{OS}(if IMAGE_WRITE_OK then 124 else 20, STAGED_FD, 493, 0, 0, 0, 0)
   | STAGED_MODE_OK := IMAGE_WRITE_OK and STAGED_MODE >= long(0)
   | STAGED_CLOSED := syscall{OS}(if STAGED_OPEN then 6 else 20, STAGED_FD, 0, 0, 0, 0, 0)
   | STAGED_MODE --> STAGED_CLOSED
   | STAGED_CLOSE_OK := STAGED_MODE_OK and STAGED_CLOSED >= long(0)
   | RENAMED := syscall{OS}(if STAGED_CLOSE_OK then 128 else 20, STAGED_ADDRESS, OUTPUT_NAME_ADDRESS, 0, 0, 0, 0)
   | RENAME_OK := STAGED_CLOSE_OK and RENAMED >= long(0)
   | UNLINKED := syscall{OS}(if STAGED_OPEN and not RENAME_OK then 10 else 20, STAGED_ADDRESS, 0, 0, 0, 0, 0)
   | OUTPUT_ERRNO := if not IMAGE_GO then 0 else if not OUT_PATH_ENDED then 63 else if not STAGED_OPEN then integer(-STAGED_FD)
                     else if not IMAGE_WRITE_OK then (if IMAGE_WRITTEN < long(0) then integer(-IMAGE_WRITTEN) else 5)
                     else if not STAGED_MODE_OK then integer(-STAGED_MODE) else if not STAGED_CLOSE_OK then integer(-STAGED_CLOSED)
                     else if not RENAME_OK then integer(-RENAMED) else 0
   | TEXT_AT := if IMAGE_GO then IMAGE_TEXT_AT else 0
   | EMIT_CAPACITY := if not UNIT_READY then F_CAP_UNITS else if not MICRO_READY then F_CAP_MICRO_OPS
                      else if not CODE_FITS then F_CAP_CODE else if not CODE_LABELS_FIT then F_CAP_CODE_LABELS
                      else if not DATA_FITS then F_CAP_DATA else F_CAP_CODE_TEXT
   | EMIT_SHORT := EMIT_PREPARED and (not EMIT_READY or CODE_DUMP and (not CW_RUN or CW_OVERFLOW))
   | IMAGE_OVER_RAM := EMIT_READY and PLATFORM = PLATFORM_MPS2 and MEMORY_BYTES - long(MPS2_UNLOADED) > long(MPS2_RAM_BYTES)
   | EMIT_MESSAGE := if EMIT_RUN and EW_FAILED then T_ARRAYS_ADDRESS else if EMIT_SHORT then T_CAPACITY
                     else if IMAGE_OVER_RAM then T_IMAGE_SIZE else 0
   | EMIT_ERROR_TOKEN := if EMIT_MESSAGE = T_ARRAYS_ADDRESS then ROWS_TOKEN[EW_FAIL_SIGNAL]
                         else if EMIT_MESSAGE = T_IMAGE_SIZE then MACHINE_TOKEN else -1
   | MERGE_BOUND := long(SIGNAL_COUNT) + long(FINISH_SIGNAL_COUNT) + long(EQUATION_COUNT) + long(FINISH_EQUATION_COUNT)
                    + long(GROUP_COUNT) + long(FINISH_GROUP_COUNT) + long(3) * long(CLOSED_COUNT) + long(LABEL_COUNT)
                    + long(MODEL_COUNT) + long(USE_COUNT) + long(TABLE_COUNT) + long(8)
   | MERGE_INDEX := 0 .. (if DUMP_RUNS and not ROWS_DUMP and not CLOCKS_DUMP and not SCHEDULE_DUMP then MERGE_BOUND else long(-1))
   | iterate MERGE_INDEX of
       (| SIGNAL_RANK_NOW := SIGNAL_RANK[?]
        | SIGNAL_RANK_OPEN := SIGNAL_RANK_NOW < CLOSED_COUNT
        | SIGNAL_LIMIT := if SIGNAL_RANK_OPEN then MODEL_CLOSE_SIGNALS[CLOSE_ORDER[SIGNAL_RANK_NOW]] else SIGNAL_COUNT
        | TAKES_PARSE_SIGNAL := SIGNAL_PARSE_CURSOR[?] < SIGNAL_LIMIT
        | TAKES_FINISH_SIGNAL := not TAKES_PARSE_SIGNAL and SIGNAL_RANK_OPEN and SIGNAL_FINISH_CURSOR[?] < FINISH_SIGNAL_COUNT
                                 and FINISH_SIGNAL_MODEL[SIGNAL_FINISH_CURSOR[?]] = CLOSE_ORDER[SIGNAL_RANK_NOW]
        | TAKES_SIGNAL := TAKES_PARSE_SIGNAL or TAKES_FINISH_SIGNAL
        | SIGNAL_RANK := SIGNAL_RANK_NOW + integer(SIGNAL_RANK_OPEN and not TAKES_SIGNAL)
        | MERGED_SIGNAL := MERGED_SIGNAL[?] next (if TAKES_SIGNAL then DUMP_SIGNAL_COUNT[?] else -1)
                           : (if TAKES_PARSE_SIGNAL then SIGNAL_PARSE_CURSOR[?] else -SIGNAL_FINISH_CURSOR[?] - 1)
        | DUMP_SIGNAL_COUNT := DUMP_SIGNAL_COUNT[?] + integer(TAKES_SIGNAL)
        | SIGNAL_PARSE_CURSOR := SIGNAL_PARSE_CURSOR[?] + integer(TAKES_PARSE_SIGNAL)
        | SIGNAL_FINISH_CURSOR := SIGNAL_FINISH_CURSOR[?] + integer(TAKES_FINISH_SIGNAL)
        | EQUATION_RANK_NOW := EQUATION_RANK[?]
        | EQUATION_RANK_OPEN := EQUATION_RANK_NOW < CLOSED_COUNT
        | EQUATION_LIMIT := if EQUATION_RANK_OPEN then MODEL_CLOSE_EQUATIONS[CLOSE_ORDER[EQUATION_RANK_NOW]] else EQUATION_COUNT
        | TAKES_PARSE_EQUATION := EQUATION_PARSE_CURSOR[?] < EQUATION_LIMIT
        | KEEPS_PARSE_EQUATION := TAKES_PARSE_EQUATION and not EQUATION_STATEMENT[EQUATION_PARSE_CURSOR[?]]
        | TAKES_FINISH_EQUATION := not TAKES_PARSE_EQUATION and EQUATION_RANK_OPEN and EQUATION_FINISH_CURSOR[?] < FINISH_EQUATION_COUNT
                                   and FINISH_EQUATION_MODEL[EQUATION_FINISH_CURSOR[?]] = CLOSE_ORDER[EQUATION_RANK_NOW]
        | KEEPS_EQUATION := KEEPS_PARSE_EQUATION or TAKES_FINISH_EQUATION
        | EQUATION_RANK := EQUATION_RANK_NOW
                           + integer(EQUATION_RANK_OPEN and not TAKES_PARSE_EQUATION and not TAKES_FINISH_EQUATION)
        | MERGED_EQUATION := MERGED_EQUATION[?] next (if KEEPS_EQUATION then DUMP_EQUATION_COUNT[?] else -1)
                             : (if TAKES_PARSE_EQUATION then EQUATION_PARSE_CURSOR[?] else -EQUATION_FINISH_CURSOR[?] - 1)
        | DUMP_EQUATION_COUNT := DUMP_EQUATION_COUNT[?] + integer(KEEPS_EQUATION)
        | EQUATION_PARSE_CURSOR := EQUATION_PARSE_CURSOR[?] + integer(TAKES_PARSE_EQUATION)
        | EQUATION_FINISH_CURSOR := EQUATION_FINISH_CURSOR[?] + integer(TAKES_FINISH_EQUATION)
        | GROUP_RANK_NOW := GROUP_RANK[?]
        | GROUP_RANK_OPEN := GROUP_RANK_NOW < CLOSED_COUNT
        | GROUP_LIMIT := if GROUP_RANK_OPEN then MODEL_CLOSE_GROUPS[CLOSE_ORDER[GROUP_RANK_NOW]] else GROUP_COUNT
        | TAKES_PARSE_GROUP := GROUP_PARSE_CURSOR[?] < GROUP_LIMIT
        | TAKES_FINISH_GROUP := not TAKES_PARSE_GROUP and GROUP_RANK_OPEN and GROUP_FINISH_CURSOR[?] < FINISH_GROUP_COUNT
                                and FINISH_GROUP_MODEL[GROUP_FINISH_CURSOR[?]] = CLOSE_ORDER[GROUP_RANK_NOW]
        | TAKES_GROUP := TAKES_PARSE_GROUP or TAKES_FINISH_GROUP
        | GROUP_RANK := GROUP_RANK_NOW + integer(GROUP_RANK_OPEN and not TAKES_GROUP)
        | MERGED_GROUP := MERGED_GROUP[?] next (if TAKES_GROUP then DUMP_GROUP_COUNT[?] else -1)
                          : (if TAKES_PARSE_GROUP then GROUP_PARSE_CURSOR[?] else -GROUP_FINISH_CURSOR[?] - 1)
        | DUMP_GROUP_COUNT := DUMP_GROUP_COUNT[?] + integer(TAKES_GROUP)
        | GROUP_PARSE_CURSOR := GROUP_PARSE_CURSOR[?] + integer(TAKES_PARSE_GROUP)
        | GROUP_FINISH_CURSOR := GROUP_FINISH_CURSOR[?] + integer(TAKES_FINISH_GROUP)
        | LABEL_WALK_MODEL_NOW := LABEL_WALK_MODEL[?]
        | LABEL_MODEL_OPEN := LABEL_WALK_MODEL_NOW < MODEL_COUNT
        | LABEL_WALK_AT := if LABEL_WALK_STARTED[?] then LABEL_WALK_NEXT[?] else MODEL_FIRST_LABEL[LABEL_WALK_MODEL_NOW] - 1
        | TAKES_LABEL := LABEL_MODEL_OPEN and LABEL_WALK_AT >= 0
        | MODEL_LABEL_OFFSET := MODEL_LABEL_OFFSET[?]
                                next (if LABEL_MODEL_OPEN and not LABEL_WALK_STARTED[?] then LABEL_WALK_MODEL_NOW else -1)
                                : ORDERED_LABEL_COUNT[?]
        | MODEL_LABEL_END := MODEL_LABEL_END[?] next (if LABEL_MODEL_OPEN and not TAKES_LABEL then LABEL_WALK_MODEL_NOW else -1)
                             : ORDERED_LABEL_COUNT[?]
        | LABEL_ORDERED_NAME := LABEL_ORDERED_NAME[?] next (if TAKES_LABEL then ORDERED_LABEL_COUNT[?] else -1)
                                : LABEL_NAME[LABEL_WALK_AT]
        | ORDERED_LABEL_COUNT := ORDERED_LABEL_COUNT[?] + integer(TAKES_LABEL)
        | LABEL_WALK_NEXT := if TAKES_LABEL then LABEL_NEXT[LABEL_WALK_AT] - 1 else -1
        | LABEL_WALK_STARTED := TAKES_LABEL
        | LABEL_WALK_MODEL := LABEL_WALK_MODEL_NOW + integer(LABEL_MODEL_OPEN and not TAKES_LABEL)
        | USE_DEPTH_MAX := if MERGE_INDEX < USE_COUNT and USE_PATH_LENGTH[MERGE_INDEX] > USE_DEPTH_MAX[?]
                           then USE_PATH_LENGTH[MERGE_INDEX] else USE_DEPTH_MAX[?]
        | TABLE_ELEMENT_TOTAL := TABLE_ELEMENT_TOTAL[?] + (if MERGE_INDEX < TABLE_COUNT then TABLE_LENGTH[MERGE_INDEX] else 0)
        |)
     with (| SIGNAL_RANK := 0 | SIGNAL_PARSE_CURSOR := 0 | SIGNAL_FINISH_CURSOR := 0 | DUMP_SIGNAL_COUNT := 0
           | EQUATION_RANK := 0 | EQUATION_PARSE_CURSOR := 0 | EQUATION_FINISH_CURSOR := 0 | DUMP_EQUATION_COUNT := 0
           | GROUP_RANK := 0 | GROUP_PARSE_CURSOR := 0 | GROUP_FINISH_CURSOR := 0 | DUMP_GROUP_COUNT := 0
           | LABEL_WALK_MODEL := 0 | LABEL_WALK_STARTED := false | LABEL_WALK_NEXT := -1 | ORDERED_LABEL_COUNT := 0
           | USE_DEPTH_MAX := 0 | TABLE_ELEMENT_TOTAL := 0 |)
     end
   | PATH_DEPTH_MAX := if USE_DEPTH_MAX > GUARD_DEPTH_MAX then USE_DEPTH_MAX else GUARD_DEPTH_MAX
   | DUMP_ROW_TOTAL := long(1) + long(7) * long(TYPE_COUNT) + long(6) * long(MODEL_COUNT) + long(5) * long(DUMP_SIGNAL_COUNT)
                       + long(3) * long(CONSTANT_COUNT) + long(2) * long(TABLE_COUNT) + long(9) * long(DUMP_EQUATION_COUNT)
                       + long(7) * long(GUARD_COUNT) + long(USE_COUNT) + long(3) * long(LOOP_COUNT)
                       + long(4) * long(DUMP_GROUP_COUNT) + long(5) * long(DEPENDENCE_COUNT)
   | FLAT_ROW_TOTAL := long(1) + long(7) * long(TYPE_COUNT) + long(5) * long(FLAT_SIGNAL_COUNT) + long(3) * long(CONSTANT_COUNT)
                       + long(2) * long(TABLE_COUNT) + long(9) * long(FLAT_EQUATION_COUNT) + long(FLAT_LABEL_COUNT)
                       + long(3) * long(FLAT_LOOP_COUNT) + long(4) * long(FLAT_GROUP_COUNT) + long(5) * long(FLAT_DEPENDENCE_COUNT)
   | FLAT_DUMP_BOUND := long(1024) + long(8) * FLAT_ROW_TOTAL + long(VALUE_COUNT) + long(TABLE_ELEMENT_TOTAL)
                        + long(2) * long(FLAT_LIST_TOTAL) + long(24) * long(FLAT_ENTRY_COUNT)
                        + long(8) * long(FLAT_MEMBER_COUNT) + long(6) * long(FLAT_PARAMETER_TOTAL)
   | PROGRAM_DUMP_BOUND := long(1024) + long(5) * DUMP_ROW_TOTAL + long(VALUE_COUNT) + long(LABEL_COUNT) + long(TABLE_ELEMENT_TOTAL)
                   + long(PATH_DEPTH_MAX) * long(2 * DUMP_EQUATION_COUNT + 2 * GUARD_COUNT + DUMP_GROUP_COUNT + DEPENDENCE_COUNT)
                   + long(20) * long(FINAL_COUNT) + long(6) * long(MEMBER_COUNT + 2 * FINISH_GROUP_COUNT)
                   + long(6) * long(TOKEN_COUNT)
   | ROWS_DUMP_BOUND := long(1024) + long(24) * long(ROW_COUNT) + long(4) * long(FLAT_GROUP_COUNT) + long(FLAT_MEMBER_COUNT)
                        + long(4) * long(DEPENDENCE_TOTAL) + long(4) * long(WAR_COUNT) + long(6) * long(EFFECT_COUNT)
                        + long(8) * long(FLAT_LOOP_COUNT) + long(FLAT_SIGNAL_COUNT) + long(16) * long(TYPE_COUNT + NEW_TYPE_COUNT)
                        + long(VALUE_COUNT) + long(4) * long(TABLE_COUNT + NEW_TABLE_COUNT) + long(TABLE_ELEMENT_TOTAL)
                        + NEW_TABLE_ELEMENTS
   | CLOCKS_DUMP_BOUND := long(1024) + long(16) * long(CLOCK_TOTAL) + long(2) * long(K_SAMPLE_COUNT) + long(18) * long(DEF_COUNT)
                          + long(8) * long(OB_COUNT) + long(2) * long(ROOT_COUNT)
   | SCHEDULE_DUMP_BOUND := long(64) + long(4) * long(SKO_COUNT) + long(4) * long(ROW_COUNT) + long(8) * long(FLAT_LOOP_COUNT)
                          + long(4) * long(FLAT_SIGNAL_COUNT)
   | DUMP_BOUND := if SCHEDULE_DUMP then SCHEDULE_DUMP_BOUND else if CLOCKS_DUMP then CLOCKS_DUMP_BOUND else if ROWS_DUMP then ROWS_DUMP_BOUND else if FLAT_DUMP then FLAT_DUMP_BOUND else PROGRAM_DUMP_BOUND
   | DUMP_COLUMN_START := if SCHEDULE_DUMP then ORDER_SCHEDULE_START else if CLOCKS_DUMP then ORDER_CLOCKS_START else if ROWS_DUMP then ORDER_ROWS_START else ORDER_PROGRAM_START
   | DUMP_COLUMN_END := if SCHEDULE_DUMP then ORDER_SCHEDULE_END else if CLOCKS_DUMP then ORDER_CLOCKS_END else if ROWS_DUMP then ORDER_ROWS_END else ORDER_PROGRAM_END
   | DUMP_INDEX := 0 .. (if DUMP_RUNS then DUMP_BOUND else long(-1))
   | iterate DUMP_INDEX of
       (| WALK_COLUMN_NOW := WALK_COLUMN[?]
        | WALK_ROW_NOW := WALK_ROW[?]
        | WALK_REL := WALK_POSITION[?]
        | WALK_INNER := WALK_INNER_POSITION[?]
        | WALK_STEP := WALK_STEP_POSITION[?]
        | WALK_MEMBER_STEP := WALK_MEMBER_POSITION[?]
        | WALKING := WALK_COLUMN_NOW < DUMP_COLUMN_END
        | COL := DUMP_ORDER[WALK_COLUMN_NOW]
        | SHAPE := COLUMN_SHAPE[COL]
        | LIST_KIND := COLUMN_LIST_KIND[COL]
        | FLAT_COLUMN_ROWS := if COL = COL_NAME then 1
                              else if COL <= COL_TYPES_SIZE then TYPE_COUNT
                              else if COL <= COL_MODELS_LABELS or COL = COL_SIGNAL_MODELS then 0
                              else if COL <= COL_SIGNAL_POSITIONS then FLAT_SIGNAL_COUNT
                              else if COL <= COL_CONSTANT_VALUES then CONSTANT_COUNT
                              else if COL <= COL_TABLE_VALUES then TABLE_COUNT
                              else if COL = COL_EQUATION_MODELS then 0
                              else if COL <= COL_EQUATION_GUARDS then FLAT_EQUATION_COUNT
                              else if COL <= COL_GUARD_SIGNALS then 0
                              else if COL = COL_LABEL_NAMES then FLAT_LABEL_COUNT
                              else if COL = COL_LABEL_USES or COL = COL_LOOP_MODELS then 0
                              else if COL <= COL_LOOP_POSITIONS then FLAT_LOOP_COUNT
                              else if COL = COL_CONSTRAINT_MODELS then 0
                              else if COL <= COL_CONSTRAINT_GUARDS then FLAT_GROUP_COUNT
                              else if COL = COL_DEPENDENCE_MODELS or COL = COL_DEPENDENCE_GUARDS then 0
                              else FLAT_DEPENDENCE_COUNT
        | ROWS_COLUMN_ROWS := if COL <= COL_TYPES_SIZE then TYPE_COUNT + NEW_TYPE_COUNT
                              else if COL < COL_ROWS_OP then TABLE_COUNT + NEW_TABLE_COUNT
                              else if COL <= COL_ROWS_GUARD then ROW_COUNT
                              else if COL <= COL_ROWS_GROUP_POSITIONS then FLAT_GROUP_COUNT
                              else if COL <= COL_ROWS_DEPENDENCE_TO then DEPENDENCE_TOTAL
                              else if COL = COL_ROWS_WAR then WAR_COUNT
                              else if COL = COL_ROWS_SNAPSHOTTED or COL = COL_LOOPS_SNAPSHOTS then 0
                              else if COL <= COL_ROWS_EFFECTS_PARAM then EFFECT_COUNT
                              else FLAT_LOOP_COUNT
        | CLOCKS_COLUMN_ROWS := if COL = COL_SAMPLE_ROWS then K_SAMPLE_COUNT else if COL <= COL_NODE_RIGHT and COL >= COL_NODE_KIND or COL = COL_PARENT then CLOCK_TOTAL
                                else if COL >= COL_OB_SMALL and COL <= COL_OB_COLUMN then OB_COUNT
                                else if COL = COL_ROOTS then ROOT_COUNT else DEF_COUNT
        | SCHEDULE_COLUMN_ROWS := if COL = COL_ORDER then SKO_COUNT else if COL = COL_SNAPSHOTTED then SNAP_TOTAL else FLAT_LOOP_COUNT
        | COLUMN_ROWS := if SCHEDULE_DUMP then SCHEDULE_COLUMN_ROWS else if CLOCKS_DUMP then CLOCKS_COLUMN_ROWS else if ROWS_DUMP then ROWS_COLUMN_ROWS else if FLAT_DUMP then FLAT_COLUMN_ROWS else if COL = COL_NAME then 1
                         else if COL <= COL_TYPES_SIZE then TYPE_COUNT
                         else if COL <= COL_MODELS_LABELS then MODEL_COUNT
                         else if COL <= COL_SIGNAL_POSITIONS then DUMP_SIGNAL_COUNT
                         else if COL <= COL_CONSTANT_VALUES then CONSTANT_COUNT
                         else if COL <= COL_TABLE_VALUES then TABLE_COUNT
                         else if COL <= COL_EQUATION_GUARDS then DUMP_EQUATION_COUNT
                         else if COL <= COL_GUARD_SIGNALS then GUARD_COUNT
                         else if COL = COL_LABEL_NAMES then 0
                         else if COL = COL_LABEL_USES then USE_COUNT
                         else if COL <= COL_LOOP_MODELS then LOOP_COUNT
                         else if COL <= COL_CONSTRAINT_GUARDS then DUMP_GROUP_COUNT
                         else DEPENDENCE_COUNT
        | AT_HEADER := WALK_ROW_NOW < 0
        | R := if AT_HEADER then 0 else WALK_ROW_NOW
        | DUMP_TYPE_NEW := R >= TYPE_COUNT
        | DUMP_TYPE_KIND := if DUMP_TYPE_NEW then TK_ARRAY else TYPE_KIND[R]
        | DUMP_TYPE_ELEMENT := if DUMP_TYPE_NEW then NEW_TYPE_ELEMENT[R - TYPE_COUNT] else TYPE_ELEMENT[R]
        | DUMP_TYPE_SIZE := if DUMP_TYPE_NEW then NEW_TYPE_SIZE[R - TYPE_COUNT] else TYPE_SIZE[R]
        | DUMP_TABLE_NEW := R >= TABLE_COUNT
        | DUMP_TABLE_TYPE := if DUMP_TABLE_NEW then NEW_TABLE_TYPE[R - TABLE_COUNT] else TABLE_TYPE[R]
        | DUMP_TABLE_SIZE := if DUMP_TABLE_TYPE >= TYPE_COUNT then NEW_TYPE_SIZE[DUMP_TABLE_TYPE - TYPE_COUNT]
                             else TYPE_SIZE[DUMP_TABLE_TYPE]
        | SIGNAL_SOURCE := if FLAT_DUMP then FLAT_SIGNAL_SOURCE[R] else MERGED_SIGNAL[R]
        | SIGNAL_FINISHED := SIGNAL_SOURCE < 0
        | SIGNAL_FINISH_ROW := -SIGNAL_SOURCE - 1
        | EQUATION_SOURCE := MERGED_EQUATION[R]
        | EQUATION_FINISHED := EQUATION_SOURCE < 0
        | EQUATION_FINISH_ROW := -EQUATION_SOURCE - 1
        | GROUP_SOURCE := MERGED_GROUP[R]
        | GROUP_FINISHED := GROUP_SOURCE < 0
        | GROUP_FINISH_ROW := -GROUP_SOURCE - 1
        | WALK_ROW_KEY := if COL = COL_NAME then MODEL_NAME[0]
                     else if COL = COL_MODELS_NAME then MODEL_NAME[R]
                     else if COL = COL_MODELS_KIND then MODEL_KIND[R] - 1
                     else if COL = COL_SIGNAL_NAMES then
                       (if SIGNAL_FINISHED then FINISH_SIGNAL_NAME[SIGNAL_FINISH_ROW] else SIGNAL_NAME[SIGNAL_SOURCE])
                     else if COL = COL_CONSTANT_NAMES then CONSTANT_NAME[R]
                     else if COL = COL_EQUATION_TARGETS then
                       (if FLAT_DUMP then FLAT_EQUATION_TARGET[R]
                        else if EQUATION_FINISHED then FINISH_EQUATION_TARGET[EQUATION_FINISH_ROW] else EQUATION_TARGET[EQUATION_SOURCE])
                     else if COL = COL_LABEL_NAMES then FLAT_LABEL_KEY[R]
                     else if COL = COL_GUARD_SIGNALS then N_ON_MARK + (R - MODEL_GUARD_START[GUARD_MODEL[R]] + 1) * NAME_CAP
                     else if COL = COL_LABEL_USES then USE_NAME[R]
                     else if COL = COL_LOOP_NAMES then LOOP_NAME[LOOP_ROW]
                     else if COL = COL_ROWS_EFFECTS_KIND then EFFECT_KIND[R]
                     else if FLAT_DUMP then (if COL = COL_DEPENDENCE_FROM then FLAT_DEPENDENCE_FROM_KEY[R] else FLAT_DEPENDENCE_TO_KEY[R])
                     else if COL = COL_DEPENDENCE_FROM then
                       (if DEPENDENCE_RENAMED_FROM[R] > 0 then DEPENDENCE_RENAMED_FROM[R] - 1 else DEPENDENCE_FROM_NAME[R])
                     else if DEPENDENCE_RENAMED_TO[R] > 0 then DEPENDENCE_RENAMED_TO[R] - 1 else DEPENDENCE_TO_NAME[R]
        | LOOP_ROW := if FLAT_DUMP then FLAT_LOOP_SOURCE[R] else R
        | WALK_ROW_INSTANCE := if not FLAT_DUMP then 0
                               else if COL = COL_SIGNAL_NAMES then FLAT_SIGNAL_INSTANCE[R]
                               else if COL = COL_EQUATION_TARGETS then FLAT_EQUATION_TARGET_INSTANCE[R]
                               else if COL = COL_LABEL_NAMES then FLAT_LABEL_INSTANCE[R]
                               else if COL = COL_LOOP_NAMES then FLAT_LOOP_INSTANCE[R]
                               else if COL = COL_DEPENDENCE_FROM or COL = COL_DEPENDENCE_TO then FLAT_DEPENDENCE_INSTANCE[R]
                               else 0
        | WALK_ROW_CALL := FLAT_DUMP and COL = COL_LABEL_NAMES and FLAT_LABEL_CALL[R]
        | ROWS_TOKEN_NOW := ROWS_TOKEN[R]
        | ROWS_NUMBER_VALUE := if COL = COL_ROWS_LEFT then long(ROWS_LEFT[R])
                               else if COL = COL_ROWS_RIGHT then long(ROWS_RIGHT[R])
                               else if COL = COL_ROWS_VALUE then ROWS_VALUE[R]
                               else if COL = COL_ROWS_TYPE then long(ROWS_TYPE[R])
                               else if COL = COL_ROWS_CTX then long(integer(ROWS_CTX[R]))
                               else if COL = COL_ROWS_LINE then long(if ROWS_TOKEN_NOW < 0 then 1 else TOKEN_LINE[ROWS_TOKEN_NOW])
                               else if COL = COL_ROWS_COLUMN then long(if ROWS_TOKEN_NOW < 0 then 1 else TOKEN_COLUMN[ROWS_TOKEN_NOW])
                               else if COL = COL_ROWS_OWNER then long(ROWS_OWNER[R])
                               else if COL = COL_ROWS_LOOP then long(ROWS_LOOP[R])
                               else if COL = COL_ROWS_GUARD then long(ROWS_GUARD[R])
                               else if COL = COL_ROWS_DEPENDENCE_FROM then long(DEPENDENCE_FROM_ROW[R])
                               else if COL = COL_ROWS_DEPENDENCE_TO then long(DEPENDENCE_TO_ROW[R])
                               else if COL = COL_ROWS_EFFECTS_RESOURCE then long(EFFECT_RESOURCE[R])
                               else if COL = COL_ROWS_EFFECTS_PARAM then EFFECT_PARAM[R]
                               else if COL = COL_LOOPS_INDEX then long(LOOP_INDEX[R])
                               else if COL = COL_LOOPS_SIZE then long(LOOP_SIZE[R])
                               else if ROWS_OP[ROWS_LEFT[LOOP_INDEX[R]]] = OP_RANGE then long(ROWS_RIGHT[ROWS_LEFT[LOOP_INDEX[R]]])
                               else long(-1)
        | CLOCK_POSITION_TOKEN := if COL = COL_DEF_LINE or COL = COL_DEF_COLUMN then DEF_TOKEN[R] else OB_TOKEN[R]
        | CLOCKS_NUMBER_VALUE := if COL = COL_PARENT then CLOCK_REP[R] else if COL = COL_SAMPLE_ROWS then SAMPLE_ROW[R]
                                 else if COL = COL_DEF_TARGET then DEF_TARGET[R] else if COL = COL_DEF_LEFT then DEF_LEFT[R]
                                 else if COL = COL_DEF_RIGHT then DEF_RIGHT[R]
                                 else if COL = COL_DEF_LINE or COL = COL_OB_LINE then
                                   (if CLOCK_POSITION_TOKEN < 0 then 1 else TOKEN_LINE[CLOCK_POSITION_TOKEN])
                                 else if COL = COL_DEF_COLUMN or COL = COL_OB_COLUMN then
                                   (if CLOCK_POSITION_TOKEN < 0 then 1 else TOKEN_COLUMN[CLOCK_POSITION_TOKEN])
                                 else if COL = COL_DEF_PENDING then integer(not DEF_DONE[R])
                                 else if COL = COL_OB_SMALL then OB_SMALL[R] else if COL = COL_OB_BIG then OB_BIG[R]
                                 else if COL = COL_NODE_PARENT then NODE_PARENT1[R] - 1 else if COL = COL_NODE_DEPTH then NODE_DEPTH[R]
                                 else if COL = COL_NODE_ROOT then NODE_ROOT1[R] - 1 else if COL = COL_NODE_LEFT then NODE_LEFT1[R] - 1
                                 else if COL = COL_NODE_RIGHT then NODE_RIGHT1[R] - 1 else ROOT_LIST[R]
        | ROW_NUMBER_VALUE := if COL = COL_ORDER then long(SKO_ORDER[R]) else if COL = COL_SNAPSHOTTED then long(SNAPPED_ALL[R])
                              else if COL >= COL_PARENT then long(CLOCKS_NUMBER_VALUE) else if COL >= COL_ROWS_OP then ROWS_NUMBER_VALUE
                              else if COL = COL_TYPES_BYTES then long(if DUMP_TYPE_NEW then 8 else TYPE_BYTES[R])
                              else if COL = COL_TYPES_SIGNED then long(integer(not DUMP_TYPE_NEW and TYPE_SIGNED[R]))
                              else if COL = COL_TYPES_ELEMENT then long(DUMP_TYPE_ELEMENT)
                              else if COL = COL_TYPES_SIZE then long(DUMP_TYPE_SIZE)
                              else if COL = COL_MODELS_PARENT then long(MODEL_PARENT[R])
                              else if COL = COL_MODELS_LINE then long(TOKEN_LINE[MODEL_TOKEN[R]])
                              else if COL = COL_MODELS_COLUMN then long(TOKEN_COLUMN[MODEL_TOKEN[R]])
                              else if COL = COL_SIGNAL_TYPES then
                                long(if SIGNAL_FINISHED then FINISH_SIGNAL_TYPE[SIGNAL_FINISH_ROW] else SIGNAL_TYPE[SIGNAL_SOURCE])
                              else if COL = COL_SIGNAL_MODELS then
                                long(if SIGNAL_FINISHED then FINISH_SIGNAL_MODEL[SIGNAL_FINISH_ROW] else SIGNAL_MODEL[SIGNAL_SOURCE])
                              else if COL = COL_CONSTANT_TYPES then long(CONSTANT_TYPE[R])
                              else if COL = COL_CONSTANT_VALUES then CONSTANT_VALUE[R]
                              else if COL = COL_TABLE_TYPES then long(DUMP_TABLE_TYPE)
                              else if COL = COL_EQUATION_LOOPS then
                                long(if FLAT_DUMP then FLAT_EQUATION_LOOP[R] else if EQUATION_FINISHED then -1 else EQUATION_LOOP[EQUATION_SOURCE])
                              else if COL = COL_EQUATION_MODELS then
                                long(if EQUATION_FINISHED then FINISH_EQUATION_MODEL[EQUATION_FINISH_ROW] else EQUATION_MODEL[EQUATION_SOURCE])
                              else if COL = COL_GUARD_MODELS then long(GUARD_MODEL[R])
                              else if COL = COL_LABEL_USES then long(USE_MODEL[R])
                              else if COL = COL_LOOP_MODELS then long(LOOP_MODEL[R])
                              else if COL = COL_CONSTRAINT_MODELS then
                                long(if GROUP_FINISHED then FINISH_GROUP_MODEL[GROUP_FINISH_ROW] else GROUP_MODEL[GROUP_SOURCE])
                              else long(DEPENDENCE_MODEL[R])
        | ROW_UNSIGNED := if ROWS_DUMP then COL = COL_LOOPS_SIZE or COL = COL_TYPES_SIZE or COL = COL_ROWS_VALUE and ROWS_TYPE[R] = BUILTIN_ULONG
                          else COL = COL_TYPES_SIZE or COL = COL_CONSTANT_VALUES and CONSTANT_TYPE[R] = BUILTIN_ULONG
        | ROW_FRAGMENT := if COL = COL_ROWS_OP then OP_FRAGMENT[ROWS_OP[R]]
                          else if COL = COL_DEF_KIND then CLOCK_KIND_FRAGMENT[DEF_KIND[R]]
                          else if COL = COL_NODE_KIND then CLOCK_KIND_FRAGMENT[NODE_KIND[R]]
                          else if COL = COL_TYPES_KIND then TYPE_KIND_FRAGMENT[DUMP_TYPE_KIND]
                          else if COL = COL_SIGNAL_ROLES then
                            ROLE_FRAGMENT[if SIGNAL_FINISHED or FLAT_DUMP and FLAT_SIGNAL_INSTANCE[R] > 0 then ROLE_LOCAL
                                          else SIGNAL_ROLE[SIGNAL_SOURCE]]
                          else if FLAT_DUMP then (if FLAT_EQUATION_SEED[R] then F_SEED else F_DEFINE)
                          else if not EQUATION_FINISHED and EQUATION_SEED[EQUATION_SOURCE] then F_SEED else F_DEFINE
        | WALK_ROW_TOKEN := if COL = COL_ROWS_GROUP_POSITIONS then FLAT_GROUP_TOKEN[R]
                       else if COL = COL_SIGNAL_POSITIONS then
                         (if SIGNAL_FINISHED then FINISH_SIGNAL_TOKEN[SIGNAL_FINISH_ROW] else SIGNAL_TOKEN[SIGNAL_SOURCE])
                       else if COL = COL_EQUATION_POSITIONS then
                         (if FLAT_DUMP then FLAT_EQUATION_TOKEN[R]
                          else if EQUATION_FINISHED then FINISH_EQUATION_TOKEN[EQUATION_FINISH_ROW] else EQUATION_POSITION[EQUATION_SOURCE])
                       else if COL = COL_GUARD_POSITIONS then GUARD_TOKEN[R]
                       else if COL = COL_LABEL_USES then USE_TOKEN[R]
                       else if COL = COL_LOOP_POSITIONS then LOOP_TOKEN[LOOP_ROW]
                       else if FLAT_DUMP then
                         (if COL = COL_CONSTRAINT_POSITIONS then FLAT_GROUP_TOKEN[R]
                          else if COL = COL_DEPENDENCE_FROM then FLAT_DEPENDENCE_FROM_TOKEN[R]
                          else if COL = COL_DEPENDENCE_TO then FLAT_DEPENDENCE_TO_TOKEN[R] else FLAT_DEPENDENCE_TOKEN[R])
                       else if COL = COL_CONSTRAINT_POSITIONS then
                         (if GROUP_FINISHED then MODEL_TOKEN[FINISH_GROUP_MODEL[GROUP_FINISH_ROW]] else GROUP_POSITION[GROUP_SOURCE])
                       else if COL = COL_DEPENDENCE_FROM then DEPENDENCE_FROM_TOKEN[R]
                       else if COL = COL_DEPENDENCE_TO then DEPENDENCE_TO_TOKEN[R]
                       else DEPENDENCE_POSITION[R]
        | ROW_IS_ARRAY := DUMP_TYPE_KIND = TK_ARRAY
        | ROW_SCALAR_LENGTH := if SHAPE = SHAPE_TYPE and not ROW_IS_ARRAY then 1 else SCALAR_LENGTH[SHAPE]
        | PATH_NODE := if FLAT_DUMP then
                         (if COL = COL_EQUATION_LABELS then FLAT_EQUATION_LABELS[R]
                          else if COL = COL_EQUATION_GUARDS then FLAT_EQUATION_GUARDS[R] else FLAT_GROUP_GUARDS[R])
                       else if COL = COL_EQUATION_LABELS then
                         (if EQUATION_FINISHED then FINISH_EQUATION_LABELS[EQUATION_FINISH_ROW] else EQUATION_LABELS[EQUATION_SOURCE])
                       else if COL = COL_EQUATION_GUARDS then
                         (if EQUATION_FINISHED then FINISH_EQUATION_GUARDS[EQUATION_FINISH_ROW] else EQUATION_GUARDS[EQUATION_SOURCE])
                       else if COL = COL_GUARD_CONTEXT then GUARD_CONTEXT[R]
                       else if COL = COL_GUARD_LABELS then GUARD_LABELS[R]
                       else if COL = COL_CONSTRAINT_GUARDS then (if GROUP_FINISHED then -1 else GROUP_GUARDS[GROUP_SOURCE])
                       else DEPENDENCE_GUARDS[R]
        | PATH_OF_USE := COL = COL_EQUATION_LABELS or COL = COL_GUARD_LABELS
        | PATH_FIRST := if PATH_OF_USE then USE_PATH_START[PATH_NODE] else GUARD_PATH_START[PATH_NODE]
        | PATH_SIZE := if PATH_NODE < 0 then 0 else if PATH_OF_USE then USE_PATH_LENGTH[PATH_NODE] else GUARD_PATH_LENGTH[PATH_NODE]
        | PATH_CONTEXT := if COL = COL_CONSTRAINT_GUARDS then FLAT_GROUP_INSTANCE[R] else FLAT_EQUATION_CONTEXT[R]
        | FLAT_PATH_COLUMN := FLAT_DUMP and (COL = COL_EQUATION_LABELS or COL = COL_EQUATION_GUARDS or COL = COL_CONSTRAINT_GUARDS)
        | INHERITED_START := if PATH_OF_USE then INSTANCE_LABEL_START[PATH_CONTEXT] else INSTANCE_GUARD_START[PATH_CONTEXT]
        | INHERITED_LENGTH := if not FLAT_PATH_COLUMN then 0
                              else if PATH_OF_USE then INSTANCE_LABEL_LENGTH[PATH_CONTEXT] else INSTANCE_GUARD_LENGTH[PATH_CONTEXT]
        | FROM_INHERITED_PATH := WALK_REL < INHERITED_LENGTH
        | INHERITED_AT := INHERITED_START + WALK_REL
        | ENTRIES_OF_EQUATION := COL = COL_EQUATION_OPS or COL = COL_EQUATION_ARGS
        | ENTRY_RUN_START := if ENTRIES_OF_EQUATION then
                               (if FLAT_DUMP then FLAT_EQUATION_START[R]
                                else if EQUATION_FINISHED then FINISH_EQUATION_FINAL_START[EQUATION_FINISH_ROW]
                                else EQUATION_FINAL_START[EQUATION_SOURCE])
                             else GUARD_FINAL_START[R]
        | ENTRY_RUN_END := if ENTRIES_OF_EQUATION then
                             (if FLAT_DUMP then FLAT_EQUATION_END[R]
                              else if EQUATION_FINISHED then FINISH_EQUATION_FINAL_END[EQUATION_FINISH_ROW]
                              else EQUATION_FINAL_END[EQUATION_SOURCE])
                           else GUARD_FINAL_END[R]
        | RUN_START := if COL = COL_ROWS_GROUPS then FLAT_GROUP_MEMBER_FIRST[R]
                       else if COL = COL_LOOP_ORDERS then LO_START[R] else if COL = COL_SNAPSHOTS then SNAP_START[R]
                       else if COL = COL_ROWS_WAR then 0
                       else if COL = COL_LOOPS_DEFINED then LOOP_DEF_START[R]
                       else if COL = COL_TYPES_VALUES then TYPE_VALUE_START[R]
                       else if COL = COL_MODELS_LABELS then MODEL_LABEL_OFFSET[R]
                       else if COL = COL_TABLE_VALUES then TABLE_START[R]
                       else if LIST_KIND = LIST_OPS or LIST_KIND = LIST_ARGS then ENTRY_RUN_START
                       else PATH_FIRST
        | RUN_LENGTH := if COL = COL_ROWS_GROUPS then FLAT_GROUP_MEMBER_TOTAL[R]
                        else if COL = COL_LOOP_ORDERS then LO_LENGTH[R] else if COL = COL_SNAPSHOTS then SNAP_LOOP_COUNT[R]
                        else if COL = COL_ROWS_WAR then 3
                        else if COL = COL_LOOPS_DEFINED then LOOP_DEF_TOTAL[R]
                        else if COL = COL_TYPES_VALUES then (if DUMP_TYPE_NEW then 0 else TYPE_VALUE_COUNT[R])
                        else if COL = COL_MODELS_LABELS then MODEL_LABEL_END[R] - MODEL_LABEL_OFFSET[R]
                        else if COL = COL_TABLE_VALUES then (if DUMP_TABLE_NEW then integer(DUMP_TABLE_SIZE) else TABLE_LENGTH[R])
                        else if LIST_KIND = LIST_OPS or LIST_KIND = LIST_ARGS then ENTRY_RUN_END - ENTRY_RUN_START
                        else INHERITED_LENGTH + PATH_SIZE
        | LIST_AT := RUN_START + WALK_REL - INHERITED_LENGTH
        | NODE_ON_KEY := N_ON_MARK + (PATH_VALUE[LIST_AT] - MODEL_GUARD_START[GUARD_MODEL[PATH_VALUE[LIST_AT]]] + 1) * NAME_CAP
        | LIST_VALUE := if COL = COL_ROWS_GROUPS then long(GROUP_MEMBER_ROW[LIST_AT])
                        else if COL = COL_LOOP_ORDERS then long(LO_LIST[LIST_AT]) else if COL = COL_SNAPSHOTS then long(SNAP_LIST[LIST_AT])
                        else if COL = COL_ROWS_WAR then
                          long(if WALK_REL = 0 then WAR_READER[R] else if WALK_REL = 1 then WAR_WRITER[R] else WAR_SIGNAL[R])
                        else if COL = COL_LOOPS_DEFINED then long(DEFINED_LIST[LIST_AT])
                        else if COL = COL_TYPES_VALUES then long(VALUE_NAME[LIST_AT])
                        else if COL = COL_MODELS_LABELS then long(LABEL_ORDERED_NAME[LIST_AT])
                        else if COL = COL_TABLE_VALUES then
                          (if DUMP_TABLE_NEW then long(WALK_REL) else if TABLE_FROM_STRING[R] then long(STRING_TEXT[LIST_AT]) else POOL_VALUE[LIST_AT])
                        else if FROM_INHERITED_PATH then long(FLAT_PATH_KEY[INHERITED_AT])
                        else if FLAT_PATH_COLUMN and not PATH_OF_USE then long(NODE_ON_KEY)
                        else long(PATH_VALUE[LIST_AT])
        | LIST_INSTANCE := if not FLAT_PATH_COLUMN then 0 else if FROM_INHERITED_PATH then FLAT_PATH_INSTANCE[INHERITED_AT]
                           else PATH_CONTEXT
        | LIST_CALL := FLAT_PATH_COLUMN and FROM_INHERITED_PATH and FLAT_PATH_CALL[INHERITED_AT]
        | LIST_KIND_SHOWN := if FLAT_PATH_COLUMN then LIST_NAMES else LIST_KIND
        | LIST_UNSIGNED := COL = COL_TABLE_VALUES and not DUMP_TABLE_NEW and TYPE_ELEMENT[TABLE_TYPE[R]] = BUILTIN_ULONG
        | MEMBER_TOTAL := if FLAT_DUMP then FLAT_GROUP_MEMBER_TOTAL[R] else if GROUP_FINISHED then 2 else GROUP_MEMBER_TOTAL[GROUP_SOURCE]
        | MEMBER_NOW := GROUP_MEMBER_FIRST[GROUP_SOURCE] + WALK_REL
        | FLAT_MEMBER_NOW := FLAT_GROUP_MEMBER_FIRST[R] + WALK_REL
        | WALK_MEMBER_ENTRY_START := if FLAT_DUMP then FLAT_MEMBER_START[FLAT_MEMBER_NOW]
                                     else if GROUP_FINISHED then FINISH_GROUP_FINAL[GROUP_FINISH_ROW] + WALK_REL
                                     else MEMBER_FINAL_START[MEMBER_NOW]
        | WALK_MEMBER_ENTRY_LENGTH := if FLAT_DUMP then FLAT_MEMBER_END[FLAT_MEMBER_NOW] - FLAT_MEMBER_START[FLAT_MEMBER_NOW]
                                      else if GROUP_FINISHED then 1 else MEMBER_FINAL_END[MEMBER_NOW] - MEMBER_FINAL_START[MEMBER_NOW]
        | IN_GROUP := SHAPE = SHAPE_GROUP
        | OPS_MODE := LIST_KIND = LIST_OPS or IN_GROUP and WALK_MEMBER_STEP = 2
        | ARGS_MODE := LIST_KIND = LIST_ARGS or IN_GROUP and WALK_MEMBER_STEP = 5
        | CONTENT_LENGTH := if SHAPE = SHAPE_LIST then RUN_LENGTH else if IN_GROUP then MEMBER_TOTAL else ROW_SCALAR_LENGTH
        | AT_NEWLINE := not AT_HEADER and WALK_REL >= CONTENT_LENGTH
        | ENTRY_AT := if IN_GROUP then WALK_MEMBER_ENTRY_START + WALK_INNER else LIST_AT
        | ENTRY_NOW := if FLAT_DUMP then FLAT_ENTRY_SOURCE[ENTRY_AT] else ENTRY_AT
        | ENTRY_OP_NOW := if FLAT_DUMP then FLAT_ENTRY_OP[ENTRY_AT] else FINAL_OP[ENTRY_NOW]
        | ENTRY_NAME_NOW := if FLAT_DUMP then FLAT_ENTRY_NAME[ENTRY_AT] else FINAL_NAME[ENTRY_NOW]
        | ENTRY_INSTANCE_NOW := if FLAT_DUMP then FLAT_ENTRY_INSTANCE[ENTRY_AT] else 0
        | ENTRY_AUX_NOW := FINAL_AUX[ENTRY_NOW]
        | ENTRY_TOKEN_NOW := FINAL_TOKEN[ENTRY_NOW]
        | ENTRY_TYPE_NOW := FINAL_TYPE[ENTRY_NOW]
        | ENTRY_VALUE_NOW := FINAL_VALUE[ENTRY_NOW]
        | IS_CALL_ENTRY := ENTRY_OP_NOW = OP_CALL or ENTRY_OP_NOW = OP_EFFECT
        | PARAMETER_TOTAL := FINAL_AUX2[ENTRY_NOW]
        | PARAMETER_LENGTH := if PARAMETER_TOTAL = 0 then 1 else PARAM_STEPS * PARAMETER_TOTAL + 2
        | PROGRAM_EXTRA := if IS_CALL_ENTRY then PARAMETER_LENGTH - 1 else 0
        | PSEUDO_OP := if ENTRY_OP_NOW = OP_DELAY then OP_TOTAL + ENTRY_AUX_NOW else ENTRY_OP_NOW
        | ARG_TOTAL := ARG_LENGTH[PSEUDO_OP] + PROGRAM_EXTRA
        | ENTRY_FINISHES := WALK_STEP >= ARG_TOTAL - 1
        | PARAMETER_OFFSET := WALK_STEP - CALL_PARAMS_STEP
        | IN_PARAMETERS := IS_CALL_ENTRY and PARAMETER_OFFSET >= 0 and PARAMETER_OFFSET < PARAMETER_LENGTH
        | PROGRAM_STEP := if IS_CALL_ENTRY and PARAMETER_OFFSET >= PARAMETER_LENGTH then WALK_STEP - PROGRAM_EXTRA else WALK_STEP
        | ARG_ATOM := ARG_PROGRAM[PSEUDO_OP * ARG_WIDTH + PROGRAM_STEP]
        | PARAMETER_INDEX := (PARAMETER_OFFSET - 1) / PARAM_STEPS
        | PARAMETER_PART := (PARAMETER_OFFSET - 1) - PARAM_STEPS * PARAMETER_INDEX
        | PARAMETER_TOKEN := ENTRY_AUX_NOW + 2 * PARAMETER_INDEX
        | PARAMETER_EDGE := PARAMETER_OFFSET = 0 or PARAMETER_OFFSET = PARAMETER_LENGTH - 1
        | PARAMETER_CLASS := if PARAMETER_TOTAL = 0 then IC_FRAGMENT
                             else if PARAMETER_OFFSET = 0 or PARAMETER_PART = 0 and not PARAMETER_EDGE then IC_OPEN
                             else if PARAMETER_EDGE or PARAMETER_PART = 5 then IC_CLOSE
                             else if PARAMETER_PART = 1 then IC_TOKEN
                             else if PARAMETER_PART = 2 then IC_FRAGMENT else IC_NUMBER
        | PARAMETER_TAG := if PARAMETER_TOTAL = 0 then F_EMPTY_LIST else KIND_FRAGMENT[integer(TOKEN_KIND[PARAMETER_TOKEN])]
        | PARAMETER_VALUE := if PARAMETER_PART = 1 then long(PARAMETER_TOKEN)
                             else if PARAMETER_PART = 3 then long(TOKEN_LINE[PARAMETER_TOKEN]) else long(TOKEN_COLUMN[PARAMETER_TOKEN])
        | ARG_CLASS := if IN_PARAMETERS then PARAMETER_CLASS
                       else if ARG_ATOM = AA_OPEN then IC_OPEN
                       else if ARG_ATOM = AA_CLOSE then IC_CLOSE
                       else if ARG_ATOM = AA_NAME or ARG_ATOM = AA_TYPE_NAME or ARG_ATOM = AA_VALUE_NAME then IC_NAME
                       else if ARG_ATOM = AA_NONE or ARG_ATOM = AA_CONST or ARG_ATOM = AA_ENUMCONST then IC_FRAGMENT
                       else IC_NUMBER
        | ARG_TAG := if IN_PARAMETERS then PARAMETER_TAG
                     else if ARG_ATOM = AA_NONE then F_NONE
                     else if ARG_ATOM = AA_CONST then OP_FRAGMENT[OP_CONST]
                     else if ARG_ATOM = AA_ENUMCONST then OP_FRAGMENT[OP_ENUMCONST]
                     else integer(ARG_ATOM = AA_VALUE and ENTRY_TYPE_NOW = BUILTIN_ULONG)
        | ARG_VALUE := if IN_PARAMETERS then PARAMETER_VALUE
                       else if ARG_ATOM = AA_NAME then long(ENTRY_NAME_NOW)
                       else if ARG_ATOM = AA_LINE then long(TOKEN_LINE[ENTRY_TOKEN_NOW])
                       else if ARG_ATOM = AA_COLUMN then long(TOKEN_COLUMN[ENTRY_TOKEN_NOW])
                       else if ARG_ATOM = AA_TYPE_NUMBER or ARG_ATOM = AA_TYPE_NAME then long(ENTRY_TYPE_NOW)
                       else if ARG_ATOM = AA_INIT_LINE then long(TOKEN_LINE[FINAL_AUX2[ENTRY_NOW]])
                       else if ARG_ATOM = AA_INIT_COLUMN then long(TOKEN_COLUMN[FINAL_AUX2[ENTRY_NOW]])
                       else ENTRY_VALUE_NOW
        | SCALAR_ATOM := SCALAR_PROGRAM[SHAPE * SCALAR_WIDTH + WALK_REL]
        | TYPE_SHOWN := if SCALAR_ATOM = SA_TYPE_ELEMENT then DUMP_TYPE_ELEMENT else R
        | SCALAR_CLASS := if SCALAR_ATOM = SA_NAME or SCALAR_ATOM = SA_TYPE_ELEMENT then IC_NAME
                          else if SCALAR_ATOM = SA_TYPE_HEAD then (if ROW_IS_ARRAY then IC_SIZE else IC_NAME)
                          else if SCALAR_ATOM = SA_FRAGMENT then IC_FRAGMENT else IC_NUMBER
        | SCALAR_TAG := if SCALAR_ATOM = SA_FRAGMENT then ROW_FRAGMENT
                        else if SCALAR_ATOM = SA_TYPE_HEAD or SCALAR_ATOM = SA_TYPE_ELEMENT then integer(TYPE_STATE[TYPE_SHOWN])
                        else integer(ROW_UNSIGNED)
        | SCALAR_VALUE := if SCALAR_ATOM = SA_NAME then long(WALK_ROW_KEY)
                          else if SCALAR_ATOM = SA_LINE then long(TOKEN_LINE[WALK_ROW_TOKEN])
                          else if SCALAR_ATOM = SA_COLUMN then long(TOKEN_COLUMN[WALK_ROW_TOKEN])
                          else if SCALAR_CLASS = IC_SIZE then long(DUMP_TYPE_SIZE)
                          else if SCALAR_CLASS = IC_NAME then
                            long(if TYPE_STATE[TYPE_SHOWN] then MODEL_NAME[TYPE_NAME[TYPE_SHOWN]] else TYPE_NAME[TYPE_SHOWN])
                          else ROW_NUMBER_VALUE
        | BRACKET_OPENS := WALK_MEMBER_STEP = 0 or WALK_MEMBER_STEP = 1 or WALK_MEMBER_STEP = 4
        | ITEM_CLASS_NOW := if AT_HEADER then IC_HEADER
                            else if AT_NEWLINE then IC_NEWLINE
                            else if OPS_MODE then IC_FRAGMENT
                            else if ARGS_MODE then ARG_CLASS
                            else if IN_GROUP then (if BRACKET_OPENS then IC_OPEN else IC_CLOSE)
                            else if SHAPE = SHAPE_LIST then (if LIST_KIND_SHOWN = LIST_NAMES then IC_NAME else IC_NUMBER)
                            else SCALAR_CLASS
        | ITEM_TAG_NOW := if AT_HEADER then COLUMN_FRAGMENT[COL]
                          else if OPS_MODE then OP_FRAGMENT[ENTRY_OP_NOW]
                          else if ARGS_MODE then ARG_TAG
                          else if SHAPE = SHAPE_LIST then integer(LIST_UNSIGNED)
                          else SCALAR_TAG
        | ITEM_VALUE_NOW := if AT_HEADER then long(COLUMN_ROWS)
                            else if ARGS_MODE then ARG_VALUE
                            else if SHAPE = SHAPE_LIST then LIST_VALUE
                            else SCALAR_VALUE
        | NAME_INSTANCE_NOW := if ARGS_MODE then (if not IN_PARAMETERS and ARG_ATOM = AA_NAME then ENTRY_INSTANCE_NOW else 0)
                               else if SHAPE = SHAPE_LIST then LIST_INSTANCE else WALK_ROW_INSTANCE
        | NAME_CALL_NOW := if SHAPE = SHAPE_LIST then LIST_CALL else not ARGS_MODE and WALK_ROW_CALL
        | PREFIX_DUE := WALKING and ITEM_CLASS_NOW = IC_NAME and ITEM_VALUE_NOW >= long(0) and NAME_INSTANCE_NOW > 0
                        and not WALK_PREFIXED[?]
        | WALK_PREFIXED := PREFIX_DUE
        | EMITTED_CLASS := if PREFIX_DUE then IC_PREFIX else ITEM_CLASS_NOW
        | EMITTED_TAG := if PREFIX_DUE then 0 else if ITEM_CLASS_NOW = IC_NAME and NAME_CALL_NOW then 2 else ITEM_TAG_NOW
        | EMITTED_VALUE := if PREFIX_DUE then long(NAME_INSTANCE_NOW) else ITEM_VALUE_NOW
        | INNER_LAST := WALK_INNER >= WALK_MEMBER_ENTRY_LENGTH - 1
        | MEMBER_FINISHES := WALK_MEMBER_STEP = 7
        | ELEMENT_FINISHES := not PREFIX_DUE and (if IN_GROUP then MEMBER_FINISHES else if ARGS_MODE then ENTRY_FINISHES else true)
        | ROW_ENDS := AT_HEADER or AT_NEWLINE
        | FOLLOWING_ROW := if AT_HEADER then 0 else R + 1
        | LEAVES_COLUMN := ROW_ENDS and FOLLOWING_ROW >= COLUMN_ROWS
        | WALK_COLUMN := if WALKING and LEAVES_COLUMN then WALK_COLUMN_NOW + 1 else WALK_COLUMN_NOW
        | WALK_ROW := if not WALKING or not ROW_ENDS then WALK_ROW_NOW else if LEAVES_COLUMN then -1 else FOLLOWING_ROW
        | WALK_POSITION := if ROW_ENDS then 0 else WALK_REL + integer(ELEMENT_FINISHES)
        | WALK_STEP_POSITION := if PREFIX_DUE then WALK_STEP else if ROW_ENDS or not ARGS_MODE or ENTRY_FINISHES then 0 else WALK_STEP + 1
        | WALK_MEMBER_POSITION := if PREFIX_DUE then WALK_MEMBER_STEP else if ROW_ENDS or not IN_GROUP or MEMBER_FINISHES then 0
                                  else if WALK_MEMBER_STEP = 2 then (if INNER_LAST then 3 else 2)
                                  else if WALK_MEMBER_STEP = 5 then (if ENTRY_FINISHES and INNER_LAST then 6 else 5)
                                  else WALK_MEMBER_STEP + 1
        | WALK_INNER_POSITION := if PREFIX_DUE then WALK_INNER else if ROW_ENDS or not IN_GROUP then 0
                                 else if WALK_MEMBER_STEP = 2 or WALK_MEMBER_STEP = 5 and ENTRY_FINISHES then
                                   (if INNER_LAST then 0 else WALK_INNER + 1)
                                 else WALK_INNER
        | DUMP_SLOT := if WALKING then DUMP_COUNT[?] else -1
        | DUMP_CLASS := DUMP_CLASS[?] next DUMP_SLOT : EMITTED_CLASS
        | DUMP_TAG := DUMP_TAG[?] next DUMP_SLOT : EMITTED_TAG
        | DUMP_VALUE := DUMP_VALUE[?] next DUMP_SLOT : EMITTED_VALUE
        | DUMP_SEPARATES := DUMP_SEPARATES[?] next DUMP_SLOT
                            : WALK_JOINS[?] and EMITTED_CLASS /= IC_HEADER and EMITTED_CLASS /= IC_NEWLINE and EMITTED_CLASS /= IC_CLOSE
        | DUMP_COUNT := DUMP_COUNT[?] + integer(WALKING)
        | WALK_JOINS := if not WALKING then WALK_JOINS[?]
                        else EMITTED_CLASS /= IC_HEADER and EMITTED_CLASS /= IC_NEWLINE and EMITTED_CLASS /= IC_OPEN
                             and EMITTED_CLASS /= IC_SIZE and EMITTED_CLASS /= IC_PREFIX
        |)
     with (| WALK_COLUMN := DUMP_COLUMN_START | WALK_ROW := -1 | WALK_POSITION := 0 | WALK_INNER_POSITION := 0 | WALK_STEP_POSITION := 0
           | WALK_MEMBER_POSITION := 0 | DUMP_COUNT := 0 | WALK_JOINS := false | WALK_PREFIXED := false |)
     end
   | DUMP_OVERFLOW := DUMP_RUNS and (WALK_COLUMN < DUMP_COLUMN_END or DUMP_COUNT > ITEM_CAP or DUMP_SIGNAL_COUNT > SIGNAL_CAP
                                     or DUMP_EQUATION_COUNT > EQUATION_CAP or DUMP_GROUP_COUNT > GROUP_CAP)
   | FRONT_MESSAGE := if PASS_MESSAGE /= 0 then PASS_MESSAGE else if INSTANTIATE_FAILED then INSTANTIATE_MESSAGE
                      else if INSTANTIATE_INCOMPLETE then T_CAPACITY else if LOWER_FAILED then LW_MESSAGE
                      else if LOWER_INCOMPLETE then T_CAPACITY else if POST_FAILED then PO_MESSAGE
                      else if POST_INCOMPLETE or EXPAND_FAILED or EXPAND_INCOMPLETE then T_CAPACITY else CLOCK_MESSAGE
   | MESSAGE := if FRONT_MESSAGE /= 0 then FRONT_MESSAGE else if DUMP_OVERFLOW or IMAGE_TOO_BIG then T_CAPACITY else 0
   | MESSAGE_ARGUMENT0 := if FRONT_MESSAGE /= 0 then PASS_ARGUMENT0 else if DUMP_OVERFLOW then F_CAP_ITEMS else F_CAP_OUTPUT
   | LAYOUT := if not BUFFER_OK then LAYOUT_NONE else if ERRNO /= 0 then LAYOUT_OS
               else if UTF8_FAILED then (if UV_FAIL_END - UV_FAIL_AT = 1 then LAYOUT_UTF8_BYTE else LAYOUT_UTF8_BYTES)
               else if DUMP_PASS = 1 or DUMP_PASS = 2 or DUMP_PASS = 3 or DUMP_PASS = 4 or DUMP_PASS = 5 or DUMP_PASS = 6 or CODE_DUMP then
                 (if MESSAGE /= 0 then LAYOUT_DUMP_ERROR else if DUMP_PASS = 1 then LAYOUT_DUMP_TOKENS
                  else if CODE_DUMP then LAYOUT_DUMP_CODE else LAYOUT_DUMP_PROGRAM)
               else if MESSAGE /= 0 then LAYOUT_COMPILE else if EN_FAILED then LAYOUT_ENCODE
               else if OUTPUT_ERRNO /= 0 then LAYOUT_OS_OUTPUT else if IMAGE_GO and ROOT_COUNT >= 2 and PLATFORM = PLATFORM_MACOS then LAYOUT_PRESENCE
               else LAYOUT_NONE
   | DUMPS_TOKENS := LAYOUT = LAYOUT_DUMP_TOKENS
   | DUMPS_PROGRAM := LAYOUT = LAYOUT_DUMP_PROGRAM
   | ITEM_COUNT := if DUMPS_TOKENS then 4 * (TOKEN_COUNT + 1) else if DUMPS_PROGRAM then DUMP_COUNT else LAYOUT_ITEM_COUNT[LAYOUT]
   | USES_ROWS := not DUMPS_TOKENS and not DUMPS_PROGRAM
   | ITEM_INDEX := 0 .. ITEM_COUNT - 1
   | iterate ITEM_INDEX of
       (| SECTION := ITEM_INDEX / (TOKEN_COUNT + 1)
        | TOKEN := ITEM_INDEX modulo (TOKEN_COUNT + 1) - 1
        | IS_HEADER := TOKEN < 0
        | KIND := integer(TOKEN_KIND[TOKEN])
        | ROW := if USES_ROWS then LAYOUT_FIRST_ROW[LAYOUT] + ITEM_INDEX else 0
        | SLOT := if USES_ROWS then ROW_SLOT[ROW] else -1
        | PROGRAM_CLASS := if DUMPS_PROGRAM then DUMP_CLASS[ITEM_INDEX] else -1
        | PROGRAM_TAG := DUMP_TAG[ITEM_INDEX]
        | PROGRAM_VALUE := DUMP_VALUE[ITEM_INDEX]
        | PROGRAM_KEY := integer(PROGRAM_VALUE)
        | PROGRAM_NAME := PROGRAM_CLASS = IC_NAME and PROGRAM_VALUE >= long(0)
        | PROGRAM_NONE := PROGRAM_CLASS = IC_NAME and PROGRAM_VALUE < long(0)
        | PROGRAM_PREFIX := PROGRAM_CLASS = IC_PREFIX
        | PROGRAM_BASE := PROGRAM_KEY modulo NAME_CAP
        | PROGRAM_SUFFIX := PROGRAM_KEY / NAME_CAP
        | PROGRAM_SUFFIXED := PROGRAM_NAME and PROGRAM_SUFFIX > 0
        | PROGRAM_NUMBERED := PROGRAM_CLASS = IC_HEADER or PROGRAM_CLASS = IC_NUMBER or PROGRAM_CLASS = IC_SIZE
        | PROGRAM_UNSIGNED := PROGRAM_CLASS = IC_NUMBER and PROGRAM_TAG = 1 or PROGRAM_CLASS = IC_SIZE
        | IS_PIECE := SLOT >= 0 and SLOT modulo 3 = 0
        | IS_ARGUMENT := SLOT >= 0 and SLOT modulo 3 /= 0
        | IS_ROW := USES_ROWS and SLOT < 0
        | ARGUMENT := (SLOT - 1) / 3
        | FIRST_HALF := (SLOT - 1) modulo 3 = 0
        | PIECE := if SLOT = 0 then TEMPLATE_PIECE0[MESSAGE] else if SLOT = 3 then TEMPLATE_PIECE1[MESSAGE]
                   else if SLOT = 6 then TEMPLATE_PIECE2[MESSAGE] else TEMPLATE_PIECE3[MESSAGE]
        | ARGUMENT_KIND := if not IS_ARGUMENT then A_NONE else if ARGUMENT = 0 then TEMPLATE_KIND0[MESSAGE]
                           else if ARGUMENT = 1 then TEMPLATE_KIND1[MESSAGE] else TEMPLATE_KIND2[MESSAGE]
        | ARGUMENT_VALUE := if ARGUMENT = 0 then MESSAGE_ARGUMENT0 else if ARGUMENT = 1 then MESSAGE_ARGUMENT1 else MESSAGE_ARGUMENT2
        | ARGUMENT_EOF := TOKEN_KIND[ARGUMENT_VALUE] = ubyte(KIND_EOF)
        | NAME_BASE := ARGUMENT_VALUE modulo NAME_CAP
        | NAME_SUFFIX := ARGUMENT_VALUE / NAME_CAP
        | TYPE_ARGUMENT := ARGUMENT_KIND = A_TYPE
        | ARGUMENT_TYPE_NEW := ARGUMENT_VALUE >= TYPE_COUNT
        | ARGUMENT_TYPE_ARRAY := TYPE_ARGUMENT and (ARGUMENT_TYPE_NEW or TYPE_KIND[ARGUMENT_VALUE] = TK_ARRAY)
        | NAMED_TYPE := if not ARGUMENT_TYPE_ARRAY then ARGUMENT_VALUE
                        else if ARGUMENT_TYPE_NEW then NEW_TYPE_ELEMENT[ARGUMENT_VALUE - TYPE_COUNT] else TYPE_ELEMENT[ARGUMENT_VALUE]
        | FLAT_PREFIX := IS_ARGUMENT and FIRST_HALF and ARGUMENT_KIND = A_FLAT and MESSAGE_INSTANCE > 0
        | NAME_HALF := IS_ARGUMENT and (FIRST_HALF and ARGUMENT_KIND = A_NAME or not FIRST_HALF and ARGUMENT_KIND = A_FLAT)
        | PREFIX_INSTANCE := if PROGRAM_PREFIX then PROGRAM_KEY else MESSAGE_INSTANCE
        | LONG_ARGUMENT := IS_ARGUMENT and FIRST_HALF and ARGUMENT_KIND = A_LONG
        | NAMED_TYPE_NAME := if TYPE_STATE[NAMED_TYPE] then MODEL_NAME[TYPE_NAME[NAMED_TYPE]] else TYPE_NAME[NAMED_TYPE]
        | SLICES_TYPE_NAME := TYPE_ARGUMENT and IS_ARGUMENT and FIRST_HALF /= ARGUMENT_TYPE_ARRAY
        | PRINTS_TYPE_SIZE := ARGUMENT_TYPE_ARRAY and FIRST_HALF
        | SLICES_NAME := NAME_HALF or FIRST_HALF and ARGUMENT_KIND = A_CODE and ARGUMENT_VALUE < C_SYMBOL_BASE
                         or SLICES_TYPE_NAME or PROGRAM_NAME or PROGRAM_PREFIX or FLAT_PREFIX
        | SLICED_NAME := if PROGRAM_PREFIX or FLAT_PREFIX then MODEL_NAME[INSTANCE_MODEL[PREFIX_INSTANCE]] else if PROGRAM_NAME then PROGRAM_BASE else if ARGUMENT_KIND = A_CODE then ARGUMENT_VALUE - 1
                         else if TYPE_ARGUMENT then NAMED_TYPE_NAME else NAME_BASE
        | QUOTES_TOKEN := FIRST_HALF and ARGUMENT_KIND = A_TOKEN and not ARGUMENT_EOF
        | SLICES_LITERAL := FIRST_HALF and ARGUMENT_KIND = A_LITERAL
        | SLICES_TEXT := IS_ARGUMENT and FIRST_HALF and ARGUMENT_KIND = A_TEXT
        | SLICES_TOKEN := DUMPS_TOKENS and not IS_HEADER and SECTION = 1 or QUOTES_TOKEN or SLICES_LITERAL or PROGRAM_CLASS = IC_TOKEN
                          or SLICES_TEXT
        | SLICED_TOKEN := if DUMPS_TOKENS then TOKEN else if DUMPS_PROGRAM then PROGRAM_KEY else ARGUMENT_VALUE
        | SLICES_CHARACTER := FIRST_HALF and ARGUMENT_KIND = A_CHARACTER
        | SLICES_CLOCK := IS_ARGUMENT and FIRST_HALF and ARGUMENT_KIND = A_CLOCK or IS_ROW and ROW_SLICE[ROW] = ROW_SLICE_CLOCK
        | ARGUMENT_CLOCK_START := if CE_LIST or ARGUMENT = 0 then 0 else CI_END[ARGUMENT - 1]
        | ARGUMENT_CLOCK_LENGTH := if CE_LIST then CJ_POSITION else CI_END[ARGUMENT] - ARGUMENT_CLOCK_START
        | ROW_NUMBER_KIND := if IS_ROW then ROW_NUMBER[ROW] else ROW_NUMBER_NONE
        | HAS_NUMBER := DUMPS_TOKENS and (IS_HEADER or SECTION >= 2) or ROW_NUMBER_KIND /= ROW_NUMBER_NONE
                        or FIRST_HALF and ARGUMENT_KIND = A_NUMBER or NAME_HALF and NAME_SUFFIX > 0 or PRINTS_TYPE_SIZE
                        or PROGRAM_NUMBERED or PROGRAM_SUFFIXED or PROGRAM_PREFIX or FLAT_PREFIX or LONG_ARGUMENT
        | NUMBER := if DUMPS_TOKENS then
                      (if IS_HEADER then long(TOKEN_COUNT) else if SECTION = 2 then long(TOKEN_LINE[TOKEN]) else long(TOKEN_COLUMN[TOKEN]))
                    else if PROGRAM_NUMBERED then PROGRAM_VALUE
                    else if PROGRAM_SUFFIXED then long(PROGRAM_SUFFIX)
                    else if PROGRAM_PREFIX or FLAT_PREFIX then long(INSTANCE_ORDINAL[PREFIX_INSTANCE])
                    else if ROW_NUMBER_KIND = ROW_NUMBER_ERROR_LINE then long(MESSAGE_LINE)
                    else if ROW_NUMBER_KIND = ROW_NUMBER_ERROR_COLUMN then long(MESSAGE_COLUMN)
                    else if ROW_NUMBER_KIND = ROW_NUMBER_ERRNO then long(ERRNO)
                    else if ROW_NUMBER_KIND = ROW_NUMBER_OUTPUT_ERRNO then long(OUTPUT_ERRNO)
                    else if ROW_NUMBER_KIND = ROW_NUMBER_UTF8_START then long(UV_FAIL_AT)
                    else if ROW_NUMBER_KIND = ROW_NUMBER_UTF8_LAST then long(UV_FAIL_END - 1)
                    else if ROW_NUMBER_KIND = ROW_NUMBER_ENCODE_OP0 then EN_FAIL_OP0
                    else if ROW_NUMBER_KIND = ROW_NUMBER_ENCODE_OP1 then EN_FAIL_OP1
                    else if ROW_NUMBER_KIND = ROW_NUMBER_ENCODE_OP2 then EN_FAIL_OP2
                    else if ROW_NUMBER_KIND = ROW_NUMBER_ENCODE_OP3 then EN_FAIL_OP3
                    else if NAME_HALF then long(NAME_SUFFIX)
                    else if LONG_ARGUMENT then (if ARGUMENT = 0 then LW_LONG0 else LW_LONG1)
                    else if TYPE_ARGUMENT then
                      long(if ARGUMENT_TYPE_NEW then NEW_TYPE_SIZE[ARGUMENT_VALUE - TYPE_COUNT] else TYPE_SIZE[ARGUMENT_VALUE])
                    else long(ARGUMENT_VALUE)
        | PREFIX := if DUMPS_TOKENS then (if IS_HEADER then SECTION_FRAGMENT[SECTION] else if SECTION = 0 then KIND_FRAGMENT[KIND] else 0)
                    else if DUMPS_PROGRAM then
                      (if PROGRAM_CLASS = IC_HEADER or PROGRAM_CLASS = IC_FRAGMENT then PROGRAM_TAG
                       else if PROGRAM_CLASS = IC_OPEN or PROGRAM_CLASS = IC_SIZE then F_OPEN
                       else if PROGRAM_CLASS = IC_CLOSE then F_CLOSE
                       else if PROGRAM_NONE then F_NONE else 0)
                    else if IS_ROW then
                      (if ROW_PREFIX[ROW] = ROW_PREFIX_FORM_NAME then FORM_NAME_FRAGMENT[EN_FAIL_FORM]
                       else if ROW_PREFIX[ROW] = ROW_PREFIX_HEX_BYTE then HEX_FRAGMENT[integer(SRC[if UV_FAIL_AT >= 0 then UV_FAIL_AT else 0])]
                       else if ROW_PREFIX[ROW] = ROW_PREFIX_UTF8_REASON then UTF8_REASON_FRAGMENT[UV_FAIL_REASON] else ROW_PREFIX[ROW])
                    else if IS_PIECE then PIECE
                    else if not FIRST_HALF then 0
                    else if PRINTS_TYPE_SIZE then F_OPEN
                    else if ARGUMENT_KIND = A_TOKEN then (if ARGUMENT_EOF then F_END_OF_FILE else F_QUOTE)
                    else if ARGUMENT_KIND = A_FRAGMENT then ARGUMENT_VALUE
                    else if ARGUMENT_KIND = A_CODE and ARGUMENT_VALUE >= C_SYMBOL_BASE then SYMBOL_FRAGMENT[ARGUMENT_VALUE - C_SYMBOL_BASE]
                    else 0
        | SLICE_OUTPUT_PATH := IS_ROW and ROW_SLICE[ROW] = ROW_SLICE_OUTPUT_PATH
        | SLICE_PATH := IS_ROW and ROW_SLICE[ROW] = ROW_SLICE_PATH or SLICE_OUTPUT_PATH
        | SLICE_START := if SLICES_TOKEN then SEED_LENGTH + TOKEN_START[SLICED_TOKEN]
                         else if SLICES_CHARACTER then SEED_LENGTH + ARGUMENT_VALUE
                         else if SLICES_NAME then NAME_AT[SLICED_NAME]
                         else if SLICES_CLOCK then ARGUMENT_CLOCK_START else if SLICE_OUTPUT_PATH then ARG_CAP else 0
        | SLICE_LENGTH := if SLICES_LITERAL then (if TOKEN_LENGTH[SLICED_TOKEN] > 20 then 20 else TOKEN_LENGTH[SLICED_TOKEN])
                          else if SLICES_TOKEN then TOKEN_LENGTH[SLICED_TOKEN]
                          else if SLICES_CHARACTER then ERROR_CHARACTER_LENGTH
                          else if SLICES_NAME then NAME_LENGTH[SLICED_NAME]
                          else if SLICES_CLOCK then ARGUMENT_CLOCK_LENGTH
                          else if SLICE_OUTPUT_PATH then OUTPUT_NAME_LENGTH else if SLICE_PATH then SOURCE_NAME_LENGTH else 0
        | FOLDS := SLICES_TOKEN and not SLICES_TEXT and TOKEN_KIND[SLICED_TOKEN] = ubyte(KIND_KEYWORD)
        | INFIX := if PROGRAM_PREFIX or FLAT_PREFIX then F_HASH else if PROGRAM_NAME and PROGRAM_TAG = 1 then F_STATE_SUFFIX
                   else if PROGRAM_SUFFIXED then (if PROGRAM_BASE /= N_ON_MARK and (PROGRAM_BASE < N_FRESH_FIRST or PROGRAM_BASE > N_FRESH_LAST) then F_QUOTE else 0)
                   else if SLICES_TYPE_NAME and TYPE_STATE[NAMED_TYPE] then F_STATE_SUFFIX
                   else if NAME_HALF and NAME_SUFFIX > 0 and NAME_BASE /= N_ON_MARK and (NAME_BASE < N_FRESH_FIRST or NAME_BASE > N_FRESH_LAST) then F_QUOTE else 0
        | SUFFIX := if DUMPS_TOKENS then 0 else if DUMPS_PROGRAM then
                      (if PROGRAM_CLASS = IC_SIZE then F_SIZE_CLOSE else if PROGRAM_PREFIX then F_DOT
                       else if PROGRAM_NAME and PROGRAM_TAG = 2 then F_CALL_SUFFIX else 0)
                    else if IS_ROW then ROW_SUFFIX[ROW]
                    else if QUOTES_TOKEN then F_QUOTE
                    else if FLAT_PREFIX then F_DOT
                    else if PRINTS_TYPE_SIZE then F_SIZE_CLOSE
                    else if SLICES_LITERAL and TOKEN_LENGTH[SLICED_TOKEN] > 20 then F_ELLIPSIS else 0
        | NEWLINE := DUMPS_TOKENS or IS_ROW and ROW_NEWLINE[ROW] = 1 or PROGRAM_CLASS = IC_HEADER or PROGRAM_CLASS = IC_NEWLINE
        | SEPARATES := DUMPS_PROGRAM and DUMP_SEPARATES[ITEM_INDEX]
        | NEGATIVE := HAS_NUMBER and NUMBER < long(0) and not PROGRAM_UNSIGNED and not TYPE_ARGUMENT
                      and not (LONG_ARGUMENT and (ARGUMENT = 1 or LW_LONG0_UNSIGNED))
        | MAGNITUDE := if NEGATIVE then ulong(-NUMBER) else ulong(NUMBER)
        | DIGITS := if not HAS_NUMBER then 0
                    else 1 + integer(MAGNITUDE >= POWERS_OF_TEN[1]) + integer(MAGNITUDE >= POWERS_OF_TEN[2])
                         + integer(MAGNITUDE >= POWERS_OF_TEN[3]) + integer(MAGNITUDE >= POWERS_OF_TEN[4])
                         + integer(MAGNITUDE >= POWERS_OF_TEN[5]) + integer(MAGNITUDE >= POWERS_OF_TEN[6])
                         + integer(MAGNITUDE >= POWERS_OF_TEN[7]) + integer(MAGNITUDE >= POWERS_OF_TEN[8])
                         + integer(MAGNITUDE >= POWERS_OF_TEN[9]) + integer(MAGNITUDE >= POWERS_OF_TEN[10])
                         + integer(MAGNITUDE >= POWERS_OF_TEN[11]) + integer(MAGNITUDE >= POWERS_OF_TEN[12])
                         + integer(MAGNITUDE >= POWERS_OF_TEN[13]) + integer(MAGNITUDE >= POWERS_OF_TEN[14])
                         + integer(MAGNITUDE >= POWERS_OF_TEN[15]) + integer(MAGNITUDE >= POWERS_OF_TEN[16])
                         + integer(MAGNITUDE >= POWERS_OF_TEN[17]) + integer(MAGNITUDE >= POWERS_OF_TEN[18])
                         + integer(MAGNITUDE >= POWERS_OF_TEN[19])
        | ITEM_LENGTH := integer(SEPARATES) + FRAGMENT_LENGTH[PREFIX] + SLICE_LENGTH + FRAGMENT_LENGTH[INFIX] + DIGITS
                         + integer(NEGATIVE) + FRAGMENT_LENGTH[SUFFIX] + integer(NEWLINE)
        | WRITE_SLOT := if ITEM_LENGTH > 0 then ITEM_POSITION[?] else -1
        | ITEM_POSITION := ITEM_POSITION[?] + integer(ITEM_LENGTH > 0)
        | ITEM_SEPARATES := ITEM_SEPARATES[?] next WRITE_SLOT : SEPARATES
        | ITEM_PREFIX := ITEM_PREFIX[?] next WRITE_SLOT : PREFIX
        | ITEM_FROM_PATH := ITEM_FROM_PATH[?] next WRITE_SLOT : SLICE_PATH
        | ITEM_FROM_CLOCK := ITEM_FROM_CLOCK[?] next WRITE_SLOT : SLICES_CLOCK
        | ITEM_SLICE_START := ITEM_SLICE_START[?] next WRITE_SLOT : SLICE_START
        | ITEM_SLICE_LENGTH := ITEM_SLICE_LENGTH[?] next WRITE_SLOT : SLICE_LENGTH
        | ITEM_FOLDS := ITEM_FOLDS[?] next WRITE_SLOT : FOLDS
        | ITEM_INFIX := ITEM_INFIX[?] next WRITE_SLOT : INFIX
        | ITEM_MAGNITUDE := ITEM_MAGNITUDE[?] next WRITE_SLOT : MAGNITUDE
        | ITEM_NEGATIVE := ITEM_NEGATIVE[?] next WRITE_SLOT : NEGATIVE
        | ITEM_DIGITS := ITEM_DIGITS[?] next WRITE_SLOT : DIGITS
        | ITEM_SUFFIX := ITEM_SUFFIX[?] next WRITE_SLOT : SUFFIX
        | ITEM_NEWLINE := ITEM_NEWLINE[?] next WRITE_SLOT : NEWLINE
        | TOTAL := TOTAL[?] + ITEM_LENGTH
        | ITEM_END := ITEM_END[?] next WRITE_SLOT : TOTAL
        |)
     with (| TOTAL := 0 | ITEM_POSITION := 0 |)
     end
   | OUTPUT_FITS := TEXT_AT + TOTAL <= NAMES_AT
   | OUTPUT_LENGTH := if OUTPUT_FITS then TOTAL else FRAGMENT_LENGTH[F_OUTPUT_FULL] + 1
   | OUTPUT_INDEX := 0 .. OUTPUT_LENGTH - 1
   | iterate OUTPUT_INDEX of
       (| CURRENT := if OUTPUT_INDEX >= ITEM_END[CURRENT[?]] then CURRENT[?] + 1 else CURRENT[?]
        | OFFSET := OUTPUT_INDEX - ITEM_END[CURRENT - 1]
        | SEPARATOR_END := integer(ITEM_SEPARATES[CURRENT])
        | PREFIX_END := SEPARATOR_END + FRAGMENT_LENGTH[ITEM_PREFIX[CURRENT]]
        | SLICE_END := PREFIX_END + ITEM_SLICE_LENGTH[CURRENT]
        | INFIX_END := SLICE_END + FRAGMENT_LENGTH[ITEM_INFIX[CURRENT]]
        | SIGN_END := INFIX_END + integer(ITEM_NEGATIVE[CURRENT])
        | DIGITS_END := SIGN_END + ITEM_DIGITS[CURRENT]
        | SUFFIX_END := DIGITS_END + FRAGMENT_LENGTH[ITEM_SUFFIX[CURRENT]]
        | SLICE_AT := ITEM_SLICE_START[CURRENT] + OFFSET - PREFIX_END
        | SLICE_BYTE := if ITEM_FROM_PATH[CURRENT] then (if SLICE_AT >= ARG_CAP then OUTPUT_NAME[SLICE_AT - ARG_CAP] else SOURCE_NAME[SLICE_AT])
                        else if ITEM_FROM_CLOCK[CURRENT] then CLOCK_TEXT[SLICE_AT]
                        else if SLICE_AT < SEED_LENGTH then SEED[SLICE_AT] else SRC[SLICE_AT - SEED_LENGTH]
        | DIGIT := ITEM_MAGNITUDE[CURRENT] / POWERS_OF_TEN[DIGITS_END - 1 - OFFSET] modulo ulong(10)
        | OUTPUT_ITEM_BYTE := if OFFSET < SEPARATOR_END then ubyte(32)
                         else if OFFSET < PREFIX_END then FRAGMENTS[FRAGMENT_START[ITEM_PREFIX[CURRENT]] + OFFSET - SEPARATOR_END]
                         else if OFFSET < SLICE_END then
                           (if ITEM_FOLDS[CURRENT] and SLICE_BYTE >= ubyte(65) and SLICE_BYTE <= ubyte(90) then SLICE_BYTE + ubyte(32) else SLICE_BYTE)
                         else if OFFSET < INFIX_END then FRAGMENTS[FRAGMENT_START[ITEM_INFIX[CURRENT]] + OFFSET - SLICE_END]
                         else if OFFSET < SIGN_END then ubyte(45)
                         else if OFFSET < DIGITS_END then ubyte(DIGIT + ulong(48))
                         else if OFFSET < SUFFIX_END then FRAGMENTS[FRAGMENT_START[ITEM_SUFFIX[CURRENT]] + OFFSET - DIGITS_END]
                         else ubyte(10)
        | OUTPUT_BYTE := if OUTPUT_FITS then OUTPUT_ITEM_BYTE
                         else if OUTPUT_INDEX < FRAGMENT_LENGTH[F_OUTPUT_FULL] then FRAGMENTS[FRAGMENT_START[F_OUTPUT_FULL] + OUTPUT_INDEX]
                         else ubyte(10)
        | store{OUTPUT, ubyte}(OUTPUT_BASE + TEXT_AT + OUTPUT_INDEX, OUTPUT_BYTE)
        |)
     with CURRENT := 0
     end
   | DUMPING := LAYOUT = LAYOUT_DUMP_TOKENS or LAYOUT = LAYOUT_DUMP_ERROR or LAYOUT = LAYOUT_DUMP_PROGRAM or LAYOUT = LAYOUT_DUMP_CODE
              or DUMP_PASS /= 0 and (LAYOUT = LAYOUT_UTF8_BYTE or LAYOUT = LAYOUT_UTF8_BYTES)
   | OUTPUT_FILE := syscall{OS}(if DUMPING then 5 else 20, ARG3, 1537, 420, 0, 0, 0)
   | UNLINKED --> OUTPUT_FILE
   | OUTPUT_FD := if LAYOUT = LAYOUT_PRESENCE then long(1) else if DUMPING then OUTPUT_FILE else long(2)
   | WRITES := LAYOUT /= LAYOUT_NONE and OUTPUT_FD >= 0
   | WRITE_LENGTH := if LAYOUT = LAYOUT_DUMP_CODE then CW_TOTAL else OUTPUT_LENGTH
   | WRITTEN := syscall{OS}(if WRITES then 4 else 20, OUTPUT_FD, BUFFER_ADDRESS + long(TEXT_AT), WRITE_LENGTH, 0, 0, 0)
   | CW_W0 --> WRITTEN
   | OUTPUT_BYTE --> WRITTEN
   | OUTPUT_CLOSED := syscall{OS}(if DUMPING and OUTPUT_FILE >= 0 then 6 else 20, OUTPUT_FILE, 0, 0, 0, 0, 0)
   | WRITTEN --> OUTPUT_CLOSED
   | OUTPUT_FAILED := WRITES and WRITTEN /= long(WRITE_LENGTH) or DUMPING and OUTPUT_FILE < 0
   | STATUS := if not USAGE_OK then 2 else if not BUFFER_OK then 3 else if ERRNO /= 0 or UTF8_FAILED or OUTPUT_FAILED or not DUMPING and MESSAGE /= 0 or EN_FAILED or OUTPUT_ERRNO /= 0 then 1 else 0
   | EXIT := syscall{OS}(1, STATUS, 0, 0, 0, 0, 0)
   | OUTPUT_CLOSED --> EXIT
   |)
  where
    constant integer DUMP_PASS = 0;
    constant integer ARG_CAP = 4096;
    constant integer PRAGMA_CAP = 17;
    constant integer SRC_CAP = 8388608;
    constant integer TOKEN_CAP = 2097152;
    constant integer ITEM_CAP = 16777216;
    constant long OUTPUT_CAP = 134217728;
    constant integer TRIE_NODE_CAP = 1048576;
    constant integer TRIE_CAP = 134217728;
    constant integer NAME_CAP = 131072;
    constant integer TYPE_CAP = 65536;
    constant integer VALUE_CAP = 262144;
    constant integer BUILTIN_TYPE_COUNT = 10;
    constant integer MODEL_CAP = 65536;
    constant integer SIGNAL_CAP = 524288;
    constant integer CONSTANT_CAP = 131072;
    constant integer TABLE_CAP = 65536;
    constant integer POOL_CAP = 2097152;
    constant integer EQUATION_CAP = 524288;
    constant integer ENTRY_CAP = 2097152;
    constant integer GUARD_CAP = 16000;
    constant integer LABEL_CAP = 131072;
    constant integer LOOP_CAP = 65536;
    constant integer GROUP_CAP = 262144;
    constant integer MEMBER_CAP = 524288;
    constant integer DEPENDENCE_CAP = 262144;
    constant integer STACK_CAP = 65536;
    constant integer PATH_CAP = 1048576;
    constant integer LOCAL_CAP = 524288;
    constant integer BUCKET_CAP = 65536;
    constant integer PARSE_CAP = 268435456;
    constant integer FINAL_CAP = 8388608;
    constant integer ROWS_CAP = 4194304;
    constant integer HASH_HEAD_CAP = 4194304;
    constant integer HASH_NODE_CAP = 2097152;
    constant integer NEW_TYPE_CAP = 65536;
    constant integer NEW_TABLE_CAP = 65536;
    constant integer IOTA_CAP = 131072;
    constant integer LOWER_STACK_CAP = 65536;
    constant integer ROW_DEPENDENCE_CAP = 4194304;
    constant integer SEGMENT_CAP = 4194304;
    constant integer CLOCK_CAP = 1048576;
    constant integer DEF_CAP = 262144;
    constant integer OB_CAP = 4194304;
    constant integer PAIR_CAP = 1048576;
    constant integer PAIR_NEXT_CAP = 5242880;
    constant integer PAIR_STRIDE = 4096;
    constant integer GRID_CAP = 16777216;
    constant integer CLOCK_NAME_CAP = 65536;
    constant integer CLOCK_TEXT_CAP = 65536;
    constant integer EDGE_CAP = 16777216;
    constant integer SCHED_NODE_CAP = 5308417;
    constant integer EFFECT_ORDER_CAP = 4096;
    constant integer EFFECT_PAIR_CAP = 16777216;
    constant integer EMIT_TYPE_CAP = 131072;
    constant integer EMIT_TABLE_CAP = 131072;
    constant integer UNIT_CAP = 4194304;
    constant integer MICRO_CAP = 8388608;
    constant integer CODE_CAP = 8388608;
    constant integer CODE_LABEL_CAP = 4194304;
    constant integer DATA_CAP = 67108864;
    constant long EMIT_PAGE_LIMIT = 1125899906842624;
    constant ulong HASH_K1 = ulong(2685821657736338717);
    constant ulong HASH_K2 = ulong(4354685564936845355);
    constant integer HASH_SHIFT = 42;
    constant integer PRE_IDLE = 0;
    constant integer PRE_NAME = 1;
    constant integer PRE_EQUAL = 2;
    constant integer PRE_KIND = 3;
    constant integer PRE_OPEN = 4;
    constant integer PRE_VALUE = 5;
    constant integer PRE_SEPARATOR = 6;
    constant integer PRE_SEMICOLON = 7;
    constant integer PRE_FAILED = 8;
    constant [3] ubyte OUTPUT_OPTION = [ubyte(45), ubyte(111), ubyte(0)];
    constant integer CLASS_INVALID = 0;
    constant integer CLASS_DIGIT = 2;
    constant integer CLASS_LETTER = 3;
    constant integer CLASS_SYMBOL = 6;
    constant integer CLASS_DOT = 7;
    constant [256] short CHARACTER_CLASS = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        1, 6, 5, 6, 6, 4, 0, 0, 6, 6, 6, 6, 6, 6, 7, 6, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 6, 6, 6, 6, 6, 6,
        0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 6, 7, 6, 6, 3,
        0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 6, 6, 6, 0, 0,
        3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
        3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
        0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    constant [256] short LETTER_VALUE = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 0, 0, 0, 0, 0,
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    constant integer MODE_IDLE = 0;
    constant integer MODE_NAME = 1;
    constant integer MODE_NUMBER = 2;
    constant integer MODE_COMMENT = 3;
    constant integer MODE_STRING = 4;
    constant integer MODE_SYMBOL = 5;
    constant integer SEQUENCE_NONE = 0;
    constant integer SEQUENCE_BACKSLASH = 1;
    constant integer SEQUENCE_OCTAL = 2;
    constant integer SEQUENCE_HEX = 3;
    constant [8] short MODE_OF_CLASS = [0, 0, 2, 1, 3, 4, 0, 0];
    constant integer KIND_KEYWORD = 0;
    constant integer KIND_NAME = 1;
    constant integer KIND_SYMBOL = 2;
    constant integer KIND_NUMBER = 3;
    constant integer KIND_EOF = 5;
    constant integer KIND_NONE = 6;
    constant [8] short OPENED_KIND_OF_CLASS = [6, 6, 3, 1, 6, 4, 2, 2];
    constant integer KEYWORD_LENGTH_MAX = 9;
    constant integer KEYWORD_MODULUS = 299;
    constant [299] ulong KEYWORD_KEYS = [
        ulong(0), ulong(0), ulong(0), ulong(302), ulong(0), ulong(0),
        ulong(20201044), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(0), ulong(0), ulong(464660), ulong(0), ulong(0), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(0), ulong(474245), ulong(176741), ulong(0), ulong(0), ulong(452089231),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(0), ulong(0), ulong(681477), ulong(655), ulong(3659220), ulong(178861),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(0), ulong(103820), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(99941), ulong(0), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(0), ulong(309556), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(12617900), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(6337125),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(0), ulong(0), ulong(5969364), ulong(0), ulong(1656889), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(198245431340), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(24385093), ulong(18226873521733),
        ulong(0), ulong(0), ulong(0), ulong(22578), ulong(0), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(4469085588), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(10340599429),
        ulong(0), ulong(1265842), ulong(0), ulong(0), ulong(762030), ulong(0),
        ulong(0), ulong(763528), ulong(0), ulong(0), ulong(0), ulong(14836),
        ulong(0), ulong(486), ulong(0), ulong(0), ulong(5572), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(494), ulong(229180581358), ulong(0),
        ulong(0), ulong(498), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(0), ulong(0), ulong(674469), ulong(0), ulong(0), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(119675684308), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(2666927150), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(663726),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(0), ulong(215533), ulong(0), ulong(0), ulong(0), ulong(25074),
        ulong(17799681651), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(0), ulong(1843057971694), ulong(0), ulong(10154581170), ulong(1476), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(0), ulong(19724), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(294), ulong(19730), ulong(0), ulong(0), ulong(409031)];
    constant integer ERROR_NONE = 0;
    constant integer ERROR_UNEXPECTED = 1;
    constant integer ERROR_SRC = 2;
    constant integer ERROR_TOKENS = 3;
    constant integer ERROR_ESCAPE = 4;
    constant integer ERROR_ESCAPE_RANGE = 5;
    constant integer F_COLON = 1;
    constant integer F_ERROR_SEPARATOR = 2;
    constant integer F_ERROR_WORD = 3;
    constant integer F_SPACE = 4;
    constant integer F_ERRNO_PREFIX = 5;
    constant integer F_ERRNO_SUFFIX = 6;
    constant integer F_QUOTE = 7;
    constant integer F_ELLIPSIS = 8;
    constant integer F_END_OF_FILE = 9;
    constant integer F_NONE = 10;
    constant integer F_OPEN = 11;
    constant integer F_CLOSE = 12;
    constant integer F_OPEN_TWO = 13;
    constant integer F_CLOSE_TWO = 14;
    constant integer F_CLOSE_THREE = 15;
    constant integer F_EMPTY_LIST = 16;
    constant integer F_OPEN_NONE = 17;
    constant integer F_NONE_CLOSE = 18;
    constant integer F_CONST_OPEN = 19;
    constant integer F_ENUMCONST_OPEN = 20;
    constant integer F_SIZE_CLOSE = 6;
    constant integer F_STATE_SUFFIX = 21;
    constant integer F_DEFINE = 22;
    constant integer F_SEED = 23;
    constant integer SEED_LENGTH = 532;
    constant integer SEED_NAME_COUNT = 85;
    constant [532] ubyte SEED = "event boolean short integer long ubyte ushort uinteger ulong pointer load store syscall instruction abs left_tt Automaton_Initial_State Automaton_Transition Automaton_IsIn clock' state' cur' on' process where end init true false when default and or xor not modulo shl shr type enum constant next iterate of with if then else procedure node function automaton label on external indices pragmas Interrupt Boot Machine cell var after from count case in array to cell' zcell' var' varm' zvar' h1' h2' m' a' za' s' zs' n' i' zcount' rep'";
    constant integer N_EVENT = 0;
    constant integer N_BOOLEAN = 1;
    constant integer N_UBYTE = 5;
    constant integer N_ULONG = 8;
    constant integer N_LOAD = 10;
    constant integer N_INSTRUCTION = 13;
    constant integer N_INITIAL = 16;
    constant integer N_TRANSITION = 17;
    constant integer N_ISIN = 18;
    constant integer N_CLOCK_MARK = 19;
    constant integer N_STATE_MARK = 20;
    constant integer N_CURRENT_MARK = 21;
    constant integer N_ON_MARK = 22;
    constant integer C_EVENT = 1;
    constant integer C_BOOLEAN = 2;
    constant integer C_SHORT = 3;
    constant integer C_INTEGER = 4;
    constant integer C_LONG = 5;
    constant integer C_PROCESS = 24;
    constant integer C_WHERE = 25;
    constant integer C_END = 26;
    constant integer C_INIT = 27;
    constant integer C_TRUE = 28;
    constant integer C_FALSE = 29;
    constant integer C_WHEN = 30;
    constant integer C_DEFAULT = 31;
    constant integer C_AND = 32;
    constant integer C_OR = 33;
    constant integer C_XOR = 34;
    constant integer C_NOT = 35;
    constant integer C_MODULO = 36;
    constant integer C_SHL = 37;
    constant integer C_SHR = 38;
    constant integer C_TYPE = 39;
    constant integer C_ENUM = 40;
    constant integer C_CONSTANT = 41;
    constant integer C_NEXT = 42;
    constant integer C_ITERATE = 43;
    constant integer C_OF = 44;
    constant integer C_WITH = 45;
    constant integer C_IF = 46;
    constant integer C_THEN = 47;
    constant integer C_ELSE = 48;
    constant integer C_PROCEDURE = 49;
    constant integer C_NODE = 50;
    constant integer C_FUNCTION = 51;
    constant integer C_AUTOMATON = 52;
    constant integer C_LABEL = 53;
    constant integer C_ON = 54;
    constant integer C_EXTERNAL = 55;
    constant integer C_OPEN_BAR = 80;
    constant integer C_BAR_CLOSE = 81;
    constant integer C_ARROW = 82;
    constant integer C_COLONS = 83;
    constant integer C_DEFINE = 84;
    constant integer C_CLOCK_EQUAL = 85;
    constant integer C_NOT_EQUAL = 86;
    constant integer C_LESS_EQUAL = 87;
    constant integer C_GREATER_EQUAL = 88;
    constant integer C_RANGE = 89;
    constant integer C_BAR = 90;
    constant integer C_DOLLAR = 91;
    constant integer C_PLUS = 92;
    constant integer C_MINUS = 93;
    constant integer C_STAR = 94;
    constant integer C_SLASH = 95;
    constant integer C_OPEN = 96;
    constant integer C_CLOSE = 97;
    constant integer C_EQUAL = 98;
    constant integer C_SEMICOLON = 99;
    constant integer C_COMMA = 100;
    constant integer C_QUESTION = 101;
    constant integer C_BANG = 102;
    constant integer C_LESS = 103;
    constant integer C_GREATER = 104;
    constant integer C_CARET = 105;
    constant integer C_HASH = 106;
    constant integer C_OPEN_BRACKET = 107;
    constant integer C_CLOSE_BRACKET = 108;
    constant integer C_COLON = 109;
    constant integer C_OPEN_BRACE = 110;
    constant integer C_CLOSE_BRACE = 111;
    constant integer C_EOF = 0;
    constant integer C_NAME = 128;
    constant integer C_NUMBER = 129;
    constant integer C_STRING = 130;
    constant integer C_SYMBOL_BASE = 80;
    constant [256] short NAME_CHAR = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 63, 0, 0, 0, 0, 0, 0, 0, 0,
        52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 6,
        7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 0, 0, 0, 0, 62,
        0, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48,
        49, 50, 51, 0, 0, 0, 0, 0, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79,
        80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103,
        104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    constant [256] short SINGLE_SYMBOL = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 102, 0, 106, 91, 0, 0, 0, 96, 97, 94, 92, 100, 93, 0, 95,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 109, 99, 103, 98, 104, 101, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 107, 0, 108, 105, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 110, 90, 111, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    constant [41] short SYMBOL_FRAGMENT = [
        289, 290, 291, 292, 293, 294, 295, 296, 297, 298, 299, 300, 301, 38, 302, 303, 304, 305, 306, 307, 308, 309, 310, 311,
        312, 313, 24, 11, 12, 1, 314, 315, 316, 317, 318, 319, 320, 321, 322, 0, 323];
    constant integer OP_CONST = 0;
    constant integer OP_SIGNAL = 1;
    constant integer OP_ENUMCONST = 2;
    constant integer OP_CALL = 3;
    constant integer OP_DELAY = 4;
    constant integer OP_PREV = 5;
    constant integer OP_INDEX = 6;
    constant integer OP_NEG = 7;
    constant integer OP_NOT = 8;
    constant integer OP_UWHEN = 9;
    constant integer OP_CLOCK = 10;
    constant integer OP_IF = 11;
    constant integer OP_BRANCH = 12;
    constant integer OP_DEFAULT = 13;
    constant integer OP_WHEN = 14;
    constant integer OP_XOR = 15;
    constant integer OP_OR = 16;
    constant integer OP_AND = 17;
    constant integer OP_EQ = 18;
    constant integer OP_NE = 19;
    constant integer OP_LT = 20;
    constant integer OP_LE = 21;
    constant integer OP_GT = 22;
    constant integer OP_GE = 23;
    constant integer OP_ADD = 24;
    constant integer OP_SUB = 25;
    constant integer OP_MUL = 26;
    constant integer OP_DIV = 27;
    constant integer OP_MOD = 28;
    constant integer OP_SHL = 29;
    constant integer OP_SHR = 30;
    constant integer OP_NEXT = 31;
    constant integer OP_PAIR = 32;
    constant integer OP_RANGE = 33;
    constant integer OP_OPEN_PAREN = 34;
    constant integer OP_OPEN_SQUARE = 35;
    constant integer OP_IF_MARK = 36;
    constant integer OP_THEN_MARK = 37;
    constant [75] short OP_FRAGMENT = [
        50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73,
        74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 23, 96,
        97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120,
        121, 122, 123];
    constant [75] short OP_IS_OPENER = [
        0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0];
    constant [75] short OP_ARITY = [
        0, 0, 0, 2, 1, 1, 2, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
        2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
        2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 2, 2,
        2, 2, 2];
    constant [132] short BINARY_OP = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 14, 13, 17, 16, 15, 0, 28, 29, 30, 0, 0, 0, 31, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 62, 0, 64, 65, 66, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 19, 21, 23, 33, 0, 0, 24, 25, 26, 27,
        0, 0, 18, 0, 0, 0, 0, 20, 22, 0, 0, 0, 0, 32, 0, 0, 48, 49, 53, 18, 21, 0, 0, 57,
        67, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    constant [132] short BINARY_PRECEDENCE = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 4, 3, 13, 12, 11, 0, 18, 18, 18, 0, 0, 0, 1, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 21, 0, 5, 5, 5, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 16, 16, 1, 0, 0, 17, 17, 18, 18,
        0, 0, 16, 0, 0, 0, 0, 16, 16, 0, 0, 0, 0, 2, 0, 0, 6, 7, 6, 15, 15, 0, 0, 23,
        18, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    constant [132] short PREFIX_OP = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 63, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 50, 51, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    constant [132] short PREFIX_PRECEDENCE = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 14, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 21, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 20, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 24, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    constant [132] short MODEL_CLASS = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    constant integer TK_EVENT = 0;
    constant integer TK_BOOLEAN = 1;
    constant integer TK_INT = 2;
    constant integer TK_POINTER = 3;
    constant integer TK_ENUM = 4;
    constant integer TK_ARRAY = 5;
    constant integer TK_EXTERNAL = 6;
    constant [7] short TYPE_KIND_FRAGMENT = [
        124, 125, 126, 127, 128, 129, 130];
    constant [10] short BUILTIN_KIND = [
        0, 1, 2, 2, 2, 2, 2, 2, 2, 3];
    constant [10] short BUILTIN_BYTES = [
        1, 1, 2, 4, 8, 1, 2, 4, 8, 8];
    constant [10] short BUILTIN_SIGNED = [
        0, 0, 1, 1, 1, 0, 0, 0, 0, 0];
    constant integer ROLE_INPUT = 0;
    constant integer ROLE_OUTPUT = 1;
    constant integer ROLE_LOCAL = 2;
    constant [3] short ROLE_FRAGMENT = [
        131, 132, 133];
    constant integer F_ROLE_SIGNAL = 237;
    constant integer F_ROLE_TYPE = 238;
    constant integer F_ROLE_MODEL = 239;
    constant integer F_ROLE_CONSTANT = 240;
    constant integer F_ROLE_LABEL = 241;
    constant integer COL_NAME = 0;
    constant integer COL_TYPES_KIND = 1;
    constant integer COL_TYPES_BYTES = 2;
    constant integer COL_TYPES_SIGNED = 3;
    constant integer COL_TYPES_NAME = 4;
    constant integer COL_TYPES_VALUES = 5;
    constant integer COL_TYPES_ELEMENT = 6;
    constant integer COL_TYPES_SIZE = 7;
    constant integer COL_MODELS_NAME = 8;
    constant integer COL_MODELS_KIND = 9;
    constant integer COL_MODELS_PARENT = 10;
    constant integer COL_MODELS_LINE = 11;
    constant integer COL_MODELS_COLUMN = 12;
    constant integer COL_MODELS_LABELS = 13;
    constant integer COL_SIGNAL_NAMES = 14;
    constant integer COL_SIGNAL_ROLES = 15;
    constant integer COL_SIGNAL_TYPES = 16;
    constant integer COL_SIGNAL_MODELS = 17;
    constant integer COL_SIGNAL_POSITIONS = 18;
    constant integer COL_CONSTANT_NAMES = 19;
    constant integer COL_CONSTANT_TYPES = 20;
    constant integer COL_CONSTANT_VALUES = 21;
    constant integer COL_TABLE_TYPES = 22;
    constant integer COL_TABLE_VALUES = 23;
    constant integer COL_EQUATION_TARGETS = 24;
    constant integer COL_EQUATION_OPS = 25;
    constant integer COL_EQUATION_ARGS = 26;
    constant integer COL_EQUATION_POSITIONS = 27;
    constant integer COL_EQUATION_LOOPS = 28;
    constant integer COL_EQUATION_KINDS = 29;
    constant integer COL_EQUATION_MODELS = 30;
    constant integer COL_EQUATION_LABELS = 31;
    constant integer COL_EQUATION_GUARDS = 32;
    constant integer COL_GUARD_MODELS = 33;
    constant integer COL_GUARD_OPS = 34;
    constant integer COL_GUARD_ARGS = 35;
    constant integer COL_GUARD_POSITIONS = 36;
    constant integer COL_GUARD_CONTEXT = 37;
    constant integer COL_GUARD_LABELS = 38;
    constant integer COL_GUARD_SIGNALS = 39;
    constant integer COL_LABEL_NAMES = 40;
    constant integer COL_LABEL_USES = 41;
    constant integer COL_LOOP_NAMES = 42;
    constant integer COL_LOOP_POSITIONS = 43;
    constant integer COL_LOOP_MODELS = 44;
    constant integer COL_CONSTRAINT_GROUPS = 45;
    constant integer COL_CONSTRAINT_POSITIONS = 46;
    constant integer COL_CONSTRAINT_MODELS = 47;
    constant integer COL_CONSTRAINT_GUARDS = 48;
    constant integer COL_DEPENDENCE_FROM = 49;
    constant integer COL_DEPENDENCE_TO = 50;
    constant integer COL_DEPENDENCE_POSITIONS = 51;
    constant integer COL_DEPENDENCE_MODELS = 52;
    constant integer COL_DEPENDENCE_GUARDS = 53;
    constant [103] short COLUMN_FRAGMENT = [
        134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157,
        158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181,
        182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205,
        206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229,
        230, 231, 232, 233, 234, 235, 236];
    constant integer F_CAP_SRC = 242;
    constant integer F_CAP_TOKENS = 243;
    constant integer F_CAP_NAMES = 244;
    constant integer F_CAP_TYPES = 245;
    constant integer F_CAP_VALUES = 246;
    constant integer F_CAP_MODELS = 247;
    constant integer F_CAP_SIGNALS = 248;
    constant integer F_CAP_CONSTANTS = 249;
    constant integer F_CAP_TABLES = 250;
    constant integer F_CAP_EQUATIONS = 251;
    constant integer F_CAP_ENTRIES = 252;
    constant integer F_CAP_GUARDS = 253;
    constant integer F_CAP_LABELS = 254;
    constant integer F_CAP_LOOPS = 255;
    constant integer F_CAP_GROUPS = 256;
    constant integer F_CAP_DEPENDENCES = 257;
    constant integer F_CAP_STACK = 258;
    constant integer F_CAP_PATHS = 259;
    constant integer F_CAP_LOCALS = 260;
    constant integer F_CAP_PARSE = 261;
    constant integer F_CAP_FINISH = 262;
    constant integer F_CAP_ITEMS = 263;
    constant integer F_CAP_OUTPUT = 264;
    constant [4] short SECTION_FRAGMENT = [
        40, 41, 42, 43];
    constant [6] short KIND_FRAGMENT = [
        44, 45, 46, 47, 48, 49];
    constant integer A_NONE = 0;
    constant integer A_TOKEN = 1;
    constant integer A_LITERAL = 2;
    constant integer A_NAME = 3;
    constant integer A_TYPE = 4;
    constant integer A_NUMBER = 5;
    constant integer A_CODE = 6;
    constant integer A_FRAGMENT = 7;
    constant integer A_CHARACTER = 8;
    constant integer T_UNEXPECTED_CHARACTER = 1;
    constant integer T_CAPACITY = 2;
    constant integer T_EXPECTED_FOUND = 3;
    constant integer T_EXPECTED_NAME = 4;
    constant integer T_RESERVED = 5;
    constant integer T_NAME_OF_MODEL = 6;
    constant integer T_DECLARED_TWICE = 7;
    constant integer T_LITERAL_BIG = 8;
    constant integer T_CONSTANT_UNDECLARED = 9;
    constant integer T_EXPECTED_INTEGER_CONSTANT = 10;
    constant integer T_CAPACITY_POSITIVE = 11;
    constant integer T_EXPECTED_TYPE = 12;
    constant integer T_EXTERNAL_SIGNAL = 13;
    constant integer T_INPUT_SCALAR = 14;
    constant integer T_ARRAYS_TO_MODELS = 15;
    constant integer T_OUTPUT_ARRAY = 16;
    constant integer T_UNEXPECTED_AFTER = 17;
    constant integer T_ENUM_TWICE = 18;
    constant integer T_CONSTANT_STRING = 19;
    constant integer T_CONSTANT_LIST = 20;
    constant integer T_CONSTANT_ELEMENT = 21;
    constant integer T_CONSTANT_TYPE = 22;
    constant integer T_CONSTANT_COUNT = 23;
    constant integer T_CONVERSION = 24;
    constant integer T_CONSTANT_LITERAL = 25;
    constant integer T_ONLY_DEFINITIONS = 26;
    constant integer T_ITERATE_NESTED = 27;
    constant integer T_ITERATE_GUARDED = 28;
    constant integer T_ARROW_NAMES = 29;
    constant integer T_EXPECTED_DEFINITION = 30;
    constant integer T_DELAY_INITIAL = 31;
    constant integer T_STATIC_PARAMETER = 32;
    constant integer T_EXPECTED_EXPRESSION = 33;
    constant integer T_EXPECTED_THEN = 34;
    constant integer T_EXPECTED_ELSE = 35;
    constant integer T_UNBALANCED = 36;
    constant integer T_EXPECTED_OPERATOR = 37;
    constant integer T_LABEL_UNDECLARED = 50;
    constant integer T_NO_INPUT = 51;
    constant integer T_WRONG_ARGUMENTS = 52;
    constant integer T_LABEL_PLACED = 53;
    constant integer T_CANNOT_GUARD = 54;
    constant integer T_EXPECTS_STATE = 55;
    constant integer T_NOT_LABEL_OF = 56;
    constant integer T_ONE_INITIAL = 57;
    constant integer T_ONLY_AUTOMATON = 58;
    constant integer T_NO_OUTPUT = 59;
    constant integer T_HAS_OUTPUT = 60;
    constant integer T_NOT_STATE = 61;
    constant [167] short TEMPLATE_PIECE0 = [
        0, 324, 325, 326, 328, 0, 0, 0, 332, 334, 336, 337, 338, 339, 341, 343, 344, 346, 348, 334, 334, 334, 334, 334,
        356, 357, 358, 359, 360, 361, 362, 363, 364, 365, 366, 367, 368, 369, 370, 371, 372, 373, 0, 376, 376, 0, 380, 381,
        0, 383, 385, 386, 388, 385, 0, 0, 0, 386, 0, 397, 397, 0, 401, 385, 403, 405, 406, 407, 397, 397, 397, 397,
        401, 0, 415, 339, 417, 0, 415, 421, 422, 424, 425, 427, 428, 430, 431, 0, 0, 434, 435, 436, 437, 438, 439, 441,
        442, 428, 444, 446, 0, 448, 428, 428, 428, 428, 428, 428, 456, 457, 348, 348, 339, 339, 460, 461, 401, 463, 465, 401,
        341, 401, 468, 469, 401, 471, 472, 473, 474, 474, 477, 479, 474, 341, 483, 484, 485, 486, 489, 490, 492, 493, 494, 496,
        498, 499, 341, 341, 341, 504, 506, 507, 508, 510, 512, 494, 514, 515, 516, 518, 401, 523, 524, 527, 428, 529, 531];
    constant [167] short TEMPLATE_PIECE1 = [
        0, 7, 0, 327, 0, 329, 330, 4, 333, 335, 0, 0, 0, 340, 342, 0, 345, 347, 331, 349, 349, 349, 349, 349,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 374, 4, 377, 378, 379, 0, 0,
        382, 384, 335, 387, 389, 391, 392, 393, 394, 395, 396, 398, 399, 400, 335, 402, 404, 0, 0, 408, 335, 409, 410, 411,
        335, 413, 416, 335, 418, 419, 420, 0, 423, 390, 426, 0, 429, 0, 0, 432, 433, 0, 0, 0, 0, 0, 440, 390,
        0, 443, 445, 0, 447, 449, 450, 451, 452, 453, 454, 455, 0, 0, 335, 458, 335, 459, 0, 0, 462, 464, 0, 349,
        466, 467, 0, 0, 470, 0, 0, 0, 475, 476, 478, 480, 481, 482, 0, 0, 0, 445, 0, 491, 0, 0, 495, 497,
        0, 500, 501, 502, 503, 505, 0, 0, 445, 511, 0, 513, 0, 0, 517, 519, 520, 0, 525, 390, 528, 530, 530];
    constant [167] short TEMPLATE_PIECE2 = [
        0, 0, 0, 0, 0, 0, 0, 331, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 350, 351, 352, 353, 354,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 375, 0, 4, 0, 0, 0,
        0, 0, 0, 0, 390, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 412,
        0, 414, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 445, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 353,
        0, 0, 0, 0, 0, 0, 0, 0, 445, 0, 0, 0, 0, 0, 0, 0, 0, 487, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 509, 0, 0, 0, 0, 0, 0, 0, 521, 0, 526, 0, 0, 0, 0];
    constant [167] short TEMPLATE_PIECE3 = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 355,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 488, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 522, 0, 0, 0, 0, 0, 0];
    constant [167] short TEMPLATE_KIND0 = [
        0, 8, 7, 6, 1, 3, 3, 7, 2, 3, 1, 0, 1, 4, 3, 0, 3, 1, 3, 3, 3, 3, 3, 3,
        0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 0, 0, 1, 1, 4, 1, 1, 6, 3, 3, 1, 0, 0,
        1, 1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 3, 3, 3, 3, 3,
        9, 3, 3, 10, 3, 3, 3, 0, 3, 4, 5, 4, 7, 0, 0, 9, 9, 0, 0, 0, 0, 0, 11, 4,
        0, 7, 4, 0, 3, 4, 7, 7, 7, 7, 7, 7, 0, 0, 3, 3, 3, 3, 0, 9, 9, 9, 0, 9,
        9, 9, 0, 0, 9, 0, 0, 0, 12, 12, 12, 12, 12, 9, 12, 12, 0, 12, 0, 3, 1, 1, 1, 5,
        0, 3, 3, 3, 3, 12, 0, 0, 3, 1, 0, 1, 0, 0, 8, 5, 3, 0, 3, 4, 7, 5, 5];
    constant [167] short TEMPLATE_KIND1 = [
        0, 0, 0, 1, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 4, 4, 4, 4,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 1, 6, 0, 0, 0,
        0, 0, 0, 0, 5, 3, 0, 3, 3, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 6, 0, 0, 0, 5,
        0, 5, 0, 0, 0, 10, 0, 0, 4, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 11, 4,
        0, 0, 4, 0, 0, 4, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 4,
        0, 0, 0, 0, 0, 0, 0, 0, 12, 0, 0, 0, 12, 0, 0, 0, 0, 12, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 7, 0, 3, 4, 4, 5, 5];
    constant [167] short TEMPLATE_KIND2 = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 4, 5,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0,
        0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0,
        0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4,
        0, 0, 0, 0, 0, 0, 0, 0, 12, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0];
    constant integer LAYOUT_NONE = 0;
    constant integer LAYOUT_OS = 1;
    constant integer LAYOUT_COMPILE = 2;
    constant integer LAYOUT_DUMP_ERROR = 3;
    constant integer LAYOUT_DUMP_TOKENS = 4;
    constant integer LAYOUT_DUMP_PROGRAM = 5;
    constant integer ROW_SLICE_NONE = 0;
    constant integer ROW_SLICE_PATH = 1;
    constant integer ROW_NUMBER_NONE = 0;
    constant integer ROW_NUMBER_ERROR_LINE = 1;
    constant integer ROW_NUMBER_ERROR_COLUMN = 2;
    constant integer ROW_NUMBER_ERRNO = 3;
    constant [12] short LAYOUT_ITEM_COUNT = [
        0, 2, 14, 13, 0, 0, 0, 6, 2, 1, 4, 3];
    constant [12] short LAYOUT_FIRST_ROW = [
        0, 0, 2, 16, 29, 29, 29, 29, 35, 37, 38, 42];
    constant [45] short ROW_PREFIX = [
        5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 5, 0, 33, 34, -2, 0, -3, 35, 0, -3];
    constant [45] short ROW_SLICE = [
        0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 2, 3, 0, 0, 0, 0, 0, 0, 0];
    constant [45] short ROW_NUMBER = [
        3, 0, 0, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 4, 5, 6, 7, 8, 0, 0, 0, 0, 9, 0, 9, 10, 0];
    constant [45] short ROW_SUFFIX = [
        6, 0, 1, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 4, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 30, 31, 32, 32, 32, 12, 6, 0, 0, 0, 36, 37, 0, 38, 37, 0];
    constant [45] short ROW_NEWLINE = [
        0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1];
    constant [45] short ROW_SLOT = [
        -1, -1, -1, -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, -1, -1, -1, 0, 1, 2, 3, 4, 5,
        6, 7, 8, 9, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1];
    constant integer MESSAGE_SLOTS = 10;
    constant [20] ulong POWERS_OF_TEN = [
        ulong(1), ulong(10), ulong(100), ulong(1000), ulong(10000), ulong(100000),
        ulong(1000000), ulong(10000000), ulong(100000000), ulong(1000000000), ulong(10000000000), ulong(100000000000),
        ulong(1000000000000), ulong(10000000000000), ulong(100000000000000), ulong(1000000000000000), ulong(10000000000000000), ulong(100000000000000000),
        ulong(1000000000000000000), ulong(-8446744073709551616)];
    constant [10139] ubyte FRAGMENTS = ":: error: error  sigc: error: [Errno ] '...'end of file'none[][[]]]]][][nonenone][CONST [[ENUMCONST ['stateDEFINESEED#.'call[expression at  at error 1 1 program exceeds compiler capacity: OUTPUT:0:0: error:  operand out of range: [, presence inputs: sigc: error: 'utf-8' codec can't decode byte 0xsigc: error: 'utf-8' codec can't decode bytes in position  in position : -memory reservation failedkinds texts lines columns keywordnamesymbolnumberstringeofCONSTSIGNALENUMCONSTCALLDELAYPREVINDEXNEGNOTUWHENCLOCKIFBRANCHDEFAULTWHENXORORANDEQNELTLEGTGEADDSUBMULDIVMODSHLSHRNEXTPAIRRANGEOPEN_PARENOPEN_SQUAREIF_MARKTHEN_MARKEFFECTINPUTCOPYCONVERTTABLEELEMENTGATHERITERARGCLOCK_PLUSCLOCK_TIMESOPEN_COLONOPEN_SLASH_COLONLEFT_TTCLOCK_MINUSABSOPERANDZERORECOVERRECOVER_SQUAREINDEX_OPERANDSIZESIZE_LESSCELLVARAFTERFROMCOUNTREPEATONERIGHT_OPERANDTARGET_SIGNALINDEX_SIGNALREPEAT_RANGEARRAY_RANGEREPEAT_BODYEVENTBOOLEANINTPOINTERENUMARRAYEXTERNALinputoutputlocalname types.kind types.bytes types.signed types.name types.values types.element types.size models.name models.kind models.parent models.line models.column models.labels signal_names signal_roles signal_types signal_models signal_positions constant_names constant_types constant_values table_types table_values equation_targets equation_ops equation_args equation_positions equation_loops equation_kinds equation_models equation_labels equation_guards guard_models guard_ops guard_args guard_positions guard_context guard_labels guard_signals label_names label_uses loop_names loop_positions loop_models constraint_groups constraint_positions constraint_models constraint_guards dependence_from dependence_to dependence_positions dependence_models dependence_guards rows.op rows.left rows.right rows.value rows.type rows.ctx rows.line rows.column rows.owner rows.loop rows.guard rows.groups rows.group_positions rows.dependence_from rows.dependence_to rows.war rows.snapshotted rows.effects.kind rows.effects.resource rows.effects.param loops.index loops.size loops.defined loops.snapshots loops.count parent sample_rows def_kind def_target def_left def_right def_line def_column def_pending ob_small ob_big ob_line ob_column node_kind node_parent node_depth node_root node_left node_right roots order loop_orders snapshots snapshotted signaltypemodelconstantlabelSRCTOKENSNAMESTYPESVALUESMODELSSIGNALSCONSTANTSTABLESEQUATIONSENTRIESGUARDSLABELSLOOPSGROUPSDEPENDENCESSTACKPATHSLOCALSPARSEFINISHITEMSOUTPUTINSTANCESINSTANTIATELOOKUPSROWSROW_DEPENDENCESSEGMENTSLOWERCLOCKSDEFINITIONSOBLIGATIONSPAIRSCLOCK_NAMESCLOCK_TEXTCLOCK_SORTEDGESSCHEDULE_NODESEFFECTSEFFECT_ORDERUNITSMICRO_OPSCODECODE_LABELSDATACODE_TEXT(||)-->:::=^=/=<=>=..|$+*/()=;,?!<>^{}^+^*^-==<<=[:[/:|*unexpected character 'program exceeds compiler capacity: expected '', found expected a name, found  is a reserved name is the name of a model is declared twiceinteger literal  does not fit in longconstant  is not declaredexpected an integer constant, found array capacity must be strictly positiveexpected a type, found type  is external; signals cannot have that typeinput signal  must be a scalararrays cannot be passed to modelsoutput  has an array type; outputs must be scalarunexpected  after the process modelenumerated value  has type  but its definition is a string but its definition is a list but its definition has an element of type  but its definition has type  but its definition has  elementsa conversion in a constant must name an integer typea constant must be defined by an integer literal, a conversion of one, or a list of themonly definitions are allowed inside iterateiterate cannot be nestediterate is not allowed inside a guarded process--> requires signal namesexpected ':=' or '^=', found the initial value of a delay must be a literal or a constant nameexpected a static parameter, found expected an expression, found expected 'then'expected 'else'unbalanced parenthesisexpected an operator, found expected an array access before abs expects a signed integer, found a case value must be a literal, found value  is listed twice in this case must declare at least one outputfunction  cannot contain  cannot call  can only be the whole definition of a signalvar takes a signal namevar is supported only where its context clock is the defined signal's clock cannot be used inside a guard, case branch, label or state actionthe bound of  must be a positive integer literal or constant namelabel automaton  has no input; its control clock is the upper bound of its inputswrong number of arguments for : expected , found  cannot be placed on  cannot be guarded expects a state name of automaton  is not a label of automaton  needs exactly one Automaton_Initial_State is allowed only in an automatonmodel  has no output and cannot be used in an expression has an output and cannot be called as a process is not a state of automaton signal  cannot be used as a signalconversion to  expects one argumentindices expects a positive constantmodel calls are not allowed inside iterateunsafe model  is called from  takes no static parameters calls itself has  outputs; only models with at most one output can be called expects  static parameters, found the word of  must be an integer constantthe resource of  must be an external type accesses an integer or pointer type, found  must fit in 32 bits':' is supported only as the right operand of nextinput 1 of  must be a pointer, found input 2 of store must have type input  of syscall must be an integer or a pointer, found input 1 of instruction must have type ulong, found operator  is not allowed inside iteratean array value can only be the whole definition of a signal[?] applies only to a signal name[?] is allowed only inside iterate[?] refers to a signal the iterate body does not defineindexing a value that is not an arraya range must start at 0the bound of a range must be an integeran array index must be an integernext expects 'index : value' on its rightconstant index  is outside 0..next expects a value of type $ is not supported on arrays expects scalar operandsoperator if expects operands of comparable types, found  and the condition of if must be boolean cannot be inside an if; gate it by its clock or its inputsno conversion from  to  expects a pointer and an integer offset expects integer operands expects operands of comparable types, found  expects operands of one type expects boolean operands expects unsigned operandsthe condition of when must be booleanthe initial value of a delay must match its type is ambiguous has no value the index of iterate must be an array of integersiterate body cannot define its index  in with is not defined by the iterate bodythe initial value of  cannot read a signal the iterate defineswith initializes an array only from an array constant or an array signal cannot be defined is defined twicea range defines an array of integersan array signal must be defined by a constant, indices, a gather, or next is never defineda range can only be the index of iteratea constant has no clockthe argument of $ cannot be a constantclock of  fits no tree: it relates root clocks  has two definitions that cannot be shown equalclocks of  are defined in terms of each otherthe clocks of guards  depend on each other cannot be shown inside the clock  must have a root of its owncausality cycle between signals causality cycle between effects at causality cycle between clockseffects  on resource  have no order between them; order them with -->arrays need more than 2^64 bytes of address spacepragma  is allowed on the top model onlyexpected 'end pragmas', found Interrupt expects an interrupt number in quotes, found interrupt number  must be a decimal from 16 to 31interrupt  is used twicepragma Boot is used twicepragma object  is not an input signal named by a pragma must be event is named by two pragmas must be named by an Interrupt or Boot pragmathe root clock of  is not the clock of an Interrupt or Boot inputsyscall is not available on QEMU virta program with Interrupt pragmas needs a Boot pragma to enable theminput signals  share one root clock; each Interrupt or Boot input needs its ownmachine  is not supported; use mps2-an385pragma Machine is used twice must be a decimal from 15 to 47syscall is not available on mps2-an385the program needs more than the 4 MiB of RAM on mps2-an385unknown escape '' in a stringescape value  does not fit in a byte is an  of  and cannot be hiddena model cannot be declared in an inner whereinitial value of  is unused:  is not defined by $, cell or var'|*' expects a value of type  expects event operands, found '|*' produces  elements but the array has the index range has notwhenifdefaultxororandmoduloshlshrnextcellvarafterfromcountROOTSAMPLEPRODUCTSUMinvalid start byteinvalid continuation byteunexpected end of data000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfeffmovz xmovz wmovk xmovk wadd x immadd w immsub x immsub w immsubs x immsubs w immadd xadds xsub xsubs xand xand worr xorr weor xorn xeor x onelslv xlsrv xsdiv xudiv xmul xmsub xumulh xcsel xcsinc wcsneg xldr xldr wldrsw xldrh wldrsh xldrb wstr xstr wstrh wstrb wldr x regldr w regldrsw x regldrh w regldrsh x regldrb w regstr x regstr w regstrh w regstrb w regldr x poststr x poststr w poststrb w postldrb w prebblb.condcbz wcbz xcbnz xadrpretsvc 0x80wordwfimovwmovtmovw addressmovt addressaddwsubwand.worr.worrs.weor.wadd.w shiftedadds.wadc.wadcs.wsbc.wsbcs.wsubs.wmov.wmvn.wlsl.wlsr.wlsl.w immlsr.w immasr.w immumullmlasubs.w immadds.w immadc.w immsbcs.w immrsb.w immeor.w immorr.w immldr.wldrb.wldrh.wldrsh.wstr.wstrb.wstrh.wldrdstrdldrd poststrd poststrb postldrb postldrb prestr preldr postb.wb.n skipbx lrwfi.wmsr primaskthumb word";
    constant [933] short FRAGMENT_START = [
        0, 0, 1, 10, 16, 17, 37, 39, 40, 43, 56, 60, 61, 62, 64, 66, 69, 71, 76, 81, 89, 101, 107, 113,
        117, 118, 119, 124, 139, 143, 194, 207, 231, 233, 250, 297, 355, 368, 370, 371, 396, 402, 408, 414, 422, 429, 433, 439,
        445, 451, 454, 459, 465, 474, 478, 483, 487, 492, 495, 498, 503, 508, 510, 516, 523, 527, 530, 532, 535, 537, 539, 541,
        543, 545, 547, 550, 553, 556, 559, 562, 565, 568, 572, 576, 581, 591, 602, 609, 618, 624, 629, 633, 640, 645, 652, 658,
        662, 665, 675, 686, 696, 712, 719, 730, 733, 740, 744, 751, 765, 778, 782, 791, 795, 798, 803, 807, 812, 818, 821, 834,
        847, 859, 871, 882, 893, 898, 905, 908, 915, 919, 924, 932, 937, 943, 948, 953, 964, 976, 989, 1000, 1013, 1027, 1038, 1050,
        1062, 1076, 1088, 1102, 1116, 1129, 1142, 1155, 1169, 1186, 1201, 1216, 1232, 1244, 1257, 1274, 1287, 1301, 1320, 1335, 1350, 1366, 1382, 1398,
        1411, 1421, 1432, 1448, 1462, 1475, 1489, 1501, 1512, 1523, 1538, 1550, 1568, 1589, 1607, 1625, 1641, 1655, 1676, 1694, 1712, 1720, 1730, 1741,
        1752, 1762, 1771, 1781, 1793, 1804, 1814, 1825, 1837, 1858, 1879, 1898, 1907, 1924, 1942, 1964, 1983, 1995, 2006, 2020, 2036, 2048, 2055, 2067,
        2076, 2087, 2096, 2106, 2115, 2126, 2138, 2147, 2154, 2162, 2172, 2182, 2194, 2205, 2215, 2225, 2236, 2242, 2248, 2260, 2270, 2282, 2288, 2292,
        2297, 2305, 2310, 2313, 2319, 2324, 2329, 2335, 2341, 2348, 2357, 2363, 2372, 2379, 2385, 2391, 2396, 2402, 2413, 2418, 2423, 2429, 2434, 2440,
        2445, 2451, 2460, 2471, 2478, 2482, 2497, 2505, 2510, 2516, 2527, 2538, 2543, 2554, 2564, 2574, 2579, 2593, 2600, 2612, 2617, 2626, 2630, 2641,
        2645, 2654, 2656, 2658, 2661, 2663, 2665, 2667, 2669, 2671, 2673, 2675, 2676, 2677, 2678, 2679, 2680, 2681, 2682, 2683, 2684, 2685, 2686, 2687,
        2688, 2689, 2690, 2691, 2692, 2694, 2696, 2698, 2700, 2703, 2705, 2708, 2710, 2732, 2767, 2777, 2786, 2809, 2828, 2851, 2869, 2885, 2906, 2915,
        2931, 2967, 3007, 3030, 3035, 3078, 3091, 3108, 3141, 3148, 3190, 3201, 3225, 3242, 3252, 3283, 3312, 3355, 3384, 3408, 3417, 3469, 3557, 3600,
        3624, 3671, 3696, 3725, 3790, 3825, 3855, 3870, 3885, 3907, 3935, 3967, 4003, 4041, 4047, 4076, 4109, 4118, 4134, 4147, 4192, 4215, 4290, 4356,
        4369, 4421, 4427, 4437, 4502, 4532, 4543, 4551, 4572, 4590, 4625, 4654, 4696, 4728, 4734, 4784, 4832, 4861, 4868, 4895, 4909, 4930, 4965, 5007,
        5020, 5036, 5063, 5076, 5081, 5140, 5149, 5175, 5187, 5215, 5231, 5256, 5300, 5320, 5370, 5381, 5407, 5439, 5445, 5496, 5547, 5556, 5586, 5645,
        5678, 5712, 5767, 5804, 5827, 5866, 5899, 5940, 5955, 5970, 5999, 6027, 6051, 6107, 6112, 6147, 6206, 6225, 6229, 6269, 6294, 6339, 6368, 6393,
        6419, 6456, 6504, 6517, 6531, 6580, 6617, 6660, 6681, 6722, 6794, 6812, 6829, 6865, 6938, 6955, 6995, 7018, 7056, 7065, 7103, 7150, 7160, 7195,
        7216, 7237, 7271, 7299, 7331, 7366, 7396, 7404, 7417, 7465, 7514, 7521, 7554, 7584, 7639, 7656, 7688, 7698, 7712, 7737, 7751, 7774, 7806, 7830,
        7875, 7893, 7940, 7977, 8044, 8058, 8123, 8131, 8164, 8192, 8224, 8262, 8320, 8336, 8349, 8362, 8385, 8392, 8396, 8417, 8461, 8478, 8490, 8523,
        8552, 8583, 8597, 8625, 8645, 8648, 8652, 8654, 8661, 8664, 8666, 8669, 8675, 8678, 8681, 8685, 8689, 8692, 8697, 8701, 8706, 8710, 8716, 8723,
        8726, 8744, 8769, 8791, 8793, 8795, 8797, 8799, 8801, 8803, 8805, 8807, 8809, 8811, 8813, 8815, 8817, 8819, 8821, 8823, 8825, 8827, 8829, 8831,
        8833, 8835, 8837, 8839, 8841, 8843, 8845, 8847, 8849, 8851, 8853, 8855, 8857, 8859, 8861, 8863, 8865, 8867, 8869, 8871, 8873, 8875, 8877, 8879,
        8881, 8883, 8885, 8887, 8889, 8891, 8893, 8895, 8897, 8899, 8901, 8903, 8905, 8907, 8909, 8911, 8913, 8915, 8917, 8919, 8921, 8923, 8925, 8927,
        8929, 8931, 8933, 8935, 8937, 8939, 8941, 8943, 8945, 8947, 8949, 8951, 8953, 8955, 8957, 8959, 8961, 8963, 8965, 8967, 8969, 8971, 8973, 8975,
        8977, 8979, 8981, 8983, 8985, 8987, 8989, 8991, 8993, 8995, 8997, 8999, 9001, 9003, 9005, 9007, 9009, 9011, 9013, 9015, 9017, 9019, 9021, 9023,
        9025, 9027, 9029, 9031, 9033, 9035, 9037, 9039, 9041, 9043, 9045, 9047, 9049, 9051, 9053, 9055, 9057, 9059, 9061, 9063, 9065, 9067, 9069, 9071,
        9073, 9075, 9077, 9079, 9081, 9083, 9085, 9087, 9089, 9091, 9093, 9095, 9097, 9099, 9101, 9103, 9105, 9107, 9109, 9111, 9113, 9115, 9117, 9119,
        9121, 9123, 9125, 9127, 9129, 9131, 9133, 9135, 9137, 9139, 9141, 9143, 9145, 9147, 9149, 9151, 9153, 9155, 9157, 9159, 9161, 9163, 9165, 9167,
        9169, 9171, 9173, 9175, 9177, 9179, 9181, 9183, 9185, 9187, 9189, 9191, 9193, 9195, 9197, 9199, 9201, 9203, 9205, 9207, 9209, 9211, 9213, 9215,
        9217, 9219, 9221, 9223, 9225, 9227, 9229, 9231, 9233, 9235, 9237, 9239, 9241, 9243, 9245, 9247, 9249, 9251, 9253, 9255, 9257, 9259, 9261, 9263,
        9265, 9267, 9269, 9271, 9273, 9275, 9277, 9279, 9281, 9283, 9285, 9287, 9289, 9291, 9293, 9295, 9297, 9299, 9301, 9303, 9309, 9315, 9321, 9327,
        9336, 9345, 9354, 9363, 9373, 9383, 9388, 9394, 9399, 9405, 9410, 9415, 9420, 9425, 9430, 9435, 9444, 9450, 9456, 9462, 9468, 9473, 9479, 9486,
        9492, 9499, 9506, 9511, 9516, 9523, 9529, 9536, 9542, 9547, 9552, 9558, 9564, 9573, 9582, 9593, 9603, 9614, 9624, 9633, 9642, 9652, 9662, 9672,
        9682, 9692, 9703, 9713, 9714, 9716, 9722, 9727, 9732, 9738, 9742, 9745, 9753, 9757, 9760, 9764, 9768, 9780, 9792, 9796, 9800, 9805, 9810, 9816,
        9821, 9834, 9840, 9845, 9851, 9856, 9862, 9868, 9873, 9878, 9883, 9888, 9897, 9906, 9915, 9920, 9923, 9933, 9943, 9952, 9962, 9971, 9980, 9989,
        9994, 10000, 10006, 10013, 10018, 10024, 10030, 10034, 10038, 10047, 10056, 10065, 10074, 10082, 10089, 10097, 10100, 10108, 10113, 10118, 10129];
    constant [933] short FRAGMENT_LENGTH = [
        0, 1, 9, 6, 1, 20, 2, 1, 3, 13, 4, 1, 1, 2, 2, 3, 2, 5, 5, 8, 12, 6, 6, 4,
        1, 1, 5, 15, 4, 51, 13, 24, 2, 17, 47, 58, 13, 2, 1, 25, 6, 6, 6, 8, 7, 4, 6, 6,
        6, 3, 5, 6, 9, 4, 5, 4, 5, 3, 3, 5, 5, 2, 6, 7, 4, 3, 2, 3, 2, 2, 2, 2,
        2, 2, 3, 3, 3, 3, 3, 3, 3, 4, 4, 5, 10, 11, 7, 9, 6, 5, 4, 7, 5, 7, 6, 4,
        3, 10, 11, 10, 16, 7, 11, 3, 7, 4, 7, 14, 13, 4, 9, 4, 3, 5, 4, 5, 6, 3, 13, 13,
        12, 12, 11, 11, 5, 7, 3, 7, 4, 5, 8, 5, 6, 5, 5, 11, 12, 13, 11, 13, 14, 11, 12, 12,
        14, 12, 14, 14, 13, 13, 13, 14, 17, 15, 15, 16, 12, 13, 17, 13, 14, 19, 15, 15, 16, 16, 16, 13,
        10, 11, 16, 14, 13, 14, 12, 11, 11, 15, 12, 18, 21, 18, 18, 16, 14, 21, 18, 18, 8, 10, 11, 11,
        10, 9, 10, 12, 11, 10, 11, 12, 21, 21, 19, 9, 17, 18, 22, 19, 12, 11, 14, 16, 12, 7, 12, 9,
        11, 9, 10, 9, 11, 12, 9, 7, 8, 10, 10, 12, 11, 10, 10, 11, 6, 6, 12, 10, 12, 6, 4, 5,
        8, 5, 3, 6, 5, 5, 6, 6, 7, 9, 6, 9, 7, 6, 6, 5, 6, 11, 5, 5, 6, 5, 6, 5,
        6, 9, 11, 7, 4, 15, 8, 5, 6, 11, 11, 5, 11, 10, 10, 5, 14, 7, 12, 5, 9, 4, 11, 4,
        9, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 2, 2, 2, 2, 3, 2, 3, 2, 22, 35, 10, 9, 23, 19, 23, 18, 16, 21, 9, 16,
        36, 40, 23, 5, 43, 13, 17, 33, 7, 42, 11, 24, 17, 10, 31, 29, 43, 29, 24, 9, 52, 88, 43, 24,
        47, 25, 29, 65, 35, 30, 15, 15, 22, 28, 32, 36, 38, 6, 29, 33, 9, 16, 13, 45, 23, 75, 66, 13,
        52, 6, 10, 65, 30, 11, 8, 21, 18, 35, 29, 42, 32, 6, 50, 48, 29, 7, 27, 14, 21, 35, 42, 13,
        16, 27, 13, 5, 59, 9, 26, 12, 28, 16, 25, 44, 20, 50, 11, 26, 32, 6, 51, 51, 9, 30, 59, 33,
        34, 55, 37, 23, 39, 33, 41, 15, 15, 29, 28, 24, 56, 5, 35, 59, 19, 4, 40, 25, 45, 29, 25, 26,
        37, 48, 13, 14, 49, 37, 43, 21, 41, 72, 18, 17, 36, 73, 17, 40, 23, 38, 9, 38, 47, 10, 35, 21,
        21, 34, 28, 32, 35, 30, 8, 13, 48, 49, 7, 33, 30, 55, 17, 32, 10, 14, 25, 14, 23, 32, 24, 45,
        18, 47, 37, 67, 14, 65, 8, 33, 28, 32, 38, 58, 16, 13, 13, 23, 7, 4, 21, 44, 17, 12, 33, 29,
        31, 14, 28, 20, 3, 4, 2, 7, 3, 2, 3, 6, 3, 3, 4, 4, 3, 5, 4, 5, 4, 6, 7, 3,
        18, 25, 22, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
        2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
        2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
        2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
        2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
        2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
        2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
        2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
        2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
        2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
        2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 6, 6, 6, 6, 9,
        9, 9, 9, 10, 10, 5, 6, 5, 6, 5, 5, 5, 5, 5, 5, 9, 6, 6, 6, 6, 5, 6, 7, 6,
        7, 7, 5, 5, 7, 6, 7, 6, 5, 5, 6, 6, 9, 9, 11, 10, 11, 10, 9, 9, 10, 10, 10, 10,
        10, 11, 10, 1, 2, 6, 5, 5, 6, 4, 3, 8, 4, 3, 4, 4, 12, 12, 4, 4, 5, 5, 6, 5,
        13, 6, 5, 6, 5, 6, 6, 5, 5, 5, 5, 9, 9, 9, 5, 3, 10, 10, 9, 10, 9, 9, 9, 5,
        6, 6, 7, 5, 6, 6, 4, 4, 9, 9, 9, 9, 8, 7, 8, 3, 8, 5, 5, 11, 10];
    constant integer BUILTIN_EVENT = 0;
    constant integer BUILTIN_BOOLEAN = 1;
    constant integer BUILTIN_SHORT = 2;
    constant integer BUILTIN_INTEGER = 3;
    constant integer BUILTIN_LONG = 4;
    constant integer BUILTIN_UBYTE = 5;
    constant integer BUILTIN_USHORT = 6;
    constant integer BUILTIN_UINTEGER = 7;
    constant integer BUILTIN_ULONG = 8;
    constant integer BUILTIN_POINTER = 9;
    constant integer P_COPY_TYPES = 0;
    constant integer P_START = 1;
    constant integer P_MODEL_NAME = 2;
    constant integer P_MODEL_EQUAL = 3;
    constant integer P_MODEL_OPEN = 4;
    constant integer P_MODEL_QUESTION = 5;
    constant integer P_INPUTS = 6;
    constant integer P_MODEL_BANG = 7;
    constant integer P_OUTPUTS = 8;
    constant integer P_MODEL_CLOSE = 9;
    constant integer P_MODEL_BODY = 10;
    constant integer P_MODEL_AFTER = 11;
    constant integer P_PROGRAM = 12;
    constant integer P_END_SEMICOLON = 13;
    constant integer P_END_CHECK = 14;
    constant integer P_TYPE_STATEMENT = 15;
    constant integer P_TYPE_SKIP = 16;
    constant integer P_TYPE = 17;
    constant integer P_TYPE_SIZE = 18;
    constant integer P_TYPE_CLOSE = 19;
    constant integer P_TYPE_NAME = 20;
    constant integer P_TYPE_INTERN = 21;
    constant integer P_DECLARE_NAME = 22;
    constant integer P_DECLARE_SEPARATOR = 23;
    constant integer P_CONSTANT_NAME = 24;
    constant integer P_CONSTANT_EQUAL = 25;
    constant integer P_CONSTANT_DEFINITION = 26;
    constant integer P_INTEGER_CONSTANT = 27;
    constant integer P_CONSTANT_ELEMENT = 28;
    constant integer P_CONSTANT_SCALAR = 29;
    constant integer P_CONSTANT_SEPARATOR = 30;
    constant integer P_LABEL_NAME = 31;
    constant integer P_LABEL_SEPARATOR = 32;
    constant integer P_PROCESS = 33;
    constant integer P_PATH_COPY = 34;
    constant integer P_GUARD_COLONS = 35;
    constant integer P_ITERATE_NAME = 36;
    constant integer P_ITERATE_OF = 37;
    constant integer P_EQUATION = 38;
    constant integer P_DEPENDENCE = 39;
    constant integer P_EQUATION_END = 40;
    constant integer P_GROUP_MEMBER = 41;
    constant integer P_POP = 42;
    constant integer P_OPERAND = 43;
    constant integer P_PARAMETER = 44;
    constant integer P_PARAMETER_CLOSE = 45;
    constant integer P_OPERATOR = 46;
    constant integer P_BRANCH = 47;
    constant integer P_STALL = 87;
    constant integer P_DONE = 88;
    constant integer P_FAILED = 89;
    constant integer X_EMPTY_CALL = 0;
    constant integer X_LITERAL = 1;
    constant integer X_CALL = 2;
    constant integer X_PARAMETERS = 3;
    constant integer X_SIGNAL = 4;
    constant integer X_OPEN_PAREN = 5;
    constant integer X_IF = 6;
    constant integer X_PREFIX = 7;
    constant integer X_PLUS = 8;
    constant integer X_FAIL = 9;
    constant integer X_REDUCE = 10;
    constant integer X_BINARY = 11;
    constant integer X_THEN = 12;
    constant integer X_ELSE = 13;
    constant integer X_DELAY = 14;
    constant integer X_PREVIOUS = 15;
    constant integer X_OPEN_SQUARE = 16;
    constant integer X_CLOSE = 17;
    constant integer X_COMMA = 18;
    constant integer X_RETURN = 19;
    constant integer FRAME_COMPOSE = 0;
    constant integer FRAME_LABEL = 1;
    constant integer FRAME_GUARD = 2;
    constant integer FRAME_ITERATE = 3;
    constant integer INIT_NONE = 0;
    constant integer INIT_CONST = 1;
    constant integer INIT_ENUMCONST = 2;
    constant integer PHASE_START = 0;
    constant integer PHASE_LABEL = 1;
    constant integer PHASE_USE = 2;
    constant integer PHASE_SIGNAL = 3;
    constant integer PHASE_STATEMENT = 6;
    constant integer PHASE_REWRITE_EQ = 7;
    constant integer PHASE_REWRITE_MEMBER = 8;
    constant integer PHASE_REWRITE_GUARD = 9;
    constant integer PHASE_REWRITE_TRIGGER = 10;
    constant integer PHASE_CLOCK = 11;
    constant integer PHASE_STATE = 12;
    constant integer PHASE_CUR = 13;
    constant integer PHASE_CUR_TAIL = 14;
    constant integer PHASE_GROUP = 15;
    constant integer PHASE_GUARD_START = 16;
    constant integer PHASE_DEFINE_PARSE = 17;
    constant integer PHASE_DEFINE_FINISH = 18;
    constant integer PHASE_READ_PARSE = 19;
    constant integer PHASE_READ_FINISH = 20;
    constant integer PHASE_READ_MEMBERS = 21;
    constant integer PHASE_READ_DEPS = 22;
    constant integer PHASE_ON = 23;
    constant integer PHASE_FILTER = 24;
    constant integer PHASE_DONE = 25;
    constant integer PHASE_FAILED = 26;
    constant integer CONDITION_PRECEDENCE = 9;
    constant integer DELAY_PRECEDENCE = 21;
    constant integer SHAPE_NAME = 0;
    constant integer SHAPE_NUMBER = 1;
    constant integer SHAPE_FRAGMENT = 2;
    constant integer SHAPE_POSITION = 3;
    constant integer SHAPE_TYPE = 4;
    constant integer SHAPE_LIST = 7;
    constant integer SHAPE_GROUP = 8;
    constant integer SHAPE_USE = 5;
    constant integer SHAPE_END_POINT = 6;
    constant integer LIST_NONE = 0;
    constant integer LIST_NAMES = 1;
    constant integer LIST_NUMBERS = 2;
    constant integer LIST_OPS = 3;
    constant integer LIST_ARGS = 4;
    constant [103] short COLUMN_SHAPE = [
        0, 2, 1, 1, 4, 7, 1, 1, 0, 0, 1, 1, 1, 7, 0, 2, 1, 1, 3, 0, 1, 1, 1, 7,
        0, 7, 7, 3, 1, 2, 1, 7, 7, 1, 7, 7, 3, 7, 7, 0, 0, 5, 0, 3, 1, 8, 3, 1,
        7, 6, 6, 3, 1, 7, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 7, 3, 1, 1, 7, 1, 0,
        1, 1, 1, 1, 7, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1,
        1, 1, 1, 1, 7, 7, 1];
    constant [103] short COLUMN_LIST_KIND = [
        0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2,
        0, 3, 4, 0, 0, 0, 0, 1, 2, 0, 3, 4, 0, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0,
        0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 2, 2, 0];
    constant integer SA_NAME = 0;
    constant integer SA_NUMBER = 1;
    constant integer SA_FRAGMENT = 2;
    constant integer SA_LINE = 3;
    constant integer SA_COLUMN = 4;
    constant integer SA_TYPE_HEAD = 5;
    constant integer SA_TYPE_ELEMENT = 6;
    constant integer IC_HEADER = 0;
    constant integer IC_NEWLINE = 1;
    constant integer IC_OPEN = 2;
    constant integer IC_CLOSE = 3;
    constant integer IC_NAME = 4;
    constant integer IC_TOKEN = 5;
    constant integer IC_NUMBER = 6;
    constant integer IC_FRAGMENT = 7;
    constant integer IC_SIZE = 8;
    constant integer AA_OPEN = 0;
    constant integer AA_CLOSE = 1;
    constant integer AA_NAME = 2;
    constant integer AA_LINE = 3;
    constant integer AA_COLUMN = 4;
    constant integer AA_VALUE = 5;
    constant integer AA_TYPE_NUMBER = 6;
    constant integer AA_TYPE_NAME = 7;
    constant integer AA_VALUE_NAME = 8;
    constant integer AA_INIT_LINE = 9;
    constant integer AA_INIT_COLUMN = 10;
    constant integer AA_NONE = 11;
    constant integer AA_CONST = 12;
    constant integer AA_ENUMCONST = 13;
    constant integer AA_PARAMS = 14;
    constant integer AA_COUNT = 15;
    constant integer SCALAR_WIDTH = 4;
    constant [9] short SCALAR_LENGTH = [
        1, 1, 1, 2, 2, 4, 3, 0, 0];
    constant [36] short SCALAR_PROGRAM = [
        0, 0, 0, 0, 1, 0, 0, 0, 2, 0, 0, 0, 3, 4, 0, 0, 5, 6, 0, 0, 1, 0, 3, 4,
        0, 3, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    constant integer OP_TOTAL = 75;
    constant integer ARG_WIDTH = 13;
    constant integer CALL_PARAMS_STEP = 4;
    constant integer PARAM_STEPS = 6;
    constant [78] short ARG_LENGTH = [
        4, 5, 6, 7, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
        4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 7, 4, 4, 4, 4, 4, 4, 4, 4, 4,
        4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
        4, 4, 4, 5, 11, 13];
    constant [1014] short ARG_PROGRAM = [
        0, 5, 6, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 3, 4, 1, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 7, 8, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 2, 14, 15, 1, 0, 0,
        0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4,
        1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3,
        4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4,
        1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 2, 14, 15, 1, 0, 0, 0,
        0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3,
        4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4,
        1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3,
        4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 11, 1, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 3, 4, 0, 12, 0, 5, 6, 1, 1, 1, 0, 0, 0, 3, 4, 0, 13, 0, 7,
        8, 9, 10, 1, 1, 1];
    constant integer F_HASH = 24;
    constant integer F_DOT = 25;
    constant integer F_CALL_SUFFIX = 26;
    constant integer N_INDICES = 55;
    constant integer OP_EFFECT = 38;
    constant integer F_CAP_INSTANCES = 265;
    constant integer F_CAP_INSTANTIATE = 266;
    constant integer T_SIGNAL_UNDECLARED = 62;
    constant integer T_LABEL_AS_SIGNAL = 63;
    constant integer T_CONVERSION_ONE = 64;
    constant integer T_INDICES_CONSTANT = 65;
    constant integer T_CALLS_IN_ITERATE = 66;
    constant integer T_UNSAFE_CALL = 67;
    constant integer T_MODEL_UNDECLARED = 68;
    constant integer T_NO_STATIC_PARAMETERS = 69;
    constant integer T_CALLS_ITSELF = 70;
    constant integer T_TOO_MANY_OUTPUTS = 71;
    constant integer IC_PREFIX = 9;
    constant integer N_STORE = 11;
    constant integer N_SYSCALL = 12;
    constant integer IP_ROOT = 0;
    constant integer IP_INSTANCE = 1;
    constant integer IP_LABEL = 2;
    constant integer IP_SIGNAL = 3;
    constant integer IP_FINISH_SIGNAL = 4;
    constant integer IP_LOOP = 5;
    constant integer IP_EQUATION = 6;
    constant integer IP_FINISH_EQUATION = 7;
    constant integer IP_GROUP = 8;
    constant integer IP_FINISH_GROUP = 9;
    constant integer IP_DEPENDENCE = 10;
    constant integer IP_ENTRY = 11;
    constant integer IP_ANCESTRY = 12;
    constant integer IP_PATH = 13;
    constant integer IP_INPUT = 14;
    constant integer IP_EMIT = 15;
    constant integer IP_DONE = 16;
    constant integer IP_FAILED = 17;
    constant integer OP_INPUT = 39;
    constant integer OP_COPY = 40;
    constant integer OP_CONVERT = 41;
    constant integer OP_TABLE = 42;
    constant integer OP_ELEMENT = 43;
    constant integer OP_GATHER = 44;
    constant integer OP_ITER = 45;
    constant integer OP_SEED = 46;
    constant integer OP_ARG = 47;
    constant [75] short OP_MONOCHRONOUS = [
        0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 1, 0, 1,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0];
    constant [75] short OP_TEXT_FRAGMENT = [
        0, 0, 0, 0, 300, 0, 0, 38, 532, 533, 313, 534, 534, 535, 533, 536, 537, 538, 306, 295, 311, 296, 312, 297,
        301, 38, 302, 303, 539, 540, 541, 542, 1, 298, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 543, 544, 545, 546, 547, 323, 0, 0, 0, 0,
        0, 0, 0];
    constant integer COL_ROWS_OP = 54;
    constant integer COL_ROWS_LEFT = 55;
    constant integer COL_ROWS_RIGHT = 56;
    constant integer COL_ROWS_VALUE = 57;
    constant integer COL_ROWS_TYPE = 58;
    constant integer COL_ROWS_CTX = 59;
    constant integer COL_ROWS_LINE = 60;
    constant integer COL_ROWS_COLUMN = 61;
    constant integer COL_ROWS_OWNER = 62;
    constant integer COL_ROWS_LOOP = 63;
    constant integer COL_ROWS_GUARD = 64;
    constant integer COL_ROWS_GROUPS = 65;
    constant integer COL_ROWS_GROUP_POSITIONS = 66;
    constant integer COL_ROWS_DEPENDENCE_FROM = 67;
    constant integer COL_ROWS_DEPENDENCE_TO = 68;
    constant integer COL_ROWS_WAR = 69;
    constant integer COL_ROWS_SNAPSHOTTED = 70;
    constant integer COL_ROWS_EFFECTS_KIND = 71;
    constant integer COL_ROWS_EFFECTS_RESOURCE = 72;
    constant integer COL_ROWS_EFFECTS_PARAM = 73;
    constant integer COL_LOOPS_INDEX = 74;
    constant integer COL_LOOPS_SIZE = 75;
    constant integer COL_LOOPS_DEFINED = 76;
    constant integer COL_LOOPS_SNAPSHOTS = 77;
    constant integer COL_LOOPS_COUNT = 78;
    constant integer F_CAP_LOOKUPS = 267;
    constant integer F_CAP_ROWS = 268;
    constant integer F_CAP_ROW_DEPENDENCES = 269;
    constant integer F_CAP_SEGMENTS = 270;
    constant integer F_CAP_LOWER = 271;
    constant integer A_FLAT = 9;
    constant integer A_TEXT = 10;
    constant integer A_LONG = 11;
    constant integer T_FLAT_UNDECLARED = 72;
    constant integer T_STATIC_COUNT = 73;
    constant integer T_WORD_CONSTANT = 74;
    constant integer T_TYPE_UNDECLARED_TEXT = 75;
    constant integer T_RESOURCE_EXTERNAL = 76;
    constant integer T_ACCESS_TYPE = 77;
    constant integer T_WORD_RANGE = 78;
    constant integer T_PAIR_OPERAND = 79;
    constant integer T_INPUT_POINTER = 80;
    constant integer T_STORE_TYPE = 81;
    constant integer T_SYSCALL_INPUT = 82;
    constant integer T_INSTRUCTION_INPUT = 83;
    constant integer T_NOT_IN_ITERATE = 84;
    constant integer T_ARRAY_VALUE = 85;
    constant integer T_PREV_SIGNAL = 86;
    constant integer T_PREV_OUTSIDE = 87;
    constant integer T_PREV_UNDEFINED = 88;
    constant integer T_NOT_ARRAY = 89;
    constant integer T_RANGE_START = 90;
    constant integer T_RANGE_BOUND = 91;
    constant integer T_INDEX_INTEGER = 92;
    constant integer T_NEXT_PAIR = 93;
    constant integer T_INDEX_RANGE = 94;
    constant integer T_NEXT_TYPE = 95;
    constant integer T_DELAY_ARRAY = 96;
    constant integer T_SCALAR_OPERANDS = 97;
    constant integer T_IF_TYPES = 98;
    constant integer T_IF_CONDITION = 99;
    constant integer T_EFFECT_IN_IF = 100;
    constant integer T_NO_CONVERSION = 101;
    constant integer T_POINTER_OFFSET = 102;
    constant integer T_INTEGER_OPERANDS = 103;
    constant integer T_COMPARABLE = 104;
    constant integer T_ONE_TYPE = 105;
    constant integer T_BOOLEAN_OPERANDS = 106;
    constant integer T_UNSIGNED_OPERANDS = 107;
    constant integer T_WHEN_CONDITION = 108;
    constant integer T_DELAY_MATCH = 109;
    constant integer T_ENUM_UNDECLARED = 110;
    constant integer T_ENUM_AMBIGUOUS = 111;
    constant integer T_TYPE_UNDECLARED = 112;
    constant integer T_NO_VALUE = 113;
    constant integer T_ITERATE_INDEX = 114;
    constant integer T_INDEX_DEFINED = 115;
    constant integer T_WITH_UNDEFINED = 116;
    constant integer T_WITH_READS = 117;
    constant integer T_WITH_ARRAY = 118;
    constant integer T_SIGNAL_TYPE = 119;
    constant integer T_INPUT_DEFINED = 120;
    constant integer T_DEFINED_TWICE = 121;
    constant integer T_RANGE_DEFINES = 122;
    constant integer T_ARRAY_DEFINITION = 123;
    constant integer T_NEVER_DEFINED = 124;
    constant integer T_RANGE_INDEX = 125;
    constant integer LS_SIGNAL = 0;
    constant integer LS_LABEL = 1;
    constant integer LS_VALUE = 2;
    constant integer LS_ARRAY = 3;
    constant integer LS_TABLE = 4;
    constant integer LS_LOOP = 5;
    constant integer LS_EQUATION = 6;
    constant integer LS_GROUP = 7;
    constant integer LS_ROWS = 8;
    constant integer LS_START = 8;
    constant integer LS_SCAN = 9;
    constant integer LS_ENTRY = 10;
    constant integer LS_NEVER = 11;
    constant integer LS_MEMBERS = 12;
    constant integer LS_DONE = 13;
    constant integer LS_FAILED = 14;
    constant integer PS_DEPENDENCE = 0;
    constant integer PS_ROWS = 1;
    constant integer PS_COUNT = 2;
    constant integer PS_PREFIX = 2;
    constant integer PS_PLACE = 3;
    constant integer PS_WALK = 4;
    constant integer PS_SIZE = 6;
    constant integer PS_DONE = 7;
    constant integer PS_FAILED = 8;
    constant integer XS_PLACE = 0;
    constant integer XS_PAIRS = 1;
    constant integer XS_PREV = 2;
    constant integer XS_DONE = 3;
    constant integer XS_FAILED = 4;
    constant integer PS_LABELSUM = 5;
    constant integer KEY_STRIDE = 8;
    constant integer KEY_SIGNAL = 0;
    constant integer KEY_LABEL = 1;
    constant integer KEY_CALL_LABEL = 2;
    constant integer KEY_VALUE = 3;
    constant integer KEY_PAIR = 4;
    constant integer KEY_ARRAY = 5;
    constant integer ORDER_PROGRAM_START = 0;
    constant integer ORDER_PROGRAM_END = 54;
    constant integer ORDER_ROWS_START = 54;
    constant integer ORDER_ROWS_END = 88;
    constant [112] short DUMP_ORDER = [
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23,
        24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47,
        48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71,
        72, 73, 74, 75, 76, 77, 78, 1, 2, 3, 4, 5, 6, 7, 22, 23, 79, 80, 81, 82, 83, 84, 85, 86,
        87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102];
    constant [5] short CLOCK_KIND_FRAGMENT = [
        10, 548, 549, 550, 551];
    constant integer ORDER_CLOCKS_START = 88;
    constant integer ORDER_CLOCKS_END = 108;
    constant integer COL_PARENT = 79;
    constant integer COL_SAMPLE_ROWS = 80;
    constant integer COL_DEF_KIND = 81;
    constant integer COL_DEF_TARGET = 82;
    constant integer COL_DEF_LEFT = 83;
    constant integer COL_DEF_RIGHT = 84;
    constant integer COL_DEF_LINE = 85;
    constant integer COL_DEF_COLUMN = 86;
    constant integer COL_DEF_PENDING = 87;
    constant integer COL_OB_SMALL = 88;
    constant integer COL_OB_BIG = 89;
    constant integer COL_OB_LINE = 90;
    constant integer COL_OB_COLUMN = 91;
    constant integer COL_NODE_KIND = 92;
    constant integer COL_NODE_PARENT = 93;
    constant integer COL_NODE_DEPTH = 94;
    constant integer COL_NODE_ROOT = 95;
    constant integer COL_NODE_LEFT = 96;
    constant integer COL_NODE_RIGHT = 97;
    constant integer COL_ROOTS = 98;
    constant integer F_CAP_CLOCKS = 272;
    constant integer F_CAP_DEFINITIONS = 273;
    constant integer F_CAP_OBLIGATIONS = 274;
    constant integer F_CAP_PAIRS = 275;
    constant integer F_CAP_CLOCK_NAMES = 276;
    constant integer A_CLOCK = 12;
    constant integer T_NO_CLOCK = 126;
    constant integer T_DELAY_CONSTANT = 127;
    constant integer T_FITS_NO_TREE = 128;
    constant integer T_TWO_DEFINITIONS = 129;
    constant integer T_CLOCK_CYCLE = 130;
    constant integer T_GUARD_CYCLE = 131;
    constant integer T_NOT_INSIDE = 132;
    constant integer T_INPUT_ROOT = 133;
    constant integer KS_ROWS = 0;
    constant integer KS_SAMPLES = 1;
    constant integer KS_GROUPS = 2;
    constant integer KS_REWRITE = 3;
    constant integer KS_TARGETS = 4;
    constant integer KS_GUARDS = 5;
    constant integer KS_SCAN = 6;
    constant integer KS_DEFS = 7;
    constant integer KS_WAIT = 8;
    constant integer KS_DONE = 9;
    constant integer KS_FAILED = 10;
    constant integer OS_START = 0;
    constant integer OS_WALK = 1;
    constant integer OS_DONE = 2;
    constant integer OS_FAILED = 3;
    constant integer CLK_NONE = 0;
    constant integer CLK_ROOT = 1;
    constant integer CLK_SAMPLE = 2;
    constant integer CLK_PRODUCT = 3;
    constant integer CLK_SUM = 4;
    constant integer F_EXPRESSION_AT = 27;
    constant integer F_AT = 28;
    constant integer ORDER_SCHEDULE_START = 108;
    constant integer ORDER_SCHEDULE_END = 112;
    constant integer COL_ORDER = 99;
    constant integer COL_LOOP_ORDERS = 100;
    constant integer COL_SNAPSHOTS = 101;
    constant integer COL_SNAPSHOTTED = 102;
    constant integer F_CAP_EDGES = 279;
    constant integer F_CAP_SCHEDULE_NODES = 280;
    constant integer F_CAP_EFFECTS = 281;
    constant integer T_SIGNAL_CYCLE = 134;
    constant integer T_EFFECT_CYCLE = 135;
    constant integer T_CLOCK_CAUSALITY = 136;
    constant integer T_EFFECTS_UNORDERED = 137;
    constant integer F_CAP_UNITS = 283;
    constant integer F_CAP_MICRO_OPS = 284;
    constant integer F_CAP_CODE = 285;
    constant integer F_CAP_CODE_LABELS = 286;
    constant integer F_CAP_DATA = 287;
    constant integer F_CAP_CODE_TEXT = 288;
    constant integer T_ARRAYS_ADDRESS = 138;
    constant integer LAYOUT_DUMP_CODE = 6;
    constant integer FORM_MOVZ_X = 0;
    constant integer FORM_MOVZ_W = 1;
    constant integer FORM_MOVK_X = 2;
    constant integer FORM_MOVK_W = 3;
    constant integer FORM_ADD_X_IMM = 4;
    constant integer FORM_ADD_W_IMM = 5;
    constant integer FORM_SUB_X_IMM = 6;
    constant integer FORM_SUB_W_IMM = 7;
    constant integer FORM_SUBS_X_IMM = 8;
    constant integer FORM_SUBS_W_IMM = 9;
    constant integer FORM_ADD_X = 10;
    constant integer FORM_ADDS_X = 11;
    constant integer FORM_SUB_X = 12;
    constant integer FORM_SUBS_X = 13;
    constant integer FORM_AND_X = 14;
    constant integer FORM_AND_W = 15;
    constant integer FORM_ORR_X = 16;
    constant integer FORM_ORR_W = 17;
    constant integer FORM_EOR_X = 18;
    constant integer FORM_ORN_X = 19;
    constant integer FORM_EOR_X_ONE = 20;
    constant integer FORM_LSLV_X = 21;
    constant integer FORM_LSRV_X = 22;
    constant integer FORM_SDIV_X = 23;
    constant integer FORM_UDIV_X = 24;
    constant integer FORM_MUL_X = 25;
    constant integer FORM_MSUB_X = 26;
    constant integer FORM_UMULH_X = 27;
    constant integer FORM_CSEL_X = 28;
    constant integer FORM_CSINC_W = 29;
    constant integer FORM_CSNEG_X = 30;
    constant integer FORM_LDR_X = 31;
    constant integer FORM_LDR_W = 32;
    constant integer FORM_LDRSW_X = 33;
    constant integer FORM_LDRH_W = 34;
    constant integer FORM_LDRSH_X = 35;
    constant integer FORM_LDRB_W = 36;
    constant integer FORM_STR_X = 37;
    constant integer FORM_STR_W = 38;
    constant integer FORM_STRH_W = 39;
    constant integer FORM_STRB_W = 40;
    constant integer FORM_LDR_X_REG = 41;
    constant integer FORM_LDR_W_REG = 42;
    constant integer FORM_LDRSW_X_REG = 43;
    constant integer FORM_LDRH_W_REG = 44;
    constant integer FORM_LDRSH_X_REG = 45;
    constant integer FORM_LDRB_W_REG = 46;
    constant integer FORM_STR_X_REG = 47;
    constant integer FORM_STR_W_REG = 48;
    constant integer FORM_STRH_W_REG = 49;
    constant integer FORM_STRB_W_REG = 50;
    constant integer FORM_LDR_X_POST = 51;
    constant integer FORM_STR_X_POST = 52;
    constant integer FORM_STR_W_POST = 53;
    constant integer FORM_STRB_W_POST = 54;
    constant integer FORM_LDRB_W_PRE = 55;
    constant integer FORM_B = 56;
    constant integer FORM_BL = 57;
    constant integer FORM_B_COND = 58;
    constant integer FORM_CBZ_W = 59;
    constant integer FORM_CBZ_X = 60;
    constant integer FORM_CBNZ_X = 61;
    constant integer FORM_ADRP = 62;
    constant integer FORM_RET = 63;
    constant integer FORM_SVC_80 = 64;
    constant integer FORM_WORD = 65;
    constant integer CC_EQ = 0;
    constant integer CC_NE = 1;
    constant integer CC_HS = 2;
    constant integer CC_LO = 3;
    constant integer CC_HI = 8;
    constant integer CC_LS = 9;
    constant integer CC_GE = 10;
    constant integer CC_LT = 11;
    constant integer CC_GT = 12;
    constant integer CC_LE = 13;
    constant integer MK_EMIT = 0;
    constant integer MK_LI = 1;
    constant integer MK_LOAD = 2;
    constant integer MK_STORE = 3;
    constant integer MK_OPERAND = 4;
    constant integer MK_ADDRESS = 5;
    constant integer MK_PLACE = 6;
    constant integer TG_NONE = 0;
    constant integer TG_LABEL = 1;
    constant integer TG_TABLE = 2;
    constant integer TG_WINDOW = 3;
    constant integer TG_SIG = 4;
    constant integer TG_MEM = 5;
    constant integer TG_CLK = 6;
    constant integer TG_IN = 7;
    constant integer TG_OUT = 8;
    constant integer TG_MALFORMED_TEXT = 9;
    constant integer TG_RESERVE_TEXT = 10;
    constant integer GL_MALFORMED = 0;
    constant integer GL_RESERVE_FAILED = 1;
    constant integer GL_READ_VALUE = 2;
    constant integer GL_PUT_INT = 3;
    constant integer GL_PUT_UINT = 4;
    constant integer GL_PUT_BOOL = 5;
    constant integer GL_STEP = 6;
    constant integer GL_READ_DONE = 7;
    constant integer ES_ROW = 0;
    constant integer ES_LEFT = 1;
    constant integer ES_RIGHT = 2;
    constant integer ES_RIGHT_LEFT = 3;
    constant integer ES_RIGHT_RIGHT = 4;
    constant integer ES_PARAM = 5;
    constant integer ES_VALUE_ROW = 6;
    constant integer ES_ARG0 = 7;
    constant integer ES_ARG1 = 8;
    constant integer ES_ARG2 = 9;
    constant integer ES_ARG3 = 10;
    constant integer ES_ARG4 = 11;
    constant integer ES_ARG5 = 12;
    constant integer ES_ARG6 = 13;
    constant integer ES_TYPE_ROW = 14;
    constant integer ES_SIZE_LEFT = 15;
    constant integer ES_SIZE_ROW = 16;
    constant integer ES_WORDS_ROW = 17;
    constant integer ES_KEY_LEFT = 18;
    constant integer ES_KEY_RIGHT = 19;
    constant integer ES_KEY_OWNER = 20;
    constant integer ES_KEY_A_RIGHT = 21;
    constant integer ES_KEY_A_ROW = 22;
    constant integer ES_KEY_P_ROW = 23;
    constant integer ES_CLOCK_ROW = 24;
    constant integer ES_CLOCK_LEFT = 25;
    constant integer ES_CLOCK_LOOP = 26;
    constant integer ES_NODE_PARENT = 27;
    constant integer ES_NODE_LEFT = 28;
    constant integer ES_NODE_RIGHT = 29;
    constant integer ES_ROOT_POSITION = 30;
    constant integer ES_INPUT_ROOT_POSITION = 31;
    constant integer ES_INPUT_BOUND = 32;
    constant integer ES_LOOP_COUNT = 33;
    constant integer ES_LOOP_SIZE = 34;
    constant integer ES_LOOP_SIZE_LESS_ONE = 35;
    constant integer ES_LOOP_CONDITION = 36;
    constant integer ES_WINDOW_OFFSET = 37;
    constant integer ES_WINDOW_BYTES = 38;
    constant integer ES_RESERVATION = 39;
    constant integer ES_LINE_CAPACITY = 40;
    constant integer ES_ROOT_COUNT = 41;
    constant integer ES_LOAD_PARAM = 42;
    constant integer ES_STORE_PARAM = 43;
    constant integer ES_LOAD_INDEXED_ROW = 44;
    constant integer ES_LOAD_INDEXED_INDEX = 45;
    constant integer ES_LOAD_INDEXED_ELEMENT = 46;
    constant integer ES_STORE_INDEXED_ELEMENT = 47;
    constant integer ES_INSTRUCTION_OP = 48;
    constant integer ES_SHIFT_OP = 49;
    constant integer ES_PAIR_FORM = 50;
    constant integer ES_SIGNED_CONDITION = 51;
    constant integer ES_UNSIGNED_CONDITION = 52;
    constant integer ES_LOOP_START = 53;
    constant integer ES_LOOP_END = 54;
    constant integer ES_LOCAL0 = 55;
    constant integer ES_LOCAL1 = 56;
    constant integer ES_LOCAL2 = 57;
    constant integer ES_LOCAL3 = 58;
    constant integer ES_LOCAL4 = 59;
    constant integer ES_PUT_OUTPUT = 60;
    constant integer ES_MALFORMED = 69;
    constant integer ES_RESERVE_FAILED = 70;
    constant integer ES_READ_VALUE = 71;
    constant integer ES_PUT_INT = 72;
    constant integer ES_PUT_UINT = 73;
    constant integer ES_PUT_BOOL = 74;
    constant integer ES_STEP = 75;
    constant integer ES_READ_DONE = 76;
    constant integer EP_ALWAYS = 0;
    constant integer EP_FLAG = 1;
    constant integer EP_HAS_ARG1 = 2;
    constant integer EP_HAS_ARG2 = 3;
    constant integer EP_HAS_ARG3 = 4;
    constant integer EP_HAS_ARG4 = 5;
    constant integer EP_HAS_ARG5 = 6;
    constant integer EP_HAS_ARG6 = 7;
    constant integer EP_RIGHT_LOADS = 8;
    constant integer EP_COUNTED = 9;
    constant integer EP_UNCOUNTED = 10;
    constant integer EP_BOUNDED = 11;
    constant integer EP_KEYS_DIFFER = 12;
    constant integer ET_PROLOGUE = 0;
    constant integer ET_RESERVE = 1;
    constant integer ET_WINDOW = 2;
    constant integer ET_JUMP_STEP = 3;
    constant integer ET_RESERVE_FAILED = 4;
    constant integer ET_READ_VALUE = 5;
    constant integer ET_STEP = 6;
    constant integer ET_READ_LINE = 7;
    constant integer ET_VALUE_INPUT = 8;
    constant integer ET_READ_TAIL = 9;
    constant integer ET_LOOP_HEAD = 10;
    constant integer ET_LOOP_MID = 11;
    constant integer ET_SNAPSHOT = 12;
    constant integer ET_LOOP_TAIL = 13;
    constant integer ET_CLOCK_ROOT_READ = 14;
    constant integer ET_CLOCK_ROOT = 15;
    constant integer ET_CLOCK_SAMPLE = 16;
    constant integer ET_CLOCK_PAIR = 17;
    constant integer ET_ROW_SEED_ARRAY = 18;
    constant integer ET_ROW_SEED = 19;
    constant integer ET_ROW_LOAD = 20;
    constant integer ET_ROW_STORE = 21;
    constant integer ET_ROW_SYSCALL = 22;
    constant integer ET_ROW_INSTRUCTION = 23;
    constant integer ET_ROW_ITER_RANGE = 24;
    constant integer ET_ROW_ITER = 25;
    constant integer ET_ROW_PREV = 26;
    constant integer ET_ROW_ELEMENT = 27;
    constant integer ET_ROW_GATHER = 28;
    constant integer ET_ROW_NEXT = 29;
    constant integer ET_ROW_CONST = 30;
    constant integer ET_ROW_DELAY = 31;
    constant integer ET_ROW_ONE = 32;
    constant integer ET_ROW_IF = 33;
    constant integer ET_ROW_DEFAULT = 34;
    constant integer ET_ROW_PLAIN = 35;
    constant integer ET_ROW_NEG = 36;
    constant integer ET_ROW_NOT_LOGICAL = 37;
    constant integer ET_ROW_NOT = 38;
    constant integer ET_ROW_BINARY = 39;
    constant integer ET_ROW_DIV_SIGNED = 40;
    constant integer ET_ROW_DIV = 41;
    constant integer ET_ROW_COMPARE_SIGNED = 42;
    constant integer ET_ROW_COMPARE = 43;
    constant integer ET_ROW_MOD_SIGNED = 44;
    constant integer ET_ROW_MOD = 45;
    constant integer ET_ROW_SHIFT = 46;
    constant integer ET_DELAY = 47;
    constant integer ET_OUTPUT_HEAD = 48;
    constant integer ET_OUTPUT = 49;
    constant integer ET_OUTPUT_TAIL = 50;
    constant integer ET_FINISH = 51;
    constant integer GLOBAL_LABEL_COUNT = 11;
    constant integer ET_COUNT = 108;
    constant [108] integer ET_START = [
        0, 3, 13, 22, 23, 33, 69, 71, 110, 121, 147, 149, 158, 166, 176, 181, 183, 187, 191, 202, 207, 213, 219, 232,
        239, 244, 250, 255, 267, 287, 306, 311, 316, 321, 330, 339, 345, 352, 359, 366, 373, 380, 387, 395, 403, 416, 424, 433,
        438, 440, 451, 459, 499, 503, 507, 509, 513, 515, 521, 524, 537, 587, 595, 600, 602, 612, 615, 636, 637, 641, 657, 666,
        682, 688, 692, 696, 710, 717, 725, 733, 741, 749, 757, 764, 781, 807, 831, 838, 845, 853, 869, 883, 891, 902, 911, 921,
        936, 962, 971, 990, 1009, 1045, 1056, 1086, 1093, 1095, 1108, 1120];
    constant [108] integer ET_LENGTH = [
        3, 10, 9, 1, 10, 36, 2, 39, 11, 26, 2, 9, 8, 10, 5, 2, 4, 4, 11, 5, 6, 6, 13, 7,
        5, 6, 5, 12, 20, 19, 5, 5, 5, 9, 9, 6, 7, 7, 7, 7, 7, 7, 8, 8, 13, 8, 9, 5,
        2, 11, 8, 40, 4, 4, 2, 4, 2, 6, 3, 13, 50, 8, 5, 2, 10, 3, 21, 1, 4, 16, 9, 16,
        6, 4, 4, 14, 7, 8, 8, 8, 8, 8, 7, 17, 26, 24, 7, 7, 8, 16, 14, 8, 11, 9, 10, 15,
        26, 9, 19, 19, 36, 11, 30, 7, 2, 13, 12, 93];
    constant [108] integer ET_LABELS = [
        0, 0, 0, 0, 0, 4, 0, 5, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 2, 1, 1, 1, 1, 1,
        1, 1, 1, 2, 3, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        0, 2, 0, 3, 0, 0, 0, 0, 0, 0, 0, 1, 3, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0,
        0, 0, 0, 2, 1, 1, 1, 1, 1, 1, 1, 2, 3, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 2, 1, 1, 1, 0, 2, 1, 4];
    constant [1213] integer STEP_KIND = [
        0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 6,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0,
        6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 6, 0, 6, 0, 0,
        0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 1, 0, 0, 0, 6,
        1, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 6, 1, 0, 0, 0, 0, 0, 1, 0, 0, 3,
        6, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 6, 2, 0, 0, 4, 1, 0, 0, 0, 0, 0, 6, 5, 5, 1, 6, 0, 0, 0, 0, 0, 4,
        1, 0, 0, 0, 1, 0, 0, 6, 1, 0, 0, 0, 3, 0, 3, 2, 4, 0, 3, 2, 2, 0, 3, 2,
        0, 5, 5, 1, 6, 0, 0, 0, 0, 6, 2, 0, 4, 3, 6, 2, 0, 4, 0, 3, 6, 2, 0, 4,
        4, 0, 6, 2, 0, 4, 4, 4, 4, 4, 4, 4, 0, 0, 3, 6, 2, 0, 4, 0, 0, 3, 6, 2,
        0, 0, 3, 6, 2, 0, 5, 0, 3, 6, 2, 0, 2, 3, 6, 2, 0, 5, 4, 1, 0, 0, 0, 0,
        6, 3, 6, 2, 0, 5, 5, 5, 0, 6, 0, 0, 1, 0, 0, 0, 6, 0, 0, 1, 0, 0, 6, 2,
        0, 5, 5, 1, 6, 0, 0, 0, 0, 5, 4, 4, 1, 0, 0, 0, 6, 6, 2, 0, 4, 3, 6, 2,
        0, 2, 3, 6, 2, 0, 0, 3, 6, 2, 0, 4, 4, 4, 0, 0, 3, 6, 2, 0, 2, 4, 4, 0,
        0, 3, 6, 2, 0, 4, 4, 3, 6, 2, 0, 4, 4, 0, 3, 6, 2, 0, 4, 4, 0, 3, 6, 2,
        0, 4, 4, 0, 3, 6, 2, 0, 4, 4, 0, 3, 6, 2, 0, 4, 4, 0, 3, 6, 2, 0, 4, 4,
        0, 3, 6, 2, 0, 4, 4, 0, 0, 3, 6, 2, 0, 4, 4, 0, 0, 3, 6, 2, 0, 4, 4, 0,
        0, 0, 0, 0, 0, 0, 3, 6, 2, 0, 4, 4, 0, 0, 3, 6, 2, 0, 4, 4, 0, 0, 0, 3,
        6, 2, 0, 2, 3, 6, 0, 0, 0, 0, 2, 0, 2, 0, 0, 6, 0, 0, 6, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 6,
        0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0,
        0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 6, 0,
        0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 2, 0, 0, 0, 0, 4, 1, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 6, 5, 5, 1, 6, 0, 0, 0, 0, 0, 0, 4, 1, 0, 0, 0,
        0, 0, 0, 0, 0, 1, 0, 0, 0, 6, 1, 0, 0, 0, 0, 3, 2, 4, 0, 3, 2, 2, 0, 3,
        2, 0, 0, 0, 5, 5, 1, 6, 0, 0, 0, 0, 0, 6, 2, 0, 0, 0, 4, 3, 6, 2, 0, 0,
        0, 4, 7, 3, 6, 2, 0, 0, 0, 4, 4, 8, 6, 2, 0, 0, 0, 4, 0, 3, 6, 2, 0, 0,
        0, 0, 0, 3, 6, 2, 0, 0, 0, 5, 7, 3, 6, 2, 0, 0, 0, 2, 3, 6, 2, 0, 0, 0,
        5, 4, 1, 0, 0, 0, 0, 0, 0, 7, 6, 3, 6, 2, 0, 0, 0, 5, 5, 5, 0, 6, 7, 0,
        0, 1, 0, 0, 0, 0, 7, 6, 8, 0, 1, 0, 0, 0, 6, 2, 0, 0, 0, 5, 5, 1, 6, 0,
        0, 0, 0, 0, 5, 4, 4, 1, 0, 0, 0, 0, 8, 6, 6, 2, 0, 0, 0, 4, 3, 6, 2, 0,
        0, 0, 2, 3, 6, 2, 0, 0, 0, 0, 0, 3, 6, 2, 0, 0, 0, 4, 4, 4, 0, 0, 0, 0,
        0, 0, 0, 3, 6, 2, 0, 0, 0, 2, 4, 4, 0, 0, 0, 0, 0, 3, 6, 2, 0, 0, 0, 4,
        4, 3, 6, 2, 0, 0, 0, 4, 4, 0, 0, 0, 3, 6, 2, 0, 0, 0, 4, 4, 0, 3, 6, 2,
        0, 0, 0, 4, 4, 0, 0, 3, 6, 2, 0, 0, 0, 4, 4, 0, 0, 0, 0, 0, 0, 0, 3, 6,
        2, 0, 0, 0, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        3, 6, 2, 0, 0, 0, 4, 4, 0, 3, 6, 2, 0, 0, 0, 4, 4, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 3, 6, 2, 0, 0, 0, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3,
        6, 2, 0, 0, 0, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 3, 6, 2, 0, 0, 0, 4, 4, 0, 0, 0, 3, 6,
        2, 0, 0, 0, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 3, 6, 2, 0, 0, 0, 2, 3, 6, 0, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0,
        6, 0, 0, 6, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0,
        0, 0, 6, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 6,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    constant [1213] integer STEP_WHEN = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 11, 11, 11, 11, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 9, 9, 9, 9, 9, 9, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9,
        9, 9, 9, 9, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
        1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 0, 0, 0, 1, 1, 1, 0,
        0, 0, 1, 1, 1, 2, 3, 4, 5, 6, 7, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 1, 1,
        1, 0, 0, 1, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1,
        1, 12, 12, 12, 12, 12, 12, 12, 12, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 1,
        1, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0,
        0, 0, 1, 1, 1, 0, 8, 0, 1, 1, 1, 0, 8, 0, 0, 1, 1, 1, 0, 8, 0, 0, 1, 1,
        1, 0, 8, 0, 0, 1, 1, 1, 0, 8, 0, 0, 1, 1, 1, 0, 8, 0, 0, 1, 1, 1, 0, 8,
        0, 0, 1, 1, 1, 0, 8, 0, 0, 0, 1, 1, 1, 0, 8, 0, 0, 0, 1, 1, 1, 0, 8, 0,
        0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 8, 0, 0, 0, 1, 1, 1, 0, 8, 0, 0, 0, 0,
        1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 9, 9, 9, 9, 9,
        9, 9, 9, 9, 9, 9, 9, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 9, 9, 9, 9,
        9, 9, 9, 9, 9, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1,
        1, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1,
        1, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 12, 12, 12, 12, 12,
        12, 12, 12, 12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1,
        1, 1, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0,
        8, 0, 1, 1, 1, 1, 1, 0, 8, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 8, 0, 0, 1, 1,
        1, 1, 1, 0, 8, 0, 0, 0, 1, 1, 1, 1, 1, 0, 8, 14, 14, 13, 13, 13, 13, 13, 0, 1,
        1, 1, 1, 1, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 1, 1, 1, 1, 1, 0, 8, 0, 0, 1, 1, 1, 1, 1, 0, 8, 15, 15, 15, 16, 16, 17, 17,
        0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 8, 15, 15, 15, 16, 16, 17, 17, 0, 0, 0, 0, 0,
        1, 1, 1, 1, 1, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 8, 0, 0, 0, 0, 1,
        1, 1, 1, 1, 0, 8, 18, 18, 18, 18, 18, 18, 18, 18, 19, 19, 19, 19, 19, 19, 19, 19, 0, 0,
        0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    constant [1213] integer STEP_FORM = [
        16, 16, 0, 0, 0, 0, 0, 19, 0, 0, 64, 58, 16, 0, 10, 62, 37, 0, 0, 0, 64, 58, 56, 0,
        0, 62, 4, 0, 0, 64, 0, 0, 64, 0, 46, 9, 58, 4, 0, 46, 9, 58, 0, 4, 0, 0, 0, 0,
        0, 46, 7, 9, 58, 27, 61, 25, 11, 58, 4, 4, 56, 0, 60, 8, 58, 60, 12, 0, 63, 0, 4, 62,
        4, 0, 0, 0, 10, 0, 0, 64, 58, 61, 61, 0, 0, 64, 0, 46, 9, 58, 4, 0, 13, 58, 56, 0,
        0, 13, 58, 0, 0, 13, 58, 46, 7, 9, 58, 4, 56, 0, 0, 46, 9, 58, 57, 61, 0, 13, 58, 0,
        0, 46, 9, 58, 0, 0, 62, 4, 0, 0, 64, 62, 4, 16, 57, 1, 54, 0, 62, 4, 12, 0, 64, 0,
        0, 64, 0, 0, 59, 0, 0, 0, 13, 28, 4, 13, 58, 0, 0, 0, 0, 0, 51, 52, 8, 58, 4, 0,
        0, 13, 28, 4, 0, 13, 58, 0, 0, 46, 9, 29, 0, 1, 0, 0, 0, 15, 0, 0, 0, 1048576, 0, 0,
        59, 0, 0, 0, 0, 51, 52, 8, 58, 0, 0, 59, 0, 0, 0, 0, 59, 0, 1048576, 0, 0, 0, 59, 0,
        0, 1048576, 0, 0, 59, 0, 0, 0, 0, 0, 0, 0, 64, 30, 0, 0, 0, 59, 0, 65, 16, 0, 0, 0,
        59, 16, 0, 0, 0, 59, 0, 1048576, 0, 0, 0, 59, 0, 0, 0, 0, 59, 0, 0, 0, 0, 13, 58, 1048576,
        0, 0, 0, 0, 59, 0, 0, 0, 0, 0, 1048576, 0, 0, 13, 58, 1048576, 0, 1048576, 4, 0, 13, 58, 0, 0,
        59, 0, 0, 0, 0, 51, 52, 8, 58, 0, 0, 0, 0, 13, 58, 1048576, 0, 0, 0, 59, 0, 0, 0, 0,
        59, 0, 0, 0, 0, 59, 0, 0, 0, 0, 59, 0, 0, 0, 8, 28, 0, 0, 0, 59, 0, 0, 0, 9,
        28, 0, 0, 0, 59, 0, 0, 0, 0, 0, 59, 0, 0, 12, 0, 0, 0, 59, 0, 0, 20, 0, 0, 0,
        59, 0, 0, 19, 0, 0, 0, 59, 0, 0, 1048576, 0, 0, 0, 59, 0, 0, 23, 0, 0, 0, 59, 0, 0,
        24, 0, 0, 0, 59, 0, 0, 13, 29, 0, 0, 0, 59, 0, 0, 13, 29, 0, 0, 0, 59, 0, 0, 23,
        26, 8, 30, 10, 8, 28, 0, 0, 0, 59, 0, 0, 24, 26, 0, 0, 0, 59, 0, 0, 8, 1048576, 28, 0,
        0, 0, 59, 0, 0, 0, 62, 4, 1, 54, 0, 59, 0, 57, 56, 0, 1, 54, 0, 1, 54, 62, 4, 12,
        0, 0, 64, 56, 0, 8, 58, 1, 54, 12, 0, 16, 6, 4, 4, 0, 0, 24, 26, 5, 54, 16, 61, 0,
        55, 54, 13, 58, 4, 63, 0, 59, 1, 3, 53, 63, 0, 1, 3, 53, 1, 54, 63, 62, 4, 4, 0, 62,
        4, 62, 37, 0, 56, 0, 66, 0, 32, 9, 58, 0, 9, 58, 0, 38, 56, 9, 29, 0, 1, 54, 62, 4,
        12, 0, 0, 0, 46, 38, 4, 13, 58, 56, 0, 8, 58, 1, 54, 12, 0, 16, 6, 4, 4, 0, 0, 24,
        26, 5, 54, 16, 61, 0, 55, 54, 13, 58, 4, 63, 0, 59, 1, 54, 1, 54, 1, 54, 1, 54, 63, 0,
        1, 54, 1, 54, 1, 54, 1, 54, 1, 54, 63, 67, 121, 67, 68, 67, 104, 67, 104, 69, 70, 69, 70, 104,
        67, 116, 0, 120, 67, 68, 100, 88, 89, 93, 118, 116, 93, 118, 116, 0, 93, 118, 116, 67, 68, 67, 68, 104,
        116, 0, 93, 118, 116, 72, 67, 86, 67, 68, 104, 116, 0, 0, 93, 118, 116, 67, 1, 1, 83, 82, 118, 84,
        118, 84, 94, 95, 93, 96, 118, 116, 0, 0, 0, 0, 0, 109, 110, 93, 118, 116, 71, 1, 1, 83, 82, 118,
        84, 118, 84, 94, 95, 0, 83, 118, 116, 0, 0, 83, 67, 118, 67, 0, 0, 0, 73, 0, 0, 0, 1048576, 0,
        0, 93, 118, 116, 0, 0, 0, 0, 109, 110, 93, 118, 116, 0, 0, 93, 118, 116, 1, 1, 0, 0, 93, 118,
        116, 0, 1, 1, 0, 0, 93, 118, 116, 0, 1, 1, 0, 0, 93, 118, 116, 1, 122, 1, 0, 0, 93, 118,
        116, 84, 67, 1, 0, 0, 93, 118, 116, 0, 1, 1, 0, 0, 93, 118, 116, 1, 1, 0, 0, 93, 118, 116,
        0, 1, 1, 67, 67, 83, 82, 118, 116, 1, 0, 1, 0, 0, 93, 118, 116, 0, 0, 0, 67, 0, 1, 67,
        67, 1, 83, 82, 118, 116, 1, 0, 1, 71, 0, 83, 118, 116, 0, 0, 93, 118, 116, 0, 0, 0, 0, 109,
        110, 93, 118, 116, 0, 1, 1, 1, 83, 82, 118, 116, 1, 0, 0, 0, 93, 118, 116, 1, 1, 0, 0, 93,
        118, 116, 1, 1, 0, 0, 93, 118, 116, 67, 67, 1, 0, 0, 93, 118, 116, 0, 1, 1, 93, 84, 84, 118,
        84, 118, 84, 1, 0, 0, 93, 118, 116, 0, 1, 1, 93, 118, 84, 118, 84, 1, 0, 0, 93, 118, 116, 1,
        1, 1, 0, 0, 93, 118, 116, 1, 1, 67, 83, 81, 1, 0, 0, 93, 118, 116, 1, 1, 98, 1, 0, 0,
        93, 118, 116, 1, 1, 85, 85, 1, 0, 0, 93, 118, 116, 1, 1, 1048576, 1048576, 91, 92, 92, 84, 84, 1, 0,
        0, 93, 118, 116, 1, 1, 90, 90, 76, 76, 83, 81, 76, 76, 83, 81, 76, 114, 117, 115, 76, 76, 83, 81,
        1, 0, 0, 93, 118, 116, 1, 1, 117, 1, 0, 0, 93, 118, 116, 1, 1, 76, 76, 75, 83, 82, 83, 82,
        67, 67, 118, 67, 1, 0, 0, 93, 118, 116, 1, 1, 76, 76, 75, 83, 82, 83, 82, 67, 67, 118, 67, 1,
        0, 0, 93, 118, 116, 1, 1, 90, 90, 76, 76, 83, 81, 76, 76, 83, 81, 114, 114, 114, 117, 115, 109, 84,
        84, 76, 76, 83, 81, 93, 118, 116, 78, 79, 0, 1, 0, 0, 93, 118, 116, 1, 1, 117, 84, 84, 1, 0,
        0, 93, 118, 116, 1, 1, 86, 97, 87, 74, 72, 86, 74, 86, 87, 97, 86, 74, 72, 87, 74, 87, 93, 96,
        118, 67, 118, 67, 1, 0, 0, 93, 118, 116, 1, 1, 0, 69, 70, 67, 111, 0, 93, 118, 116, 1, 117, 116,
        0, 67, 111, 0, 67, 111, 69, 70, 67, 68, 0, 112, 104, 83, 118, 116, 116, 0, 93, 118, 116, 67, 111, 67,
        83, 81, 0, 114, 72, 71, 0, 67, 67, 117, 71, 111, 75, 118, 116, 0, 113, 111, 83, 118, 116, 71, 115, 0,
        93, 118, 116, 67, 111, 67, 111, 67, 111, 67, 111, 119, 0, 67, 111, 67, 111, 67, 111, 67, 111, 67, 111, 119,
        0, 75, 118, 84, 118, 84, 118, 67, 118, 67, 118, 119, 67, 67, 67, 0, 78, 80, 80, 80, 67, 95, 83, 82,
        96, 118, 84, 118, 84, 118, 99, 93, 118, 116, 84, 84, 119];
    constant [1213] integer STEP_A0 = [
        25, 26, 22, 0, 1, 2, 3, 4, 5, 16, 0, 0, 24, 9, 0, 8, 0, 1, 2, 16, 0, 0, 0, 1048576,
        0, 1, 1, 2, 16, 0, 0, 16, 0, 1048576, 9, 31, 0, 19, 11, 9, 31, 0, 11, 19, 1048576, 0, 12, 13,
        1048576, 9, 9, 31, 0, 14, 14, 0, 0, 0, 19, 12, 0, 1048576, 12, 31, 0, 11, 0, 1048576, 0, 1048576, 22, 21,
        21, 19, 1048576, 0, 1, 2, 16, 0, 0, 0, 19, 0, 16, 0, 1048576, 9, 31, 0, 19, 11, 31, 0, 0, 1048576,
        11, 31, 0, 19, 1048576, 31, 0, 9, 9, 31, 0, 19, 0, 1048576, 10, 9, 31, 0, 0, 11, 12, 31, 0, 0,
        1048576, 9, 31, 0, 1048576, 0, 1, 1, 2, 16, 0, 20, 20, 0, 0, 10, 10, 0, 1, 1, 2, 16, 0, 0,
        16, 0, 1048576, 9, 9, 23, 11, 12, 31, 11, 11, 31, 0, 1048576, 12, 13, 15, 1048576, 9, 9, 15, 0, 23, 11,
        12, 31, 11, 11, 11, 31, 0, 1048576, 10, 9, 31, 9, 9, 9, 9, 9, 10, 9, 9, 9, 10, 9, 9, 9,
        9, 12, 13, 15, 1048576, 9, 9, 15, 0, 1048576, 9, 9, 9, 9, 1048576, 9, 9, 9, 9, 9, 1048576, 9, 9, 9,
        10, 10, 1048576, 9, 9, 0, 1, 2, 3, 4, 5, 16, 0, 9, 9, 1048576, 9, 9, 0, 0, 9, 9, 1048576, 9,
        9, 9, 9, 1048576, 9, 9, 12, 9, 9, 1048576, 9, 9, 9, 9, 1048576, 9, 9, 12, 10, 11, 9, 31, 0, 9,
        1048576, 9, 1048576, 9, 9, 12, 13, 14, 15, 1048576, 10, 9, 11, 31, 0, 9, 1048576, 9, 15, 17, 31, 0, 1048576, 9,
        9, 12, 13, 15, 1048576, 9, 9, 15, 0, 12, 10, 9, 11, 31, 0, 9, 1048576, 1048576, 9, 9, 9, 9, 1048576, 9,
        9, 9, 9, 1048576, 9, 9, 9, 9, 1048576, 9, 9, 9, 10, 11, 31, 9, 9, 1048576, 9, 9, 11, 9, 10, 31,
        9, 9, 1048576, 9, 9, 9, 10, 9, 1048576, 9, 9, 9, 10, 9, 9, 1048576, 9, 9, 9, 10, 9, 9, 1048576, 9,
        9, 9, 10, 9, 9, 1048576, 9, 9, 9, 10, 9, 9, 1048576, 9, 9, 9, 10, 9, 9, 1048576, 9, 9, 9, 10,
        9, 9, 1048576, 9, 9, 9, 10, 31, 9, 9, 1048576, 9, 9, 9, 10, 31, 9, 9, 1048576, 9, 9, 9, 10, 11,
        11, 31, 12, 12, 31, 9, 9, 1048576, 9, 9, 9, 10, 11, 9, 9, 1048576, 9, 9, 9, 10, 31, 11, 9, 9,
        1048576, 9, 9, 9, 9, 1048576, 20, 20, 10, 10, 9, 9, 0, 0, 0, 1048576, 10, 10, 1048576, 10, 10, 1, 1, 2,
        0, 16, 0, 0, 1048576, 31, 0, 10, 10, 0, 1048576, 9, 31, 11, 15, 12, 1048576, 13, 14, 14, 14, 9, 9, 1048576,
        14, 14, 31, 0, 31, 0, 1048576, 0, 9, 9, 9, 0, 1048576, 9, 9, 9, 9, 9, 0, 9, 9, 31, 22, 0,
        0, 8, 0, 21, 0, 1048576, 0, 9, 21, 31, 0, 1048576, 31, 0, 9, 21, 0, 31, 9, 9, 10, 10, 1, 1,
        2, 9, 11, 1048576, 10, 10, 11, 31, 0, 0, 1048576, 31, 0, 10, 10, 0, 1048576, 9, 31, 11, 15, 12, 1048576, 13,
        14, 14, 14, 9, 9, 1048576, 14, 14, 31, 0, 31, 0, 1048576, 0, 9, 9, 9, 9, 9, 9, 9, 9, 0, 1048576,
        9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 0, 0, 0, 6, 6, 0, 0, 0, 0, 0, 0, 14, 14, 0,
        11, 0, 1048576, 0, 6, 6, 11, 11, 11, 15, 0, 0, 15, 0, 0, 1048576, 15, 0, 0, 6, 6, 0, 0, 0,
        0, 1048576, 15, 0, 0, 0, 1, 1, 6, 6, 1, 0, 1048576, 0, 15, 0, 0, 12, 4, 2, 14, 14, 0, 4,
        0, 5, 4, 5, 14, 14, 0, 0, 1048576, 6, 7, 9, 1048576, 0, 0, 9, 0, 0, 12, 4, 2, 14, 14, 0,
        4, 0, 5, 4, 5, 4, 15, 0, 0, 1048576, 6, 15, 0, 0, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0,
        0, 15, 0, 0, 6, 7, 9, 1048576, 0, 0, 9, 0, 0, 1048576, 0, 15, 0, 0, 0, 0, 1048576, 0, 15, 0,
        0, 0, 0, 0, 1048576, 0, 15, 0, 0, 6, 2, 2, 1048576, 0, 15, 0, 0, 0, 0, 0, 1048576, 0, 15, 0,
        0, 0, 1, 0, 1048576, 0, 15, 0, 0, 6, 0, 0, 1048576, 0, 15, 0, 0, 0, 0, 1048576, 0, 15, 0, 0,
        6, 2, 4, 0, 1, 14, 14, 0, 0, 0, 1048576, 0, 1048576, 0, 15, 0, 0, 6, 7, 8, 9, 1048576, 2, 0,
        1, 4, 14, 14, 0, 0, 0, 1048576, 0, 9, 14, 15, 0, 0, 1048576, 0, 15, 0, 0, 6, 7, 9, 1048576, 0,
        0, 9, 0, 0, 6, 2, 0, 4, 14, 14, 0, 0, 0, 1048576, 1048576, 0, 15, 0, 0, 0, 0, 1048576, 0, 15,
        0, 0, 0, 0, 1048576, 0, 15, 0, 0, 0, 1, 0, 1048576, 0, 15, 0, 0, 0, 2, 4, 15, 0, 1, 0,
        0, 0, 1, 0, 1048576, 0, 15, 0, 0, 4, 0, 2, 15, 0, 0, 0, 1, 0, 1048576, 0, 15, 0, 0, 0,
        2, 0, 1048576, 0, 15, 0, 0, 0, 2, 14, 0, 1, 0, 1048576, 0, 15, 0, 0, 0, 2, 0, 0, 1048576, 0,
        15, 0, 0, 0, 2, 0, 1, 0, 1048576, 0, 15, 0, 0, 0, 2, 0, 1, 4, 5, 5, 0, 1, 0, 1048576,
        0, 15, 0, 0, 0, 2, 8, 9, 0, 1, 0, 1, 2, 3, 2, 3, 8, 8, 0, 8, 0, 1, 0, 1,
        0, 1048576, 0, 15, 0, 0, 0, 2, 0, 0, 1048576, 0, 15, 0, 0, 0, 2, 4, 5, 4, 14, 14, 14, 14,
        0, 1, 0, 0, 0, 1048576, 0, 15, 0, 0, 0, 2, 4, 5, 4, 14, 14, 14, 14, 0, 1, 0, 0, 0,
        1048576, 0, 15, 0, 0, 0, 2, 8, 9, 0, 1, 0, 1, 2, 3, 2, 3, 3, 2, 8, 0, 8, 4, 0,
        1, 0, 1, 0, 1, 15, 0, 0, 0, 1, 1048576, 0, 1048576, 0, 15, 0, 0, 0, 2, 0, 0, 1, 0, 1048576,
        0, 15, 0, 0, 0, 2, 4, 5, 6, 4, 5, 6, 1, 0, 4, 5, 6, 4, 5, 6, 0, 1, 14, 14,
        0, 0, 0, 1, 0, 1048576, 0, 15, 0, 0, 0, 0, 1048576, 10, 10, 2, 2, 0, 15, 0, 0, 0, 0, 0,
        1048576, 2, 2, 1048576, 2, 2, 6, 6, 7, 7, 1048576, 2, 2, 15, 0, 0, 0, 1048576, 15, 0, 0, 2, 2, 2,
        0, 1, 1048576, 14, 13, 12, 1048576, 2, 3, 0, 2, 2, 4, 0, 0, 1048576, 2, 2, 15, 0, 0, 13, 15, 1048576,
        15, 0, 0, 2, 2, 2, 2, 2, 2, 2, 2, 0, 1048576, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0,
        1048576, 4, 0, 2, 0, 3, 0, 0, 0, 1, 0, 0, 4, 5, 9, 1048576, 0, 1, 4, 5, 8, 8, 6, 7,
        8, 0, 4, 0, 5, 0, 0, 9, 0, 0, 2, 3, 0];
    constant [1213] integer STEP_A1 = [
        31, 31, 0, 0, 1048576, 0, 0, 31, 0, 0, 0, 0, 31, 1048576, 24, 0, 8, 1048576, 0, 0, 0, 0, 0, 0,
        0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 21, 9, 0, 19, 0, 21, 9, 0, 0, 19, 0, 0, 0, 0,
        0, 21, 9, 9, 0, 0, 0, 0, 0, 0, 19, 12, 0, 0, 0, 12, 0, 0, 31, 0, 0, 0, 22, 0,
        21, 0, 0, 0, 21, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 21, 9, 0, 19, 1048576, 19, 0, 0, 0,
        1048576, 19, 0, 0, 0, 19, 0, 21, 9, 9, 0, 19, 0, 0, 1048576, 21, 9, 0, 0, 0, 1048576, 0, 0, 1048576,
        0, 21, 9, 0, 0, 0, 0, 1, 0, 0, 0, 0, 20, 31, 0, 0, 20, 0, 0, 1, 20, 0, 0, 0,
        0, 0, 0, 7, 0, 0, 1048576, 1048576, 11, 11, 11, 23, 0, 0, 1048576, 1048576, 1048576, 0, 12, 13, 15, 0, 23, 1048576,
        1048576, 11, 11, 11, 1048576, 23, 0, 0, 1048576, 21, 9, 31, 7, 0, 7, 7, 1048576, 9, 7, 7, 7, 9, 7, 7,
        0, 1048576, 1048576, 1048576, 0, 12, 13, 15, 0, 0, 7, 0, 1048576, 1048576, 0, 7, 0, 1048576, 9, 1048576, 0, 7, 0, 1048576,
        1048576, 9, 0, 7, 0, 1048576, 1048576, 1048576, 1048576, 1048576, 1048576, 1048576, 0, 0, 1048576, 0, 7, 0, 1048576, 0, 31, 1048576, 0, 7,
        0, 31, 1048576, 0, 7, 0, 1048576, 12, 1048576, 0, 7, 0, 1048576, 1048576, 0, 7, 0, 1048576, 1048576, 1048576, 0, 10, 0, 12,
        0, 1048576, 0, 7, 0, 1048576, 1048576, 1048576, 0, 0, 13, 0, 1048576, 10, 0, 12, 0, 14, 15, 1048576, 15, 0, 0, 7,
        0, 1048576, 1048576, 1048576, 0, 12, 13, 15, 0, 1048576, 1048576, 1048576, 1048576, 10, 0, 12, 0, 0, 7, 0, 1048576, 1048576, 0, 7,
        0, 1048576, 1048576, 0, 7, 0, 0, 1048576, 0, 7, 0, 1048576, 1048576, 1048576, 9, 10, 1048576, 0, 7, 0, 7, 1048576, 1048576, 11,
        9, 1048576, 0, 7, 0, 1048576, 1048576, 1048576, 0, 7, 0, 1048576, 1048576, 31, 1048576, 0, 7, 0, 1048576, 1048576, 9, 1048576, 0, 7,
        0, 1048576, 1048576, 31, 1048576, 0, 7, 0, 1048576, 1048576, 9, 1048576, 0, 7, 0, 1048576, 1048576, 9, 1048576, 0, 7, 0, 1048576, 1048576,
        9, 1048576, 0, 7, 0, 1048576, 1048576, 9, 31, 1048576, 0, 7, 0, 1048576, 1048576, 9, 31, 1048576, 0, 7, 0, 1048576, 1048576, 9,
        11, 10, 10, 11, 11, 12, 1048576, 0, 7, 0, 1048576, 1048576, 9, 11, 1048576, 0, 7, 0, 1048576, 1048576, 10, 9, 11, 1048576,
        0, 7, 0, 1048576, 1048576, 0, 0, 20, 0, 20, 7, 0, 1048576, 0, 0, 0, 0, 20, 0, 0, 20, 0, 1, 20,
        0, 0, 0, 0, 0, 0, 0, 0, 20, 31, 0, 31, 31, 31, 31, 0, 0, 9, 13, 14, 11, 31, 0, 0,
        11, 20, 11, 0, 31, 0, 0, 0, 0, 0, 20, 0, 0, 0, 0, 20, 0, 20, 0, 0, 9, 9, 0, 0,
        0, 0, 8, 0, 0, 0, 0, 0, 9, 21, 0, 0, 21, 0, 0, 9, 0, 21, 31, 7, 0, 20, 0, 1,
        20, 0, 0, 0, 1, 9, 11, 11, 0, 0, 0, 0, 0, 0, 20, 31, 0, 31, 31, 31, 31, 0, 0, 9,
        13, 14, 11, 31, 0, 0, 11, 20, 11, 0, 31, 0, 0, 0, 0, 20, 0, 20, 0, 20, 0, 20, 0, 0,
        0, 20, 0, 20, 0, 20, 0, 20, 0, 20, 0, 0, 0, 0, 0, 0, 6, 0, 6, 0, 0, 0, 0, 14,
        0, 0, 0, 0, 0, 0, 6, 11, 11, 11, 0, 0, 11, 0, 0, 0, 11, 0, 0, 0, 0, 0, 0, 6,
        0, 0, 11, 0, 0, 11, 0, 1, 0, 0, 6, 0, 0, 7, 0, 0, 0, 0, 1048576, 1048576, 4, 5, 0, 2,
        0, 3, 4, 5, 4, 5, 0, 0, 0, 1048576, 1048576, 1048576, 0, 6, 7, 9, 0, 0, 12, 1048576, 1048576, 4, 5, 0,
        2, 0, 3, 4, 5, 1048576, 12, 0, 0, 0, 1048576, 11, 0, 0, 0, 7, 7, 1048576, 0, 7, 7, 7, 0, 7,
        7, 0, 0, 0, 1048576, 1048576, 1048576, 0, 6, 7, 9, 0, 0, 0, 7, 0, 0, 0, 1048576, 1048576, 0, 7, 0, 0,
        0, 1048576, 1048576, 1048576, 0, 7, 0, 0, 0, 1048576, 1048576, 1048576, 0, 7, 0, 0, 0, 1048576, 0, 1048576, 0, 7, 0, 0,
        0, 12, 0, 1048576, 0, 7, 0, 0, 0, 1048576, 1048576, 1048576, 0, 7, 0, 0, 0, 1048576, 1048576, 0, 7, 0, 0, 0,
        1048576, 1048576, 1048576, 0, 0, 2, 3, 0, 0, 1048576, 0, 1048576, 0, 7, 0, 0, 0, 1048576, 1048576, 1048576, 0, 0, 1048576, 0,
        0, 1048576, 2, 3, 0, 0, 1048576, 0, 1048576, 9, 1048576, 9, 0, 0, 0, 7, 0, 0, 0, 1048576, 1048576, 1048576, 0, 6,
        7, 9, 0, 0, 1048576, 1048576, 1048576, 1048576, 2, 3, 0, 0, 1048576, 0, 0, 7, 0, 0, 0, 1048576, 1048576, 0, 7, 0,
        0, 0, 1048576, 1048576, 0, 7, 0, 0, 0, 0, 0, 1048576, 0, 7, 0, 0, 0, 1048576, 1048576, 1048576, 0, 4, 5, 0,
        2, 0, 3, 1048576, 0, 7, 0, 0, 0, 7, 1048576, 1048576, 4, 0, 2, 0, 3, 1048576, 0, 7, 0, 0, 0, 1048576,
        1048576, 1048576, 0, 7, 0, 0, 0, 1048576, 1048576, 0, 14, 14, 1048576, 0, 7, 0, 0, 0, 1048576, 1048576, 0, 1048576, 0, 7,
        0, 0, 0, 1048576, 1048576, 0, 1, 1048576, 0, 7, 0, 0, 0, 1048576, 1048576, 0, 1, 0, 0, 1, 4, 5, 1048576, 0,
        7, 0, 0, 0, 1048576, 1048576, 1, 3, 0, 1, 0, 1, 2, 3, 2, 3, 8, 13, 0, 13, 0, 1, 0, 1,
        1048576, 0, 7, 0, 0, 0, 1048576, 1048576, 0, 1048576, 0, 7, 0, 0, 0, 1048576, 1048576, 0, 1, 4, 0, 1, 2, 3,
        0, 0, 0, 0, 1048576, 0, 7, 0, 0, 0, 1048576, 1048576, 0, 1, 4, 0, 1, 2, 3, 0, 0, 0, 0, 1048576,
        0, 7, 0, 0, 0, 1048576, 1048576, 1, 3, 0, 1, 0, 1, 2, 3, 2, 3, 13, 13, 13, 0, 13, 13, 2,
        3, 0, 1, 0, 1, 1, 0, 0, 0, 1, 0, 1048576, 0, 7, 0, 0, 0, 1048576, 1048576, 0, 2, 3, 1048576, 0,
        7, 0, 0, 0, 1048576, 1048576, 1, 2, 0, 4, 2, 0, 4, 0, 0, 2, 1, 4, 2, 1, 4, 1, 2, 3,
        0, 0, 0, 0, 1048576, 0, 7, 0, 0, 0, 1048576, 1048576, 0, 0, 0, 0, 10, 7, 0, 0, 0, 1048576, 0, 0,
        0, 0, 10, 0, 0, 10, 0, 0, 0, 0, 0, 6, 7, 6, 0, 0, 0, 0, 1, 0, 0, 0, 10, 0,
        2, 2, 0, 13, 13, 13, 0, 0, 0, 0, 2, 12, 0, 0, 0, 0, 12, 10, 13, 0, 0, 13, 13, 0,
        0, 0, 0, 0, 10, 0, 10, 0, 10, 0, 10, 0, 0, 0, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0,
        0, 2, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 4, 5, 0, 8, 4, 5,
        8, 0, 6, 0, 7, 0, 0, 9, 0, 0, 4, 5, 0];
    constant [1213] integer STEP_A2 = [
        0, 1, 0, 0, 0, 0, 4098, 31, 0, 197, 0, 0, 0, 0, 9, 0, 0, 0, 3, 74, 0, 0, 0, 0,
        2, 0, 0, 26, 4, 0, 3, 1, 0, 0, 19, 32, 0, 1, 0, 19, 45, 0, 1, 1, 0, 0, 0, 10,
        0, 19, 48, 9, 0, 13, 0, 13, 9, 0, 1, 1, 0, 0, 0, 20, 0, 0, 0, 0, 0, 0, 1, 0,
        0, 0, 0, 0, 19, 1, 3, 0, 0, 0, 0, 0, 1, 0, 0, 19, 10, 0, 1, 0, 11, 0, 0, 0,
        0, 11, 0, 0, 0, 11, 0, 19, 48, 1, 0, 1, 0, 0, 0, 10, 49, 0, 0, 0, 0, 12, 0, 0,
        0, 19, 10, 0, 0, 2, 0, 0, 33, 4, 0, 0, 0, 22, 0, 10, 1, 2, 0, 0, 1, 4, 0, 2,
        1, 0, 0, 0, 0, 0, 0, 0, 12, 12, 1, 11, 0, 0, 0, 0, 0, 0, 8, 8, 1, 0, 1, 0,
        0, 12, 12, 1, 0, 11, 0, 0, 0, 10, 49, 31, 0, 1, 0, 0, 0, 10, 0, 0, 0, 10, 0, 0,
        0, 0, 0, 0, 0, 8, 8, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1048576, 0, 0, 0, 0,
        0, 23, 0, 0, 0, 0, 0, 23, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 11, 0, 10,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 15, 0, 0, 11, 0, 10, 0, 15, 1, 0, 17, 0, 0, 0,
        0, 0, 0, 0, 0, 8, 8, 1, 0, 0, 0, 0, 0, 11, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 11, 0, 0, 0, 0, 0, 0, 0, 0,
        10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 9, 0, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0,
        10, 0, 0, 0, 0, 0, 0, 10, 31, 0, 0, 0, 0, 0, 0, 10, 31, 0, 0, 0, 0, 0, 0, 10,
        10, 0, 10, 12, 0, 11, 0, 0, 0, 0, 0, 0, 10, 10, 0, 0, 0, 0, 0, 0, 64, 10, 31, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 32, 1, 0, 0, 0, 0, 0, 0, 45, 1, 0, 10, 1, 0, 0, 1,
        1, 4, 0, 0, 0, 0, 0, 45, 1, 0, 0, 0, 32, 0, 0, 10, 0, 12, 12, 48, 1, 13, 0, 0,
        -1, 1, 15, 0, 32, 0, 0, 0, 29300, 25973, 4, 0, 0, 24934, 29548, 4, 101, 1, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 1024, 0, 0, 0, 2049, 12, 1048576, 0, 0, 1020, 0, 2049, 16, 0, 1048576, 31, 0, 10, 1, 0, 0,
        1, 2304, 0, 0, 11, 0, 1, 2, 0, 0, 0, 0, 0, 45, 1, 0, 0, 0, 32, 0, 0, 10, 0, 12,
        12, 48, 1, 13, 0, 0, -1, 1, 15, 0, 32, 0, 0, 0, 116, 1, 114, 1, 117, 1, 101, 1, 0, 0,
        102, 1, 97, 1, 108, 1, 115, 1, 101, 1, 0, 1, 0, 16384, 16384, 16, 16, 1, 8, 0, 0, 0, 0, 0,
        1024, 0, 0, 0, 60676, 57344, 0, 11, 23, 15, 0, 0, 1048576, 0, 0, 0, 15, 0, 0, 60676, 57344, 0, 512, 0,
        0, 0, 48, 0, 0, 16, 1, 0, 57984, 57344, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 3, 0, 0,
        0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 8, 8, 1, 0, 0, 1, 0, 0, 2, 3, 0,
        0, 0, 0, 1, 0, 0, 4, 0, 0, 0, 0, 6, 0, 0, 1, 0, 0, 0, 2, 0, 0, 0, 2, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 8, 8, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 1048576, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 4, 5, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0,
        0, 0, 4, 5, 0, 0, 6, 0, 8, 1, 0, 14, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8,
        8, 1, 0, 0, 0, 0, 0, 0, 4, 5, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 3, 2, 3, 2, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 31, 31, 8, 8, 8, 8, 9, 9, 9, 9, 9, 8, 0, 8, 8, 8, 8, 8,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 3, 5, 2, 3, 0, 1,
        0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 2, 3, 5, 2, 3, 0, 1, 0, 0, 0, 1, 0,
        0, 0, 0, 0, 0, 0, 0, 31, 31, 8, 8, 8, 8, 9, 9, 9, 9, 4, 4, 8, 0, 8, 8, 0,
        0, 8, 8, 8, 8, 0, 0, 0, 4, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 2, 32, 5, 6, 32, 5, 6, 2, 2, 32, 5, 6, 32, 5, 6, 2, 64, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 1, 0, 0, 0, 0, 0, 0, 0,
        0, 45, 1, 0, 10, 1, 0, 0, 16384, 16384, 0, 1, 0, 10, 0, 0, 0, 0, 0, 0, 0, 45, 1, 0,
        0, 1, 0, 8, 24, 0, 0, 10, 0, 0, 48, 1, 1, 0, 0, 0, 1, 1, 12, 0, 0, 24, 8, 0,
        0, 0, 0, 116, 1, 114, 1, 117, 1, 101, 1, 0, 0, 102, 1, 97, 1, 108, 1, 115, 1, 101, 1, 0,
        0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 64, 0, 0, 1, 4, 5, 0, 0, 2, 3,
        0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0];
    constant [1213] integer STEP_A3 = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 8, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 0, 0,
        0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 2, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 1048576, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0,
        0, 0, 1048576, 0, 0, 0, 3, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 3, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
        1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 1048576, 0, 0, 0, 0, 0, 0, 0, 1048576, 0, 0, 0, 0, 0, 0, 0,
        9, 0, 10, 0, 0, 11, 0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0,
        0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 2, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0,
        0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        9, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1048576, 0,
        1048576, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1048576,
        0, 1048576, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1,
        0, 0, -1, 0, 0, 0, 0, 1, 0, 0, 0, -1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1,
        0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 12, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0,
        0, 0, 0, 0, 0, 0, 0, 3, 0, 2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 9, 0,
        0, 0, 0, 0, 3, 0, 2, 0, 9, 0, 0, 0, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1,
        1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0,
        1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0,
        0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,
        0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 5, 5, 5, 0, 0, 0, 0,
        0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 1048576, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1048576, 0, 0,
        0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0,
        0, 0, 0, 0, 0, 0, 11, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        3, 0, 3, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 11, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 3, 0, 3, 0, 3, 0, 0, 0, 0, 0, 0, 0];
    constant [1213] integer STEP_TARGET = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1048576, 0, 0, 0, 1048576, 1048576, 0, 0, 0, 0, 1048576, 1048576, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1048576, 0, 0, 0, 0, 1048576, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 1048576, 0, 1048576, 0, 0, 1048576, 0, 0, 1048576, 0, 1048576, 0, 1048576, 1048576, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 1048576, 1048576, 1048576, 0, 0, 0, 0, 0, 0, 1048576, 0, 0, 0, 1048576, 1048576, 0,
        0, 0, 1048576, 0, 0, 0, 1048576, 0, 0, 0, 1048576, 0, 1048576, 0, 0, 0, 0, 1048576, 1048576, 1048576, 0, 0, 1048576, 1048577,
        0, 0, 0, 1048576, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1048576, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 1048576, 1048576, 0, 0, 0, 0, 0, 0, 0, 1048576, 0, 0, 0, 0, 0, 0, 0, 0, 1048576, 0, 0,
        0, 0, 0, 0, 0, 0, 1048576, 0, 0, 0, 0, 0, 1048576, 0, 1048576, 1048576, 0, 0, 1048576, 1048576, 1048576, 0, 1048576, 1048576,
        1048576, 0, 0, 0, 0, 0, 0, 0, 1048576, 0, 1048576, 1048576, 0, 1048577, 0, 1048576, 1048576, 0, 0, 1048577, 0, 1048576, 1048576, 0,
        0, 0, 0, 1048576, 1048576, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1048577, 0, 1048576, 1048576, 0, 0, 0, 1048577, 0, 1048576,
        1048576, 0, 1048577, 0, 1048576, 1048576, 0, 0, 1048577, 0, 1048576, 1048576, 1048577, 1048577, 0, 1048576, 1048576, 0, 0, 0, 0, 0, 1048576, 0,
        0, 1048577, 0, 1048576, 1048576, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1048576, 0, 0, 0, 0, 0, 0, 1048576, 0, 1048576,
        1048576, 0, 0, 0, 0, 0, 0, 0, 1048576, 0, 0, 0, 0, 0, 1048576, 0, 0, 0, 1048576, 1048576, 0, 1048577, 0, 1048576,
        1048576, 1048577, 1048577, 0, 1048576, 1048576, 0, 1048577, 0, 1048576, 1048576, 0, 0, 0, 0, 0, 1048577, 0, 1048576, 1048576, 1048576, 0, 0, 0,
        0, 1048577, 0, 1048576, 1048576, 0, 0, 1048577, 0, 1048576, 1048576, 0, 0, 0, 1048577, 0, 1048576, 1048576, 0, 0, 0, 1048577, 0, 1048576,
        1048576, 0, 0, 0, 1048577, 0, 1048576, 1048576, 0, 0, 0, 1048577, 0, 1048576, 1048576, 0, 0, 0, 1048577, 0, 1048576, 1048576, 0, 0,
        0, 1048577, 0, 1048576, 1048576, 0, 0, 0, 0, 1048577, 0, 1048576, 1048576, 0, 0, 0, 0, 1048577, 0, 1048576, 1048576, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 1048577, 0, 1048576, 1048576, 0, 0, 0, 0, 1048577, 0, 1048576, 1048576, 0, 0, 0, 0, 0, 1048577,
        0, 1048576, 1048576, 1048577, 1048577, 0, 0, 0, 0, 0, 1048576, 1048576, 1048577, 1048576, 1048576, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 1048576, 0, 0, 1048576, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1048576, 0,
        0, 0, 0, 1048576, 0, 0, 0, 1048576, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1048576,
        1048576, 1048576, 1048576, 0, 1048576, 0, 0, 0, 0, 0, 1048576, 0, 0, 1048576, 0, 0, 1048576, 0, 0, 1048576, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 1048576, 1048576, 0, 0, 1048576, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 1048576, 0, 0, 0, 0, 1048576, 0, 0, 0, 1048576, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1048576, 1048576, 1048576, 1048576, 0,
        0, 1048576, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1048576, 0, 0, 1048576, 0, 0, 0, 1048576, 0, 0, 0, 0, 0,
        1048576, 0, 0, 0, 1048576, 0, 0, 0, 0, 0, 0, 1048576, 0, 1048576, 0, 0, 1048576, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 1048576, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1048576, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 1048576, 0, 0, 0, 0, 0, 0, 1048576, 1048576, 0, 0, 1048576, 1048576, 1048576, 0, 1048576,
        1048576, 0, 0, 1048576, 0, 0, 0, 0, 0, 0, 0, 0, 1048576, 0, 1048576, 0, 0, 1048576, 0, 1048577, 0, 1048576, 0, 0,
        1048576, 0, 0, 1048577, 0, 1048576, 0, 0, 1048576, 0, 0, 0, 0, 1048576, 0, 0, 1048576, 0, 0, 1048577, 0, 1048576, 0, 0,
        1048576, 0, 0, 1048577, 0, 1048576, 0, 0, 1048576, 0, 0, 1048577, 0, 1048576, 0, 0, 1048576, 1048577, 1048577, 0, 1048576, 0, 0, 1048576,
        0, 0, 0, 0, 0, 0, 0, 0, 1048576, 0, 0, 1048577, 0, 1048576, 0, 0, 1048576, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 1048576, 0, 0, 0, 0, 0, 0, 0, 1048576, 0, 1048576, 0, 0, 1048576, 0, 0, 0, 0, 0,
        0, 0, 0, 1048576, 0, 0, 0, 0, 0, 0, 0, 1048576, 0, 0, 0, 1048576, 0, 0, 1048576, 0, 1048577, 0, 1048576, 0,
        0, 1048576, 1048577, 1048577, 0, 1048576, 0, 0, 1048576, 0, 0, 1048577, 0, 1048576, 0, 0, 1048576, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 1048577, 0, 1048576, 0, 0, 1048576, 1048576, 0, 0, 0, 0, 0, 0, 0, 1048577, 0, 1048576, 0, 0, 1048576, 0,
        0, 1048577, 0, 1048576, 0, 0, 1048576, 0, 0, 0, 0, 0, 1048577, 0, 1048576, 0, 0, 1048576, 0, 0, 0, 1048577, 0, 1048576,
        0, 0, 1048576, 0, 0, 0, 0, 1048577, 0, 1048576, 0, 0, 1048576, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1048577, 0,
        1048576, 0, 0, 1048576, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1048576, 0, 0, 0, 0, 0,
        1048577, 0, 1048576, 0, 0, 1048576, 0, 0, 1048576, 1048577, 0, 1048576, 0, 0, 1048576, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 1048577, 0, 1048576, 0, 0, 1048576, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1048577,
        0, 1048576, 0, 0, 1048576, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1048576, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 1048576, 0, 0, 0, 1048577, 0, 1048576, 0, 0, 1048576, 0, 0, 1048576, 0, 0, 1048577, 0,
        1048576, 0, 0, 1048576, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 1048577, 0, 1048576, 0, 0, 1048576, 1048577, 1048577, 0, 0, 0, 0, 0, 1048576, 0, 0, 1048576, 1048577, 1048576, 1048576,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1048576, 1048576, 0, 0, 0, 1048576, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 1048576, 0, 0, 0, 0, 1048576, 0, 0, 0, 0, 0, 1048576, 0, 0, 0,
        0, 0, 1048576, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 1048576, 0, 0, 0];
    constant [1213] integer STEP_TARGET_KIND = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 3, 3, 0, 0, 0, 0, 1, 1, 0,
        0, 10, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 1, 1, 0, 0, 0, 0, 0, 7,
        7, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0,
        0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 4,
        0, 0, 0, 1, 0, 0, 9, 9, 0, 0, 0, 8, 8, 0, 1, 0, 0, 0, 8, 8, 0, 0, 0, 0,
        0, 0, 0, 6, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0,
        0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 6, 0, 6, 6, 0, 0, 6, 6, 6, 0, 6, 6,
        1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 6, 1, 0, 4, 0, 6, 1, 0, 0, 4, 0, 6, 1, 0,
        0, 0, 0, 6, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 6, 1, 0, 0, 0, 4, 0, 6,
        1, 0, 4, 0, 6, 1, 0, 0, 4, 0, 6, 1, 4, 4, 0, 6, 1, 0, 0, 0, 0, 0, 1, 0,
        0, 4, 0, 6, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 6,
        1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 6, 1, 0, 4, 0, 6,
        1, 5, 4, 0, 6, 1, 0, 4, 0, 6, 1, 0, 0, 0, 0, 0, 4, 0, 6, 1, 6, 0, 0, 0,
        0, 4, 0, 6, 1, 0, 0, 4, 0, 6, 1, 0, 0, 0, 4, 0, 6, 1, 0, 0, 0, 4, 0, 6,
        1, 0, 0, 0, 4, 0, 6, 1, 0, 0, 0, 4, 0, 6, 1, 0, 0, 0, 4, 0, 6, 1, 0, 0,
        0, 4, 0, 6, 1, 0, 0, 0, 0, 4, 0, 6, 1, 0, 0, 0, 0, 4, 0, 6, 1, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 4, 0, 6, 1, 0, 0, 0, 0, 4, 0, 6, 1, 0, 0, 0, 0, 0, 4,
        0, 6, 1, 4, 5, 0, 8, 8, 0, 0, 6, 1, 4, 1, 1, 0, 0, 0, 0, 0, 0, 8, 8, 0,
        0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0,
        0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 12, 12, 0, 0, 11,
        11, 3, 3, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 6, 0, 0, 8, 8,
        0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 11, 11, 3, 3, 0,
        0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0,
        1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 6, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 6, 6, 0, 0, 6, 6, 6, 0, 6,
        6, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 6, 0, 0, 1, 0, 4, 0, 6, 0, 0,
        1, 0, 0, 4, 0, 6, 0, 0, 1, 0, 0, 0, 0, 6, 0, 0, 1, 0, 0, 4, 0, 6, 0, 0,
        1, 0, 0, 4, 0, 6, 0, 0, 1, 0, 0, 4, 0, 6, 0, 0, 1, 4, 4, 0, 6, 0, 0, 1,
        0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 4, 0, 6, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 6, 0, 0, 1, 0, 0, 0, 0, 0,
        0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 6, 0, 0, 1, 0, 4, 0, 6, 0,
        0, 1, 5, 4, 0, 6, 0, 0, 1, 0, 0, 4, 0, 6, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 4, 0, 6, 0, 0, 1, 6, 0, 0, 0, 0, 0, 0, 0, 4, 0, 6, 0, 0, 1, 0,
        0, 4, 0, 6, 0, 0, 1, 0, 0, 0, 0, 0, 4, 0, 6, 0, 0, 1, 0, 0, 0, 4, 0, 6,
        0, 0, 1, 0, 0, 0, 0, 4, 0, 6, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0,
        6, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0,
        4, 0, 6, 0, 0, 1, 0, 0, 1, 4, 0, 6, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 4, 0, 6, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4,
        0, 6, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 4, 0, 6, 0, 0, 1, 0, 0, 1, 0, 0, 4, 0,
        6, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 4, 0, 6, 0, 0, 1, 4, 5, 0, 8, 8, 0, 0, 6, 0, 0, 1, 4, 1, 1,
        0, 0, 0, 0, 0, 0, 8, 8, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0,
        0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0];
    constant [1213] integer STEP_SOURCE0 = [
        -1, -1, -1, -1, 39, -1, -1, -1, -1, -1, -1, 70, -1, 37, -1, 0, 0, 38, -1, -1, -1, 70, 75, 70,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, 71, -1, -1, 69, -1, -1, -1, -1, 55, -1, -1, 55, -1, -1, -1,
        56, -1, -1, -1, 57, -1, 69, -1, -1, 69, -1, -1, 56, 57, 69, -1, 69, 58, -1, 58, -1, 75, -1, -1,
        -1, -1, 55, -1, -1, -1, -1, -1, 69, 56, 69, -1, -1, -1, 56, -1, -1, 57, -1, 40, -1, 55, 69, 57,
        41, -1, 69, -1, 58, -1, 59, -1, -1, -1, 69, -1, 58, 59, 31, -1, -1, 55, 71, 69, 32, -1, 69, 14,
        55, -1, -1, 76, 69, -1, -1, -1, -1, -1, -1, -1, -1, -1, 72, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, 76, 26, 54, -1, 33, 35, -1, 36, -1, -1, 54, 53, 22, 23, 17, 55, -1, -1, -1, 55, -1, 33,
        35, -1, 36, -1, 34, -1, 53, 54, 30, -1, -1, -1, 0, -1, 0, 27, 28, -1, 0, 28, 29, 50, 0, 24,
        55, 18, 21, 17, 56, -1, -1, -1, 56, 55, 24, 55, 1, 14, 55, 24, 55, 7, 42, 14, 55, 24, 55, 7,
        8, 43, 55, 24, 55, 8, 9, 10, 11, 12, 13, 7, -1, -1, 14, 55, 24, 55, 7, 5, -1, 14, 55, 24,
        55, -1, 14, 55, 24, 55, 18, 44, 14, 55, 24, 55, 14, 14, 55, 24, 55, 18, 2, 15, -1, -1, 56, 44,
        56, 14, 55, 24, 55, 18, 19, 20, -1, 56, 45, -1, 15, -1, 57, 46, 57, 47, -1, 16, -1, 56, 55, 24,
        55, 18, 20, 17, 56, -1, -1, -1, 56, 20, 3, 4, 16, -1, 57, 47, 57, 55, 24, 55, 0, 14, 55, 24,
        55, 14, 14, 55, 24, 55, -1, 14, 55, 24, 55, 1, 3, 4, -1, -1, 14, 55, 24, 55, 25, 1, 2, -1,
        -1, 14, 55, 24, 55, 1, 2, 14, 55, 24, 55, 1, 2, -1, 14, 55, 24, 55, 1, 2, -1, 14, 55, 24,
        55, 1, 2, -1, 14, 55, 24, 55, 1, 2, 48, 14, 55, 24, 55, 1, 2, -1, 14, 55, 24, 55, 1, 2,
        -1, 14, 55, 24, 55, 1, 2, -1, 51, 14, 55, 24, 55, 1, 2, -1, 52, 14, 55, 24, 55, 1, 2, -1,
        -1, -1, -1, -1, -1, -1, 14, 55, 24, 55, 1, 2, -1, -1, 14, 55, 24, 55, 1, 2, -1, 49, -1, 14,
        55, 24, 55, 14, 14, 55, -1, -1, -1, -1, 24, 55, 14, 60, 56, 55, -1, -1, 56, -1, -1, -1, -1, -1,
        -1, -1, -1, 75, 72, -1, 73, -1, -1, -1, 73, -1, -1, -1, -1, -1, 55, -1, -1, -1, -1, -1, 55, 56,
        -1, -1, -1, 56, -1, -1, 74, 57, -1, -1, -1, -1, 57, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0,
        0, 0, 0, -1, 75, 77, -1, -1, -1, 0, 75, 78, -1, 77, -1, -1, 77, 61, -1, 0, -1, -1, -1, -1,
        -1, -1, -1, 55, -1, -1, -1, -1, 55, 78, 72, -1, 73, -1, -1, -1, 73, -1, -1, -1, -1, -1, 55, -1,
        -1, -1, -1, -1, 55, 56, -1, -1, -1, 56, -1, -1, 74, 57, -1, -1, -1, -1, -1, -1, -1, -1, -1, 57,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, -1,
        -1, 75, 77, -1, -1, -1, -1, -1, -1, -1, -1, 77, 0, -1, 75, 78, -1, -1, 55, -1, -1, -1, -1, -1,
        77, 55, -1, -1, 77, -1, -1, -1, -1, -1, -1, 77, 75, 26, -1, -1, 54, -1, 33, 35, -1, -1, 36, -1,
        36, -1, -1, -1, -1, -1, -1, 54, 53, 22, 23, 17, 55, -1, -1, -1, -1, 55, -1, 33, 35, -1, -1, 36,
        -1, 36, -1, -1, -1, 34, -1, -1, 53, 54, 61, -1, -1, -1, -1, 0, 27, 28, -1, 0, 28, 29, 64, 0,
        24, -1, -1, 55, 18, 21, 17, 56, -1, -1, -1, -1, 56, 55, 24, -1, -1, 55, 1, 14, 55, 24, -1, -1,
        55, 7, 5, 14, 55, 24, -1, -1, 55, 7, 8, 5, 55, 24, -1, -1, 55, 7, 5, 14, 55, 24, -1, -1,
        55, -1, -1, 14, 55, 24, -1, -1, 55, 18, 14, 14, 55, 24, -1, -1, 55, 14, 14, 55, 24, -1, -1, 55,
        18, 2, 15, -1, -1, -1, -1, -1, 56, 14, 56, 14, 55, 24, -1, -1, 55, 18, 19, 20, -1, 56, 68, -1,
        -1, 15, -1, -1, -1, 57, 67, 57, 67, -1, 16, -1, -1, 56, 55, 24, -1, -1, 55, 18, 20, 17, 56, -1,
        -1, -1, -1, 56, 20, 3, 4, 16, -1, -1, -1, 57, 67, 57, 55, 24, -1, -1, 55, 0, 14, 55, 24, -1,
        -1, 55, 14, 14, 55, 24, -1, -1, 55, -1, -1, 14, 55, 24, -1, -1, 55, 1, 3, 4, -1, -1, -1, -1,
        -1, -1, -1, 14, 55, 24, -1, -1, 55, 25, 1, 2, -1, -1, -1, -1, -1, 14, 55, 24, -1, -1, 55, 1,
        2, 14, 55, 24, -1, -1, 55, 1, 2, -1, -1, -1, 14, 55, 24, -1, -1, 55, 1, 2, -1, 14, 55, 24,
        -1, -1, 55, 1, 2, -1, -1, 14, 55, 24, -1, -1, 55, 1, 2, 62, 63, -1, -1, -1, -1, -1, 14, 55,
        24, -1, -1, 55, 1, 2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 79, -1, -1, -1, -1, -1,
        14, 55, 24, -1, -1, 55, 1, 2, 79, 14, 55, 24, -1, -1, 55, 1, 2, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, 65, -1, 14, 55, 24, -1, -1, 55, 1, 2, -1, -1, -1, -1, -1, -1, -1, -1, -1, 66, -1, 14,
        55, 24, -1, -1, 55, 1, 2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 79, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, 56, -1, -1, 56, 14, 55, 24, -1, -1, 55, 1, 2, 79, -1, -1, 14, 55,
        24, -1, -1, 55, 1, 2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, 14, 55, 24, -1, -1, 55, 14, 14, 55, -1, -1, -1, -1, 24, -1, -1, 55, 14, 60, 56,
        55, -1, -1, 56, -1, -1, -1, -1, -1, -1, 55, -1, -1, -1, -1, 55, 78, 72, -1, -1, 73, -1, -1, -1,
        -1, -1, 73, -1, -1, -1, 55, -1, -1, 79, -1, -1, -1, -1, 55, 56, -1, -1, -1, -1, 56, -1, -1, 74,
        -1, -1, 57, -1, -1, -1, -1, -1, -1, -1, -1, -1, 57, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        79, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 58, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, 58, -1, -1, -1];
    constant [1213] integer STEP_SOURCE1 = [
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 2, -1, -1, -1, -1, -1, 0, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, 0, -1, -1,
        -1, -1, 0, -1, -1, -1, -1, -1, 0, -1, -1, -1, 1, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, -1, -1,
        -1, 0, 0, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, -1,
        -1, 0, -1, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, 0, -1, -1,
        -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1,
        -1, 0, -1, -1, -1, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, -1, -1, 0,
        -1, -1, -1, 1, 0, -1, -1, -1, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 2, -1, -1, -1, -1,
        -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, -1, -1, -1, -1,
        -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, 1, 0, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, -1, -1, -1,
        -1, -1, 0, 0, -1, -1, -1, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1,
        -1, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, -1, -1, 0, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        0, -1, -1, -1, -1, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, 1, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1];
    constant [18] integer LOAD_OFFSET_FORM = [
        0, 0, 36, 0, 34, 35, 0, 0, 32, 33, 0, 0, 0, 0, 0, 0, 31, 31];
    constant [18] integer LOAD_INDEXED_FORM = [
        0, 0, 46, 0, 44, 45, 0, 0, 42, 43, 0, 0, 0, 0, 0, 0, 41, 41];
    constant [9] integer STORE_OFFSET_FORM = [
        0, 40, 39, 0, 38, 0, 0, 0, 37];
    constant [9] integer STORE_INDEXED_FORM = [
        0, 50, 49, 0, 48, 0, 0, 0, 47];
    constant [75] integer OP_INSTRUCTION_FORM = [
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 18, 16, 14, -1, -1, -1, -1, -1, -1,
        10, 12, 25, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1];
    constant [75] integer OP_SHIFT_FORM = [
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, 21, 22, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1];
    constant [75] integer OP_SIGNED_CONDITION = [
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 1, 0, 10, 12, 13, 11,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1];
    constant [75] integer OP_UNSIGNED_CONDITION = [
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 1, 0, 2, 8, 9, 3,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1];
    constant integer CODE_COLUMN_COUNT = 10;
    constant [10] ulong CODE_HEADER_WORD0 = [
        ulong(139275169638), ulong(540045423), ulong(540110959), ulong(540176495), ulong(540242031), ulong(8313491416025293172),
        ulong(8025261039873581428), ulong(7378707494940729700), ulong(7596553733751988580), ulong(139073970532)];
    constant [10] ulong CODE_HEADER_WORD1 = [
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(9128624044401509),
        ulong(35684290356838), ulong(139375961459), ulong(2338340649032314471), ulong(0)];
    constant [10] integer CODE_HEADER_LENGTH = [
        5, 4, 4, 4, 4, 15, 14, 13, 16, 5];
    constant [58] ubyte EMIT_TEXT = "presence input malformed at step memory reservation failed";
    constant integer MALFORMED_TEXT_LENGTH = 33;
    constant integer STEP_SOURCE_BASE = 1048576;
    constant integer UPH_PROLOGUE = 0;
    constant integer UPH_RESERVE = 1;
    constant integer UPH_WINDOW = 2;
    constant integer UPH_JUMP_STEP = 3;
    constant integer UPH_RESERVE_FAILED = 8;
    constant integer UPH_READ_VALUE = 9;
    constant integer UPH_STEP = 10;
    constant integer UPH_READ_LINE = 11;
    constant integer UPH_VALUE_INPUT = 12;
    constant integer UPH_READ_TAIL = 13;
    constant integer UPH_ORDER = 14;
    constant integer UPH_DELAY = 15;
    constant integer UPH_OUTPUT_HEAD = 16;
    constant integer UPH_OUTPUT = 17;
    constant integer UPH_OUTPUT_TAIL = 18;
    constant integer UPH_FINISH = 19;
    constant integer UPH_DONE = 20;
    constant [20] integer UNIT_PHASE_TEMPLATE = [
        0, 1, 2, 3, 54, 55, 56, 57, 4, 5, 6, 7, 8, 9, -1, 47, 48, 49, 50, 51];
    constant integer F_OUTPUT_FULL = 29;
    constant integer F_CAP_CLOCK_TEXT = 277;
    constant integer F_CAP_CLOCK_SORT = 278;
    constant integer F_CAP_EFFECT_ORDER = 282;
    constant integer F_ENCODE_POSITION = 30;
    constant integer F_OUT_OF_RANGE = 31;
    constant integer F_LIST_SEPARATOR = 32;
    constant integer F_PRESENCE_PREFIX = 33;
    constant integer LAYOUT_ENCODE = 7;
    constant integer LAYOUT_OS_OUTPUT = 8;
    constant integer LAYOUT_PRESENCE = 9;
    constant integer ROW_SLICE_OUTPUT_PATH = 2;
    constant integer ROW_SLICE_CLOCK = 3;
    constant integer ROW_NUMBER_ENCODE_OP0 = 4;
    constant integer ROW_NUMBER_ENCODE_OP1 = 5;
    constant integer ROW_NUMBER_ENCODE_OP2 = 6;
    constant integer ROW_NUMBER_ENCODE_OP3 = 7;
    constant integer ROW_NUMBER_OUTPUT_ERRNO = 8;
    constant integer FIELD_NONE = 0;
    constant integer FIELD_PCREL = 1;
    constant integer FIELD_PAGE = 2;
    constant integer FIELD_PAGEOFF = 3;
    constant [123] long FORM_BASE = [
        3531603968, 1384120320, 4068474880, 1920991232, 2432696320, 285212672,
        3506438144, 1358954496, 4043309056, 1895825408, 2332033024, 2868903936,
        3405774848, 3942645760, 2315255808, 167772160, 2852126720, 704643072,
        3388997632, 2854223872, 3527409664, 2596282368, 2596283392, 2596277248,
        2596276224, 2600500224, 2600501248, 2613083136, 2592079872, 444597248,
        3665822720, 4181721088, 3107979264, 3112173568, 2034237440, 2038431744,
        960495616, 4177526784, 3103784960, 2030043136, 956301312, 4167071744,
        3093329920, 3097524224, 2019588096, 2023782400, 945842176, 4162877440,
        3089135616, 2015393792, 941647872, 4164944896, 4160750592, 3087008768,
        939525120, 943721472, 335544320, 2483027968, 1409286144, 872415232,
        3019898880, 3036676096, 2415919104, 3596551104, 3556773889, 0,
        3573751935, 62016, 62144, 62016, 62144, 61952,
        62112, 59904, 59968, 59984, 60032, 60160,
        60176, 60224, 60240, 60256, 60272, 60336,
        59983, 60015, 4026595840, 4026595872, 59983, 1108559,
        2157135, 64416, 64256, 61872, 61712, 61760,
        61808, 61888, 61568, 61504, 63696, 63632,
        63664, 63920, 63680, 63616, 63648, 59856,
        59840, 59632, 59616, 184612864, 184612880, 218167312,
        218167360, 184612944, 3087069184, 4160811008, 3204501506, 3204466544,
        2147742639, 2282812288, 0];
    constant [123] short FORM_SIGNED = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0,
        0, 0, 0];
    constant [123] short FORM_KIND = [
        0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 2, 0, 0, 0, 0, 0, 0, 5, 6, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 4, 0, 0,
        0, 0, 0];
    constant [123] short FORM_TOP2 = [
        16, 16, 16, 16, 12, 12, 12, 12, 12, 12, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 0, 5, 5, 5,
        5, 5, 5, 5, 5, 5, 5, 15, 14, 14, 13, 13, 12, 15, 14, 13, 12, 5, 5, 5, 5, 5, 5, 5,
        5, 5, 5, 9, 9, 9, 9, 9, 28, 28, 21, 21, 21, 21, 33, 0, 0, 32, 0, 16, 16, 16, 16, 12,
        12, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 0, 0, 4, 4, 5, 5, 5, 4, 4, 8, 8, 8,
        8, 8, 8, 8, 12, 12, 12, 12, 12, 12, 12, 10, 10, 10, 10, 8, 8, 8, 8, 8, 23, 23, 0, 0,
        0, 0, 32];
    constant [615] short FORM_FIELD_SLOT = [
        0, 2, 3, 0, 0, 0, 2, 3, 0, 0, 0, 2, 3, 0, 0, 0, 2, 3, 0, 0, 0, 1, 2, 0,
        0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2,
        0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 1,
        2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0,
        1, 2, 0, 0, 0, 1, 0, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0,
        0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 3, 0, 0, 1, 2, 0, 0, 0, 1, 2, 3,
        0, 0, 1, 2, 3, 0, 0, 1, 2, 3, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2,
        0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 1,
        2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0,
        1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0,
        0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0,
        0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 2, 0, 0, 0, 0, 2, 0, 0,
        0, 0, 3, 2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 2,
        2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        2, 2, 2, 2, 0, 2, 2, 2, 2, 0, 2, 2, 2, 2, 0, 2, 2, 2, 2, 0, 1, 2, 2, 2,
        0, 1, 2, 2, 2, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0,
        0, 0, 1, 2, 3, 3, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2,
        0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1,
        2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 2, 0, 0, 1, 2, 2, 0, 0, 1, 2, 2, 0, 0,
        1, 2, 3, 0, 0, 1, 2, 3, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0,
        0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0,
        0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2,
        0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 3, 0, 0, 1, 2, 3, 0, 0, 1, 2, 3, 0, 0, 1,
        2, 3, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0, 1, 2, 0, 0, 0,
        1, 2, 0, 0, 2, 2, 2, 0, 0, 2, 2, 2, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 0, 0, 0];
    constant [615] short FORM_FIELD_LOW = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 2, 0, 0, 0, 0, 2,
        0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0,
        2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 2, 0, 0,
        0, 0, 0, 2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 12,
        14, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 8, 11, 12, 0, 0, 8, 11, 12, 0, 0, 8, 11, 12, 0, 0, 8, 11, 12, 0, 0, 0, 8, 11,
        0, 0, 0, 8, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 2, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 2, 0, 0, 0, 0,
        2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 1, 12, 22, 0, 0, 1, 12, 22, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 0, 0, 0];
    constant [615] short FORM_FIELD_WIDTH = [
        5, 16, 2, 0, 0, 5, 16, 1, 0, 0, 5, 16, 2, 0, 0, 5, 16, 1, 0, 0, 5, 5, 12, 0,
        0, 5, 5, 12, 0, 0, 5, 5, 12, 0, 0, 5, 5, 12, 0, 0, 5, 5, 12, 0, 0, 5, 5, 12,
        0, 0, 5, 5, 5, 0, 0, 5, 5, 5, 0, 0, 5, 5, 5, 0, 0, 5, 5, 5, 0, 0, 5, 5,
        5, 0, 0, 5, 5, 5, 0, 0, 5, 5, 5, 0, 0, 5, 5, 5, 0, 0, 5, 5, 5, 0, 0, 5,
        5, 5, 0, 0, 5, 5, 0, 0, 0, 5, 5, 5, 0, 0, 5, 5, 5, 0, 0, 5, 5, 5, 0, 0,
        5, 5, 5, 0, 0, 5, 5, 5, 0, 0, 5, 5, 5, 5, 0, 5, 5, 5, 0, 0, 5, 5, 5, 4,
        0, 5, 5, 5, 4, 0, 5, 5, 5, 4, 0, 5, 5, 12, 0, 0, 5, 5, 12, 0, 0, 5, 5, 12,
        0, 0, 5, 5, 12, 0, 0, 5, 5, 12, 0, 0, 5, 5, 12, 0, 0, 5, 5, 12, 0, 0, 5, 5,
        12, 0, 0, 5, 5, 12, 0, 0, 5, 5, 12, 0, 0, 5, 5, 5, 0, 0, 5, 5, 5, 0, 0, 5,
        5, 5, 0, 0, 5, 5, 5, 0, 0, 5, 5, 5, 0, 0, 5, 5, 5, 0, 0, 5, 5, 5, 0, 0,
        5, 5, 5, 0, 0, 5, 5, 5, 0, 0, 5, 5, 5, 0, 0, 5, 5, 9, 0, 0, 5, 5, 9, 0,
        0, 5, 5, 9, 0, 0, 5, 5, 9, 0, 0, 5, 5, 9, 0, 0, 26, 0, 0, 0, 0, 26, 0, 0,
        0, 0, 4, 19, 0, 0, 0, 5, 19, 0, 0, 0, 5, 19, 0, 0, 0, 5, 19, 0, 0, 0, 5, 2,
        19, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4,
        8, 3, 1, 4, 4, 8, 3, 1, 4, 4, 8, 3, 1, 4, 4, 8, 3, 1, 4, 4, 4, 8, 3, 1,
        4, 4, 8, 3, 1, 4, 4, 4, 0, 0, 4, 4, 4, 0, 0, 4, 4, 4, 0, 0, 4, 4, 4, 0,
        0, 4, 4, 4, 2, 3, 4, 4, 4, 0, 0, 4, 4, 4, 0, 0, 4, 4, 4, 0, 0, 4, 4, 4,
        0, 0, 4, 4, 4, 0, 0, 4, 4, 4, 0, 0, 4, 4, 0, 0, 0, 4, 4, 0, 0, 0, 4, 4,
        4, 0, 0, 4, 4, 4, 0, 0, 4, 4, 2, 3, 0, 4, 4, 2, 3, 0, 4, 4, 2, 3, 0, 4,
        4, 4, 4, 0, 4, 4, 4, 4, 0, 4, 4, 8, 0, 0, 4, 4, 8, 0, 0, 4, 4, 8, 0, 0,
        4, 4, 8, 0, 0, 4, 4, 8, 0, 0, 4, 4, 8, 0, 0, 4, 4, 8, 0, 0, 4, 4, 12, 0,
        0, 4, 4, 12, 0, 0, 4, 4, 12, 0, 0, 4, 4, 12, 0, 0, 4, 4, 12, 0, 0, 4, 4, 12,
        0, 0, 4, 4, 12, 0, 0, 4, 4, 8, 4, 0, 4, 4, 8, 4, 0, 4, 4, 8, 4, 0, 4, 4,
        8, 4, 0, 4, 4, 8, 0, 0, 4, 4, 8, 0, 0, 4, 4, 8, 0, 0, 4, 4, 8, 0, 0, 4,
        4, 8, 0, 0, 11, 10, 1, 0, 0, 11, 10, 1, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 16, 0, 0, 0];
    constant [615] short FORM_FIELD_AT = [
        0, 5, 21, 0, 0, 0, 5, 21, 0, 0, 0, 5, 21, 0, 0, 0, 5, 21, 0, 0, 0, 5, 10, 0,
        0, 0, 5, 10, 0, 0, 0, 5, 10, 0, 0, 0, 5, 10, 0, 0, 0, 5, 10, 0, 0, 0, 5, 10,
        0, 0, 0, 5, 16, 0, 0, 0, 5, 16, 0, 0, 0, 5, 16, 0, 0, 0, 5, 16, 0, 0, 0, 5,
        16, 0, 0, 0, 5, 16, 0, 0, 0, 5, 16, 0, 0, 0, 5, 16, 0, 0, 0, 5, 16, 0, 0, 0,
        5, 16, 0, 0, 0, 5, 0, 0, 0, 0, 5, 16, 0, 0, 0, 5, 16, 0, 0, 0, 5, 16, 0, 0,
        0, 5, 16, 0, 0, 0, 5, 16, 0, 0, 0, 5, 16, 10, 0, 0, 5, 16, 0, 0, 0, 5, 16, 12,
        0, 0, 5, 16, 12, 0, 0, 5, 16, 12, 0, 0, 5, 10, 0, 0, 0, 5, 10, 0, 0, 0, 5, 10,
        0, 0, 0, 5, 10, 0, 0, 0, 5, 10, 0, 0, 0, 5, 10, 0, 0, 0, 5, 10, 0, 0, 0, 5,
        10, 0, 0, 0, 5, 10, 0, 0, 0, 5, 10, 0, 0, 0, 5, 16, 0, 0, 0, 5, 16, 0, 0, 0,
        5, 16, 0, 0, 0, 5, 16, 0, 0, 0, 5, 16, 0, 0, 0, 5, 16, 0, 0, 0, 5, 16, 0, 0,
        0, 5, 16, 0, 0, 0, 5, 16, 0, 0, 0, 5, 16, 0, 0, 0, 5, 12, 0, 0, 0, 5, 12, 0,
        0, 0, 5, 12, 0, 0, 0, 5, 12, 0, 0, 0, 5, 12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 5, 0, 0, 0, 0, 5, 0, 0, 0, 0, 5, 0, 0, 0, 0, 5, 0, 0, 0, 0, 29,
        5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 24,
        16, 28, 10, 0, 24, 16, 28, 10, 0, 24, 16, 28, 10, 0, 24, 16, 28, 10, 0, 24, 0, 16, 28, 10,
        24, 0, 16, 28, 10, 24, 0, 16, 0, 0, 24, 0, 16, 0, 0, 24, 0, 16, 0, 0, 24, 0, 16, 0,
        0, 24, 0, 16, 22, 28, 24, 0, 16, 0, 0, 24, 0, 16, 0, 0, 24, 0, 16, 0, 0, 24, 0, 16,
        0, 0, 24, 0, 16, 0, 0, 24, 0, 16, 0, 0, 24, 16, 0, 0, 0, 24, 16, 0, 0, 0, 24, 0,
        16, 0, 0, 24, 0, 16, 0, 0, 24, 16, 22, 28, 0, 24, 16, 22, 28, 0, 24, 16, 22, 28, 0, 28,
        0, 16, 24, 0, 24, 0, 16, 28, 0, 24, 0, 16, 0, 0, 24, 0, 16, 0, 0, 24, 0, 16, 0, 0,
        24, 0, 16, 0, 0, 24, 0, 16, 0, 0, 24, 0, 16, 0, 0, 24, 0, 16, 0, 0, 28, 0, 16, 0,
        0, 28, 0, 16, 0, 0, 28, 0, 16, 0, 0, 28, 0, 16, 0, 0, 28, 0, 16, 0, 0, 28, 0, 16,
        0, 0, 28, 0, 16, 0, 0, 28, 0, 16, 24, 0, 28, 0, 16, 24, 0, 28, 0, 16, 24, 0, 28, 0,
        16, 24, 0, 28, 0, 16, 0, 0, 28, 0, 16, 0, 0, 28, 0, 16, 0, 0, 28, 0, 16, 0, 0, 28,
        0, 16, 0, 0, 16, 0, 10, 0, 0, 16, 0, 10, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 0, 0, 0, 0];
    constant integer FORM_FIELD_SLOTS = 5;
    constant [123] short FORM_NAME_FRAGMENT = [
        811, 812, 813, 814, 815, 816, 817, 818, 819, 820, 821, 822, 823, 824, 825, 826, 827, 828, 829, 830, 831, 832, 833, 834,
        835, 836, 837, 838, 839, 840, 841, 842, 843, 844, 845, 846, 847, 848, 849, 850, 851, 852, 853, 854, 855, 856, 857, 858,
        859, 860, 861, 862, 863, 864, 865, 866, 867, 868, 869, 870, 871, 872, 873, 874, 875, 876, 877, 878, 879, 880, 881, 882,
        883, 884, 885, 886, 887, 888, 889, 890, 891, 892, 893, 894, 895, 896, 897, 898, 899, 900, 901, 902, 903, 904, 905, 906,
        907, 908, 909, 910, 911, 912, 913, 914, 915, 916, 917, 918, 919, 920, 921, 922, 923, 924, 925, 926, 927, 868, 928, 929,
        930, 931, 932];
    constant integer ROW_PREFIX_FORM_NAME = -1;
    constant integer TEXT_OFFSET = 392;
    constant integer SEGMENT_BYTES = 16384;
    constant integer SUPERBLOB_HEADER_BYTES = 20;
    constant integer CODE_DIRECTORY_HEADER_BYTES = 48;
    constant integer HASH_BYTES = 32;
    constant integer HEADER_WORD_COUNT = 98;
    constant [98] uinteger HEADER_WORD = [
        uinteger(4277009103), uinteger(16777228), uinteger(0), uinteger(2), uinteger(7), uinteger(360),
        uinteger(2097156), uinteger(0), uinteger(25), uinteger(72), uinteger(1095786335), uinteger(1163543879),
        uinteger(20306), uinteger(0), uinteger(0), uinteger(0), uinteger(0), uinteger(1),
        uinteger(0), uinteger(0), uinteger(0), uinteger(0), uinteger(0), uinteger(0),
        uinteger(0), uinteger(0), uinteger(25), uinteger(72), uinteger(1163157343), uinteger(21592),
        uinteger(0), uinteger(0), uinteger(0), uinteger(1), uinteger(0), uinteger(0),
        uinteger(0), uinteger(0), uinteger(0), uinteger(0), uinteger(5), uinteger(5),
        uinteger(0), uinteger(0), uinteger(25), uinteger(72), uinteger(1094999903), uinteger(16724),
        uinteger(0), uinteger(0), uinteger(0), uinteger(1), uinteger(0), uinteger(0),
        uinteger(0), uinteger(0), uinteger(0), uinteger(0), uinteger(3), uinteger(3),
        uinteger(0), uinteger(0), uinteger(25), uinteger(72), uinteger(1229741919), uinteger(1145391950),
        uinteger(21577), uinteger(0), uinteger(0), uinteger(1), uinteger(0), uinteger(0),
        uinteger(0), uinteger(0), uinteger(0), uinteger(0), uinteger(1), uinteger(1),
        uinteger(0), uinteger(0), uinteger(14), uinteger(32), uinteger(12), uinteger(1920169263),
        uinteger(1651076143), uinteger(1819894831), uinteger(100), uinteger(0), uinteger(2147483688), uinteger(24),
        uinteger(392), uinteger(0), uinteger(0), uinteger(0), uinteger(29), uinteger(16),
        uinteger(0), uinteger(0)];
    constant [98] short HEADER_FIELD = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 1, 0, 2, 0, 1, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 4, 0,
        3, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        3, 5];
    constant integer HV_CONSTANT = 0;
    constant integer HV_TEXT_BYTES = 1;
    constant integer HV_DATA_BYTES = 2;
    constant integer HV_SIGNED_BYTES = 3;
    constant integer HV_LINKEDIT_BYTES = 4;
    constant integer HV_SIGNATURE_BYTES = 5;
    constant integer SIGNATURE_HEADER_BYTES = 68;
    constant [17] uinteger SIGNATURE_WORD = [
        uinteger(4208856256), uinteger(0), uinteger(1), uinteger(0), uinteger(20), uinteger(4208856066),
        uinteger(0), uinteger(131328), uinteger(2), uinteger(49), uinteger(48), uinteger(0),
        uinteger(0), uinteger(0), uinteger(537001998), uinteger(0), uinteger(0)];
    constant [17] short SIGNATURE_FIELD = [
        0, 1, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 3, 4, 0, 0, 0];
    constant integer SV_CONSTANT = 0;
    constant integer SV_SIGNATURE_BYTES = 1;
    constant integer SV_DIRECTORY_BYTES = 2;
    constant integer SV_PAGES = 3;
    constant integer SV_SIGNED_BYTES = 4;
    constant [64] uinteger SHA_K = [
        uinteger(1116352408), uinteger(1899447441), uinteger(3049323471), uinteger(3921009573), uinteger(961987163), uinteger(1508970993),
        uinteger(2453635748), uinteger(2870763221), uinteger(3624381080), uinteger(310598401), uinteger(607225278), uinteger(1426881987),
        uinteger(1925078388), uinteger(2162078206), uinteger(2614888103), uinteger(3248222580), uinteger(3835390401), uinteger(4022224774),
        uinteger(264347078), uinteger(604807628), uinteger(770255983), uinteger(1249150122), uinteger(1555081692), uinteger(1996064986),
        uinteger(2554220882), uinteger(2821834349), uinteger(2952996808), uinteger(3210313671), uinteger(3336571891), uinteger(3584528711),
        uinteger(113926993), uinteger(338241895), uinteger(666307205), uinteger(773529912), uinteger(1294757372), uinteger(1396182291),
        uinteger(1695183700), uinteger(1986661051), uinteger(2177026350), uinteger(2456956037), uinteger(2730485921), uinteger(2820302411),
        uinteger(3259730800), uinteger(3345764771), uinteger(3516065817), uinteger(3600352804), uinteger(4094571909), uinteger(275423344),
        uinteger(430227734), uinteger(506948616), uinteger(659060556), uinteger(883997877), uinteger(958139571), uinteger(1322822218),
        uinteger(1537002063), uinteger(1747873779), uinteger(1955562222), uinteger(2024104815), uinteger(2227730452), uinteger(2361852424),
        uinteger(2428436474), uinteger(2756734187), uinteger(3204031479), uinteger(3329325298)];
    constant [8] uinteger SHA_IV = [
        uinteger(1779033703), uinteger(3144134277), uinteger(1013904242), uinteger(2773480762), uinteger(1359893119), uinteger(2600822924),
        uinteger(528734635), uinteger(1541459225)];
    constant long MACHO_BASE = 4294967296;
    constant integer F_UTF8_BYTE_PREFIX = 34;
    constant integer F_UTF8_BYTES_PREFIX = 35;
    constant integer F_IN_POSITION = 36;
    constant integer F_COLON_SPACE = 37;
    constant integer F_DASH = 38;
    constant integer F_RESERVATION_FAILED = 39;
    constant integer LAYOUT_UTF8_BYTE = 10;
    constant integer LAYOUT_UTF8_BYTES = 11;
    constant integer ROW_NUMBER_UTF8_START = 9;
    constant integer ROW_NUMBER_UTF8_LAST = 10;
    constant integer ROW_PREFIX_HEX_BYTE = -2;
    constant integer ROW_PREFIX_UTF8_REASON = -3;
    constant integer UTF8_INVALID_START = 0;
    constant integer UTF8_INVALID_CONTINUATION = 1;
    constant integer UTF8_UNEXPECTED_END = 2;
    constant [3] short UTF8_REASON_FRAGMENT = [
        552, 553, 554];
    constant [256] short HEX_FRAGMENT = [
        555, 556, 557, 558, 559, 560, 561, 562, 563, 564, 565, 566, 567, 568, 569, 570, 571, 572, 573, 574, 575, 576, 577, 578,
        579, 580, 581, 582, 583, 584, 585, 586, 587, 588, 589, 590, 591, 592, 593, 594, 595, 596, 597, 598, 599, 600, 601, 602,
        603, 604, 605, 606, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616, 617, 618, 619, 620, 621, 622, 623, 624, 625, 626,
        627, 628, 629, 630, 631, 632, 633, 634, 635, 636, 637, 638, 639, 640, 641, 642, 643, 644, 645, 646, 647, 648, 649, 650,
        651, 652, 653, 654, 655, 656, 657, 658, 659, 660, 661, 662, 663, 664, 665, 666, 667, 668, 669, 670, 671, 672, 673, 674,
        675, 676, 677, 678, 679, 680, 681, 682, 683, 684, 685, 686, 687, 688, 689, 690, 691, 692, 693, 694, 695, 696, 697, 698,
        699, 700, 701, 702, 703, 704, 705, 706, 707, 708, 709, 710, 711, 712, 713, 714, 715, 716, 717, 718, 719, 720, 721, 722,
        723, 724, 725, 726, 727, 728, 729, 730, 731, 732, 733, 734, 735, 736, 737, 738, 739, 740, 741, 742, 743, 744, 745, 746,
        747, 748, 749, 750, 751, 752, 753, 754, 755, 756, 757, 758, 759, 760, 761, 762, 763, 764, 765, 766, 767, 768, 769, 770,
        771, 772, 773, 774, 775, 776, 777, 778, 779, 780, 781, 782, 783, 784, 785, 786, 787, 788, 789, 790, 791, 792, 793, 794,
        795, 796, 797, 798, 799, 800, 801, 802, 803, 804, 805, 806, 807, 808, 809, 810];
    constant integer N_PRAGMAS = 56;
    constant integer N_INTERRUPT = 57;
    constant integer N_BOOT = 58;
    constant integer T_PRAGMAS_TOP = 128;
    constant integer T_PRAGMA_UNKNOWN = 129;
    constant integer T_PRAGMAS_END = 140;
    constant integer T_INTERRUPT_STATEMENT = 141;
    constant integer T_INTERRUPT_NUMBER = 142;
    constant integer T_INTERRUPT_TWICE = 143;
    constant integer T_BOOT_TWICE = 144;
    constant integer T_PRAGMA_INPUT = 145;
    constant integer T_PRAGMA_EVENT = 146;
    constant integer T_PRAGMA_TWICE = 147;
    constant integer T_INPUT_UNNAMED = 148;
    constant integer T_VIRT_ROOT = 149;
    constant integer T_SYSCALL_VIRT = 150;
    constant integer P_PRAGMA_NAME = 48;
    constant integer P_PRAGMA_OPEN = 49;
    constant integer P_PRAGMA_OBJECT = 50;
    constant integer P_PRAGMA_CLOSE = 51;
    constant integer P_PRAGMA_STATEMENT = 52;
    constant integer FORM_WFI = 66;
    constant integer ELF_WORD_COUNT = 30;
    constant [30] uinteger ELF_WORD = [
        uinteger(1179403647), uinteger(65794), uinteger(0), uinteger(0), uinteger(11993090), uinteger(1),
        uinteger(1073741944), uinteger(0), uinteger(64), uinteger(0), uinteger(0), uinteger(0),
        uinteger(0), uinteger(3670080), uinteger(1), uinteger(0), uinteger(1), uinteger(7),
        uinteger(0), uinteger(0), uinteger(1073741824), uinteger(0), uinteger(1073741824), uinteger(0),
        uinteger(0), uinteger(0), uinteger(0), uinteger(0), uinteger(16384), uinteger(0)];
    constant [30] short ELF_FIELD = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        1, 0, 2, 0, 0, 0];
    constant integer EV_CONSTANT = 0;
    constant integer EV_SIGNED_BYTES = 1;
    constant integer EV_MEMORY_BYTES = 2;
    constant long VIRT_BASE = 1073741824;
    constant integer VIRT_TEXT_OFFSET = 120;
    constant integer BOOT_ID = 1024;
    constant integer TG_TAIL = 11;
    constant integer TG_STACK = 12;
    constant integer GL_WAIT = 8;
    constant integer ES_ROOT_IRQ = 61;
    constant integer ES_WAIT = 77;
    constant integer ET_PROLOGUE_VIRT = 52;
    constant integer ET_WINDOW_VIRT = 53;
    constant integer ET_BOOT = 54;
    constant integer ET_WAIT = 55;
    constant integer ET_DISPATCH = 56;
    constant integer ET_WAIT_TAIL = 57;
    constant integer ET_CLOCK_ROOT_VIRT = 58;
    constant integer ET_OUTPUT_TAIL_VIRT = 59;
    constant integer ET_FINISH_VIRT = 60;
    constant integer UPH_BOOT = 4;
    constant integer UPH_WAIT = 5;
    constant integer UPH_DISPATCH = 6;
    constant integer UPH_WAIT_TAIL = 7;
    constant [20] integer UNIT_PHASE_TEMPLATE_VIRT = [
        52, 1, 53, 3, 54, 55, 56, 57, 4, 5, 6, 7, 8, 9, -1, 47, 48, 49, 59, 60];
    constant integer T_INPUT_SHARED = 152;
    constant integer T_BOOT_MISSING = 151;
    constant integer GL_COMPLETE = 9;
    constant integer ES_COMPLETE = 78;
    constant integer N_MACHINE = 59;
    constant integer T_MACHINE_UNKNOWN = 153;
    constant integer T_MACHINE_TWICE = 154;
    constant integer T_INTERRUPT_NUMBER_MPS2 = 155;
    constant integer T_SYSCALL_MPS2 = 156;
    constant integer T_IMAGE_SIZE = 157;
    constant integer FORM_MOVW_T = 67;
    constant integer FORM_MOVT_T = 68;
    constant integer FORM_MOVW_ABS_T = 69;
    constant integer FORM_MOVT_ABS_T = 70;
    constant integer FORM_ADDW_T = 71;
    constant integer FORM_SUBW_T = 72;
    constant integer FORM_AND_T = 73;
    constant integer FORM_ORR_T = 74;
    constant integer FORM_ORRS_T = 75;
    constant integer FORM_EOR_T = 76;
    constant integer FORM_ADD_SHIFT_T = 77;
    constant integer FORM_ADDS_T = 78;
    constant integer FORM_ADC_T = 79;
    constant integer FORM_ADCS_T = 80;
    constant integer FORM_SBC_T = 81;
    constant integer FORM_SBCS_T = 82;
    constant integer FORM_SUBS_T = 83;
    constant integer FORM_MOV_T = 84;
    constant integer FORM_MVN_T = 85;
    constant integer FORM_LSL_T = 86;
    constant integer FORM_LSR_T = 87;
    constant integer FORM_LSL_IMM_T = 88;
    constant integer FORM_LSR_IMM_T = 89;
    constant integer FORM_ASR_IMM_T = 90;
    constant integer FORM_UMULL_T = 91;
    constant integer FORM_MLA_T = 92;
    constant integer FORM_SUBS_IMM_T = 93;
    constant integer FORM_ADDS_IMM_T = 94;
    constant integer FORM_ADC_IMM_T = 95;
    constant integer FORM_SBCS_IMM_T = 96;
    constant integer FORM_RSB_IMM_T = 97;
    constant integer FORM_EOR_IMM_T = 98;
    constant integer FORM_ORR_IMM_T = 99;
    constant integer FORM_LDR_T = 100;
    constant integer FORM_LDRB_T = 101;
    constant integer FORM_LDRH_T = 102;
    constant integer FORM_LDRSH_T = 103;
    constant integer FORM_STR_T = 104;
    constant integer FORM_STRB_T = 105;
    constant integer FORM_STRH_T = 106;
    constant integer FORM_LDRD_T = 107;
    constant integer FORM_STRD_T = 108;
    constant integer FORM_LDRD_POST_T = 109;
    constant integer FORM_STRD_POST_T = 110;
    constant integer FORM_STRB_POST_T = 111;
    constant integer FORM_LDRB_POST_T = 112;
    constant integer FORM_LDRB_PRE_DEC_T = 113;
    constant integer FORM_STR_PRE_DEC_T = 114;
    constant integer FORM_LDR_POST_T = 115;
    constant integer FORM_B_W_T = 116;
    constant integer FORM_BL_T = 117;
    constant integer FORM_SKIP_T = 118;
    constant integer FORM_BX_LR_T = 119;
    constant integer FORM_WFI_T = 120;
    constant integer FORM_MSR_PRIMASK_T = 121;
    constant integer FORM_WORD_T = 122;
    constant integer FIELD_THUMB_PCREL = 4;
    constant integer FIELD_ABS_LO = 5;
    constant integer FIELD_ABS_HI = 6;
    constant [23] uinteger ELF32_WORD = [
        uinteger(1179403647), uinteger(65793), uinteger(0), uinteger(0), uinteger(2621442), uinteger(1),
        uinteger(9), uinteger(52), uinteger(0), uinteger(83886592), uinteger(2097204), uinteger(2621441),
        uinteger(0), uinteger(1), uinteger(84), uinteger(0), uinteger(0), uinteger(0),
        uinteger(0), uinteger(7), uinteger(4), uinteger(0), uinteger(9)];
    constant [23] short ELF32_FIELD = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 0, 0, 2, 0];
    constant integer MPS2_HEADER_BYTES = 92;
    constant integer MPS2_UNLOADED = 84;
    constant integer MPS2_RAM_BYTES = 4194304;
    constant integer MPS2_STACK_BYTES = 64;
    constant integer VIRT_STACK_BYTES = 32;
    constant integer PLATFORM_MACOS = 0;
    constant integer PLATFORM_VIRT = 1;
    constant integer PLATFORM_MPS2 = 2;
    constant integer MACHINE_TEXT_LENGTH = 10;
    constant [10] ubyte MACHINE_TEXT = "mps2-an385";
    constant integer MK_LOAD_AT = 7;
    constant integer MK_STORE_AT = 8;
    constant integer GL_DIVIDE = 10;
    constant integer ES_BINARY_LO = 62;
    constant integer ES_BINARY_HI = 63;
    constant integer ES_PAIR_FORM_THUMB = 64;
    constant integer ES_SIGNED_CONDITION_THUMB = 65;
    constant integer ES_UNSIGNED_CONDITION_THUMB = 66;
    constant integer ES_ELEMENT_ROW = 67;
    constant integer ES_INDEX_ELEMENT = 68;
    constant integer ES_DIVIDE = 79;
    constant integer EP_MUL = 13;
    constant integer EP_NOT_MUL = 14;
    constant integer EP_COMPARE_EQUAL = 15;
    constant integer EP_COMPARE_DIRECT = 16;
    constant integer EP_COMPARE_SWAPPED = 17;
    constant integer EP_SHIFT_LEFT = 18;
    constant integer EP_SHIFT_RIGHT = 19;
    constant integer ET_PROLOGUE_THUMB = 61;
    constant integer ET_WINDOW_THUMB = 62;
    constant integer ET_BOOT_THUMB = 63;
    constant integer ET_WAIT_THUMB = 64;
    constant integer ET_DISPATCH_THUMB = 65;
    constant integer ET_WAIT_TAIL_THUMB = 66;
    constant integer ET_STEP_THUMB = 67;
    constant integer ET_LOOP_HEAD_THUMB = 68;
    constant integer ET_LOOP_MID_THUMB = 69;
    constant integer ET_SNAPSHOT_THUMB = 70;
    constant integer ET_LOOP_TAIL_THUMB = 71;
    constant integer ET_CLOCK_ROOT_THUMB = 72;
    constant integer ET_CLOCK_SAMPLE_THUMB = 73;
    constant integer ET_CLOCK_PAIR_THUMB = 74;
    constant integer ET_ROW_SEED_ARRAY_THUMB = 75;
    constant integer ET_ROW_SEED_THUMB = 76;
    constant integer ET_ROW_LOAD_THUMB = 77;
    constant integer ET_ROW_STORE_THUMB = 78;
    constant integer ET_ROW_INSTRUCTION_THUMB = 79;
    constant integer ET_ROW_ITER_RANGE_THUMB = 80;
    constant integer ET_ROW_ITER_THUMB = 81;
    constant integer ET_ROW_PREV_THUMB = 82;
    constant integer ET_ROW_ELEMENT_THUMB = 83;
    constant integer ET_ROW_GATHER_THUMB = 84;
    constant integer ET_ROW_NEXT_THUMB = 85;
    constant integer ET_ROW_CONST_THUMB = 86;
    constant integer ET_ROW_DELAY_THUMB = 87;
    constant integer ET_ROW_ONE_THUMB = 88;
    constant integer ET_ROW_IF_THUMB = 89;
    constant integer ET_ROW_DEFAULT_THUMB = 90;
    constant integer ET_ROW_PLAIN_THUMB = 91;
    constant integer ET_ROW_NEG_THUMB = 92;
    constant integer ET_ROW_NOT_LOGICAL_THUMB = 93;
    constant integer ET_ROW_NOT_THUMB = 94;
    constant integer ET_ROW_BINARY_THUMB = 95;
    constant integer ET_ROW_DIV_SIGNED_THUMB = 96;
    constant integer ET_ROW_DIV_THUMB = 97;
    constant integer ET_ROW_COMPARE_SIGNED_THUMB = 98;
    constant integer ET_ROW_COMPARE_THUMB = 99;
    constant integer ET_ROW_MOD_SIGNED_THUMB = 100;
    constant integer ET_ROW_MOD_THUMB = 101;
    constant integer ET_ROW_SHIFT_THUMB = 102;
    constant integer ET_DELAY_THUMB = 103;
    constant integer ET_OUTPUT_HEAD_THUMB = 104;
    constant integer ET_OUTPUT_THUMB = 105;
    constant integer ET_OUTPUT_TAIL_THUMB = 106;
    constant integer ET_FINISH_THUMB = 107;
    constant [108] integer THUMB_TEMPLATE = [
        61, -1, 62, -1, -1, -1, 67, -1, -1, -1, 68, 69, 70, 71, -1, 72, 73, 74, 75, 76, 77, 78, -1, 79,
        80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103,
        104, 105, 106, 107, 61, 62, 63, 64, 65, 66, 72, 106, 107, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71,
        72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95,
        96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107];
    constant [18] integer THUMB_LOAD_FORM = [
        0, 0, 101, 101, 102, 103, 0, 0, 100, 100, 0, 0, 0, 0, 0, 0, 107, 107];
    constant [9] integer THUMB_STORE_FORM = [
        0, 105, 106, 0, 104, 0, 0, 0, 108];
    constant [75] integer THUMB_BINARY_LO = [
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 76, 74, 73, -1, -1, -1, -1, -1, -1,
        78, 83, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1];
    constant [75] integer THUMB_BINARY_HI = [
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 76, 74, 73, -1, -1, -1, -1, -1, -1,
        79, 81, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1];
    constant [75] integer THUMB_SIGNED_SKIP = [
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 1, 0, 10, 11, 10, 11,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1];
    constant [75] integer THUMB_UNSIGNED_SKIP = [
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 1, 0, 2, 3, 2, 3,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1];
    constant integer N_ABS = 14;
    constant integer N_LEFT_TT = 15;
    constant integer C_CELL = 61;
    constant integer C_VAR = 62;
    constant integer C_AFTER = 63;
    constant integer C_FROM = 64;
    constant integer C_COUNT = 65;
    constant integer C_CASE = 66;
    constant integer C_IN = 67;
    constant integer C_ARRAY = 68;
    constant integer C_TO = 69;
    constant integer C_CLOCK_PLUS = 112;
    constant integer C_CLOCK_TIMES = 113;
    constant integer C_CLOCK_MINUS = 114;
    constant integer C_EQUAL_EQUAL = 115;
    constant integer C_LESS_LESS_EQUAL = 116;
    constant integer C_OPEN_COLON = 117;
    constant integer C_OPEN_SLASH_COLON = 118;
    constant integer C_BACKSLASHES = 119;
    constant integer C_BAR_STAR = 120;
    constant integer NAME_FANOUT = 128;
    constant [256] short PAIR_ROW = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 2, 3,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 5, 6, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 9, 0, 10, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    constant [256] short PAIR_COLUMN = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 0, 4, 5, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    constant integer PAIR_WIDTH = 10;
    constant [120] short PAIR_CODE = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 80, 0, 0, 0, 0,
        0, 89, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 86, 0, 0, 0, 0, 0, 0, 0, 0, 83, 84,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 87, 0, 0, 0, 0, 0, 0, 0, 0, 0, 115, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 88, 0, 0, 0, 0, 0, 0, 0, 0, 117, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 119, 0, 0, 0, 113, 112, 114, 0, 0, 85, 0, 0, 0, 81, 120, 0, 0, 0, 0, 0, 0, 0];
    constant [256] short TRIPLE_SECOND = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 45, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 60, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 47, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    constant [256] short TRIPLE_THIRD = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 62, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 61, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 58, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    constant [256] short TRIPLE_CODE = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 82, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 116, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 118, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    constant [256] short ESCAPE_VALUE = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 34, 0, 0, 37, 0, 39, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 63, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 92, 0, 0, 0,
        0, 7, 8, 0, 0, 0, 12, 0, 0, 0, 0, 0, 0, 0, 10, 0, 0, 0, 13, 0, 9, 0, 11, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    constant [256] short HEX_DIGIT = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 0, 0, 0, 0, 0, 0, 0, 11, 12, 13, 14, 15, 16, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 11, 12, 13, 14, 15, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    constant integer T_ESCAPE = 158;
    constant integer T_ESCAPE_RANGE = 159;
    constant integer T_PRAGMA_TOP_ONLY = 139;
    constant integer T_HIDES_OUTPUT = 160;
    constant integer T_MODEL_IN_INNER_WHERE = 161;
    constant integer P_PRAGMA_OTHER = 53;
    constant integer P_PRAGMA_SKIP = 54;
    constant integer P_PRAGMA_TEXT = 55;
    constant integer P_SET_NAME = 56;
    constant integer P_SET_SEPARATOR = 57;
    constant integer P_SET_EMIT = 58;
    constant integer P_ALIAS_END = 59;
    constant integer P_HIDE_NAME = 60;
    constant integer P_HIDE_SEPARATOR = 61;
    constant integer PHASE_HIDE = 4;
    constant integer T_INIT_UNUSED = 162;
    constant integer P_DECLARE_INIT = 62;
    constant integer INIT_NAME = 3;
    constant integer PHASE_INITS = 5;
    constant integer OP_CLOCK_PLUS = 48;
    constant integer OP_CLOCK_TIMES = 49;
    constant integer OP_OPEN_COLON = 50;
    constant integer OP_OPEN_SLASH_COLON = 51;
    constant integer OP_LEFT_TT = 52;
    constant [75] short OP_BRACKETED = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0];
    constant [75] short OP_POST_START = [
        11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
        11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
        11, 13, 15, 16, 18, 20, 27, 34, 34, 34, 45, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52,
        52, 57, 60];
    constant [75] short OP_POST_LENGTH = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        2, 2, 1, 2, 2, 7, 7, 0, 0, 11, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        5, 3, 6];
    constant integer OP_CLOCK_MINUS = 53;
    constant integer OP_ABS = 54;
    constant integer OP_OPERAND = 55;
    constant integer OP_ZERO = 56;
    constant integer OP_RECOVER = 57;
    constant integer OP_RECOVER_SQUARE = 58;
    constant integer OP_INDEX_OPERAND = 59;
    constant integer OP_SIZE = 60;
    constant integer OP_SIZE_LESS = 61;
    constant [75] short OP_PRE_START = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 1, 2, 2, 2, 2, 3, 3, 3, 3, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
        11, 11, 11];
    constant [75] short OP_PRE_LENGTH = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        1, 1, 0, 0, 0, 1, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0];
    constant [66] short STAGE_OP = [
        10, 10, 10, 59, 56, 23, 59, 61, 21, 17, 14, 10, 13, 10, 14, 9, 8, 9, 14, 13, 10, 14, 8, 55,
        10, 13, 9, 56, 20, 55, 7, 55, 12, 11, 69, 18, 59, 56, 23, 17, 69, 69, 12, 11, 13, 60, 28, 60,
        24, 60, 28, 6, 56, 69, 68, 25, 33, 56, 69, 33, 70, 5, 71, 55, 32, 31];
    constant integer T_RECOVERY_ACCESS = 38;
    constant integer INIT_SIZE = 4;
    constant integer T_ABS_SIGNED = 39;
    constant integer P_TUPLE_NAME = 63;
    constant integer P_TUPLE_SEPARATOR = 64;
    constant integer T_CASE_VALUE = 40;
    constant integer T_CASE_DUPLICATE = 41;
    constant integer P_CASE_IN = 65;
    constant integer P_CASE_BRANCH = 66;
    constant integer P_CASE_COPY = 67;
    constant integer P_CASE_LITERAL = 68;
    constant integer P_CASE_SCAN = 69;
    constant integer P_CASE_ELSE_VALUE = 70;
    constant integer P_CASE_COMPARE = 71;
    constant integer P_CASE_JOIN = 72;
    constant integer P_CASE_SEPARATOR = 73;
    constant integer P_CASE_WHEN = 74;
    constant integer P_CASE_GUARD = 75;
    constant integer FRAME_CASE = 4;
    constant integer P_STATE_SIGNAL = 76;
    constant integer P_STATE_CALL = 77;
    constant integer P_STATE_WHEN = 78;
    constant integer P_STATE_GUARD = 79;
    constant integer T_CLASS_NEEDS_OUTPUT = 42;
    constant integer T_FUNCTION_MEMORY = 43;
    constant integer T_FUNCTION_CALL = 44;
    constant integer P_SYNC = 80;
    constant integer OP_CELL = 62;
    constant integer OP_VAR = 63;
    constant integer OP_AFTER = 64;
    constant integer OP_FROM = 65;
    constant [75] short OP_TEMPLATE_KIND = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 1, 1, 1, 0, 0, 0, 0, 0,
        0, 0, 0];
    constant [75] short OP_TEMPLATE_SKIPS_LEFT = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0,
        0, 0, 0];
    constant [75] short OP_TEMPLATE_INLINE_START = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 15, 36, 90, 150, 169, 169, 169, 169, 169,
        169, 169, 169];
    constant [75] short OP_TEMPLATE_INLINE_LENGTH = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 4, 7, 7, 9, 0, 0, 0, 0, 0,
        0, 0, 0];
    constant [75] short OP_TEMPLATE_REST_START = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 19, 43, 97, 159, 169, 169, 169, 169, 169,
        169, 169, 169];
    constant integer TPK_EMIT = 0;
    constant integer TPK_LEFT = 1;
    constant integer TPK_RIGHT = 2;
    constant integer TPK_DEFINE = 3;
    constant integer TPK_GROUP = 4;
    constant integer TPK_END = 5;
    constant integer TPV_LITERAL = 0;
    constant integer TPV_INIT = 1;
    constant integer TPV_INIT_DECL = 2;
    constant integer TPV_BOUND = 3;
    constant integer TPR_TARGET = -2;
    constant integer TPR_OPERAND = -3;
    constant integer TPR_BOUND = -4;
    constant integer N_FRESH_FIRST = 69;
    constant integer N_FRESH_LAST = 84;
    constant integer T_WHOLE_DEFINITION = 45;
    constant integer T_VAR_NAME = 46;
    constant integer T_VAR_CONTEXT = 47;
    constant integer T_TEMPLATE_GUARDED = 48;
    constant integer T_CONSTANT_BOUND = 49;
    constant integer X_INIT = 20;
    constant [169] short TEMPLATE_ROW_KIND = [
        0, 0, 0, 0, 3, 1, 0, 2, 0, 0, 3, 0, 0, 4, 5, 0, 0, 0, 0, 0, 0, 0, 3, 0,
        0, 3, 0, 0, 0, 0, 0, 3, 0, 0, 4, 5, 0, 0, 0, 0, 0, 0, 0, 1, 0, 3, 2, 0,
        3, 0, 0, 0, 3, 0, 0, 0, 0, 0, 3, 0, 0, 3, 0, 0, 0, 3, 0, 0, 3, 0, 0, 0,
        0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 4, 0, 0, 4, 5, 0, 0, 0, 0, 0, 0,
        0, 1, 0, 3, 2, 0, 3, 0, 0, 0, 3, 0, 0, 0, 0, 0, 3, 0, 0, 3, 0, 0, 0, 3,
        0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 3, 0,
        0, 4, 0, 0, 4, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 1, 0, 3, 0, 0, 4,
        5];
    constant [169] short TEMPLATE_ROW_OP = [
        1, 13, 1, 4, -1, -1, 10, -1, 9, 13, -1, 1, 1, -1, -1, 1, 1, 10, 14, 1, 1, 13, -1, 1,
        4, -1, 1, 10, 1, 10, 13, -1, 1, 1, -1, -1, 1, 1, 14, 0, 1, 14, 13, -1, 10, -1, -1, 10,
        -1, 1, 1, 13, -1, 0, 1, 14, 1, 13, -1, 1, 4, -1, 1, 1, 13, -1, 1, 4, -1, 0, 1, 14,
        1, 13, -1, 1, 0, 24, 1, 14, 1, 14, -1, 1, 1, -1, 1, 1, -1, -1, 1, 1, 14, 0, 1, 14,
        13, -1, 10, -1, -1, 10, -1, 1, 1, 13, -1, 0, 1, 14, 1, 13, -1, 1, 4, -1, 1, 1, 13, -1,
        1, 4, -1, 0, 1, 14, 1, 14, 0, 1, 14, 13, 1, 13, -1, 1, 0, 24, 1, 14, 1, 14, -1, 1,
        1, -1, 1, 1, -1, -1, 0, 1, 0, 23, 14, 1, 0, 24, 13, 1, 4, -1, -1, 10, -1, 1, 1, -1,
        -1];
    constant [169] integer TEMPLATE_ROW_NAME = [
        70, -1, -2, -1, 70, -1, -1, -1, -1, -1, 69, -2, 69, -1, -1, 72, -2, -1, -1, -3, 73, -1, 72, 72,
        -1, 73, -3, -1, -2, -1, -1, 71, 72, 71, -1, -1, 81, 74, -1, -1, 74, -1, -1, -1, -1, 74, -1, -1,
        75, 74, 75, -1, 76, -1, 75, -1, 78, -1, 77, 77, -1, 78, 81, 80, -1, 79, 79, -1, 80, -1, 75, -1,
        82, -1, 81, 80, -1, -1, 78, -1, 74, -1, 82, 77, 76, -1, 79, 76, -1, -1, 81, 74, -1, -1, 74, -1,
        -1, -1, -1, 74, -1, -1, 75, 74, 75, -1, 76, -1, 75, -1, 78, -1, 77, 77, -1, 78, 81, 80, -1, 79,
        79, -1, 80, -1, 75, -1, 74, -1, -1, 75, -1, -1, 82, -1, 81, 80, -1, -1, 78, -1, 74, -1, 82, 77,
        76, -1, 79, 76, -1, -1, -1, 83, -1, -1, -1, 83, -1, -1, -1, -2, -1, 83, -1, -1, 74, -2, 74, -1,
        -1];
    constant [169] integer TEMPLATE_ROW_VALUE = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0];
    constant [169] short TEMPLATE_ROW_REF = [
        0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0,
        0];
    constant [169] integer TEMPLATE_ROW_TYPE = [
        -1, -1, -1, -1, -2, -1, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -3, -1,
        -1, -3, -1, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, -1, 2, -1, -1, -1, -1, -1, 0, -1, -1,
        0, -1, -1, -1, 0, 1, -1, -1, -1, -1, 1, -1, 1, 1, -1, -1, -1, -2, -1, 2, -2, 2, -1, -1,
        -1, -1, -2, -1, 2, -1, -1, -1, -1, -1, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 2, -1, -1,
        -1, -1, -1, 0, -1, -1, 0, -1, -1, -1, 0, 1, -1, -1, -1, -1, 1, -1, 1, 1, -1, -1, -1, -2,
        -1, 2, -2, 2, -1, -1, -1, -1, 2, -1, -1, -1, -1, -1, -2, -1, 2, -1, -1, -1, -1, -1, -2, -1,
        -1, -1, -1, -1, -1, -1, 2, -1, -4, -1, -1, -1, 2, -1, -1, -1, -4, -2, -1, -1, 0, -1, -1, -1,
        -1];
    constant integer OP_COUNT = 66;
    constant integer N_REPEAT_MARK = 84;
    constant integer OP_REPEAT = 67;
    constant integer OP_ONE = 68;
    constant integer OP_RIGHT_OPERAND = 69;
    constant integer OP_TARGET_SIGNAL = 70;
    constant integer OP_INDEX_SIGNAL = 71;
    constant integer OP_REPEAT_RANGE = 72;
    constant integer OP_ARRAY_RANGE = 73;
    constant integer OP_REPEAT_BODY = 74;
    constant integer P_REPEAT_START = 81;
    constant integer P_INDEX_EMIT = 82;
    constant integer P_REPEAT_EMIT = 83;
    constant integer P_ARRAY_TO = 84;
    constant integer P_INDEX_TYPE = 85;
    constant integer P_INDEX_DECLARE = 86;
    constant integer T_REPEAT_TYPE = 163;
    constant integer T_COUNTER_EVENT = 164;
    constant integer T_REPEAT_SIZE = 165;
    constant integer T_RANGE_FIT = 166;
    type ARGS = external;
    type OS = external;
    type FILE = external;
    type OUTPUT = external;
    type CODE_OUT0 = external;
    type CODE_OUT1 = external;
    type CODE_OUT2 = external;
    type CODE_OUT3 = external;
    type IMAGE = external;
    type SIGNATURE = external;
    type STAGE = external;
    type NAMES = external;
    type RESERVE = external;
    integer ARGC, PATH_LENGTH, ERRNO, LENGTH, CLASS, PREVIOUS_MODE, SYMBOL_LENGTH, OPENED_KIND, REMAINING, MODE, COLUMN,
      CODE_POINTS, LINE_START, LINE, OPEN_AT, OPEN_LINE, OPEN_COLUMN, OPEN_KIND, PENDING, LETTER, FINISHED_LENGTH,
      FINISHED_SLOT, OPENED_SLOT, TOKEN_COUNT, FOUND, LEX_ERROR, LEX_ERROR_LINE, LEX_ERROR_COLUMN, LEX_ERROR_AT,
      SEQUENCE, SEQUENCE_DIGITS, SEQUENCE_VALUE, STRING_BASE, STRING_AT, STRING_FILL, ESCAPE_AT, ESCAPE_LINE, ESCAPE_COLUMN,
      LEX_ERROR_VALUE,
      ERROR, ERROR_CHARACTER_LENGTH, MESSAGE, MESSAGE_LINE, MESSAGE_COLUMN, MESSAGE_ARGUMENT0, MESSAGE_ARGUMENT1,
      MESSAGE_ARGUMENT2, LAYOUT, ITEM_COUNT, SECTION, TOKEN, KIND, ROW, SLOT, ARGUMENT, PIECE, ARGUMENT_KIND,
      ARGUMENT_VALUE, SLICED_TOKEN, ROW_NUMBER_KIND, PREFIX, SLICE_START, SLICE_LENGTH, INFIX, SUFFIX, DIGITS,
      ARGUMENT_CLOCK_START, ARGUMENT_CLOCK_LENGTH,
      ITEM_LENGTH, WRITE_SLOT, ITEM_POSITION, TOTAL, OUTPUT_LENGTH, CURRENT, OFFSET, SEPARATOR_END, PREFIX_END, SLICE_END, INFIX_END,
      SIGN_END, DIGITS_END, SUFFIX_END, SLICE_AT, STATUS, SOURCE_AT, CURSOR, CURSOR_START, CURSOR_LENGTH, CURSOR_KIND,
      TRIE_PARENT, TRIE_SLOT, TRIE_EXISTING, TRIE_NODE, TRIE_NODE_COUNT, NAME_BEGIN, KNOWN_NAME, NAME_ID, NAME_COUNT,
      SYMBOL_CODE, CODE_VALUE, CODE_SLOT, VALUE_SLOT, INTERN_ERROR_TOKEN, SCAN_CODE, SCAN_NAME, SCAN_PREVIOUS,
      SCAN_MESSAGE, SCAN_ARGUMENT0, SCAN_ARGUMENT1, SCAN_STATE, SCAN_TYPE_NAME, SCAN_TYPE_KIND, SCAN_VALUE_START,
      VALUE_COUNT, USER_TYPE_SLOT, USER_TYPE_COUNT, PRESCAN_MESSAGE, PRESCAN_TOKEN, PRESCAN_ARGUMENT0, PRESCAN_ARGUMENT1,
      MESSAGE_TOKEN, NAME_BASE, NAME_SUFFIX, SLICED_NAME;
    pointer ARGV, ARG1, ARG2, ARG3, SOURCE_BASE, OUTPUT_BASE;
    boolean ARGUMENT_COUNT_OK, DASH_MATCHES, USAGE_OK, PATH_ENDED, OPEN_OK, READ_OK, SIZE_OK, SOURCE_FITS, OUTPUT_FITS, MAP_WANTED,
      MAP_OK, SOURCE_OK, AT_EOF, AT_END, CONTINUES, STARTS, OPENS_TOKEN, ENDS_LINE, NOT_ALL_LETTERS, HAS_LOWER,
      HAS_UPPER, IS_KEYWORD, UNCLOSED, UNEXPECTED, FIRST_FOUND, IN_TEXT, ESCAPED, IN_STRING, STRING_CLOSES, OCTAL, EXTENDS,
      SEQUENCE_CLOSES, AFTER_BACKSLASH, OPENS_SEQUENCE, SIMPLE_ESCAPE, PLAIN_BYTE, STRING_WRITES, ESCAPE_UNKNOWN, ESCAPE_TOO_BIG,
      IN_ESCAPE, SOURCE_TOO_BIG, ERROR_MULTIBYTE, ERROR_FIRST_CONTINUES,
      ERROR_SECOND_CONTINUES, ERROR_THIRD_CONTINUES, DUMPS_TOKENS, IS_HEADER, IS_PIECE, IS_ARGUMENT, IS_ROW, FIRST_HALF,
      ARGUMENT_EOF, QUOTES_TOKEN, SLICES_LITERAL, SLICES_TOKEN, SLICES_CHARACTER, SLICES_CLOCK, HAS_NUMBER, SLICE_PATH, FOLDS,
      NEWLINE, SEPARATES, NEGATIVE, DUMPING, WRITES, OUTPUT_FAILED, LEXED, IN_SEED, CURSOR_ENDED, IN_TOKEN, TOKEN_BEGINS,
      TOKEN_ENDS, NAMEISH, NAME_BEGINS, NAME_ENDS, TRIE_SKIPS, TRIE_CREATES, NEW_NAME, TOO_BIG, INTERN_OVERFLOWS, INTERNED,
      SCAN_IS_NAME, SCAN_CLASHES, SCAN_DUPLICATE, SCAN_FULL, SCAN_FAILS, SCAN_APPENDS_VALUE, SCAN_REGISTERS,
      FIRST_SCAN_FAILURE, SLICES_NAME;
    ubyte DASH_BYTE, PATH_BYTE, SOURCE_BYTE, BYTE, NEXT_BYTE, ERROR_LEAD, SLICE_BYTE, OUTPUT_BYTE, OUTPUT_ITEM_BYTE, NAME_BYTE, FOLDED_BYTE;
    ulong KEY, MAGNITUDE, DIGIT, DIGIT_VALUE, ACCUMULATED;
    long BUFFER_ADDRESS, SOURCE_FD, PROBE, SIZE, MAPPED, SOURCE_CLOSED, OUTPUT_FILE, OUTPUT_FD, WRITTEN, OUTPUT_CLOSED,
      EXIT, NUMBER;
    [3] integer DASH_INDEX;
    [ARG_CAP] integer PATH_INDEX;
    [ARG_CAP] ubyte PATH_TEXT;
    [SRC_CAP] integer COPY_INDEX, LEX_INDEX, INTERN_INDEX;
    [SRC_CAP] ubyte SRC;
    [SRC_CAP] ubyte STRING_TEXT;
    [TOKEN_CAP] ubyte TOKEN_KIND;
    [TOKEN_CAP] ubyte TOKEN_CODE;
    [TOKEN_CAP] integer TOKEN_LENGTH, TOKEN_START, TOKEN_TEXT, TOKEN_LINE, TOKEN_COLUMN, TOKEN_NAME, PRESCAN_INDEX;
    [TOKEN_CAP] long TOKEN_VALUE;
    [TOKEN_CAP] boolean TOKEN_BIG, VALUE_BRACE;
    [TRIE_CAP] integer TRIE_CHILD;
    [TRIE_NODE_CAP] integer TRIE_NAME;
    [NAME_CAP] integer NAME_AT, NAME_LENGTH, NAME_TYPE, VALUE_STAMP;
    [TYPE_CAP] integer USER_TYPE_NAME, USER_TYPE_KIND, USER_TYPE_VALUE_START, USER_TYPE_VALUE_COUNT;
    [VALUE_CAP] integer VALUE_NAME;
    [ITEM_CAP] integer ITEM_INDEX, ITEM_PREFIX, ITEM_SLICE_START, ITEM_SLICE_LENGTH, ITEM_INFIX, ITEM_DIGITS, ITEM_SUFFIX,
      ITEM_END;
    [ITEM_CAP] boolean ITEM_SEPARATES, ITEM_FROM_PATH, ITEM_FROM_CLOCK, ITEM_FOLDS, ITEM_NEGATIVE, ITEM_NEWLINE;
    [ITEM_CAP] ulong ITEM_MAGNITUDE;
    [OUTPUT_CAP] integer OUTPUT_INDEX;
    [STACK_CAP] integer FRAME_KIND, FRAME_VALUE, PENDING_OP, PENDING_PRECEDENCE, PENDING_TOKEN, PENDING_COUNT,
      PENDING_PARAMETERS, PENDING_PARAMETER_COUNT, PENDING_SPLIT, PENDING_OPENER_BELOW, PENDING_RIGHT_START, PENDING_LEFT_END,
      PENDING_INDEX_START, PENDING_INDEX_END, FRAME_CASE_START, FRAME_CASE_END, FRAME_CASE_LAST;
    [PATH_CAP] integer PATH_VALUE;
    [ENTRY_CAP] integer ENTRY_OP, ENTRY_TOKEN, ENTRY_NAME, ENTRY_TYPE, ENTRY_AUX, ENTRY_AUX2, ENTRY_SPLIT, CASE_VALUE_ENTRY,
      CASE_VALUE_PREV;
    [TYPE_CAP] integer TYPE_KIND, TYPE_BYTES, TYPE_NAME, TYPE_VALUE_START, TYPE_VALUE_COUNT, TYPE_ELEMENT, ARRAY_NEXT;
    [BUCKET_CAP] integer ARRAY_HEAD;
    [MODEL_CAP] integer MODEL_NAME, MODEL_KIND, MODEL_PARENT, MODEL_TOKEN, MODEL_SIGNAL_START, MODEL_LABEL_START,
      MODEL_INPUTS, MODEL_EQUATION_START, MODEL_EQUATION_END, MODEL_GROUP_START, MODEL_GROUP_END,
      MODEL_DEPENDENCE_START, MODEL_DEPENDENCE_END, MODEL_GUARD_START, MODEL_GUARD_END, MODEL_USE_START,
      MODEL_USE_END, MODEL_MEMBER_START, MODEL_MEMBER_END, MODEL_INTRINSICS, MODEL_STATEMENTS, MODEL_CLOSE_SIGNALS,
      MODEL_CLOSE_EQUATIONS, MODEL_CLOSE_GROUPS, MODEL_CLOSE_LABELS, MODEL_STATE_TYPE, CLOSE_ORDER,
      MODEL_FIRST_SIGNAL, MODEL_LAST_SIGNAL, MODEL_FIRST_LABEL, MODEL_LAST_LABEL, MODEL_HIDE_START, MODEL_HIDE_END;
    [NAME_CAP] integer LOCAL_HEAD, NAME_CONSTANT, NAME_ALIAS;
    [SIGNAL_CAP] integer HIDE_NAME, HIDE_TOKEN, SIGNAL_INIT_KIND, SIGNAL_INIT_TYPE, SIGNAL_INIT_NAME, SIGNAL_INIT_TOKEN;
    [SIGNAL_CAP] long SIGNAL_INIT_VALUE;
    [LOCAL_CAP] integer LOCAL_MODEL, LOCAL_PREVIOUS;
    [SIGNAL_CAP] integer SIGNAL_NAME, SIGNAL_ROLE, SIGNAL_TYPE, SIGNAL_MODEL, SIGNAL_TOKEN, SIGNAL_NEXT;
    [LABEL_CAP] integer LABEL_NAME, LABEL_MODEL, LABEL_NEXT, USE_MODEL, USE_NAME, USE_TOKEN, USE_PARENT,
      USE_PATH_START, USE_PATH_LENGTH;
    [CONSTANT_CAP] integer CONSTANT_NAME, CONSTANT_TYPE;
    [TABLE_CAP] integer TABLE_TYPE, TABLE_START, TABLE_LENGTH;
    [GUARD_CAP] integer GUARD_MODEL, GUARD_ENTRY_START, GUARD_ENTRY_COUNT, GUARD_TOKEN, GUARD_CONTEXT, GUARD_LABELS,
      GUARD_PATH_START, GUARD_PATH_LENGTH, GUARD_EQUATION_FIRST, GUARD_GROUP_FIRST, GUARD_DEPENDENCE_FIRST, GUARD_END,
      GUARD_EQUATION_LAST, GUARD_GROUP_LAST, GUARD_DEPENDENCE_LAST;
    [LOOP_CAP] integer LOOP_NAME, LOOP_TOKEN, LOOP_MODEL, INDEX_ID_NAME, INDEX_ID_BOUND, INDEX_ID_BOUND_END, INDEX_ID_TOKEN,
      INDEX_ID_OP_TOKEN, INDEX_ID_MODEL, INDEX_ID_TYPE, INDEX_STACK;
    [LOOP_CAP] boolean INDEX_ID_ARRAY;
    integer INDEX_TOP, DRAIN_ID, LOOKUP_KEY, DRAIN_BOUND, DRAIN_BOUND_OP, DRAIN_CONSTANT, DRAIN_TYPE, DRAIN_BUCKET,
      INDEX_DECLARE_MESSAGE, ELEMENT_TYPE, INDEX_BOUND_AT, INDEX_BOUND_END, REPEAT_SEEN, REPEAT_FIRST_TOKEN, INDEX_RETURN,
      INDEX_NAME, INDEX_TOKEN, REPEAT_E_START, REPEAT_LOOP, INDEX_SLOT, INDEX_DEPTH, INDEX_TOTAL;
    long DRAIN_VALUE;
    ulong DRAIN_SIZE;
    boolean DRAIN_ARRAY, DECLARES_INDEX, DRAIN_DUE, REPEAT_DUE, DRAIN_OK, APPENDS_INDEX_SIGNAL, REPEAT_WHOLE, REPEAT_MISPLACED,
      INDEX_STAGING, INDEX_FRESH, EMITS_ONE, EMITS_NAMED, COUNTS_REPEAT, INDEX_IS_ARRAY, INDEX_EQUATION, INDEX_DECLARES,
      IN_REPEAT_START, IN_INDEX_EMIT, IN_REPEAT_EMIT, IN_ARRAY_TO, IN_INDEX_TYPE, IN_INDEX_DECLARE;
    [EQUATION_CAP] integer EQUATION_TARGET, EQUATION_ENTRY_START, EQUATION_ENTRY_COUNT, EQUATION_POSITION,
      EQUATION_LOOP, EQUATION_MODEL, EQUATION_LABELS, EQUATION_GUARDS;
    [MEMBER_CAP] integer MEMBER_ENTRY_START, MEMBER_ENTRY_COUNT;
    [GROUP_CAP] integer GROUP_POSITION, GROUP_MODEL, GROUP_GUARDS, GROUP_MEMBER_FIRST, GROUP_MEMBER_TOTAL;
    [DEPENDENCE_CAP] integer DEPENDENCE_FROM_NAME, DEPENDENCE_FROM_TOKEN, DEPENDENCE_TO_NAME, DEPENDENCE_TO_TOKEN,
      DEPENDENCE_POSITION, DEPENDENCE_MODEL, DEPENDENCE_GUARDS;
    [PARSE_CAP] integer PARSE_INDEX;
    [TYPE_CAP] boolean TYPE_SIGNED, TYPE_STATE;
    [TYPE_CAP] ulong TYPE_SIZE;
    [MODEL_CAP] boolean MODEL_CLOSED;
    [NAME_CAP] boolean NAME_MODEL, NAME_SIGNAL_EVER, NAME_LABEL_EVER;
    [TABLE_CAP] boolean TABLE_FROM_STRING;
    [EQUATION_CAP] boolean EQUATION_SEED, EQUATION_STATEMENT;
    [CONSTANT_CAP] long CONSTANT_VALUE;
    [POOL_CAP] long POOL_VALUE;
    [ENTRY_CAP] long ENTRY_VALUE;
    integer HERE, STATE_BEFORE, CODE0, CODE1, CODE2, CODE3, NAME0, NAME1, NAME2, MODEL_NOW, LOCAL_TOP, LOCAL_TOP_MODEL,
      STATE, CLASH_MESSAGE, TOKEN_TYPE, COPIED_TYPE, COPIED_USER, MODEL_KIND_NOW, PARENT_NOW, SIZE_CONSTANT,
      SIZE_CONSTANT_TYPE, SIZE_MESSAGE, INTERN_CANDIDATE, BUCKET_HERE, FINISHED_TYPE, DECLARED_TYPE, DECLARED_KIND,
      DECLARED_ELEMENT, DECLARED_BASE, DECLARE_MESSAGE, CONSTANT_NAME_MESSAGE, STRING_BYTES, DEFINITION_MESSAGE,
      SIGN_AT, NUMBER_AT, CONSTANT_LITERAL_TYPE, TARGET_BYTES, INTEGER_CONSTANT_MESSAGE, INTEGER_CONSTANT_TOKEN,
      VALUE_TYPE, SUBTYPE_TARGET, ELEMENT_COUNT, ELEMENT_MESSAGE, SCALAR_MESSAGE, FRAME_TOP, FRAME_TOP_KIND,
      FRAME_TOP_VALUE, PROCESS_MESSAGE, PATH_PARENT_START, PATH_PARENT_LENGTH, PATH_FROM, PATH_LEFT, PATH_APPEND,
      PATH_COUNT, FOLLOWER, EQUATION_MESSAGE, LAST_ENTRY, EQUATION_END_MESSAGE, DEPENDENCE_MESSAGE, POP_MESSAGE,
      PUSHED_FRAME_KIND, PUSHED_FRAME_VALUE, FRAME_DEPTH, PENDING_TOP, TOP_OP, TOP_PRECEDENCE, TOP_TOKEN, OPENER_NOW,
      OPENER_OP, MISSING_MESSAGE, LITERAL_AT, LITERAL_CODE, LITERAL_NEXT_CODE, LITERAL_VALUE_NAME_AT, LITERAL_MESSAGE,
      LITERAL_MESSAGE_TOKEN, LITERAL_TYPE, NAME_AT_LITERAL, LITERAL_END, OPERAND_CASE, OPERAND_MESSAGE, BINARY_HERE,
      OPERATOR_CASE, DELAY_MESSAGE, OPERATOR_FAIL_MESSAGE, OPERATOR_MESSAGE, PARAMETER_MESSAGE,
      PARAMETER_CLOSE_MESSAGE, PUSHED_OP, PUSHED_PRECEDENCE, PUSHED_TOKEN, PUSHED_COUNT, PUSHED_PARAMETERS,
      PUSHED_PARAMETER_COUNT, PENDING_SLOT, PUSHED_SPLIT, PENDING_DEPTH, OPENER_TOP, ENTRY_KIND, ENTRY_SLOT,
      ENTRY_COUNT, TEMPLATE_ENTRIES, INIT_LITERAL_BASE, INIT_MESSAGE, BODY_INTRINSICS, BODY_STATEMENTS, BODY_EQUATION_START, BODY_GROUP_START, BODY_DEPENDENCE_START,
      BODY_GUARD_START, BODY_USE_START, BODY_MEMBER_START, MODEL_MESSAGE, EXPECTED_CODE, TYPE_MESSAGE,
      SEPARATOR_MESSAGE, STATEMENT_MESSAGE, BODY_MESSAGE, FULL_TABLE, STEP_MESSAGE, STEP_TOKEN, STEP_ARGUMENT0,
      STEP_ARGUMENT1, STEP_ARGUMENT2, NEXT_AT, AT, NEXT_STATE, PARSE_STATE, RETURN_STATE, ROLE, PENDING_MODEL_KIND,
      ARRAY_BUCKET, CANDIDATE, ARRAY_ELEMENT, PARSED_TYPE, DECLARE_NAME, DECLARE_TOKEN, CONSTANT_RETURN,
      CONSTANT_VALUE_TYPE, LIST_COUNT, LIST_START, LOOP_NOW, LABEL_NODE, GUARD_NODE, GUARD_START_TOKEN,
      EXPRESSION_START, EXPRESSION_RETURN, TARGET, EQUATION_TOKEN, GROUP_MEMBER_START, CALL_HEAD,
      PARAMETER_START, PARAMETER_COUNT, CURRENT_MODEL, TYPE_SLOT, TYPE_COUNT, MODEL_SLOT, MODEL_COUNT, BODY_SLOT,
      CLOSE_SLOT, CLOSED_COUNT, LOCAL_SLOT, LOCAL_COUNT, SIGNAL_SLOT, SIGNAL_SLOT_MODEL, SIGNAL_COUNT, LABEL_SLOT,
      LABEL_COUNT, CONSTANT_SLOT, CONSTANT_COUNT, TABLE_SLOT, TABLE_COUNT, POOL_COUNT, USE_SLOT, USE_COUNT,
      GUARD_SLOT, GUARD_CLOSE_SLOT, GUARD_COUNT, GUARD_DEPTH_MAX, LOOP_SLOT, LOOP_COUNT, EQUATION_SLOT,
      EQUATION_COUNT, MEMBER_SLOT, MEMBER_COUNT, GROUP_SLOT, GROUP_COUNT, DEPENDENCE_SLOT, DEPENDENCE_COUNT,
      PARSE_MESSAGE, PARSE_TOKEN, PARSE_ARGUMENT0, PARSE_ARGUMENT1, PARSE_ARGUMENT2, BRACKET_COUNT, COLONS_COUNT,
      SET_NAMES, COPY_COUNT, SCAN_LAST_CODE, EMIT_FROM_TOKEN, EMIT_TO_TOKEN, SET_MESSAGE, HIDE_MESSAGE, BODY_HIDE_START, ALIAS_NAME,
      PRAGMA_ITEMS, SET_LEFT_START, SET_LEFT_COUNT, SET_RIGHT_START, SET_RIGHT_COUNT, EMIT_I, EMIT_J, HIDE_RETURN,
      HIDE_SLOT, HIDE_COUNT, HIDE_RANGE_SLOT, DECLARE_INIT_MESSAGE, INIT_SLOT, POST_KEY, STAGE_INDEX,
      TUPLE_SEPARATOR_MESSAGE, TUPLE_SEPARATOR_EXPECTED, TUPLE_NEXT, TUPLE_NAME_TOKEN, TUPLE_FIRST_NAME, TUPLE_END_MESSAGE,
      TUPLE_TOKEN, TUPLE_ARITY, TUPLE_INDEX, CASE_TOP_START, CASE_TOP_END, CASE_LAST_TOP, CASE_BRANCH_EXPECTED,
      CASE_BRANCH_MESSAGE, CASE_GUARD_MESSAGE, CASE_VALUE_MESSAGE, CASE_ITEM_NEXT, CASE_BRANCH_ITEMS, CASE_WALK, CASE_SCAN_AT,
      CASE_LITERAL_TOKEN, CASE_OP_TOKEN, CASE_VALUE_SLOT, CASE_VALUE_COUNT, CASE_FRAME_SLOT, CASE_DEPTH, SELECTOR_TOKENS,
      BRACE_COMMAS, CASE_VALUES, LAST_OPEN_BRACE, INTERFACE_NOW, SYNC_I,
      ARGUMENTS_FOUND, STAGE_ITEM, TOP_CALLEE, ARGUMENTS_EXPECTED, COPY_BASE, STAGE_BASE, COPY_END, COPY_FROM, COPY_I,
      COPY_OFFSET, STAGE_KIND, STAGE_KEY, STAGE_LENGTH, STAGE_START, RECOVER_ARRAY_AT, RECOVER_INDEX_START,
      RECOVER_INDEX_END, RECOVER_ARRAY, RECOVER_ARRAY_TOKEN, RECOVER_ARRAY_MESSAGE, PARSED_ENTRY_NAME, COPIED_SPLIT;
    boolean SET_OPENS, IN_SET_SCAN, EMIT_LAST_J, EMIT_LAST, HIDE_OPENS, INNER_WHERE_OPENS, APPENDS_HIDE, EMPTY_COMPOSITION,
      ALIAS_STATEMENT, INNER_WHERE, SET_STARTS, SET_FROM_NAME, SET_RIGHT_OPENS, SET_READING_RIGHT, SET_ARROWED,
      IN_PRAGMA_OTHER, IN_PRAGMA_SKIP, IN_PRAGMA_TEXT, IN_SET_NAME, IN_SET_SEPARATOR, IN_SET_EMIT, IN_ALIAS_END,
      IN_HIDE_NAME, IN_HIDE_SEPARATOR, IN_DECLARE_INIT, INIT_IS_NAME, DELAY_NAME_INIT, DECLARE_INITED,       LEFT_TT_FALSE, INTRINSIC_CALL, STAGING, COPYING, STAGE_ADVANCES, EMITS_ZERO, PRE_STAGING, COPIES_INDEX,
      STAGE_DONE, RECOVERED_CLOSE, RECOVER_LATCH, RECOVER_READY, EMITS_SIZE;
    boolean TYPE_ARGUMENT, ARGUMENT_TYPE_ARRAY, SLICES_TYPE_NAME, PRINTS_TYPE_SIZE;
    integer NAMED_TYPE, NAMED_TYPE_NAME;
    boolean PARSES, LOOKS_UP, STALE, DECLARED, GLOBALLY_USED, RESERVED, COPY_IS_BUILTIN, COPY_DONE, MODEL_NAME_OK,
      MODEL_NAME_CLASHES, CREATES_MODEL, CLOSES_MODEL, MAKES_STATE_TYPE, TYPE_STATEMENT_CLASHES, SIZE_IS_NUMBER,
      SIZE_IS_CONSTANT, SIZE_POSITIVE, INTERN_MATCHES, CREATES_ARRAY_TYPE, TYPE_FINISHED, DECLARED_ARRAY,
      APPENDS_SIGNAL, APPENDS_LABEL, PUSHES_LOCAL, DEFINITION_IS_STRING, CONVERTS, CONVERSION_OK, NEGATES, IS_SUBTYPE,
      STORES_STRING, STORES_LIST, STORES_SCALAR, STORES_CONSTANT, STORES_TABLE, APPENDS_POOL, IN_LOOP, LABEL_FOLLOWS,
      CREATES_USE, CREATES_GUARD, STARTS_PATH, STARTS_EXPRESSION, LAST_IS_CALL, MAKES_GROUP, CONTINUES_GROUP,
      APPENDS_EQUATION, APPENDS_MEMBER, APPENDS_GROUP, IS_STATEMENT, APPENDS_DEPENDENCE, POP_COMPOSE_BREAKS,
      POP_ITERATE_SEEDS, POPS_FRAME, PUSHES_FRAME, HAS_PENDING, TOP_IS_OPENER, TOP_REDUCIBLE, LITERAL_NEGATED,
      LITERAL_IS_NUMBER, LITERAL_IS_BOOLEAN, LITERAL_IS_TYPED_ENUM, LITERAL_IS_ENUM, LITERAL_IS, DELAY_HAS_INIT,
      CALL_HEAD_HERE, EMPTY_CALL, IS_TERMINATOR, REDUCES, CLOSES_OPENER, PUSHES_PENDING, UPDATES_PENDING,
      POPS_PENDING, PUSHED_OPENER, APPENDS_ENTRY, ENTRY_FROM_TOP, COUNTS_INTRINSIC, STARTS_BODY, FAILS, GO, LOOP_SEED,
      ENDS_BODY, MODEL_HAS_SIGNAL, MODEL_HAS_LABEL, FIRST_PARSE_FAILURE, PARSE_FAILED, PARSE_INCOMPLETE,
      IN_COPY_TYPES, IN_START, IN_MODEL_NAME, IN_MODEL_EQUAL, IN_MODEL_OPEN, IN_MODEL_QUESTION, IN_INPUTS,
      IN_MODEL_BANG, IN_OUTPUTS, IN_MODEL_CLOSE, IN_MODEL_BODY, IN_MODEL_AFTER, IN_PROGRAM, IN_END_SEMICOLON,
      IN_END_CHECK, IN_TYPE_STATEMENT, IN_TYPE_SKIP, IN_TYPE, IN_TYPE_SIZE, IN_TYPE_CLOSE, IN_TYPE_NAME,
      IN_TYPE_INTERN, IN_DECLARE_NAME, IN_DECLARE_SEPARATOR, IN_CONSTANT_NAME, IN_CONSTANT_EQUAL,
      IN_CONSTANT_DEFINITION, IN_INTEGER_CONSTANT, IN_CONSTANT_ELEMENT, IN_CONSTANT_SCALAR, IN_CONSTANT_SEPARATOR,
      IN_LABEL_NAME, IN_LABEL_SEPARATOR, IN_PROCESS, IN_PATH_COPY, IN_GUARD_COLONS, IN_ITERATE_NAME, IN_ITERATE_OF,
      IN_EQUATION, IN_DEPENDENCE, IN_EQUATION_END, IN_GROUP_MEMBER, IN_POP, IN_OPERAND, IN_PARAMETER,
      IN_PARAMETER_CLOSE, IN_OPERATOR, IN_BRANCH, IN_TUPLE_NAME, IN_TUPLE_SEPARATOR, TUPLE_OPENS, TUPLE_DEFINES,
      TUPLE_ACTIVE, TUPLE_EXTRA, TUPLE_CONTINUES, TUPLE_STARTS, TUPLE_NAMES_TARGET, IN_CASE_IN, IN_CASE_BRANCH, IN_CASE_COPY, IN_CASE_LITERAL, IN_CASE_SCAN, IN_CASE_ELSE_VALUE, IN_CASE_COMPARE, IN_CASE_JOIN, IN_CASE_SEPARATOR, IN_CASE_WHEN, IN_CASE_GUARD,
      CASE_AFTER_ELSE, CASE_BRANCH_STARTS, CASE_ENDS, CASE_OPENS, CASE_ELSE_BRANCH, CASE_COPYING, CASE_DUPLICATE, CASE_ITEM_DONE,
      CASE_ELSE_MARKS, IN_SELECTOR_SCAN, CLOSES_VALUES, IN_STATE_SIGNAL, IN_STATE_CALL, IN_STATE_WHEN, IN_STATE_GUARD, STATE_ACTION_OPENS,
      STATE_GUARDED, TEMPLATE_INIT, VAR_OPERAND_BAD, CARRIES_INIT, INIT_GIVEN, IN_SYNC, NEEDS_OUTPUT, IS_FUNCTION, BODY_CLOSING, SYNC_PENDING, SYNC_LAST, SYNC_DONE;
    long PARSE_BOUND, SIZE_VALUE, CONSTANT_LITERAL, SIGNED_LITERAL, MASKED, HALF_RANGE, WRAPPED, CONSTANT_VALUE_NOW,
      LITERAL_NUMBER, LITERAL_VALUE, CONSTANT_VALUE_HELD;
    ulong TARGET_MASK, ARRAY_SIZE, DECLARED_SIZE;
    [PRAGMA_CAP] integer PRAGMA_IRQ, PRAGMA_OBJECT, PRAGMA_TOKEN;
    [SIGNAL_CAP] integer SIGNAL_IRQ1;
    [PARSE_CAP] integer PC_INDEX;
    integer PC_PRAGMA, PC_SIGNAL, PC_STEP_MESSAGE, PRAGMA_MESSAGE, PRAGMA_MESSAGE_TOKEN, PRAGMA_ARGUMENT0;
    boolean PRAGMA_CHECKS, PC_NAMING, PC_TOP_INPUT, PC_MATCHES, PC_FOUND, PC_FIRST, PRAGMA_FAILED, PC_OUT_OF_RANGE,
      PRAGMAS_STARTED, MACHINE_OK, MACHINE_STATEMENT;
    integer PLATFORM, INTERRUPT_LOWEST, INTERRUPT_HIGHEST, PC_IRQ, MACHINE_AT, MACHINE_TOKEN;
    integer PRAGMA_KIND, PRAGMA_NAME_HELD, PRAGMA_TOKEN_HELD, INTERRUPT_HIGH, INTERRUPT_LOW, INTERRUPT_VALUE,
      PRAGMA_MESSAGE_HERE, PRAGMA_SLOT, PRAGMA_COUNT;
    boolean IN_PRAGMA_NAME, IN_PRAGMA_OPEN, IN_PRAGMA_OBJECT, IN_PRAGMA_CLOSE, IN_PRAGMA_STATEMENT, PRAGMAS_HERE,
      PRAGMAS_OPEN, PRAGMAS_CLOSE, PRAGMA_KNOWN, INTERRUPT_OK, PRAGMA_HAS_BOOT;
    ulong INTERRUPT_BIT, PRAGMA_USED;
    [FINAL_CAP] integer FINAL_OP, FINAL_NAME, FINAL_TOKEN, FINAL_TYPE, FINAL_AUX, FINAL_AUX2;
    [FINAL_CAP] long FINAL_VALUE;
    [FINAL_CAP] integer FINAL_MODEL;
    [EQUATION_CAP] integer EQUATION_FINAL_START, EQUATION_FINAL_END, TRANSITION_FINAL_START, TRANSITION_FINAL_END,
      TRANSITION_SOURCE, TRANSITION_TARGET, TRANSITION_TRIGGER_START, TRANSITION_TRIGGER_END, TRANSITION_GUARD,
      TRANSITION_TOKEN, FINISH_EQUATION_TARGET, FINISH_EQUATION_FINAL_START, FINISH_EQUATION_FINAL_END,
      FINISH_EQUATION_TOKEN, FINISH_EQUATION_MODEL, FINISH_EQUATION_LABELS, FINISH_EQUATION_GUARDS;
    [MEMBER_CAP] integer MEMBER_FINAL_START, MEMBER_FINAL_END;
    [GUARD_CAP] integer GUARD_FINAL_START, GUARD_FINAL_END, FILTER_ROW_START;
    [NAME_CAP] integer OWN_INIT, INIT_USED;
    [NAME_CAP] integer LABEL_STAMP, OWN_STAMP, OWN_TYPE, OWN_ROLE, STATE_STAMP, STATE_ORDINAL, DEFINED_STAMP, INPUT_STAMP;
    [SIGNAL_CAP] integer INPUT_LIST, FINISH_SIGNAL_NAME, FINISH_SIGNAL_TYPE, FINISH_SIGNAL_MODEL, FINISH_SIGNAL_TOKEN;
    [DEPENDENCE_CAP] integer DEPENDENCE_RENAMED_FROM, DEPENDENCE_RENAMED_TO;
    [GROUP_CAP] integer FINISH_GROUP_MODEL, FINISH_GROUP_FINAL;
    [PARSE_CAP] integer FINISH_INDEX;
    integer HIDE_KEY, HIDE_ROLE, HIDE_FINISH_MESSAGE, RW_TARGET, RW_DECL_ROW, RW_INIT_KIND, RW_INIT_CONSTANT, RW_INIT_TOKEN,
      RW_INIT_MESSAGE, RW_SIZE_CONSTANT, RW_SIZE_TYPE;
    long RW_SIZE, RW_SIZE_VALUE;
    boolean AT_HIDE, HIDES_DONE, AT_INITS, INITS_DONE, INIT_UNUSED_HERE, RW_IS_DELAY, RW_FILLS_DECL, RW_DECL_SITE, RW_INIT_NAMED, RW_IS_SIZE;
    integer PHASE, CLOSE_RANK, MODEL_HERE, MODEL_STAMP, WORK_ROW, STEP, STATE_TYPE_NOW, MODEL_AT, MODEL_KEY,
      GUARD_NOW, GUARD_SUFFIX, GUARD_AT, ST_START, ST_COUNT, ST_CALL, ST_NAME, ST_ARGUMENTS, ST_TOKEN, ST_EXPECTED,
      ST_STATE, ST_STATE_TOKEN, ST_ORDINAL, AUTOMATON_STATEMENT_MESSAGE, RW_ITEMS_END, RW_ITEM_START, RW_ITEM_COUNT,
      RW_REAL_END, RW_ENTRY, RW_EXTENSION, RW_OP, RW_NAME, RW_ARGUMENTS, RW_PREVIOUS_NAME, RW_MESSAGE, CLOCK_LAST_SUB,
      CUR_GUARD_NUMBER, CUR_TOKEN, CUR_LAST_SUB, GUARD_LAST_EQUATION, CHAIN_START_NOW, DEFINED_KEY, GUARD_FIRST_GROUP,
      GUARD_LAST_GROUP, READ_START, READ_END, READ_ENTRY, READ_KEY, RENAMED_KEY, FILTER_KEY, COPY_SOURCE, EMIT_OP,
      EMIT_NAME, EMIT_TOKEN, EMIT_TYPE, EMIT_AUX, EMIT_AUX2, FINAL_SLOT, FINAL_NAME_SLOT, FINAL_COUNT, ROW_KEY,
      ROW_TYPE, ROW_TOKEN, STEP_FINISH_MESSAGE, FINISH_STEP_TOKEN, FINISH_STEP_ARGUMENT0, FINISH_STEP_ARGUMENT1,
      FINISH_STEP_ARGUMENT2, FINISH_MESSAGE, FINISH_TOKEN, FINISH_ARGUMENT0, FINISH_ARGUMENT1, FINISH_ARGUMENT2,
      NEXT_PHASE, FINISH_PHASE, ENTRY_ROW, NEXT_ROW, FINISH_ROW, NEXT_SUB, FINISH_SUB, RW_AT, RW_LAST, RW_ITEM_FIRST,
      ITEM_BEGIN, ITEM_END_VALUE, ITEM_SLOT_EQUATION, ITEM_SLOT_MEMBER, ITEM_SLOT_GUARD, ITEM_SLOT_TRIGGER,
      ITEM_START_VALUE, OWN_SLOT, STATE_SLOT, STATE_COUNT, INITIAL_ORDINAL, TRANSITION_SOURCE_HELD, TRANSITION_FIRST,
      TRANSITION_SLOT, TRANSITION_COUNT, SYNTH_COUNT, GUARD_NUMBER, GUARD_STAMP, CHAIN_START, GUARD_INPUT_START,
      INPUT_COUNT, FINISH_SIGNAL_SLOT, FINISH_SIGNAL_COUNT, FINISH_EQUATION_SLOT, FINISH_EQUATION_COUNT,
      FINISH_GROUP_SLOT, FINISH_GROUP_COUNT, FINISH_MODEL_ORDINAL, REST_ROW, REST_KIND, TEMPLATE_AT_HELD, ITEM_LAST_ENTRY,
      TR_OP_KIND, CONSTRUCT, CONSTRUCT_SPLIT, CONSTRUCT_TOKEN, OPERAND_NAME, BOUND_OP, BOUND_CONSTANT, BOUND_TYPE,
      CONSTRUCT_MESSAGE, TEMPLATE_NOW, TEMPLATE_SAFE, VAR_MONO_MESSAGE, TEMPLATE_MESSAGE, NEXT_TEMPLATE_PC, TEMPLATE_PC,
      TEMPLATE_AT, SKIP_FROM, NEXT_ROW_KIND, COPY_RANGE_START, COPY_RANGE_END, TEMPLATE_ORDINAL, TR_ROW, TR_REF, TR_OP,
      TR_ROW_NAME, TR_NAME, TR_ROW_TYPE, TR_TYPE, SEGMENT_BEGIN;
    long BOUND_VALUE, TR_VALUE;
    boolean REST, REST_COPY, TR_INIT_ROW, WHOLE_HERE, SKIPPED, AT_CONSTRUCT, RW_LIVE, BOUND_OK, GUARDED_ITEM, NONMONO_HERE,
      ITEM_NONMONO, REST_DUE, ENTERS_REST, REST_ROW_DONE, REST_ENDS, MOVES_TO_COPY, TR_EMITTING, TEMPLATE_DEFINES,
      TEMPLATE_GROUPS;
    boolean ALL_CLOSED, AT_CLOCK, AT_CUR, AT_CUR_TAIL, AT_DEFINE_FINISH, AT_DEFINE_PARSE, AT_FILTER, AT_GROUP,
      AT_GUARD_START, AT_LABEL, AT_ON, AT_READ, AT_READ_DEPS, AT_REWRITE, AT_SIGNAL, AT_START, AT_STATE, AT_STATEMENT,
      AT_USE, AUTOMATON_NOW, CLOCK_DONE, CLOCK_ROWS, COPIES_FINAL, CUR_DONE, CUR_ROWS, DEFINES, DEFINE_FINISH_DONE,
      DEFINE_PARSE_DONE, DEPS_DONE, EMITS, FILTER_DONE, FILTER_ROWS, FINISHES, FINISH_FAILED, FINISH_FAILS,
      FINISH_INCOMPLETE, FIRST_FINISH_FAILURE, FULL, GOES, HAS_INITIAL, HAS_TRANSITIONS, IS_INPUT, ITEM_ENDS,
      LABELS_DONE, NEW_INPUT, ON_COPYING, ON_HEADER, ON_ROWS, PHASE_CHANGES, READS, READ_ENTRY_DONE, READ_HEADER,
      RECORDS_INITIAL, RECORDS_TRANSITION, REGISTERS_STATE, RW_EMITS, RW_ENTRY_DONE, RW_HEADER, RW_INTRINSIC,
      RW_IS_EXTENSION, RW_ITEM_DONE, RW_NEXT_IS_ISIN, RW_PHASE_DONE, SIGNALS_DONE, STARTS_GUARD, STATEMENTS_DONE,
      STATE_ROWS, ST_INITIAL, ST_IS_STATEMENT, ST_KNOWN, ST_SHAPE_OK, TRIGGER_GUARDED, USES_DONE, USE_UNDECLARED,
      WRITES_FINAL_NAME, WRITES_ROWS;
    long EMIT_VALUE, FINISH_BOUND;
    [PARSE_CAP] integer MERGE_INDEX, DUMP_INDEX;
    [SIGNAL_CAP] integer MERGED_SIGNAL;
    [EQUATION_CAP] integer MERGED_EQUATION;
    [GROUP_CAP] integer MERGED_GROUP;
    [MODEL_CAP] integer MODEL_LABEL_OFFSET, MODEL_LABEL_END;
    [LABEL_CAP] integer LABEL_ORDERED_NAME;
    [ITEM_CAP] integer DUMP_CLASS, DUMP_TAG;
    [ITEM_CAP] long DUMP_VALUE;
    [ITEM_CAP] boolean DUMP_SEPARATES;
    integer PASS_MESSAGE, PASS_ARGUMENT0, SIGNAL_RANK_NOW, SIGNAL_LIMIT, SIGNAL_RANK, DUMP_SIGNAL_COUNT, SIGNAL_PARSE_CURSOR,
      SIGNAL_FINISH_CURSOR, EQUATION_RANK_NOW, EQUATION_LIMIT, EQUATION_RANK, DUMP_EQUATION_COUNT,
      EQUATION_PARSE_CURSOR, EQUATION_FINISH_CURSOR, GROUP_RANK_NOW, GROUP_LIMIT, GROUP_RANK, DUMP_GROUP_COUNT,
      GROUP_PARSE_CURSOR, GROUP_FINISH_CURSOR, LABEL_WALK_MODEL_NOW, LABEL_WALK_AT, ORDERED_LABEL_COUNT,
      LABEL_WALK_NEXT, LABEL_WALK_MODEL, USE_DEPTH_MAX, TABLE_ELEMENT_TOTAL, PATH_DEPTH_MAX, WALK_COLUMN_NOW,
      WALK_ROW_NOW, WALK_REL, WALK_INNER, WALK_STEP, WALK_MEMBER_STEP, COL, SHAPE, LIST_KIND, COLUMN_ROWS, R,
      SIGNAL_SOURCE, SIGNAL_FINISH_ROW, EQUATION_SOURCE, EQUATION_FINISH_ROW, GROUP_SOURCE, GROUP_FINISH_ROW,
      WALK_ROW_KEY, ROW_FRAGMENT, WALK_ROW_TOKEN, ROW_SCALAR_LENGTH, PATH_NODE, PATH_FIRST, PATH_SIZE,
      ENTRY_RUN_START, ENTRY_RUN_END, RUN_START, RUN_LENGTH, LIST_AT, MEMBER_TOTAL, MEMBER_NOW,
      WALK_MEMBER_ENTRY_START, WALK_MEMBER_ENTRY_LENGTH, CONTENT_LENGTH, ENTRY_NOW, ENTRY_OP_NOW, ENTRY_AUX_NOW,
      ENTRY_TOKEN_NOW, ENTRY_TYPE_NOW, PARAMETER_TOTAL, PARAMETER_LENGTH, PROGRAM_EXTRA, PSEUDO_OP, ARG_TOTAL,
      PARAMETER_OFFSET, PROGRAM_STEP, ARG_ATOM, PARAMETER_INDEX, PARAMETER_PART, PARAMETER_TOKEN,
      PARAMETER_CLASS, PARAMETER_TAG, ARG_CLASS, ARG_TAG, SCALAR_ATOM, TYPE_SHOWN, SCALAR_CLASS, SCALAR_TAG,
      ITEM_CLASS_NOW, ITEM_TAG_NOW, FOLLOWING_ROW, WALK_COLUMN, WALK_ROW, WALK_POSITION, WALK_STEP_POSITION,
      WALK_MEMBER_POSITION, WALK_INNER_POSITION, DUMP_SLOT, DUMP_COUNT, PROGRAM_CLASS, PROGRAM_TAG, PROGRAM_KEY,
      PROGRAM_BASE, PROGRAM_SUFFIX;
    boolean DUMP_RUNS, SIGNAL_RANK_OPEN, TAKES_PARSE_SIGNAL, TAKES_FINISH_SIGNAL, TAKES_SIGNAL,
      EQUATION_RANK_OPEN, TAKES_PARSE_EQUATION, KEEPS_PARSE_EQUATION, TAKES_FINISH_EQUATION, KEEPS_EQUATION,
      GROUP_RANK_OPEN, TAKES_PARSE_GROUP, TAKES_FINISH_GROUP, TAKES_GROUP, LABEL_MODEL_OPEN, TAKES_LABEL,
      LABEL_WALK_STARTED, WALKING, AT_HEADER, SIGNAL_FINISHED, EQUATION_FINISHED, GROUP_FINISHED, ROW_UNSIGNED,
      ROW_IS_ARRAY, PATH_OF_USE, ENTRIES_OF_EQUATION, LIST_UNSIGNED, IN_GROUP, OPS_MODE, ARGS_MODE, AT_NEWLINE,
      IS_CALL_ENTRY, ENTRY_FINISHES, IN_PARAMETERS, PARAMETER_EDGE, BRACKET_OPENS, INNER_LAST, MEMBER_FINISHES,
      ELEMENT_FINISHES, ROW_ENDS, LEAVES_COLUMN, WALK_JOINS, DUMP_OVERFLOW, DUMPS_PROGRAM, PROGRAM_NAME,
      PROGRAM_NONE, PROGRAM_SUFFIXED, PROGRAM_NUMBERED, PROGRAM_UNSIGNED;
    long MERGE_BOUND, DUMP_ROW_TOTAL, DUMP_BOUND, ROW_NUMBER_VALUE, LIST_VALUE, ENTRY_VALUE_NOW,
      PARAMETER_VALUE, ARG_VALUE, SCALAR_VALUE, ITEM_VALUE_NOW, PROGRAM_VALUE;
    constant integer INSTANCE_CAP = 262144;
    constant integer FLAT_PATH_CAP = 4194304;
    [MODEL_CAP] integer MODEL_SIGNAL_TOTAL, MODEL_LABEL_TOTAL, MODEL_ENTRY_TOTAL, MODEL_CALL_TOTAL, LEVEL_NEXT, LEVEL_NOW;
    [FINAL_CAP] integer SITE_CALLER, SITE_NAME;
    [PARSE_CAP] integer RELAX_INDEX;
    integer SPAN_SIGNAL_SLOT, SPAN_LABEL_MODEL, SPAN_LABEL_SLOT, SPAN_ENTRY_MODEL, SPAN_ENTRY_SLOT, SITE_SLOT, SITE_COUNT,
      USE_PATH_LIMIT, GUARD_PATH_LIMIT, PATH_LIMIT, RELAX_ROUND_LENGTH, RELAX_POSITION, RELAX_DEPTH, RELAX_CALLER,
      RELAX_CALLEE, CALLER_LEVEL, LEVEL_SUM, RELAX_M, LEVEL_SLOT, MODEL_LEVEL, MODEL_ROW_COUNT, RELAX_AT, RELAX_ROUND;
    boolean SPAN_CALLS, RELAX_SITE_PHASE, RELAX_ENDS_ROUND;
    long RELAX_BOUND, RELAX_CALL_COST, MODEL_STEP_COST, WORK_BOUND;
    [MODEL_CAP] integer MODEL_INPUT_TOTAL, MODEL_OUTPUT_TOTAL, MODEL_FINISH_SIGNAL_START, MODEL_FINISH_SIGNAL_END,
      MODEL_FINISH_EQUATION_START, MODEL_FINISH_EQUATION_END, MODEL_FINISH_GROUP_START, MODEL_FINISH_GROUP_END,
      MODEL_LOOP_START, MODEL_LOOP_END, MODEL_INSTANCE_TALLY;
    [NAME_CAP] integer MODEL_OF_NAME, OWNED_MARK, LABELED_MARK;
    [INSTANCE_CAP] integer INSTANCE_MODEL, INSTANCE_PARENT, INSTANCE_ORDINAL, INSTANCE_PURE, INSTANCE_LABEL_START,
      INSTANCE_LABEL_LENGTH, INSTANCE_GUARD_START, INSTANCE_GUARD_LENGTH;
    [SIGNAL_CAP] integer FLAT_SIGNAL_SOURCE, FLAT_SIGNAL_INSTANCE;
    [LABEL_CAP] integer FLAT_LABEL_KEY, FLAT_LABEL_INSTANCE;
    [LABEL_CAP] boolean FLAT_LABEL_CALL;
    [LOOP_CAP] integer FLAT_LOOP_SOURCE, FLAT_LOOP_INSTANCE, FLAT_LOOP_OF;
    [GROUP_CAP] integer FLAT_GROUP_TOKEN, FLAT_GROUP_GUARDS, FLAT_GROUP_INSTANCE, FLAT_GROUP_MEMBER_FIRST,
      FLAT_GROUP_MEMBER_TOTAL;
    [FINAL_CAP] integer WORK_SOURCE, WORK_OP, WORK_NAME, WORK_INSTANCE, START_STACK, FLAT_ENTRY_SOURCE, FLAT_ENTRY_OP,
      FLAT_ENTRY_NAME, FLAT_ENTRY_INSTANCE;
    [FLAT_PATH_CAP] integer FLAT_PATH_KEY, FLAT_PATH_INSTANCE;
    [FLAT_PATH_CAP] boolean FLAT_PATH_CALL;
    [EQUATION_CAP] integer FLAT_EQUATION_TARGET, FLAT_EQUATION_TARGET_INSTANCE, FLAT_EQUATION_START, FLAT_EQUATION_END,
      FLAT_EQUATION_TOKEN, FLAT_EQUATION_LOOP, FLAT_EQUATION_CONTEXT, FLAT_EQUATION_LABELS, FLAT_EQUATION_GUARDS;
    [EQUATION_CAP] boolean FLAT_EQUATION_SEED;
    [MEMBER_CAP] integer FLAT_MEMBER_START, FLAT_MEMBER_END;
    [DEPENDENCE_CAP] integer FLAT_DEPENDENCE_INSTANCE, FLAT_DEPENDENCE_FROM_KEY, FLAT_DEPENDENCE_TO_KEY,
      FLAT_DEPENDENCE_FROM_TOKEN, FLAT_DEPENDENCE_TO_TOKEN, FLAT_DEPENDENCE_TOKEN;
    [PARSE_CAP] integer SPAN_INDEX, INSTANTIATE_INDEX;
    integer SPAN_SIGNAL_MODEL, ROW_NOW, FAULT_MESSAGE, FAULT_TOKEN, FAULT_ARGUMENT0, FAULT_ARGUMENT1, FAULT_ARGUMENT2, SPAN_ROLE, SPAN_FINISH_SIGNAL_MODEL, SPAN_FINISH_SIGNAL_SLOT,
      SPAN_FINISH_EQUATION_MODEL, SPAN_FINISH_EQUATION_SLOT, SPAN_FINISH_GROUP_MODEL, SPAN_FINISH_GROUP_SLOT,
      SPAN_LOOP_MODEL, SPAN_LOOP_SLOT, SPAN_MODEL_NAME, IP_NOW, INST, INST_MODEL, INST_MARK, MEMBER_ORDINAL,
      SIGNAL_KEY_NOW, GROUP_MEMBER_COUNT, SELECT_TARGET, SELECT_TOKEN, SELECT_MEMBER_ROW, FROM_KEY, TO_KEY, E,
      POSTFIX_END_NOW, E_OP, E_NAME, E_TOKEN, E_COUNT, E_PARAMS, E_ARITY, CHECK_KEY, BUILTIN_INPUTS, PURE_INSTANCE,
      PURE_MODEL, CALLEE, WALKER, CALLEE_INPUTS, CALLEE_OUTPUTS, CALLEE_FIRST_SIGNAL, CALLEE_OUTPUT_KEY, CALLEE_KIND,
      CALLER_LABEL_START, CALLER_LABEL_LENGTH, CALLER_GUARD_START, CALLER_GUARD_LENGTH, POSTFIX_LABEL_NODE,
      POSTFIX_GUARD_NODE, POSTFIX_LABEL_LENGTH, POSTFIX_GUARD_LENGTH, NEW_LABEL_LENGTH, NEW_GUARD_LENGTH, PATH_K,
      PATH_NEW, PATH_LABEL_TOTAL, PART_K, PART_INHERITED, PART_INHERITED_AT, PART_NODE_LENGTH, NODE_VALUE,
      NODE_GUARD_KEY, PATH_KEY_NOW, PATH_INSTANCE_NOW, INPUT_I, OPERAND_BASE, SEGMENT_FROM, SEGMENT_TO, COPY_NOW,
      INPUT_KEY, OVERFLOW_FRAGMENT, INSTANTIATE_MESSAGE, INSTANTIATE_TOKEN, INSTANTIATE_ARGUMENT0,
      INSTANTIATE_ARGUMENT1, INSTANTIATE_ARGUMENT2, OWNED_SLOT, SIGNAL_ROW_SLOT, FLAT_SIGNAL_COUNT, LABEL_ROW_SLOT,
      FLAT_LABEL_COUNT, LOOP_ROW_SLOT, FLAT_LOOP_COUNT, POSTFIX_START, POSTFIX_END, POSTFIX_TARGET, POSTFIX_LOOP,
      POSTFIX_TOKEN, POSTFIX_LABELS, POSTFIX_GUARDS, POSTFIX_RETURN, GROUP_ROW_SLOT, FLAT_GROUP_COUNT,
      ENTRY_START_VALUE, WORK_SLOT, START_SLOT, WORK_TOP, START_TOP, ENTRY_CURSOR, NEW_INSTANCE, INSTANCE_SLOT,
      NEW_MODEL, NEW_KIND, CALLEE_TALLY, INSTANCE_TOTAL, CALL_INSTANCE, PATH_SLOT, FLAT_PATH_COUNT, PATH_STEP,
      ENTRY_SLOT_FLAT, COPIED_SOURCE, COPIED_OP, FLAT_ENTRY_COUNT, FLAT_PARAMETER_TOTAL, COPY_CURSOR, INPUT_CURSOR,
      EQUATION_ROW_SLOT, ROW_LENGTH, FLAT_EQUATION_COUNT, FLAT_LIST_TOTAL, MEMBER_ROW_SLOT, FLAT_MEMBER_COUNT,
      DEPENDENCE_ROW_SLOT, FLAT_DEPENDENCE_COUNT, ANCESTOR_CURSOR, IP_STATE, ROW_CURSOR, MEMBER_CURSOR, INSTANCE_AT,
      FLAT_COLUMN_ROWS, LOOP_ROW, WALK_ROW_INSTANCE, PATH_CONTEXT, INHERITED_START, INHERITED_LENGTH, INHERITED_AT,
      NODE_ON_KEY, LIST_INSTANCE, LIST_KIND_SHOWN, FLAT_MEMBER_NOW, ENTRY_AT, ENTRY_NAME_NOW, ENTRY_INSTANCE_NOW,
      NAME_INSTANCE_NOW, EMITTED_CLASS, EMITTED_TAG, FRONT_MESSAGE;
    boolean INSTANTIATES, AT_IP_ROOT, AT_IP_INSTANCE, AT_IP_LABEL, AT_IP_SIGNAL, AT_IP_FINISH_SIGNAL, AT_IP_LOOP,
      AT_IP_EQUATION, AT_IP_FINISH_EQUATION, AT_IP_GROUP, AT_IP_FINISH_GROUP, AT_IP_DEPENDENCE, AT_IP_ENTRY,
      AT_IP_ANCESTRY, AT_IP_PATH, AT_IP_INPUT, AT_IP_EMIT, INSTANCES_DONE, LABEL_LIVE, PARSE_SIGNAL_LIVE,
      FINISH_SIGNAL_LIVE, SIGNAL_WANTED, LOOP_LIVE, EQUATION_LIVE, EQUATION_SKIPS, SELECTS_PARSE_EQUATION,
      SELECTS_FINISH_EQUATION, SELECTS_EQUATION, PARSE_GROUP_LIVE, FINISH_GROUP_LIVE, SELECTS_MEMBER, GROUP_ADVANCES,
      SELECTS, SELECT_SEED, DEPENDENCE_LIVE, ENTRY_LIVE, E_IS_LEAF, E_IS_CALL, CHECK_OWNED, CHECK_LABELED, TO_OWNED,
      TO_LABELED, LOOP_FAILS, TARGET_FAILS, SIGNAL_CHECKED, SIGNAL_LABEL_FAILS, SIGNAL_UNDECLARED_FAILS, CALL_LIVE,
      AS_PROCESS, CALLS_TYPE, CALLS_BUILTIN, TYPE_CALL_LIVE, TYPE_PROCESS_FAILS, TYPE_SHAPE_FAILS, BUILTIN_LIVE,
      BUILTIN_HAS_OUTPUT, BUILTIN_ITERATE_FAILS, BUILTIN_COUNT_FAILS, BUILTIN_PROCESS_FAILS, BUILTIN_EXPRESSION_FAILS,
      BUILTIN_UNSAFE_FAILS, FUNCTION_CALL_FAILS, MODEL_CALL_LIVE, CALLEE_UNDECLARED_FAILS, CALLEE_PARAMS_FAILS, CALLEE_ITERATE_FAILS,
      STARTS_ANCESTRY, ANCESTRY_PASSES, SELF_CALL_FAILS, CALLEE_COUNT_FAILS, CALLEE_OUTPUTS_FAILS,
      CALLEE_PROCESS_FAILS, CALLEE_EXPRESSION_FAILS, FROM_FAILS, TO_FAILS, CALL_LABEL_ADDED, PATH_LIVE, IN_LABEL_PART,
      FROM_INHERITED, FROM_NODE, PATH_CALL_NOW, INPUT_LIVE, INPUT_COPIES, INPUT_CLOSES, CALL_FINISHES, CALLEE_ORDERED,
      EMIT_COPIES, EMIT_CLOSES, EQUATION_ROW_WANTED, MEMBER_ROW_WANTED, DEPENDENCE_ROW_WANTED, ENTRY_COPY_WANTED,
      PLAIN_ENTRY, LABEL_ROW_WANTED, GROUP_ROW_WANTED, FAILS_NOW, GOES_ON, POSTFIX_IS_MEMBER, POSTFIX_SEED,
      CALL_HAS_OUTPUT, CREATES_INSTANCE, NEW_PURE, INSTANTIATE_FAILED, INSTANTIATE_INCOMPLETE, FLAT_READY, FLAT_DUMP,
      WALK_ROW_CALL, FLAT_PATH_COLUMN, FROM_INHERITED_PATH, LIST_CALL, NAME_CALL_NOW, PREFIX_DUE, WALK_PREFIXED,
      PROGRAM_PREFIX;
    long SPAN_BOUND, INSTANTIATE_BOUND, FLAT_ROW_TOTAL, FLAT_DUMP_BOUND, PROGRAM_DUMP_BOUND, EMITTED_VALUE, ROWS_DUMP_BOUND,
      ROWS_NUMBER_VALUE, NEW_TABLE_ELEMENTS;
    ulong DUMP_TYPE_SIZE, DUMP_TABLE_SIZE;
    boolean DUMP_TYPE_NEW, DUMP_TABLE_NEW;
    integer DUMP_TYPE_KIND, DUMP_TYPE_ELEMENT, DUMP_TABLE_TYPE, DUMP_COLUMN_START, DUMP_COLUMN_END, ROWS_COLUMN_ROWS, ROWS_TOKEN_NOW, MESSAGE_INSTANCE, PREFIX_INSTANCE, LW_ENUM_ARGUMENT0,
      LW_INDEX_TOKEN;
    boolean ARGUMENT_TYPE_NEW, FLAT_PREFIX, NAME_HALF, LONG_ARGUMENT, SLICES_TEXT;
    [HASH_NODE_CAP] long HN_A, HN_B;
    [HASH_NODE_CAP] integer HN_VALUE, HN_NEXT;
    [HASH_HEAD_CAP] integer HASH_HEAD;
    [NAME_CAP] integer HOLDER_COUNT, HOLDER_TYPE;
    [NEW_TYPE_CAP] integer NEW_TYPE_ELEMENT;
    [NEW_TYPE_CAP] ulong NEW_TYPE_SIZE;
    [ROWS_CAP] integer ROWS_OP, ROWS_LEFT, ROWS_RIGHT, ROWS_TYPE, ROWS_TOKEN, ROWS_OWNER, ROWS_LOOP, ROWS_GUARD,
      FIRST_EFFECT, EFFECT_KIND, EFFECT_RESOURCE, LEFT_HEAD, LEFT_NEXT, LEFT_TAIL, RIGHT_HEAD, RIGHT_NEXT, RIGHT_TAIL,
      PREV_LIST;
    [ROWS_CAP] long ROWS_VALUE, EFFECT_PARAM;
    [ROWS_CAP] boolean ROWS_CTX;
    [SIGNAL_CAP] integer LW_SIGNAL_KEY, SIGNAL_LOOP_MARK, SIGNAL_TOP, SIGNAL_DEF_TOKEN, SIGNAL_DEF_GUARD, DEF_START,
      DEF_END, DEFINED_LIST;
    [IOTA_CAP] integer LW_IOTA;
    [NEW_TABLE_CAP] integer NEW_TABLE_TYPE;
    [LOOP_CAP] integer LOOP_INDEX, LOOP_DEF_TOTAL, LOOP_DEF_START, LOOP_DEF_FILL;
    [LOOP_CAP] ulong LOOP_SIZE;
    [EQUATION_CAP] integer LW_EQ_SIGNAL, LW_GUARD_MARK, EQ_ROW_START, EQ_ROW_END, EQ_ROW_SIGNAL;
    [GROUP_CAP] integer LW_GROUP_GUARD;
    [MEMBER_CAP] integer GROUP_MEMBER_ROW;
    [LOWER_STACK_CAP] integer LW_STACK;
    [DEPENDENCE_CAP] integer PO_FROM_SIGNAL, PO_FROM_LABEL, PO_TO_SIGNAL, PO_TO_LABEL;
    [LABEL_CAP] boolean LABEL_NEEDED;
    [LABEL_CAP] integer LABEL_ROW_TOTAL, LABEL_START, LABEL_FILL;
    [SEGMENT_CAP] integer SEGMENT_LABEL, SEGMENT_EQUATION;
    [ROW_DEPENDENCE_CAP] integer DEPENDENCE_FROM_ROW, DEPENDENCE_TO_ROW, WAR_READER, WAR_WRITER, WAR_SIGNAL,
      LABEL_ROWS;
    [PARSE_CAP] integer LOWER_INDEX, POST_INDEX, EXPAND_INDEX;
    integer LW_NOW, LW_I, LW_K, LW_SIGNAL_SOURCE, LW_SIGNAL_KEY_NOW, LW_SIGNAL_TYPE_NOW, LW_VALUE_KEY, LW_TABLE_TYPE,
      LW_LOOP_SOURCE, LW_EQ_TARGET, LW_EQ_TARGET_INSTANCE, LW_EQ_LOOP, LW_EQ_TOKEN, LW_EQ_LOOP_NAME,
      LW_EQ_LOOP_INSTANCE, LW_GUARD_NODE, LW_GUARD_CONTEXT, LW_GUARD_NODE_LENGTH, LW_GUARD_INHERITED, LW_GUARD_LAST,
      LW_GUARD_AT, LW_GUARD_KEY, LW_GUARD_INSTANCE, LW_EQ_STEP, LW_START_SIGNAL, LW_E, LW_END_NOW, LW_SRC, LW_OP,
      LW_NAME, LW_INST, LW_ENTRY_TOKEN, LW_LOOP_NOW, LW_TOP_NOW, LW_INITIAL, LW_LEFT, LW_RIGHT, LW_LEFT_OP,
      LW_RIGHT_OP, LT, RT, LT_KIND, LT_ELEMENT, RT_KIND, RT_ELEMENT, LW_PREV_INSTANCE, LW_ENUM_TYPE_KEY,
      LW_ENUM_VALUE_KEY, LW_ENUM_TOKEN, LW_ENUM_NAMED_TYPE, LW_ENUM_HOLDERS, LW_ENUM_TYPE, LW_PAIR_KEY_NAME,
      LW_PAIR_KEY_INSTANCE, LW_PAIR_KEY_LOOP, LW_ARRAY_ELEMENT, LK_HASH, LK_N0, LK_N1, LK_N2, LK_N3, LK_N4, LK_N5,
      LK_N6, LK_N7, LK_NODE, LK_VALUE, LK_NEW, LW_NEW_TYPE, LK_INSERT_VALUE, HN_SLOT, HN_COUNT, LW_HOLDER_SLOT,
      LW_NEW_TYPE_SLOT, NEW_TYPE_COUNT, LW_INTERNED, LW_IOTA_TABLE, LW_NEW_TABLE, LW_LOOP_SIGNAL, LW_LOOP_TYPE, LW_INDEX_SIGNAL_ROW, LW_INDEX_DEF, LW_INDEX_DEF_SAFE,
      LW_CONSTANT, LW_ENUM_MESSAGE, FX_STEP, FX_COUNT, FX_PARAMS, FX_P0, FX_P1, FX_KEY0, FX_KEY1, FX_TYPE0, FX_TYPE1,
      FX_EXPECTED, FX_CONSTANT1, FX_BASE, FX_O0, FX_O1, FX_O2, FX_O3, FX_O4, FX_O5, FX_O6, FX_PAIR_AT, FX_T0, FX_T1,
      FX_T2, FX_T3, FX_T4, FX_T5, FX_T6, FX_K0, FX_K1, FX_K2, FX_K3, FX_K4, FX_K5, FX_K6, FX_SYSCALL_AT,
      FX_SYSCALL_TYPE, FX_ROW_TYPE, FX_MESSAGE, FX_TOKEN, FX_ARGUMENT0, FX_ARGUMENT1, FX_OPERAND, FX_PREVIOUS,
      LW_PREV_MESSAGE, LW_INDEX_ROW, LW_INDEX_TYPE, LW_CALL_TYPE, LW_CALL_KIND, LW_IF_EFFECT, LW_INITIAL_TYPE,
      LW_OPERATOR_MESSAGE, LW_OPERATOR_TOKEN, LW_OP_TEXT, LW_COUNTER_OP, LW_OPERATOR_ARGUMENT0, LW_OPERATOR_ARGUMENT1, LUB_A, LUB_B,
      LUB_A_KIND, LUB_B_KIND, LUB_A_BYTES, LUB_B_BYTES, LUB_UNSIGNED_BYTES, LUB_SIGNED_BYTES, LUB_SIGNED, LUB_WIDENED,
      LUB, LW_RESULT_OP, LW_RESULT_TYPE, LW_END_TOP, LW_END_TOP_OP, LW_END_TOP_TYPE, LW_SIGNAL_NOW,
      LW_END_SIGNAL_TYPE, LW_END_TYPE, LW_END_MESSAGE, LW_MEMBER_INDEX, LW_ROW, LW_OVERFLOW, LW_MESSAGE_NOW,
      LW_START_TOKEN, LW_TOKEN_NOW, LW_FLAT_KEY, LW_FLAT_INSTANCE, LW_ARGUMENT0_NOW, LW_ARGUMENT1_NOW,
      LW_ARGUMENT2_NOW, LW_MESSAGE, LW_TOKEN, LW_ARGUMENT0, LW_ARGUMENT1, LW_ARGUMENT2, LW_INSTANCE, LW_ROW_SLOT,
      LW_ROW_OP, LW_ROW_LEFT, LW_ROW_RIGHT, LW_ROW_TYPE, LW_CARRIED_TOKEN, LW_ROW_TOKEN, LW_REWRITE_TABLE, ROW_COUNT,
      LW_EFFECT_SLOT, EFFECT_COUNT, LW_FX_PREVIOUS, LW_FX_STEP, LW_NEW_TABLE_SLOT, NEW_TABLE_COUNT, LW_STACK_SLOT,
      LW_TOP, LW_CUR_TOKEN, LW_FL_TOKEN, LW_FL_START, LW_FL_END, LW_FL_LOOP, LW_FL_OWNER, LW_FL_GUARD,
      LW_FL_ROW_START, LW_ENTRY, LW_STATE, LW_CURSOR, LW_SUB, PO_NOW, PO_I, PO_K, PO_END_KEY, PO_END_INSTANCE,
      PO_END_SIGNAL, PO_ROW_OP, PO_ROW_LEFT, PO_ROW_RIGHT, PO_LEFT_TAIL, PO_RIGHT_TAIL, PO_PREV_SLOT, PREV_COUNT,
      PO_SIGNAL_LOOP, PO_PLACE_FILL, PO_WALK_CONTEXT, PO_WALK_NODE, PO_INHERITED, PO_PATH_LENGTH, PO_WALK_AT,
      PO_WALK_KEY, PO_WALK_INSTANCE, PO_HASH, PO_N0, PO_N1, PO_N2, PO_N3, PO_N4, PO_N5, PO_N6, PO_N7, PO_NODE,
      PO_VALUE, PO_WALK_LABEL, PO_WALK_EQUATION, PO_SEGMENT_SIZE, PO_FROM_SIGNAL_NOW, PO_TO_SIGNAL_NOW,
      PO_MESSAGE_NOW, PO_MESSAGE, PO_TOKEN, PO_ARGUMENT0, PO_INSTANCE, PO_SEGMENT_SLOT, SEGMENT_COUNT, PO_RUNNING,
      PO_STATE, PO_CURSOR, PO_SUB, XP_NOW, XP_I, XP_J, XP_K, XP_LABEL, XP_EQUATION, XP_RANGE_LENGTH, XP_SEGMENT_SIZE,
      XP_PLACE_FILL, XP_FROM_SIGNAL, XP_FROM_LABEL, XP_TO_SIGNAL, XP_TO_LABEL, XP_FROM_HEAD, XP_DEF_LENGTH,
      XP_TO_HEAD, XP_FROM_LENGTH, XP_TO_LENGTH, XP_FROM_ROW, XP_TO_ROW, XP_PREVIOUS, XP_SIGNAL, XP_WRITER, XP_A, XP_B,
      XP_READER, XP_DEPENDENCE_SLOT, DEPENDENCE_TOTAL, XP_WAR_SLOT, WAR_COUNT, XP_LEFT_AT, XP_RIGHT_AT, XP_STATE,
      XP_CURSOR, XP_INNER, XP_SUB;
    boolean ROWS_DUMP, LOWERS, AT_LS_SIGNAL, AT_LS_LABEL, AT_LS_VALUE, AT_LS_ARRAY, AT_LS_TABLE, AT_LS_LOOP,
      AT_LS_EQUATION, AT_LS_GROUP, AT_LS_START, AT_LS_SCAN, AT_LS_ENTRY, AT_LS_NEVER, AT_LS_MEMBERS, LW_SIGNAL_LIVE,
      LW_SIGNAL_INPUT, LW_LABEL_LIVE, LW_VALUE_TYPE_LIVE, LW_VALUE_LIVE, LW_ARRAY_LIVE, LW_TABLE_LIVE,
      LW_TABLE_CANDIDATE, LW_TABLE_WALKS, LW_TABLE_MATCHES, LW_TABLE_OK, LW_TABLE_IOTA, LW_LOOP_LIVE,
      LW_EQUATION_LIVE, LW_EQ_SEED, LW_LOOP_DEFINES, LW_HAS_GUARD, LW_EQ_MORE, LW_GROUP_LIVE, LW_START_LIVE,
      LW_SCAN_LIVE, LW_ENTRY_LIVE, LW_FINISHING, LW_SCAN_READS, LW_IS_SIGNAL, LW_IS_ITER, LW_LOOKS_SIGNAL,
      LW_IS_CONST, LW_IS_EFFECT, LW_IS_DELAY, LW_IS_ENUM, LW_ENUM_LIVE, LW_IS_LEAF, LW_OPERATOR, LW_UNARY, LT_NEW,
      LT_INT, LT_LOGICAL, RT_NEW, RT_INT, RT_LOGICAL, LW_ARRAY_OPERAND, LW_IS_INDICES, LW_IS_GATHER, LW_IS_PREV,
      LW_ENUM_NAMED, LW_START_LOOKS, LW_LOOKS_PAIR, LW_LOOKS_ARRAY, LW_LOOKS_GUARD, LK_LIVE, LK_WANTS_INSERT, LK_M0,
      LK_M1, LK_M2, LK_M3, LK_M4, LK_M5, LK_M6, LK_M7, LK_FOUND, LK_UNSURE, LK_INSERTS, LK_FULL, LW_TYPE_FULL,
      LW_TABLE_FULL, LW_LOOP_UNDECLARED, LW_LOOP_NOT_INDEX, LW_INDEX_DEFINED, LW_TARGET_UNDECLARED,
      LW_START_SEED_FAILS, LW_START_DEFINES, LW_START_UNDECLARED, LW_START_INPUT, LW_START_TWICE, LW_SCAN_FAILS,
      LW_SIGNAL_FOUND, LW_FROM_CONSTANT, LW_SIGNAL_UNDECLARED, LW_ENUM_UNDECLARED, LW_ENUM_AMBIGUOUS,
      LW_ENUM_TYPE_UNDECLARED, LW_ENUM_NO_VALUE, FX_IS_LOAD, FX_IS_STORE, FX_IS_SYSCALL, FX_IS_INSTRUCTION,
      FX_NUMBER1, FX_WORD_CONSTANT, FX_WORD_BIG, FX_CHECKS, FX_EMITS_ARG, FX_EMITS_EFFECT, LW_NOT_IN_ITERATE,
      LW_LEFT_ARRAY_VALUE, LW_RIGHT_ARRAY_VALUE, LW_RIGHT_PAIR, LW_INDICES_FAILS, LW_INDEXES, LW_INDEX_INT,
      LW_INDEX_OUTSIDE, LW_IS_NEXT, LW_FROM_REPEAT, LW_RANGE_MISMATCH, LW_INDEX_COUNTS, LW_CONVERTS, LW_INTEGER_OP, LW_COMPARE_OP, LW_LOGIC_OP, LW_SHIFT_OP,
      LW_POINTER_ARITHMETIC, LW_FROM_ABS, LUB_A_SIGNED, LUB_B_SIGNED, LUB_SUBTYPE, LW_MEMBER_NOW, LW_END_SEED, LW_END_DEFINES,
      LW_END_RANGE, LW_END_SIGNAL_ARRAY, LW_NEVER_LIVE, LW_NEVER_FAILS, LW_MEMBERS_LIVE, LW_MEMBER_STARTS,
      LW_MEMBERS_CLOSE, LW_GROUP_FAILS, LW_CREATES, LW_PUSHES, LW_FAILS, LW_LONG0_UNSIGNED, LW_GOES, LW_ROW_CTX,
      LW_INDICES_REWRITES, LW_RANGE_REWRITES, LW_NEVER_WRITES, LW_END_WRITES, LW_EQ_CLOSES, LW_MEMBER_CLOSES,
      LW_GROUP_ARRAY, LW_FL_MEMBER, LOWER_FAILED, LOWER_INCOMPLETE, LOWER_READY, AT_PS_DEPENDENCE, AT_PS_ROWS,
      AT_PS_PREFIX, AT_PS_PLACE, AT_PS_WALK, AT_PS_LABELSUM, AT_PS_SIZE, PO_DEPENDENCE_LIVE, PO_TO_END,
      PO_LOOKS_LABEL, PO_ROWS_LIVE, PO_LEFT_RANGE, PO_RIGHT_RANGE, PO_RANGE_FAILS, PO_LEFT_PREV, PO_RIGHT_PREV,
      PO_COUNTS, PO_PREFIX_LIVE, PO_PLACE_LIVE, PO_PLACES, PO_WALK_LIVE, PO_WALK_STEP, PO_FROM_INHERITED,
      PO_WALK_CALL, PO_LIVE, PO_M0, PO_M1, PO_M2, PO_M3, PO_M4, PO_M5, PO_M6, PO_M7, PO_FOUND, PO_UNSURE,
      PO_END_FAILS, PO_SEGMENT_FULL, PO_LABELSUM_LIVE, PO_SIZE_LIVE, PO_SIZE_FAILS, PO_LABELS_FULL, PO_FAILS, PO_GOES,
      PO_MARKS, PO_NEEDS_LABELS, POST_FAILED, POST_INCOMPLETE, POST_READY, AT_XS_PLACE, AT_XS_PAIRS, AT_XS_PREV,
      XP_PLACE_LIVE, XP_PLACES, XP_PLACE_ENDS, XP_PAIRS_LIVE, XP_EMITS_PAIR, XP_PAIR_ROW_ENDS, XP_PAIR_ENDS,
      XP_PREV_LIVE, XP_SCALAR, XP_STARTED, XP_TAKES_A, XP_TAKES_B, XP_PREV_SCALAR, XP_EMITS_WAR, XP_PREV_ENDS,
      XP_DEPENDENCE_WANTED, XP_FAILS, XP_PREV_STARTED, EXPAND_FAILED, EXPAND_INCOMPLETE, ROWS_READY;
    long LOWER_BOUND, LW_LEFT_VALUE, LW_INDICES_COUNT, LK_A, LK_B, FX_WORD, LW_INDEX_VALUE, LW_INITIAL_VALUE,
      LW_RESULT_VALUE, LW_LONG0, LW_LONG1, LW_ROW_VALUE, POST_BOUND, PO_A, PO_B, PO_FROM_LIST, PO_TO_LIST,
      PO_PAIR_TOTAL, EXPAND_BOUND;
    ulong LT_SIZE, RT_SIZE, LW_ARRAY_SIZE, LW_RANGE_SIZE;
    [CLOCK_CAP] integer CK_LINK, CK_SIZE, CK_OFFICIAL, SAMPLE_OF, SAMPLE_ROW, GUARDED, TSTAMP, CGSTAMP, CGUARD, CAND,
      NODE_KIND, NODE_PARENT1, NODE_DEPTH, NODE_ROOT1, NODE_LEFT1, NODE_RIGHT1, UP_0, UP_1, UP_2, UP_3, UP_4, UP_5,
      UP_6, UP_7, UP_8, UP_9, UP_10, UP_11, UP_12, UP_13, UP_14, UP_15, UP_16, UP_17, UP_18, UP_19, CLOCK_STAMP,
      CLOCK_LOCAL, CONTAINER_STAMP, CONTAINER_LOCAL, ROOT_LIST, CLOCK_REP;
    [CLOCK_CAP] boolean ROOT_LISTED;
    [CLOCK_CAP] integer ROOT_IRQ1, ROOT_INPUT1;
    integer CF_ROOT_IRQ1, CF_PARTNER;
    boolean CF_FREE, CF_VIRT_ROOT, CF_SHARED, CF_SHARED_ROOT;
    [DEF_CAP] integer DEF_KIND, DEF_TARGET, DEF_LEFT, DEF_RIGHT, DEF_TOKEN, PEND;
    [DEF_CAP] boolean DEF_DONE;
    [OB_CAP] integer OB_SMALL, OB_BIG, OB_TOKEN;
    [PAIR_CAP] integer PAIR_CLOCK, PAIR_CONTAINER, STACK_PAIR, STACK_SLOT;
    [PAIR_CAP] boolean PAIR_HOLDS;
    [PAIR_NEXT_CAP] integer PAIR_NEXT;
    [GRID_CAP] integer GRID_STAMP, GRID_PAIR;
    [PARSE_CAP] integer CP_INDEX, CK_INDEX, CO_INDEX, CF_INDEX, CE0_INDEX, CE1_INDEX, CL_INDEX, CR_INDEX, CS_INDEX,
      CJ_INDEX;
    [CLOCK_CAP] boolean CE_STALLED, CE_SEEN;
    [CLOCK_NAME_CAP] integer CE_ITEM_MEMBER, CI_P, CI_A_AT, CI_A_LENGTH, CI_F1, CI_N1, CI_D1, CI_F2, CI_B_AT,
      CI_B_LENGTH, CI_F3, CI_N2, CI_D2, CI_S, CI_END, CE_ORDER;
    [CLOCK_NAME_CAP] long CE_ITEM_KEY, CI_KEY;
    [CLOCK_NAME_CAP] integer CE_OTHER_MEMBER;
    [CLOCK_NAME_CAP] boolean CE_DUPLICATE;
    [CLOCK_TEXT_CAP] ubyte CE_TEXT, CLOCK_TEXT;
    integer CLOCK_MESSAGE, CLOCK_TOKEN, CLOCK_ARGUMENT0, CF_SIGNAL_SOURCE, CLOCKS_COLUMN_ROWS, CLOCK_POSITION_TOKEN,
      CLOCKS_NUMBER_VALUE, CP_OP, CP_OP_UNIONS, CP_UNIONS, CP_SAMPLE_BOUND, CP_DEF_BOUND, CP_GUARDED, KS_NOW, KC, KK,
      KRN, K_SAMPLES_NOW, K_DEFS_NOW, K_OBS_NOW, KR_OP, KR_LEFT, KR_RIGHT, KR_CONDITION, KR_EXISTING, KR_NEW_SAMPLE,
      KR_SAMPLE, KR_X0, KR_X1, KR_OP_UNIONS, KR_LOOP, KR_UNIONS, KR_X, KM_CONDITION, KG_TOTAL, KG_AT, KG_MEMBER,
      KG_HEAD, KW_MERGED, KW_A, KW_B, KW_FIRST, KW_SECOND, KW_CONDITION, KW_V0, KW_V1, K_DEF_LIMIT, K_LISTED_DEF,
      KU_ROW, KS_CLOCK, KS_GUARD_SOURCE, KD_DEF, KD_KIND, KD_T, KD_L, KD_R, KD_OTHER, KD_TARGET_KIND, KD_ROOT_L,
      KD_ROOT_R, KD_DEPTH_L, KD_DEPTH_R, KD_HIGH, KD_DIFF, KZ_0, KZ_1, KZ_2, KZ_3, KZ_4, KZ_5, KZ_6, KZ_7, KZ_8, KZ_9,
      KZ_10, KZ_11, KZ_12, KZ_13, KZ_14, KZ_15, KZ_16, KZ_17, KZ_18, KZ_19, KZ_20, KD_LIFTED, KA_20, KB_20, KA_UP_19,
      KB_UP_19, KA_19, KB_19, KA_UP_18, KB_UP_18, KA_18, KB_18, KA_UP_17, KB_UP_17, KA_17, KB_17, KA_UP_16, KB_UP_16,
      KA_16, KB_16, KA_UP_15, KB_UP_15, KA_15, KB_15, KA_UP_14, KB_UP_14, KA_14, KB_14, KA_UP_13, KB_UP_13, KA_13,
      KB_13, KA_UP_12, KB_UP_12, KA_12, KB_12, KA_UP_11, KB_UP_11, KA_11, KB_11, KA_UP_10, KB_UP_10, KA_10, KB_10,
      KA_UP_9, KB_UP_9, KA_9, KB_9, KA_UP_8, KB_UP_8, KA_8, KB_8, KA_UP_7, KB_UP_7, KA_7, KB_7, KA_UP_6, KB_UP_6,
      KA_6, KB_6, KA_UP_5, KB_UP_5, KA_5, KB_5, KA_UP_4, KB_UP_4, KA_4, KB_4, KA_UP_3, KB_UP_3, KA_3, KB_3, KA_UP_2,
      KB_UP_2, KA_2, KB_2, KA_UP_1, KB_UP_1, KA_1, KB_1, KA_UP_0, KB_UP_0, KA_0, KB_0, KD_COMMON, KD_ALIAS, KD_PARENT,
      KD_NODE_LEFT, KD_NODE_RIGHT, KD_OLD_LEFT, KD_OLD_RIGHT, KF1_SOURCE, KF2_SOURCE, KF3_SOURCE, KF1_0, KF1_1, KF1_2,
      KF1_3, KF1_4, KF1_5, KF1_6, KF1_7, KF1_8, KF1_9, KF1_10, KF1_11, KF1_12, KF1_13, KF1_14, KF1_15, KF1_16, KF1_17,
      KF1_18, KF1_19, KF1_20, KF1_ROOT, KF1, KF2_0, KF2_1, KF2_2, KF2_3, KF2_4, KF2_5, KF2_6, KF2_7, KF2_8, KF2_9,
      KF2_10, KF2_11, KF2_12, KF2_13, KF2_14, KF2_15, KF2_16, KF2_17, KF2_18, KF2_19, KF2_20, KF2_ROOT, KF2, KF3_0,
      KF3_1, KF3_2, KF3_3, KF3_4, KF3_5, KF3_6, KF3_7, KF3_8, KF3_9, KF3_10, KF3_11, KF3_12, KF3_13, KF3_14, KF3_15,
      KF3_16, KF3_17, KF3_18, KF3_19, KF3_20, KF3_ROOT, KF3, KN_ALIAS_ROOT, KN_A, KN_B, KN_OFFICIAL, KN_SIZE_A,
      KN_SIZE_B, KN_TOP, KN_CHILD, K_SAMPLE_COUNT, KQ_SLOT, KQ_REWRITE_SLOT, DEF_COUNT, KO_SLOT, OB_COUNT,
      GUARDED_COUNT, KP_SLOT, KY_0, KY_1, KY_2, KY_3, KY_4, KY_5, KY_6, KY_7, KY_8, KY_9, KY_10, KY_11, KY_12, KY_13,
      KY_14, KY_15, KY_16, KY_17, KY_18, KY_19, K_CAPACITY, K_MESSAGE_NOW, CK_MESSAGE, CK_TOKEN, CK_ARGUMENT0,
      CK_CLOCK0, CK_CLOCK1, CK_CLOCK2, CK_STATE, CK_SUB, CK_CURSOR, CK_ROUND, CK_DEF_LIMIT, CK_SCAN_LIMIT, CK_CAND_W,
      CK_PEND_W, CLOCK_TOTAL, OG_NOW, OG_O, OG_STAMP, OF1_0, OF1_1, OF1_2, OF1_3, OF1_4, OF1_5, OF1_6, OF1_7, OF1_8,
      OF1_9, OF1_10, OF1_11, OF1_12, OF1_13, OF1_14, OF1_15, OF1_16, OF1_17, OF1_18, OF1_19, OF1_20, OF1_ROOT, OF1,
      OF2_0, OF2_1, OF2_2, OF2_3, OF2_4, OF2_5, OF2_6, OF2_7, OF2_8, OF2_9, OF2_10, OF2_11, OF2_12, OF2_13, OF2_14,
      OF2_15, OF2_16, OF2_17, OF2_18, OF2_19, OF2_20, OF2_ROOT, OF2, OG_SMALL_ROOT, OG_BIG_ROOT, OG_P, OG_S, OG_DEPTH,
      OG_C, OG_K, OG_KIND_C, OG_KIND_K, OG_DIFF, OZ_0, OZ_1, OZ_2, OZ_3, OZ_4, OZ_5, OZ_6, OZ_7, OZ_8, OZ_9, OZ_10,
      OZ_11, OZ_12, OZ_13, OZ_14, OZ_15, OZ_16, OZ_17, OZ_18, OZ_19, OZ_20, OG_NEXT_CLOCK, OG_NEXT_CONTAINER,
      OG_PAIR_CLOCK, OG_PAIR_CONTAINER, OG_CLOCK_LOCAL, OG_CONTAINER_LOCAL, OG_CLOCK_COUNT, OG_CONTAINER_COUNT,
      OG_PAIR_COUNT, OG_CLOCK_AT, OG_CONTAINER_AT, OG_CELL, OG_Q, CO_CLOCK_COUNT, CO_CONTAINER_COUNT, CO_PAIR_COUNT,
      OG_MESSAGE, CO_MESSAGE, CO_TOKEN, CO_CLOCK0, CO_CLOCK1, CO_CLOCK2, CO_STATE, CO_OBLIGATION, CO_TOP, CO_TOP_SLOT,
      CO_DEPTH, CF_I, CF_CLOCK, FF_0, FF_1, FF_2, FF_3, FF_4, FF_5, FF_6, FF_7, FF_8, FF_9, FF_10, FF_11, FF_12,
      FF_13, FF_14, FF_15, FF_16, FF_17, FF_18, FF_19, FF_20, FF_ROOT, FF, CF_SOURCE, CF_ROOT, ROOT_COUNT, CF_SIGNAL,
      CLOCK_MESSAGE_RAW, CE_ARGS, CE_Q0, CE_Q1, CE_Q2, E0_0, E0_1, E0_2, E0_3, E0_4, E0_5, E0_6, E0_7, E0_8, E0_9,
      E0_10, E0_11, E0_12, E0_13, E0_14, E0_15, E0_16, E0_17, E0_18, E0_19, E0_20, E0, E1_X, E1_0, E1_1, E1_2, E1_3,
      E1_4, E1_5, E1_6, E1_7, E1_8, E1_9, E1_10, E1_11, E1_12, E1_13, E1_14, E1_15, E1_16, E1_17, E1_18, E1_19, E1_20,
      E1, E1_GUARD, E1_MARK, E1_SLOT, E1_OTHER_SLOT, E1_MEMBER, E1_TOKEN, CE_COUNT, CE_OTHER_COUNT, CE_MIN0, CE_MIN1, CE_MIN2,
      E1_ROOT, CE_FS1, CE_FS2, CE_KEY1, CE_KEY2, CE_ITEMS_WANTED, CE_ITEMS, L_M, L_ROW, L_SOURCE, L_NAME_KEY, L_INSTANCE, L_BASE,
      L_SUFFIX, L_TOKEN, L_P, L_A, L_F1, L_N1, L_F2, L_B, L_F3, L_N2, L_S, L_D1_ALL, L_D2_ALL, L_D1, L_D2, L_A_LENGTH,
      L_B_LENGTH, L_LENGTH, CL_TOTAL, CL_LONGEST, CR_ITEM, CR_OFFSET, CR_P_END, CR_A_END, CR_F1_END, CR_N1_END,
      CR_F2_END, CR_B_END, CR_F3_END, CR_N2_END, CR_NAME_AT, CR_FRAGMENT, S_I, S_J, S_K, S_I_START, S_J_START,
      S_I_BYTE, S_J_BYTE, S_RANK, CS_LESS, CS_I, CS_J, CS_K, J_R, J_O, J_ITEM, J_START,
      J_SEPARATOR, CJ_POSITION, CJ_EMITTED, CJ_R, CJ_O, CE_GUARD_TOKEN;
    boolean CLOCK_FAILED, CLOCK_INCOMPLETE, CLOCKS_READY, CLOCKS_DUMP, CLOCKS_RUN, CP_LEFT_CTX, CP_RIGHT_CTX,
      CP_SAMPLES, AT_KS_ROWS, AT_KS_SAMPLES, AT_KS_GROUPS, AT_KS_REWRITE, AT_KS_TARGETS, AT_KS_GUARDS, AT_KS_SCAN,
      AT_KS_DEFS, AT_KS_WAIT, K_FIRST_ROUND, KR_LIVE, KR_TOO_MANY, KR_LEFT_CTX, KR_RIGHT_CTX, KR_IS_WHEN, KR_SAMPLES,
      KR_FIRST, KR_NO_CLOCK, KR_DELAY_CONSTANT, KR_EVENT, KR_CREATES, KR_CLOCKS_FULL, KR_MONO, KR_ONE, KR_HAS_LOOP,
      KR_UNITES, KR_ENDS, KR_DEFINES, KR_OBLIGES, KR_GUARDED, KM_LIVE, KG_LIVE, KG_STEPS, KG_NO_CLOCK, KG_UNITES,
      KG_ENDS, KW_LIVE, KW_SECOND_NEGATES, KW_FIRST_NEGATES, KW_SHAPED, KW_BOTH_CTX, KW_UNITES, KW_PRODUCT, KT_LIVE,
      KT_MARKS, KU_LIVE, KU_SETS, KS_LIVE, KS_OPEN, KS_ELIGIBLE, KS_GUARDED, KS_ATTACHES, KS_ROOTS, KS_KEEPS, KD_LIVE,
      KD_ACTS, KD_SAMPLE, KD_PRODUCT, KD_HITS, KD_OBLIGES, KD_EQUAL, KD_WAITS, KD_SETTLES, KD_FITS_NO_TREE,
      KD_R_DEEPER, KD_ANCESTOR_LR, KD_ANCESTOR_RL, KD_PLACED, KD_RESOLVES, KD_ALIASES, KD_CREATES, KD_SAME,
      KD_TWO_DEFINITIONS, KD_DONE, KV_LIVE, KV_WAITS, KN_UNITES, KN_LINKS, KN_A_ON_TOP, KQ_APPENDS, KQ_DEFS_FULL,
      KO_APPENDS, KO_FULL, KD_ENDS_ROUND, K_PROGRESS_NOW, K_STALLS, K_FAILS, KX_ROUND_START,
      K_STEPS_ON, CK_PROGRESS, CK_DONE, OG_STARTS, OG_WALKS, OG_FITS_NO_TREE, OG_OPENS, OG_INSIDE, OG_C_SPLITS,
      OG_K_SPLITS, OG_POPS, OG_SLOT_LIVE, OG_APPLIES, OG_FOUND, OG_ADDS, OG_PAIRS_FULL, OG_NEW, OG_LINKS, OG_PUSHES,
      OG_H0, OG_H1, OG_H2, OG_H3, OG_H4, OG_HOLDS, OG_FINISHES, OG_NOT_INSIDE, OG_FAILS, CO_DONE, CF_SIGNALS,
      CF_GOING, CF_INPUT, CF_NOT_ROOT, CF_LISTS, CF_FAILED, CE_STALL, CE_GUARDS, CE_LIST, CE_FITS, CE_FROM_CK,
      E1_SIGNAL, E1_WAITS, E1_STALLED, E1_NEW, E1_APPENDS, E1_OTHER, E1_PLACED, CE_OTHERS, SM_OWNED, CE_SWAP, L_SIGNAL, L_SAMPLE, L_FLAT, L_FRESH,
      L_BRACKET, L_PREFIXED, CE_OVERFLOW, S_LIVE, S_SKIPS, S_KEYS_DIFFER, S_EQUAL, S_DECIDED, S_LESS, S_ROW_ENDS, CS_UNFINISHED, CE_FAILS, EF_UNFINISHED,
      S_DUPLICATE, CS_DUPLICATE, J_LIVE, J_SKIPS, J_EMITS, J_ADVANCES;
    long CLOCKS_DUMP_BOUND, CP_STEPS, CK_TOTAL_BOUND, CK_DEF_BOUND, CK_ROUND_BOUND, CK_BOUND, E1_KEY;
    ubyte CR_NAME_BYTE, CR_BYTE, J_BYTE;
    ulong CR_DIGIT;
    [EDGE_CAP] integer SG_FROM, SG_TO, SO_FROM, SO_TO, SG_SUCC, SG_PRED, SO_SUCC, SO_PRED;
    [SCHED_NODE_CAP] integer SG_OUT, SG_IN, SO_OUT, SO_IN, SI_IN, SG_START, SG_PSTART, SO_START, SO_PSTART, SG_SFILL,
      SG_PFILL, SO_SFILL, SO_PFILL, SKO_DEC, SKO_STACK, SKO_ORDER, SCB_DEC, SCB_STACK, SCB_ORDER, SC_OUTC, VIS1, VIS2,
      EF_STACK;
    [SCHED_NODE_CAP] boolean SKO_MARK, SCB_MARK;
    [ROWS_CAP] integer SW_OUT, SW_IN, SW_START, SW_FILL, SKA_DEC, SKA_STACK, SKA_ORDER, SKB_DEC, SKB_STACK, SKB_ORDER,
      SNAP_GATHER1, WAR_SNAP1, SNAPPED_ALL, SNAP_LIST, LO_LIST;
    [ROWS_CAP] boolean SKB_MARK, SM_SEEN;
    [ROW_DEPENDENCE_CAP] integer SW_SUCC;
    [LOOP_CAP] integer LOOP_MEMBERS, SKA_LOOP_POPS, SKB_LOOP_POPS, LO_START, LO_LENGTH, SNAP_LOOP_COUNT, SNAP_START,
      SNAP_FILL, LO_FILL;
    [EFFECT_ORDER_CAP] integer SE_EROW;
    [EFFECT_PAIR_CAP] boolean EF_ORDERED;
    [TYPE_CAP] integer RES_COUNT;
    [CLOCK_NAME_CAP] integer SM_OWNER_ITEM_ROW, SM_EFFECT_ITEM_ROW;
    [CLOCK_NAME_CAP] long SM_EFFECT_ITEM_KEY;
    [PARSE_CAP] integer SE_INDEX, SWC_INDEX, SN_INDEX, SPL_INDEX, SKO_INDEX, SKA_INDEX, SKB_INDEX, SL_INDEX,
      SCA_INDEX, SCB_INDEX, SM_INDEX, EF_INDEX, SWS_INDEX, SSC_INDEX, SNS_INDEX, SNP_INDEX, LOP_INDEX;
    integer TX_ARGS, SCHEDULE_ARGUMENT2, SCHEDULE_COLUMN_ROWS, SCHED_LOOP_BASE, SCHED_NODES, SE_CLOCK_END, SE_DEP_END,
      E_ROW, E_SUB, E_CLOCK, E_CSUB, E_D, E_L, E_ROW_OP, E_LEFT, E_RIGHT, E_KIND, E_FROM, E_TO, E_SFROM, E_STO,
      E_OFROM, E_OTO, E_GSLOT, E_OSLOT, SG_COUNT, SO_COUNT, E_LOOP, E_RESOURCE, SE_ECOUNT, W_READER, W_WRITER, SN_G,
      SN_GP, SN_O, SN_OP, SN_W, SPL_MAX, P_GF, P_GT, P_OF, P_OT, P_WR, SKO_INIT_NODE, SKO_NODE_NOW, SKO_K, SKO_LEN0,
      SKO_S, SKO_NEW_DEC, SKO_POPPED, SKO_TOP, SKO_COUNT, SKO_PRESENT, SKO_NODE, SKO_STEP, SKO_CURSOR, SKA_INIT_NODE,
      SKA_NODE_NOW, SKA_K, SKA_LEN0, SKA_LEN1, SKA_S, SKA_NEW_DEC, SKA_POPPED, SKA_TOP, SKA_COUNT, SKA_PRESENT,
      SKA_POP_LOOP, SKA_NODE, SKA_STEP, SKA_CURSOR, SKB_INIT_NODE, SKB_NODE_NOW, SKB_K, SKB_LEN0, SKB_S, SKB_NEW_DEC,
      SKB_POPPED, SKB_TOP, SKB_COUNT, SKB_PRESENT, SKB_POP_LOOP, SKB_NODE, SKB_STEP, SKB_CURSOR, SL_ERROR_LOOP,
      L_POPS, LO_SUM, SC_N, A_NODE, A_K, A_LEN, A_S, A_ACC, SCA_NODE, SCA_K, SCA_ACC, SCB_INIT_NODE, SCB_NODE_NOW,
      SCB_K, SCB_LEN0, SCB_S, SCB_NEW_DEC, SCB_POPPED, SCB_TOP, SCB_COUNT, SCB_PRESENT, SCB_NODE, SCB_STEP,
      SCB_CURSOR, M_NODE, M_OWNER, M_OWNER_SLOT, M_EFFECT_SLOT, M_ROW, SM_EFFECTS, SM_OWNERS, SM_OWNER_TOKEN, SM_EFFECT_TOKEN, SM_ROW_TOKEN,
      EF_E, F_I, F_PH, F_ROW, F_RES, F_STAMP, F_SUP, F_NODE, F_K, F_LEN, F_S, F_PUSHED, EF_TOP, F_J, F_JROW, F_JSUP,
      F_PI, F_PJ, EF_FIRST, EF_SECOND, EF_PH, EF_I, EF_J, EF_NODE, EF_K, EF_FIRST_ROW, EF_SECOND_ROW,
      SCHEDULE_MESSAGE, SCHEDULE_TOKEN, SCHEDULE_ARGUMENT0, WS_READER, C_L1, SNAP_TOTAL, SNS_SUM, N_L, O_NODE, O_LOOP;
    boolean SCHED_LIST, SCHED_PAIR, L_EFFECT, L_POSITION, L_PLAIN, SCHEDULE_DUMP, SCHEDULE_RUN, E_IN_ROWS,
      E_IN_CLOCKS, E_IN_DEPS, E_IN_LOOPS, E_SEED, E_MONO, E_LEFT_EDGE, E_RIGHT_EDGE, E_SAMPLE, E_BINARY, E_HAS,
      E_GLOBAL, E_OUTER, E_INNER, E_ROW0, E_MEMBER, E_GATHERS, E_EFFECT, SCHED_OVERFLOW, SCHED_GO, W_KEPT, P_G, P_O,
      P_W, SKO_IN_INIT, SKO_INIT_PRESENT, SKO_INIT_PUSH, SKO_EXPANDING, SKO_COUNTS, SKO_SUCC_PUSH, SKO_POPS, SKO_PUSH,
      SKO_FAILED, SKA_RUN, SKA_IN_INIT, SKA_INIT_PRESENT, SKA_INIT_PUSH, SKA_EXPANDING, SKA_IN_SEG0, SKA_COUNTS,
      SKA_SUCC_PUSH, SKA_POPS, SKA_PUSH, SKB_RUN, SKB_IN_INIT, SKB_INIT_PRESENT, SKB_INIT_PUSH, SKB_EXPANDING,
      SKB_COUNTS, SKB_SUCC_PUSH, SKB_POPS, SKB_PUSH, SKB_FAILED, L_FAILED1, L_FAILED2, SC_OUTER, SC_INNER, SC_RUN,
      A_EXPANDING, A_HIT, SCB_IN_INIT, SCB_INIT_PRESENT, SCB_INIT_PUSH, SCB_EXPANDING, SCB_COUNTS, SCB_SUCC_PUSH,
      SCB_POPS, SCB_PUSH, M_IN, M_OWNS, M_NEW, M_EFFECT, M_OWNER_BETTER, M_EFFECT_BETTER, M_ROW_BETTER,
      EF_RUN, F_ACTIVE, F_START1, F_SKIP, F_TO_PAIRS, F_START2, F_DFS, F_EXPANDING, F_VISITS, F_POPS, F_DFS_ENDS,
      F_PUSH, F_SCAN, F_REACHED, F_SCAN_ENDS, F_PAIRS, F_PAIR_FAILS, F_PAIRS_END, EF_FAILED, SCHEDULE_READY, WS_MARKS,
      O_FIRST_RUN, O_TAKES;
    long SCHEDULE_DUMP_BOUND, M_KEY, M_SELF_KEY, SM_OWNER_KEY, SM_EFFECT_KEY, SM_ROW_KEY, EF_BOUND;
    integer CK_ROUND_LIMIT, OV_NOW, OV_O, OV_SIDE, OV_F_0, OV_F_1, OV_F_2, OV_F_3, OV_F_4, OV_F_5, OV_F_6, OV_F_7, OV_F_8,
      OV_F_9, OV_F_10, OV_F_11, OV_F_12, OV_F_13, OV_F_14, OV_F_15, OV_F_16, OV_F_17, OV_F_18, OV_F_19, OV_F_20,
      OV_FIRST, OV_N, OV_S, OV_DEPTH,
      OV_KIND, OV_NEXT, OV_CAND, OV_LOOK, OV_STAMP, OV_BELOW, OW_COUNT, OW_CLOCKS, OW_STATE, OW_SIDE, OW_O, OW_NODE,
      OW_SLOT, OW_DEPTH;
    boolean OV_STARTS, OV_WALKS, OV_SPLITS, OV_POPS, OV_SLOT_LIVE, OV_APPLIES, OV_PUSHES, OV_ENTERS, OV_FINISHES, OW_DONE;
    long OW_BOUND;
    [CLOCK_CAP] integer OW_STAMP, OW_STACK_NODE, OW_STACK_SLOT;
    [PARSE_CAP] integer OW_INDEX;
    [EMIT_TYPE_CAP] integer XT_KIND, XT_BYTES, XT_ELEMENT, XT_EB;
    [EMIT_TYPE_CAP] boolean XT_SIGNED;
    [EMIT_TYPE_CAP] ulong XT_SIZE, XT_WORDS;
    [ROWS_CAP] integer WIN_A1, WIN_SIGNAL, VI_LIST, OUT_LIST, WIN_P1, DELAY_INDEX, DELAY_LIST, SEED_HEAD1, SEED_NEXT1,
      SEED_TAIL1, SK_KEY, SK_STACK;
    [ROWS_CAP] boolean SIG_ONE, SK_DONE;
    [ROWS_CAP] long PAGES_BEFORE, PAGES_OF;
    [CLOCK_CAP] integer CLK_INDEX, ROOT_POSITION;
    [EMIT_TABLE_CAP] integer TABLE_EB, TABLE_LIVE;
    [EMIT_TABLE_CAP] long TABLE_OFFSET, TABLE_BYTES;
    [UNIT_CAP] integer UNIT_TEMPLATE, UNIT_P, UNIT_LABEL;
    [UNIT_CAP] boolean UNIT_FLAG;
    [MICRO_CAP] integer MO_KIND, MO_FORM, MO_A0, MO_A1, MO_A3, MO_TK, MO_TID;
    [MICRO_CAP] long MO_A2;
    [CODE_CAP] integer CODE_FORM, CODE_OP0, CODE_OP1, CODE_OP3, CODE_TK, CODE_TID;
    [CODE_CAP] long CODE_OP2;
    [CODE_LABEL_CAP] integer LABEL_AT1;
    [DATA_CAP] ubyte DATA_BYTE;
    [PARSE_CAP] integer XT_INDEX, EA_INDEX, EW_INDEX, ER_INDEX, EC_INDEX, ETB_INDEX, SK_INDEX, UN_INDEX, PL_INDEX, EX_INDEX,
      DB_INDEX, CW_INDEX;
    integer XT_TOTAL, XT_NEW_SLOT, XT_OLD_SLOT, XT_ELEMENT_NOW, XT_EB_NOW, EA_SOURCE, EA_ROLE, EA_LEFT, EA_LEFT_OP,
      WIN_A_COUNT, VI_COUNT, EMIT_INPUT_COUNT, OUT_COUNT, EMIT_WINDOWS, EW_SIGNAL, EW_FAIL_SIGNAL, ER_LOOP, ER_TAIL,
      DELAY_COUNT, SEED_TOTAL, CLK_COUNT, EMIT_TABLE_COUNT, ETB_TYPE, ETB_EB, TABLE_LIVE_COUNT, LINE_CAPACITY,
      ITEM_TOTAL, SK_X, SK_ROW, SK_OP, SK_LEFT, SK_LEFT_ROW, SK_OWNER, SK_VALUE, SK_TOP, SK_CURSOR, UN_PH, UN_J, UN_LS,
      UN_K, UN_PHASE_LENGTH, UN_NODE, UN_L, UN_C, UN_SNAP_COUNT, UN_LO_LENGTH, UN_LOOP_ROW, UN_X, TP_ROW, TP_OP,
      TP_TYPE, TP_KIND, TP_LEFT, TP_RIGHT, TP_LEFT_ROW, TP_RIGHT_ROW, TP_LEFT_LEFT, TP_EFFECT, TP_LT, TP_RT,
      TP_SIGNED_BYTES, TP_UNSIGNED_BYTES, TP_TEMPLATE, UN_CLOCK_KIND, UN_BASE_TEMPLATE, UN_TEMPLATE, UN_P, UN_SEED_NEXT, UN_AFTER_SNAPS,
      UN_LS_AFTER, UN_K_AFTER, UN_NEXT_PH, UN_NEXT_J, UN_NEXT_LS, UN_NEXT_K, UN_SLOT, UN_TEMPLATE_ROW, UNIT_COUNT,
      UNIT_LABEL_TOTAL, PL_U, PL_K, PL_T, PL_P, PL_LOCAL, PL_STEP, PL_NEXT_U, PL_NEXT_K, PL_KIND, PL_WHEN,
      PL_SOURCE0, PL_SOURCE1, PL_ROW, PL_CLOCK, PL_LOOP, PL_WINDOW, PL_OP, PL_TYPE, PL_LEFT, PL_RIGHT, PL_LEFT_ROW,
      PL_RIGHT_ROW, PL_OWNER, PL_OWNER_KEY, PL_C1, PL_C2, PL_C3, PL_C4, PL_C5, PL_C6, PL_PARAM_TYPE, PL_ELEMENT,
      PL_INDEX_ELEMENT, PL_LOOP_LEFT, PL_LOOP_LEFT_ROW, PL_COUNT_ROW, PL_INPUT_ROOT1, PL_INPUT_ROOT, PL_FORM_SPEC,
      PL_A0_SPEC, PL_A1_SPEC, PL_A2_SPEC, PL_A3_SPEC, PL_TARGET_SPEC, PL_FORM, PL_A0, PL_A3, PL_TARGET,
      PL_OPERAND_ROW, PL_MICRO, PL_TYPE_OR_KEY, PL_TARGET_KIND, PL_TARGET_ID, PL_CHUNKS, PL_INSTRUCTIONS, PL_SLOT,
      MO_COUNT, EX_M, EX_S, EX_KIND, EX_A0, EX_A1, EX_COUNT, EX_NEXT_M, EX_NEXT_S, EX_CHUNK, EX_TYPE, EX_FORM, EX_OP0,
      EX_OP1, EX_OP3, EX_TK, EX_TID, EX_SLOT, EX_CODE_COUNT, DB_CURSOR, DB_NEXT_TABLE, DB_TABLE, DB_ELEMENT,
      DB_TABLE_SHIFT, DB_AT, DB_TEXT, CODE_COUNT, CW_C, CW_I, CW_COLUMN_LENGTH, CW_NEXT_C, CW_NEXT_I, CW_COLUMN,
      CW_CODE_ROW, CW_SECTION, CW_ITEM, CW_ITEM_WINDOW, CW_ITEM_SIG,
      CW_ITEM_MEM, CW_ITEM_CLK, CW_ITEM_TAIL, CW_ITEM_ALIGNMENT, CW_DIGITS, CW_PREFIX, CW_SHIFT_BYTES, CW_SHIFT_WORD,
      CW_SHIFT_BITS, CW_SPILL_BITS, CW_NEWLINE_AT, CW_NEWLINE_WORD, CW_AT, CW_TOTAL, EMIT_CAPACITY, EMIT_MESSAGE,
      EMIT_ERROR_TOKEN, WRITE_LENGTH;
    boolean CODE_DUMP, EMIT_RUN, XT_NEW, XT_LAST_SIGNED, EA_EVENT, EA_WINDOW, EA_INPUT, EA_VALUE_INPUT, EA_OUTPUT,
      EW_SNAPPED, EW_FAILS, EW_FAILED, ER_DELAY, ER_SEED, EC_LIVE, ETB_NEW, READS_LINE, SK_STARTS, SK_LIVE,
      SK_SNAPSHOT, SK_CHAINS, SK_ALREADY, SK_READY, SK_RESOLVES, SK_PUSHES, EMIT_PREPARED, UNIT_RUN, UN_ORDER,
      UN_IN_PHASE, UN_LOOP_NODE, UN_CLOCK_NODE, UN_ROW_LIKE, TP_L_LOGICAL, TP_R_LOGICAL, TP_BOTH_INT, TP_L_SIGNED,
      TP_R_SIGNED, TP_SIGNED, TP_SKIPS, UN_FLAG, UN_STEPS_LOOP, UN_ADVANCES, UN_EMITS, UNIT_READY, PLAN_RUN, PL_FLAG,
      PL_LAST, PL_ACTIVE, PL_OPERAND, PL_CONSTANT, MICRO_READY, CODE_FITS, CODE_LABELS_FIT, CODE_RUN, EX_NZ1, EX_NZ2,
      EX_NZ3, EX_PLACES, EX_LAST, EX_TABLE_KEY, DATA_FITS, DATA_RUN, DB_IN_TABLE, DB_OLD, DB_IN_SIG, DB_IN_MEM,
      EMIT_READY, CW_RUN, CW_HEADER, CW_NEGATIVE, CW_FITS, CW_OVERFLOW, EMIT_SHORT;
    long EW_PAGES, EW_PAGES_TOTAL, ETB_LENGTH, ETB_OFFSET, ETB_END, WIN_BASE, SIG_BASE, MEM_BASE, CLK_BASE, IN_BASE,
      OUT_BASE, MAL_BASE, RES_BASE, DATA_END, UNIT_BOUND, UNIT_STEP_TOTAL, PL_PARAM, PL_V0, PL_V1, PL_A1, PL_A2,
      PL_VALUE, MO_CODE_TOTAL, MO_PLACE_TOTAL, EXPAND_TOTAL, EX_A2, EX_CHUNK_VALUE, EX_OP2, DB_POSITION, DB_EB, DB_REL,
      DB_VALUE, DB_SIG, DB_MEM, DB_DELAY_VALUE, CW_LINES, CW_TARGET_OFFSET, CW_ITEM_OFFSET, CW_VALUE, CW_NUMBER;
    ulong XT_SIZE_NOW, XT_PER, EW_WORDS, PL_BITS, EX_BITS, CW_MAGNITUDE, CW_D0, CW_D1, CW_D2, CW_D3, CW_D4, CW_D5, CW_D6,
      CW_D7, CW_D8, CW_D9, CW_D10, CW_D11, CW_D12, CW_D13, CW_D14, CW_D15, CW_D16, CW_D17, CW_D18, CW_D19, CW_S0,
      CW_S1, CW_S2, CW_P0, CW_P1, CW_P2, CW_P3, CW_P4, CW_NEWLINE, CW_W0, CW_W1, CW_W2, CW_W3;
    constant integer IMAGE_WORD_CAP = 33554432;
    constant integer PAGE_CAP = 8192;
    [ARG_CAP] integer OUT_PATH_INDEX;
    [ARG_CAP] ubyte OUT_PATH_TEXT;
    [PARSE_CAP] integer RF_INDEX, EN_INDEX, IM_INDEX, SH_INDEX, SG_INDEX, SP_INDEX;
    [CLOCK_CAP] integer ROOT_FIRST;
    [CODE_CAP] integer CODE_SECTION;
    [CODE_CAP] long CODE_TARGET;
    [CODE_CAP] uinteger CODE_WORD;
    [IMAGE_WORD_CAP] uinteger IMAGE_WORD;
    [PAGE_CAP] uinteger PAGE_HASH0, PAGE_HASH1, PAGE_HASH2, PAGE_HASH3, PAGE_HASH4, PAGE_HASH5, PAGE_HASH6, PAGE_HASH7;
    boolean OUT_PATH_ENDED, CE_ROOTS, EN_NEGATIVE, EN_FITS, EN_FIRST_FAIL, IMAGE_TOO_BIG, IMAGE_RUN, EN_FAILED, IMAGE_GO,
      SH_START, SH_END, SH_PAGE_END, SG_IN_HEADER, STAGE_GO, STAGED_OPEN, IMAGE_WRITE_OK, STAGED_MODE_OK, STAGED_CLOSE_OK,
      RENAME_OK, SLICE_OUTPUT_PATH;
    integer OUT_PATH_LENGTH, RF_CLOCK, RF_REP, EN_TK, EN_TID, EN_LABEL_AT, EN_SECTION, EN_TID_ROW, EN_FORM,
      EN_KIND, EN_F, EN_S0, EN_S1, EN_S2, EN_S3, EN_L0, EN_L1, EN_L2, EN_L3, EN_W0, EN_W1, EN_W2, EN_W3,
      EN_A0, EN_A1, EN_A2, EN_A3, EN_TOP2, EN_FAIL_AT, EN_FAIL_FORM, TEXT_BYTES, DATA_BYTES, SIGNED_BYTES, PAGES,
      DIRECTORY_BYTES, SIGNATURE_BYTES, LINKEDIT_BYTES, FILE_BYTES, STAGED_AT, IMAGE_TEXT_AT, TEXT_AT, IM_OFFSET, IM_FIELD,
      IM_CODE, IM_DATA, SH_T, SH_BLOCK, SH_B, SH_P, SG_FIELD, SG_HASH_AT, SG_PAGE, SG_HASH_WORD, SG_SHIFT, STAGED_DIR,
      OUTPUT_ERRNO;
    integer HEADER_BYTES, IM_ELF_FIELD, PL_ROOT_IRQ;
    integer UNLOADED_BYTES, IM_ELF32_FIELD, PL_THUMB_INSTRUCTIONS, EX_BYTES, EX_INDEX_REGISTER, EX_THUMB_COUNT,
      EX_THUMB_CHUNK, EX_ROLE, EX_LOAD_FORM, EX_STORE_FORM, EX_ADDRESS_REGISTER, EX_THUMB_FORM, EX_THUMB_OP0, EX_THUMB_OP1,
      EX_THUMB_OP3, EX_THUMB_TK, EX_THUMB_TID, EN_S4, EN_L4, EN_W4, EN_A4;
    long EX_THUMB_OP2;
    ulong EN_V4, EN_B4;
    boolean PL_PAIR, PL_EXTENDS, PL_INDEXED, EX_PAIR, EX_SIGNED, EX_EXTENDS, EX_INDEXED, EX_AT, EX_DUAL, EX_EXTEND_STEP,
      EX_ABSOLUTE_STEP, EX_MEMORY_STEP, IMAGE_OVER_RAM;
    long TAIL_BYTES, MEMORY_BYTES, IMAGE_BASE;
    boolean RESERVES;
    long TEXT_BASE, DATA_BASE, EN_OFFSET, EN_PC, EN_ADDRESS, EN_OP0, EN_OP1, EN_OP2, EN_OP3, EN_R2_VALUE, EN_FAIL_OP0,
      EN_FAIL_OP1, EN_FAIL_OP2, EN_FAIL_OP3, PID, STAGED_FD, IMAGE_WRITTEN, STAGED_MODE, STAGED_CLOSED, RENAMED, UNLINKED;
    ulong EN_V0, EN_V1, EN_V2, EN_V3, EN_B0, EN_B1, EN_B2, EN_B3, EN_WORD, EN_R0, EN_R1, EN_R2, EN_R3, SP_NIBBLE;
    uinteger IM_HEADER, IM_WORD, SH_LE, SH_M, SH_X1, SH_X14, SH_SMALL0, SH_SMALL1, SH_W, SH_Q0, SH_Q1, SH_Q2, SH_Q3, SH_Q4, SH_Q5, SH_Q6, SH_Q7, SH_Q8, SH_Q9, SH_Q10, SH_Q11, SH_Q12, SH_Q13, SH_Q14, SH_Q15,
      SH_H0_IN, SH_H1_IN, SH_H2_IN, SH_H3_IN, SH_H4_IN, SH_H5_IN, SH_H6_IN, SH_H7_IN, SH_IA, SH_IB, SH_IC, SH_ID, SH_IE, SH_IF, SH_IG, SH_IH, SH_BIG0, SH_BIG1, SH_CH, SH_MAJ, SH_T1,
      SH_VA, SH_VB, SH_VC, SH_VD, SH_VE, SH_VF, SH_VG, SH_VH, SH_H0, SH_H1, SH_H2, SH_H3, SH_H4, SH_H5, SH_H6, SH_H7, SG_HEADER, SG_VALUE;
    ubyte OUT_PATH_BYTE, SP_BYTE, SG_BYTE;
    pointer STAGED_ADDRESS;
    boolean USES_ROWS;
    [ARG_CAP] ubyte SOURCE_NAME, OUTPUT_NAME;
    [PARSE_CAP] integer NP_INDEX, NC_INDEX, UV_INDEX, RS_INDEX;
    boolean BUFFER_OK, NP_OUT, NP_SEPARATOR_SLOT, NP_DOT, NP_IN_NAME, NP_STARTS, NP_FIRST, NP_FINAL, NP_WRITES, NC_OUT, UV_AT_END,
      UV_LIVE, UV_SECOND, UV_CONTINUES, UV_BAD_START, UV_BAD_CONTINUATION, UV_TRUNCATED, UV_FAILS, UTF8_FAILED, TEXT_OK, FALLBACK_OK;
    integer SOURCE_ROOT, OUT_ROOT, SOURCE_SLOTS, NP_K, NP_I, NP_L, NP_ROOT, NP_NAMES_IN, NP_LENGTH_IN, NP_NAMES, NP_LENGTH,
      SOURCE_NAME_LENGTH, OUTPUT_NAME_LENGTH, OUTPUT_NAME_SLASH, NAMES_AT, NC_J, NC_LENGTH, UV_NEED_IN, UV_FAIL_AT, UV_FAIL_END,
      UV_FAIL_REASON, UV_NEED, UV_START;
    ubyte NP_C, NP_P, NP_N, NP_BYTE, NC_BYTE, UV_BYTE, UV_LEAD, UV_LOW, UV_HIGH, RS_BYTE;
    long FALLBACK, RESERVATION_WRITTEN;
    pointer SOURCE_NAME_ADDRESS, OUTPUT_NAME_ADDRESS;
  end;
