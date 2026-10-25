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
   | BUFFER_ADDRESS := syscall{OS}(if USAGE_OK then 197 else 20, 0, OUTPUT_CAP, 3, 4098, -1, 0)
   | SOURCE_FD := syscall{OS}(if USAGE_OK then 5 else 20, ARG1, 0, 0, 0, 0, 0)
   | BUFFER_ADDRESS --> SOURCE_FD
   | OPEN_OK := USAGE_OK and SOURCE_FD >= 0
   | PROBE := syscall{OS}(if OPEN_OK then 3 else 20, SOURCE_FD, BUFFER_ADDRESS, 1, 0, 0, 0)
   | READ_OK := OPEN_OK and PROBE >= 0
   | SIZE := syscall{OS}(if READ_OK then 199 else 20, SOURCE_FD, 0, 2, 0, 0, 0)
   | SIZE_OK := READ_OK and SIZE >= 0
   | SOURCE_FITS := SIZE <= long(SRC_CAP - 4)
   | MAP_WANTED := SIZE_OK and SOURCE_FITS and SIZE > 0
   | MAPPED := syscall{OS}(if MAP_WANTED then 197 else 20, 0, SIZE, 1, 2, SOURCE_FD, 0)
   | MAP_OK := not MAP_WANTED or MAPPED >= 0
   | SOURCE_CLOSED := syscall{OS}(if OPEN_OK then 6 else 20, SOURCE_FD, 0, 0, 0, 0, 0)
   | MAPPED --> SOURCE_CLOSED
   | ERRNO := if not USAGE_OK then 0 else if not OPEN_OK then integer(-SOURCE_FD) else if not READ_OK then integer(-PROBE)
              else if not SIZE_OK then integer(-SIZE) else if not MAP_OK then integer(-MAPPED) else 0
   | SOURCE_OK := USAGE_OK and ERRNO = 0 and SOURCE_FITS
   | LENGTH := integer(SIZE)
   | SOURCE_BASE := pointer(ulong(MAPPED))
   | COPY_INDEX := 0 .. (if SOURCE_OK then LENGTH - 1 else -1)
   | iterate COPY_INDEX of
       (| SOURCE_BYTE := load{FILE, ubyte}(SOURCE_BASE + COPY_INDEX)
        | SRC := SRC[?] next COPY_INDEX : SOURCE_BYTE
        |)
     end
   | LEX_INDEX := 0 .. (if SOURCE_OK then LENGTH + 1 else -1)
   | iterate LEX_INDEX of
       (| AT_EOF := LEX_INDEX = LENGTH
        | AT_END := LEX_INDEX >= LENGTH
        | BYTE := SRC[LEX_INDEX]
        | NEXT_BYTE := SRC[LEX_INDEX + 1]
        | CLASS := CHARACTER_CLASS[BYTE]
        | PREVIOUS_MODE := MODE[?]
        | CONTINUES := not AT_END
            and (PREVIOUS_MODE = MODE_NAME and (CLASS = CLASS_LETTER or CLASS = CLASS_DIGIT)
                 or PREVIOUS_MODE = MODE_NUMBER and CLASS = CLASS_DIGIT
                 or PREVIOUS_MODE = MODE_COMMENT or PREVIOUS_MODE = MODE_STRING or PREVIOUS_MODE = MODE_SYMBOL)
        | STARTS := not CONTINUES
        | SYMBOL_LENGTH := if BYTE = ubyte(45) and NEXT_BYTE = ubyte(45) and SRC[LEX_INDEX + 2] = ubyte(62) then 3
                           else if PAIR_SECOND[BYTE] /= 0 and PAIR_SECOND[BYTE] = NEXT_BYTE
                                   or BYTE = ubyte(58) and NEXT_BYTE = ubyte(61) then 2
                           else if CLASS = CLASS_SYMBOL then 1 else 0
        | OPENED_KIND := if AT_EOF then KIND_EOF else if AT_END then KIND_NONE else OPENED_KIND_OF_CLASS[CLASS]
        | OPENS_TOKEN := STARTS and OPENED_KIND /= KIND_NONE
        | REMAINING := if STARTS then SYMBOL_LENGTH - 1 else REMAINING[?] - 1
        | MODE := if STARTS then (if AT_END then MODE_IDLE else if SYMBOL_LENGTH > 1 then MODE_SYMBOL else MODE_OF_CLASS[CLASS])
                  else if PREVIOUS_MODE = MODE_COMMENT and BYTE = ubyte(37)
                       or PREVIOUS_MODE = MODE_STRING and BYTE = ubyte(34)
                       or PREVIOUS_MODE = MODE_SYMBOL and REMAINING = 0 then MODE_IDLE
                  else PREVIOUS_MODE
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
                   else if OPENS_TOKEN and TOKEN_COUNT[?] >= TOKEN_CAP then ERROR_TOKENS else ERROR_NONE
        | FIRST_FOUND := LEX_ERROR[?] = ERROR_NONE and FOUND /= ERROR_NONE
        | LEX_ERROR := if FIRST_FOUND then FOUND else LEX_ERROR[?]
        | LEX_ERROR_LINE := if not FIRST_FOUND then LEX_ERROR_LINE[?] else if UNCLOSED then OPEN_LINE[?] else LINE[?]
        | LEX_ERROR_COLUMN := if not FIRST_FOUND then LEX_ERROR_COLUMN[?] else if UNCLOSED then OPEN_COLUMN[?] else COLUMN
        | LEX_ERROR_AT := if not FIRST_FOUND then LEX_ERROR_AT[?] else if UNCLOSED then OPEN_AT[?] else LEX_INDEX
        |)
     with (| MODE := MODE_IDLE | REMAINING := 0 | CODE_POINTS := 0 | LINE_START := 0 | LINE := 1
           | OPEN_AT := 0 | OPEN_LINE := 1 | OPEN_COLUMN := 1 | OPEN_KIND := KIND_NONE | PENDING := -1
           | KEY := ulong(0) | NOT_ALL_LETTERS := false | HAS_LOWER := false | HAS_UPPER := false | TOKEN_COUNT := 0
           | LEX_ERROR := ERROR_NONE | LEX_ERROR_LINE := 0 | LEX_ERROR_COLUMN := 0 | LEX_ERROR_AT := 0 |)
     end
   | LEXED := SOURCE_OK and LEX_ERROR = ERROR_NONE and DUMP_PASS /= 1
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
        | TRIE_SLOT := TRIE_PARENT * 64 + NAME_CHAR[FOLDED_BYTE]
        | TRIE_EXISTING := TRIE_CHILD[?][TRIE_SLOT]
        | TRIE_CREATES := NAMEISH and TRIE_EXISTING = 0
        | TRIE_NODE := if not NAMEISH then TRIE_NODE[?] else if TRIE_CREATES then TRIE_NODE_COUNT[?] else TRIE_EXISTING
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
        | SYMBOL_CODE := if CURSOR_LENGTH = 3 then C_ARROW
                         else if CURSOR_LENGTH = 2 then
                           (if NAME_BYTE = ubyte(58) and SRC[SOURCE_AT + 1] = ubyte(61) then C_DEFINE else DOUBLE_SYMBOL[NAME_BYTE])
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
        | SCAN_CLASHES := SCAN_NAME < 17 or NAME_TYPE[?][SCAN_NAME] > 0
        | SCAN_DUPLICATE := VALUE_STAMP[?][SCAN_NAME] = USER_TYPE_COUNT[?] + 1
        | SCAN_FULL := SCAN_PREVIOUS = PRE_SEMICOLON and USER_TYPE_COUNT[?] >= TYPE_CAP - BUILTIN_TYPE_COUNT
                       or SCAN_PREVIOUS = PRE_VALUE and VALUE_COUNT[?] >= VALUE_CAP
        | SCAN_MESSAGE := if SCAN_PREVIOUS = PRE_NAME then
                            (if not SCAN_IS_NAME then T_EXPECTED_NAME
                             else if SCAN_CLASHES then (if SCAN_NAME >= N_LOAD and SCAN_NAME <= N_ISIN then T_RESERVED else T_DECLARED_TWICE) else 0)
                          else if SCAN_PREVIOUS = PRE_EQUAL then (if SCAN_CODE /= C_EQUAL then T_EXPECTED_FOUND else 0)
                          else if SCAN_PREVIOUS = PRE_KIND then
                            (if SCAN_CODE /= C_EXTERNAL and SCAN_CODE /= C_ENUM then T_EXPECTED_FOUND else 0)
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
                        else if SCAN_PREVIOUS = PRE_KIND then (if SCAN_CODE = C_EXTERNAL then PRE_SEMICOLON else PRE_OPEN)
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
        |)
     with (| BRACKET_COUNT := 0 | COLONS_COUNT := 0 | SCAN_STATE := PRE_IDLE | SCAN_TYPE_NAME := 0 | SCAN_TYPE_KIND := 0 | SCAN_VALUE_START := 0 | VALUE_COUNT := 0
           | USER_TYPE_COUNT := 0 | PRESCAN_MESSAGE := 0 | PRESCAN_TOKEN := 0 | PRESCAN_ARGUMENT0 := 0
           | PRESCAN_ARGUMENT1 := 0 |)
     end
   | PARSES := INTERNED and PRESCAN_MESSAGE = 0
   | PARSE_BOUND := long(BUILTIN_TYPE_COUNT + USER_TYPE_COUNT + 16) + long(8) * long(TOKEN_COUNT)
                    + long(BRACKET_COUNT) * long(BRACKET_COUNT) + long(COLONS_COUNT) * long(COLONS_COUNT)
   | PARSE_INDEX := 0 .. (if PARSES then PARSE_BOUND else long(-1))
   | iterate PARSE_INDEX of
       (| HERE := AT[?]
        | STATE_BEFORE := PARSE_STATE[?]
        | CODE0 := integer(TOKEN_CODE[HERE])
        | CODE1 := integer(TOKEN_CODE[HERE + 1])
        | CODE2 := integer(TOKEN_CODE[HERE + 2])
        | NAME0 := TOKEN_NAME[HERE] - 1
        | NAME1 := TOKEN_NAME[HERE + 1] - 1
        | NAME2 := TOKEN_NAME[HERE + 2] - 1
        | MODEL_NOW := CURRENT_MODEL[?]
        | LOOKS_UP := (STATE_BEFORE = P_TYPE_SIZE or STATE_BEFORE = P_DECLARE_NAME or STATE_BEFORE = P_CONSTANT_NAME
                       or STATE_BEFORE = P_LABEL_NAME) and CODE0 = C_NAME
        | LOCAL_TOP := if LOOKS_UP then LOCAL_HEAD[?][NAME0] - 1 else -1
        | LOCAL_TOP_MODEL := LOCAL_MODEL[?][LOCAL_TOP]
        | STALE := LOCAL_TOP >= 0 and MODEL_CLOSED[?][LOCAL_TOP_MODEL]
        | STATE := if STALE then P_STALL else STATE_BEFORE
        | DECLARED := LOCAL_TOP >= 0 and LOCAL_TOP_MODEL = MODEL_NOW or NAME_CONSTANT[?][NAME0] > 0 or NAME_TYPE[NAME0] > 0
                      or NAME_MODEL[?][NAME0] or NAME0 >= N_LOAD and NAME0 <= N_ISIN
        | GLOBALLY_USED := NAME_SIGNAL_EVER[?][NAME0] or NAME_LABEL_EVER[?][NAME0]
        | RESERVED := NAME0 >= N_LOAD and NAME0 <= N_ISIN
        | CLASH_MESSAGE := if RESERVED then T_RESERVED else if NAME_MODEL[?][NAME0] then T_NAME_OF_MODEL else T_DECLARED_TWICE
        | TOKEN_TYPE := if NAME0 >= 0 and NAME0 < BUILTIN_TYPE_COUNT then NAME0 else NAME_TYPE[NAME0] - 1
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
        | COPIED_TYPE := TYPE_COUNT[?]
        | COPIED_USER := COPIED_TYPE - BUILTIN_TYPE_COUNT
        | COPY_IS_BUILTIN := COPIED_TYPE < BUILTIN_TYPE_COUNT
        | COPY_DONE := COPIED_TYPE + 1 >= BUILTIN_TYPE_COUNT + USER_TYPE_COUNT
        | MODEL_NAME_OK := CODE0 = C_NAME
        | MODEL_NAME_CLASHES := NAME_MODEL[?][NAME0] or GLOBALLY_USED or NAME_CONSTANT[?][NAME0] > 0 or NAME_TYPE[NAME0] > 0
                                or NAME0 >= N_LOAD and NAME0 <= N_INSTRUCTION
        | CREATES_MODEL := IN_MODEL_NAME and MODEL_NAME_OK and not MODEL_NAME_CLASHES
        | MODEL_KIND_NOW := MODEL_KIND[?][MODEL_NOW]
        | CLOSES_MODEL := (IN_MODEL_AFTER and CODE0 /= C_WHERE or IN_END_SEMICOLON) and CODE0 = C_SEMICOLON
        | MAKES_STATE_TYPE := CLOSES_MODEL and MODEL_KIND_NOW = C_AUTOMATON
        | PARENT_NOW := MODEL_PARENT[?][MODEL_NOW]
        | TYPE_STATEMENT_CLASHES := GLOBALLY_USED or NAME_CONSTANT[?][NAME0] > 0 or NAME_MODEL[?][NAME0]
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
        | BUCKET_HERE := integer((ulong(TOKEN_TYPE) * ulong(40503) + ARRAY_SIZE[?] * ulong(2654435761)) modulo ulong(BUCKET_CAP))
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
        | APPENDS_LABEL := IN_LABEL_NAME and CODE0 = C_NAME and not DECLARED
        | PUSHES_LOCAL := APPENDS_SIGNAL or APPENDS_LABEL
        | CONSTANT_NAME_MESSAGE := if CODE0 /= C_NAME then T_EXPECTED_NAME
                                   else if DECLARED or GLOBALLY_USED then CLASH_MESSAGE else 0
        | DEFINITION_IS_STRING := CODE0 = C_STRING
        | STRING_BYTES := TOKEN_LENGTH[HERE] - 2
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
                             else if LABEL_FOLLOWS or CODE0 = C_ON then (if IN_LOOP then T_ONLY_DEFINITIONS else 0)
                             else if CODE0 = C_ITERATE then
                               (if IN_LOOP then T_ITERATE_NESTED else if GUARD_NODE[?] >= 0 then T_ITERATE_GUARDED else 0)
                             else 0
        | CREATES_USE := IN_PROCESS and CODE0 /= C_OPEN_BAR and LABEL_FOLLOWS and PROCESS_MESSAGE = 0
        | CREATES_GUARD := IN_GUARD_COLONS and CODE0 = C_COLONS
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
        | STARTS_EXPRESSION := IN_PROCESS and CODE0 = C_ON and PROCESS_MESSAGE = 0
                               or IN_EQUATION and EQUATION_MESSAGE = 0 and FOLLOWER /= C_ARROW
                               or CONTINUES_GROUP
        | LAST_ENTRY := ENTRY_COUNT[?] - 1
        | LAST_IS_CALL := ENTRY_OP[?][LAST_ENTRY] = OP_CALL and LAST_ENTRY >= EXPRESSION_START[?]
        | MAKES_GROUP := TARGET[?] < 0 and (CODE0 = C_CLOCK_EQUAL or not LAST_IS_CALL)
        | EQUATION_END_MESSAGE := if IN_EQUATION_END and MAKES_GROUP and CODE0 /= C_CLOCK_EQUAL then T_EXPECTED_DEFINITION else 0
        | CONTINUES_GROUP := (IN_EQUATION_END and MAKES_GROUP or IN_GROUP_MEMBER) and CODE0 = C_CLOCK_EQUAL
        | APPENDS_EQUATION := IN_EQUATION_END and not MAKES_GROUP
        | APPENDS_MEMBER := IN_EQUATION_END and MAKES_GROUP and CODE0 = C_CLOCK_EQUAL or IN_GROUP_MEMBER
        | APPENDS_GROUP := IN_GROUP_MEMBER and CODE0 /= C_CLOCK_EQUAL
        | IS_STATEMENT := TARGET[?] < 0 and LAST_IS_CALL
                          and (ENTRY_NAME[?][LAST_ENTRY] = N_INITIAL or ENTRY_NAME[?][LAST_ENTRY] = N_TRANSITION)
        | DEPENDENCE_MESSAGE := if CODE0 = C_ARROW then (if CODE1 /= C_NAME then T_ARROW_NAMES else 0)
                                else if CODE0 /= C_BAR and CODE0 /= C_BAR_CLOSE then T_ARROW_NAMES else 0
        | APPENDS_DEPENDENCE := IN_DEPENDENCE and CODE0 = C_ARROW and CODE1 = C_NAME
        | POP_COMPOSE_BREAKS := FRAME_TOP_KIND = FRAME_COMPOSE and CODE0 = C_BAR and CODE1 /= C_BAR_CLOSE
        | POP_ITERATE_SEEDS := FRAME_TOP_KIND = FRAME_ITERATE and not LOOP_SEED[?] and CODE0 = C_WITH
        | POP_MESSAGE := if FRAME_TOP_KIND = FRAME_COMPOSE then
                           (if CODE0 /= C_BAR and CODE0 /= C_BAR_CLOSE then T_EXPECTED_FOUND else 0)
                         else if FRAME_TOP_KIND = FRAME_ITERATE and not POP_ITERATE_SEEDS and CODE0 /= C_END then T_EXPECTED_FOUND
                         else 0
        | POPS_FRAME := IN_POP and not POP_COMPOSE_BREAKS and not POP_ITERATE_SEEDS and POP_MESSAGE = 0
        | PUSHES_FRAME := IN_PROCESS and PROCESS_MESSAGE = 0 and (CODE0 = C_OPEN_BAR or LABEL_FOLLOWS)
                          or CREATES_GUARD or IN_ITERATE_OF and CODE0 = C_OF
        | PUSHED_FRAME_KIND := if IN_PROCESS then (if CODE0 = C_OPEN_BAR then FRAME_COMPOSE else FRAME_LABEL)
                               else if IN_GUARD_COLONS then FRAME_GUARD else FRAME_ITERATE
        | PUSHED_FRAME_VALUE := if IN_PROCESS then USE_COUNT[?] else if IN_GUARD_COLONS then GUARD_COUNT[?] else LOOP_COUNT[?] - 1
        | FRAME_KIND := FRAME_KIND[?] next (if PUSHES_FRAME then FRAME_DEPTH[?] else -1) : PUSHED_FRAME_KIND
        | FRAME_VALUE := FRAME_VALUE[?] next (if PUSHES_FRAME then FRAME_DEPTH[?] else -1) : PUSHED_FRAME_VALUE
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
        | MISSING_MESSAGE := if TOP_OP = OP_IF_MARK then T_EXPECTED_THEN else if TOP_OP = OP_THEN_MARK then T_EXPECTED_ELSE
                             else T_UNBALANCED
        | LITERAL_AT := if IN_OPERATOR then
                          HERE + 2 + integer(integer(TOKEN_CODE[HERE + 2]) = C_MINUS and integer(TOKEN_CODE[HERE + 3]) = C_NUMBER)
                        else HERE
        | LITERAL_CODE := integer(TOKEN_CODE[LITERAL_AT])
        | LITERAL_NEXT_CODE := integer(TOKEN_CODE[LITERAL_AT + 1])
        | LITERAL_NEGATED := IN_OPERATOR and LITERAL_AT = HERE + 3
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
        | CALL_HEAD_HERE := (CODE0 = C_NAME or CODE0 >= C_EVENT and CODE0 <= C_LONG) and (CODE1 = C_OPEN or CODE1 = C_OPEN_BRACE)
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
                             else if OPERAND_CASE = X_FAIL then T_EXPECTED_EXPRESSION else 0
        | BINARY_HERE := BINARY_PRECEDENCE[CODE0]
        | IS_TERMINATOR := CODE0 = C_BAR or CODE0 = C_BAR_CLOSE or CODE0 = C_SEMICOLON or CODE0 = C_CLOCK_EQUAL
                           or CODE0 = C_WITH or CODE0 = C_END or CODE0 = C_COLONS or CODE0 = C_CLOSE
        | OPERATOR_CASE := if BINARY_HERE > 0 then (if TOP_REDUCIBLE and TOP_PRECEDENCE >= BINARY_HERE then X_REDUCE else X_BINARY)
                           else if (CODE0 = C_THEN or CODE0 = C_ELSE) and OPENER_NOW >= 0 then
                             (if TOP_REDUCIBLE then X_REDUCE
                              else if CODE0 = C_THEN then (if TOP_OP = OP_IF_MARK then X_THEN else X_FAIL)
                              else if TOP_OP = OP_THEN_MARK then X_ELSE else X_FAIL)
                           else if CODE0 = C_DOLLAR then (if TOP_REDUCIBLE and TOP_PRECEDENCE > DELAY_PRECEDENCE then X_REDUCE else X_DELAY)
                           else if CODE0 = C_OPEN_BRACKET and CODE1 = C_QUESTION then X_PREVIOUS
                           else if CODE0 = C_OPEN_BRACKET then X_OPEN_SQUARE
                           else if (CODE0 = C_CLOSE or CODE0 = C_CLOSE_BRACKET) and OPENER_NOW >= 0 then
                             (if TOP_REDUCIBLE then X_REDUCE
                              else if TOP_OP = OP_IF_MARK or TOP_OP = OP_THEN_MARK or (TOP_OP = OP_OPEN_SQUARE) /= (CODE0 = C_CLOSE_BRACKET)
                              then X_FAIL else X_CLOSE)
                           else if CODE0 = C_COMMA and OPENER_NOW >= 0 and OPENER_OP = OP_CALL then
                             (if PENDING_TOP /= OPENER_NOW then X_REDUCE else X_COMMA)
                           else if IS_TERMINATOR then
                             (if not HAS_PENDING then X_RETURN else if TOP_IS_OPENER then X_FAIL else X_REDUCE)
                           else X_FAIL
        | DELAY_MESSAGE := if not DELAY_HAS_INIT then 0 else if not LITERAL_IS then T_DELAY_INITIAL else LITERAL_MESSAGE
        | OPERATOR_FAIL_MESSAGE := if (CODE0 = C_THEN or CODE0 = C_ELSE) and OPENER_NOW >= 0
                                      or (CODE0 = C_CLOSE or CODE0 = C_CLOSE_BRACKET) and OPENER_NOW >= 0
                                      or IS_TERMINATOR then MISSING_MESSAGE
                                   else if OPENER_NOW >= 0 and OPENER_OP = OP_IF_MARK then T_EXPECTED_THEN
                                   else if OPENER_NOW >= 0 and OPENER_OP = OP_THEN_MARK then T_EXPECTED_ELSE
                                   else T_EXPECTED_OPERATOR
        | OPERATOR_MESSAGE := if OPERATOR_CASE = X_FAIL then OPERATOR_FAIL_MESSAGE
                              else if OPERATOR_CASE = X_DELAY then DELAY_MESSAGE
                              else if OPERATOR_CASE = X_PREVIOUS and CODE2 /= C_CLOSE_BRACKET then T_EXPECTED_FOUND
                              else 0
        | PARAMETER_MESSAGE := if CODE0 = C_NAME or CODE0 = C_NUMBER or CODE0 >= 1 and CODE0 < C_SYMBOL_BASE then 0
                               else T_STATIC_PARAMETER
        | PARAMETER_CLOSE_MESSAGE := if CODE0 /= C_CLOSE_BRACE or CODE1 /= C_OPEN then T_EXPECTED_FOUND else 0
        | REDUCES := IN_OPERATOR and OPERATOR_CASE = X_REDUCE
        | CLOSES_OPENER := IN_OPERATOR and OPERATOR_CASE = X_CLOSE or IN_OPERAND and OPERAND_CASE = X_EMPTY_CALL
        | PUSHES_PENDING := IN_OPERAND and (OPERAND_CASE = X_CALL or OPERAND_CASE = X_OPEN_PAREN or OPERAND_CASE = X_IF
                                            or OPERAND_CASE = X_PREFIX)
                            or IN_PARAMETER_CLOSE and PARAMETER_CLOSE_MESSAGE = 0
                            or IN_OPERATOR and (OPERATOR_CASE = X_BINARY or OPERATOR_CASE = X_OPEN_SQUARE)
                            or IN_BRANCH
        | UPDATES_PENDING := IN_OPERATOR and (OPERATOR_CASE = X_THEN or OPERATOR_CASE = X_ELSE or OPERATOR_CASE = X_COMMA)
        | POPS_PENDING := REDUCES or CLOSES_OPENER
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
        | PENDING_OPENER_BELOW := PENDING_OPENER_BELOW[?] next (if PUSHES_PENDING then PENDING_DEPTH[?] else -1) : OPENER_NOW
        | PENDING_DEPTH := PENDING_DEPTH[?] + integer(PUSHES_PENDING) - integer(POPS_PENDING)
        | OPENER_TOP := if PUSHES_PENDING and PUSHED_OPENER then PENDING_DEPTH[?]
                        else if CLOSES_OPENER or IN_OPERATOR and OPERATOR_CASE = X_ELSE then PENDING_OPENER_BELOW[?][PENDING_TOP]
                        else OPENER_NOW
        | ENTRY_KIND := if IN_OPERAND then
                          (if OPERAND_CASE = X_EMPTY_CALL then OP_CALL
                           else if OPERAND_CASE = X_LITERAL then (if LITERAL_IS_ENUM then OP_ENUMCONST else OP_CONST)
                           else if OPERAND_CASE = X_SIGNAL then OP_SIGNAL else -1)
                        else if IN_OPERATOR then
                          (if OPERATOR_CASE = X_REDUCE then TOP_OP
                           else if OPERATOR_CASE = X_CLOSE then (if TOP_OP = OP_CALL then OP_CALL else if TOP_OP = OP_OPEN_SQUARE then OP_INDEX else -1)
                           else if OPERATOR_CASE = X_DELAY then OP_DELAY
                           else if OPERATOR_CASE = X_PREVIOUS then OP_PREV else -1)
                        else -1
        | APPENDS_ENTRY := ENTRY_KIND >= 0
        | ENTRY_FROM_TOP := REDUCES or CLOSES_OPENER
        | ENTRY_SLOT := if APPENDS_ENTRY then ENTRY_COUNT[?] else -1
        | ENTRY_OP := ENTRY_OP[?] next ENTRY_SLOT : ENTRY_KIND
        | ENTRY_TOKEN := ENTRY_TOKEN[?] next ENTRY_SLOT : (if ENTRY_FROM_TOP then TOP_TOKEN else HERE)
        | ENTRY_NAME := ENTRY_NAME[?] next ENTRY_SLOT
                        : (if ENTRY_KIND = OP_CALL then TOKEN_NAME[TOP_TOKEN] - 1
                           else if ENTRY_KIND = OP_SIGNAL then NAME0
                           else if ENTRY_KIND = OP_ENUMCONST then integer(LITERAL_VALUE) else -1)
        | ENTRY_VALUE := ENTRY_VALUE[?] next ENTRY_SLOT
                         : (if ENTRY_KIND = OP_CALL then long(PENDING_COUNT[?][PENDING_TOP] + integer(OPERATOR_CASE = X_CLOSE and IN_OPERATOR))
                            else LITERAL_VALUE)
        | ENTRY_TYPE := ENTRY_TYPE[?] next ENTRY_SLOT
                        : (if ENTRY_KIND = OP_DELAY and not DELAY_HAS_INIT then -1 else LITERAL_TYPE)
        | ENTRY_AUX := ENTRY_AUX[?] next ENTRY_SLOT
                       : (if ENTRY_KIND = OP_CALL then PENDING_PARAMETERS[?][PENDING_TOP]
                          else if ENTRY_KIND = OP_DELAY then
                            (if not DELAY_HAS_INIT then INIT_NONE else if LITERAL_IS_ENUM then INIT_ENUMCONST else INIT_CONST)
                          else -1)
        | ENTRY_AUX2 := ENTRY_AUX2[?] next ENTRY_SLOT
                        : (if ENTRY_KIND = OP_CALL then PENDING_PARAMETER_COUNT[?][PENDING_TOP] else LITERAL_AT)
        | ENTRY_SPLIT := ENTRY_SPLIT[?] next ENTRY_SLOT : (if ENTRY_KIND = OP_CALL then PENDING_SPLIT[?][PENDING_TOP] else -1)
        | ENTRY_COUNT := ENTRY_COUNT[?] + integer(APPENDS_ENTRY)
        | COUNTS_INTRINSIC := ENTRY_KIND = OP_CALL and TOKEN_NAME[TOP_TOKEN] - 1 >= N_INITIAL and TOKEN_NAME[TOP_TOKEN] - 1 <= N_ISIN
        | STARTS_BODY := IN_MODEL_BODY and CODE0 = C_OPEN_BAR
        | BODY_INTRINSICS := if STARTS_BODY then 0 else BODY_INTRINSICS[?] + integer(COUNTS_INTRINSIC)
        | BODY_STATEMENTS := if STARTS_BODY then 0 else BODY_STATEMENTS[?] + integer(APPENDS_EQUATION and IS_STATEMENT)
        | BODY_EQUATION_START := if STARTS_BODY then EQUATION_COUNT[?] else BODY_EQUATION_START[?]
        | BODY_GROUP_START := if STARTS_BODY then GROUP_COUNT[?] else BODY_GROUP_START[?]
        | BODY_DEPENDENCE_START := if STARTS_BODY then DEPENDENCE_COUNT[?] else BODY_DEPENDENCE_START[?]
        | BODY_GUARD_START := if STARTS_BODY then GUARD_COUNT[?] else BODY_GUARD_START[?]
        | BODY_USE_START := if STARTS_BODY then USE_COUNT[?] else BODY_USE_START[?]
        | BODY_MEMBER_START := if STARTS_BODY then MEMBER_COUNT[?] else BODY_MEMBER_START[?]
        | MODEL_MESSAGE := if IN_START then (if CODE0 /= C_PROCESS then T_EXPECTED_FOUND else 0)
                           else if IN_MODEL_NAME then (if not MODEL_NAME_OK then T_EXPECTED_NAME else if MODEL_NAME_CLASHES then
                                                         (if RESERVED then T_RESERVED else T_DECLARED_TWICE) else 0)
                           else if IN_MODEL_EQUAL then (if CODE0 /= C_EQUAL then T_EXPECTED_FOUND else 0)
                           else if IN_MODEL_OPEN then (if CODE0 /= C_OPEN then T_EXPECTED_FOUND else 0)
                           else if IN_MODEL_CLOSE then (if CODE0 /= C_CLOSE then T_EXPECTED_FOUND else 0)
                           else if IN_MODEL_BODY then (if CODE0 /= C_OPEN_BAR then T_EXPECTED_FOUND else 0)
                           else if IN_MODEL_AFTER then (if CODE0 /= C_WHERE and CODE0 /= C_SEMICOLON then T_EXPECTED_FOUND else 0)
                           else if IN_END_SEMICOLON then (if CODE0 /= C_SEMICOLON then T_EXPECTED_FOUND else 0)
                           else if IN_END_CHECK then (if CODE0 /= C_EOF then T_UNEXPECTED_AFTER else 0)
                           else if IN_TYPE_STATEMENT then (if TYPE_STATEMENT_CLASHES then CLASH_MESSAGE else 0)
                           else if IN_TYPE_SKIP then (if CODE0 = C_EOF then T_EXPECTED_FOUND else 0)
                           else 0
        | EXPECTED_CODE := if IN_START then C_PROCESS else if IN_MODEL_EQUAL or IN_CONSTANT_EQUAL then C_EQUAL
                           else if IN_MODEL_OPEN then C_OPEN else if IN_MODEL_CLOSE then C_CLOSE
                           else if IN_MODEL_BODY then C_OPEN_BAR else if IN_TYPE_CLOSE then C_CLOSE_BRACKET
                           else if IN_GUARD_COLONS then C_COLONS else if IN_ITERATE_OF then C_OF
                           else if IN_POP then (if FRAME_TOP_KIND = FRAME_COMPOSE then C_BAR_CLOSE else C_END)
                           else if IN_PARAMETER_CLOSE then (if CODE0 /= C_CLOSE_BRACE then C_CLOSE_BRACE else C_OPEN)
                           else if IN_OPERATOR then C_CLOSE_BRACKET
                           else if IN_INTEGER_CONSTANT then C_CLOSE
                           else if IN_CONSTANT_ELEMENT then C_CLOSE_BRACKET
                           else C_SEMICOLON
        | TYPE_MESSAGE := if IN_TYPE_SIZE then (if SIZE_MESSAGE /= 0 then SIZE_MESSAGE else if not SIZE_POSITIVE then T_CAPACITY_POSITIVE else 0)
                          else if IN_TYPE_CLOSE then (if CODE0 /= C_CLOSE_BRACKET then T_EXPECTED_FOUND else 0)
                          else if IN_TYPE_NAME then
                            (if TOKEN_TYPE < 0 then T_EXPECTED_TYPE else if ARRAY_SIZE[?] /= ulong(0) and TOKEN_TYPE = BUILTIN_EVENT then T_EVENT_ARRAYS else 0)
                          else 0
        | SEPARATOR_MESSAGE := if CODE0 /= C_COMMA and CODE0 /= C_SEMICOLON then T_EXPECTED_FOUND else 0
        | STATEMENT_MESSAGE := if IN_DECLARE_NAME then DECLARE_MESSAGE
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
                          else if IN_EQUATION then EQUATION_MESSAGE
                          else if IN_DEPENDENCE then DEPENDENCE_MESSAGE
                          else if IN_EQUATION_END then EQUATION_END_MESSAGE
                          else if IN_POP then POP_MESSAGE
                          else if IN_OPERAND then OPERAND_MESSAGE
                          else if IN_PARAMETER then PARAMETER_MESSAGE
                          else if IN_PARAMETER_CLOSE then PARAMETER_CLOSE_MESSAGE
                          else if IN_OPERATOR then OPERATOR_MESSAGE
                          else 0
        | FULL_TABLE := if CREATES_MODEL and MODEL_COUNT[?] >= MODEL_CAP then F_CAP_MODELS
                        else if (IN_COPY_TYPES or CREATES_ARRAY_TYPE or MAKES_STATE_TYPE) and TYPE_COUNT[?] >= TYPE_CAP then F_CAP_TYPES
                        else if APPENDS_SIGNAL and SIGNAL_COUNT[?] >= SIGNAL_CAP then F_CAP_SIGNALS
                        else if PUSHES_LOCAL and LOCAL_COUNT[?] >= LOCAL_CAP then F_CAP_LOCALS
                        else if STORES_CONSTANT and CONSTANT_COUNT[?] >= CONSTANT_CAP then F_CAP_CONSTANTS
                        else if (STORES_TABLE and TABLE_COUNT[?] >= TABLE_CAP or APPENDS_POOL and POOL_COUNT[?] >= POOL_CAP) then F_CAP_TABLES
                        else if (APPENDS_LABEL and LABEL_COUNT[?] >= LABEL_CAP or CREATES_USE and USE_COUNT[?] >= LABEL_CAP) then F_CAP_LABELS
                        else if CREATES_GUARD and GUARD_COUNT[?] >= GUARD_CAP then F_CAP_GUARDS
                        else if IN_ITERATE_NAME and LOOP_COUNT[?] >= LOOP_CAP then F_CAP_LOOPS
                        else if APPENDS_EQUATION and EQUATION_COUNT[?] >= EQUATION_CAP then F_CAP_EQUATIONS
                        else if APPENDS_ENTRY and ENTRY_COUNT[?] >= ENTRY_CAP then F_CAP_ENTRIES
                        else if (APPENDS_GROUP and GROUP_COUNT[?] >= GROUP_CAP or APPENDS_MEMBER and MEMBER_COUNT[?] >= MEMBER_CAP) then F_CAP_GROUPS
                        else if APPENDS_DEPENDENCE and DEPENDENCE_COUNT[?] >= DEPENDENCE_CAP then F_CAP_DEPENDENCES
                        else if (PUSHES_FRAME and FRAME_DEPTH[?] >= STACK_CAP or PUSHES_PENDING and PENDING_DEPTH[?] >= STACK_CAP) then F_CAP_STACK
                        else if IN_PATH_COPY and PATH_COUNT[?] >= PATH_CAP then F_CAP_PATHS
                        else 0
        | STEP_MESSAGE := if STATE = P_STALL then 0
                          else if FULL_TABLE /= 0 then T_CAPACITY
                          else if MODEL_MESSAGE /= 0 then MODEL_MESSAGE
                          else if TYPE_MESSAGE /= 0 then TYPE_MESSAGE
                          else if STATEMENT_MESSAGE /= 0 then STATEMENT_MESSAGE
                          else BODY_MESSAGE
        | STEP_TOKEN := if IN_OPERAND and OPERAND_CASE = X_LITERAL or IN_OPERATOR and OPERATOR_CASE = X_DELAY and DELAY_HAS_INIT and LITERAL_IS
                        then LITERAL_MESSAGE_TOKEN
                        else if IN_OPERATOR and OPERATOR_CASE = X_DELAY then LITERAL_AT
                        else if IN_OPERATOR and OPERATOR_CASE = X_PREVIOUS then HERE + 2
                        else if IN_DEPENDENCE and CODE0 = C_ARROW then HERE + 1
                        else if IN_PARAMETER_CLOSE and CODE0 = C_CLOSE_BRACE then HERE + 1
                        else if IN_INTEGER_CONSTANT then INTEGER_CONSTANT_TOKEN
                        else if IN_CONSTANT_DEFINITION or IN_CONSTANT_ELEMENT and STEP_MESSAGE /= T_EXPECTED_FOUND or IN_CONSTANT_SCALAR
                        then DECLARE_TOKEN[?]
                        else HERE
        | STEP_ARGUMENT0 := if STEP_MESSAGE = T_CAPACITY then FULL_TABLE
                            else if STEP_MESSAGE = T_EXPECTED_FOUND then EXPECTED_CODE
                            else if STEP_MESSAGE = T_DECLARED_TWICE then
                              (if IN_MODEL_NAME then F_ROLE_MODEL else if IN_TYPE_STATEMENT then F_ROLE_TYPE
                               else if IN_CONSTANT_NAME then F_ROLE_CONSTANT else if IN_LABEL_NAME then F_ROLE_LABEL else F_ROLE_SIGNAL)
                            else if STEP_MESSAGE = T_EXTERNAL_SIGNAL then DECLARED_BASE
                            else if STEP_MESSAGE = T_CONSTANT_STRING or STEP_MESSAGE = T_CONSTANT_LIST or STEP_MESSAGE = T_CONSTANT_ELEMENT
                                    or STEP_MESSAGE = T_CONSTANT_TYPE or STEP_MESSAGE = T_CONSTANT_COUNT then DECLARE_NAME[?]
                            else if STEP_MESSAGE = T_RESERVED or STEP_MESSAGE = T_NAME_OF_MODEL or STEP_MESSAGE = T_CONSTANT_UNDECLARED
                                    or STEP_MESSAGE = T_INPUT_SCALAR or STEP_MESSAGE = T_OUTPUT_ARRAY then NAME0
                            else STEP_TOKEN
        | STEP_ARGUMENT1 := if STEP_MESSAGE = T_EXPECTED_FOUND then STEP_TOKEN
                            else if STEP_MESSAGE = T_DECLARED_TWICE then NAME0
                            else DECLARED_TYPE
        | STEP_ARGUMENT2 := if STEP_MESSAGE = T_CONSTANT_COUNT then (if IN_CONSTANT_DEFINITION then STRING_BYTES else ELEMENT_COUNT)
                            else VALUE_TYPE
        | FAILS := STEP_MESSAGE /= 0
        | GO := not FAILS
        | NEXT_AT := if not GO then HERE
                     else if IN_START or IN_MODEL_NAME or IN_MODEL_EQUAL or IN_MODEL_OPEN or IN_MODEL_CLOSE or IN_END_SEMICOLON
                             or IN_TYPE_STATEMENT or IN_TYPE_SKIP or IN_TYPE_CLOSE or IN_TYPE_NAME or IN_DECLARE_NAME
                             or IN_DECLARE_SEPARATOR or IN_CONSTANT_NAME or IN_CONSTANT_EQUAL or IN_CONSTANT_SEPARATOR
                             or IN_LABEL_NAME or IN_LABEL_SEPARATOR or IN_GUARD_COLONS or IN_ITERATE_NAME or IN_ITERATE_OF
                     then HERE + 1
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
                       (if CODE0 = C_OPEN_BAR or CODE0 = C_ON or CODE0 = C_ITERATE then HERE + 1 else if LABEL_FOLLOWS then HERE + 2 else HERE)
                     else if IN_EQUATION then (if FOLLOWER = C_ARROW then HERE + 1 else if FOLLOWER = C_DEFINE then HERE + 2 else HERE)
                     else if IN_DEPENDENCE then HERE + 2 * integer(CODE0 = C_ARROW)
                     else if IN_EQUATION_END or IN_GROUP_MEMBER then HERE + integer(CONTINUES_GROUP)
                     else if IN_POP then
                       (if FRAME_TOP_KIND = FRAME_COMPOSE then (if POP_COMPOSE_BREAKS or CODE0 = C_BAR_CLOSE then HERE + 1 else HERE + 2)
                        else if FRAME_TOP_KIND = FRAME_ITERATE then HERE + 1 else HERE)
                     else if IN_OPERAND then
                       (if OPERAND_CASE = X_LITERAL then LITERAL_END
                        else if OPERAND_CASE = X_CALL or OPERAND_CASE = X_PARAMETERS then HERE + 2 else HERE + 1)
                     else if IN_PARAMETER then HERE + 1 + integer(CODE1 = C_COMMA)
                     else if IN_PARAMETER_CLOSE then HERE + 2
                     else if IN_OPERATOR then
                       (if OPERATOR_CASE = X_REDUCE or OPERATOR_CASE = X_RETURN then HERE
                        else if OPERATOR_CASE = X_DELAY then (if DELAY_HAS_INIT then LITERAL_END else HERE + 1)
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
                        else if IN_MODEL_BODY then P_PROCESS
                        else if IN_MODEL_AFTER or IN_END_SEMICOLON then
                          (if IN_MODEL_AFTER and CODE0 = C_WHERE then P_PROGRAM else if PARENT_NOW < 0 then P_END_CHECK else P_PROGRAM)
                        else if IN_PROGRAM then
                          (if MODEL_CLASS[CODE0] = 1 then P_MODEL_NAME else if CODE0 = C_END then P_END_SEMICOLON
                           else if CODE0 = C_TYPE then P_TYPE_STATEMENT else if CODE0 = C_LABEL then P_LABEL_NAME else P_TYPE)
                        else if IN_END_CHECK then P_DONE
                        else if IN_TYPE_STATEMENT then P_TYPE_SKIP
                        else if IN_TYPE_SKIP then (if CODE0 = C_SEMICOLON then P_PROGRAM else P_TYPE_SKIP)
                        else if IN_TYPE then (if CODE0 = C_OPEN_BRACKET then P_TYPE_SIZE else P_TYPE_NAME)
                        else if IN_TYPE_SIZE then P_TYPE_CLOSE
                        else if IN_TYPE_CLOSE then P_TYPE_NAME
                        else if TYPE_FINISHED then RETURN_STATE[?]
                        else if IN_TYPE_NAME or IN_TYPE_INTERN then P_TYPE_INTERN
                        else if IN_DECLARE_NAME then P_DECLARE_SEPARATOR
                        else if IN_DECLARE_SEPARATOR then
                          (if CODE0 = C_COMMA then P_DECLARE_NAME else if ROLE[?] = ROLE_INPUT then P_INPUTS
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
                          (if CODE0 = C_OPEN_BAR then P_PROCESS else if LABEL_FOLLOWS then P_PATH_COPY
                           else if CODE0 = C_ON then P_OPERAND else if CODE0 = C_ITERATE then P_ITERATE_NAME else P_EQUATION)
                        else if IN_PATH_COPY then (if PATH_LEFT[?] > 0 then P_PATH_COPY else P_PROCESS)
                        else if IN_GUARD_COLONS then P_PATH_COPY
                        else if IN_ITERATE_NAME then P_ITERATE_OF
                        else if IN_ITERATE_OF then P_PROCESS
                        else if IN_EQUATION then (if FOLLOWER = C_ARROW then P_DEPENDENCE else P_OPERAND)
                        else if IN_DEPENDENCE then (if CODE0 = C_ARROW then P_DEPENDENCE else P_POP)
                        else if IN_EQUATION_END or IN_GROUP_MEMBER then (if CONTINUES_GROUP then P_OPERAND else P_POP)
                        else if IN_POP then
                          (if POP_COMPOSE_BREAKS or POP_ITERATE_SEEDS then P_PROCESS
                           else if FRAME_DEPTH[?] = 1 then P_MODEL_AFTER else P_POP)
                        else if IN_OPERAND then
                          (if OPERAND_CASE = X_EMPTY_CALL or OPERAND_CASE = X_LITERAL or OPERAND_CASE = X_SIGNAL then P_OPERATOR
                           else if OPERAND_CASE = X_PARAMETERS then P_PARAMETER else P_OPERAND)
                        else if IN_PARAMETER then (if CODE1 = C_COMMA then P_PARAMETER else P_PARAMETER_CLOSE)
                        else if IN_PARAMETER_CLOSE then P_OPERAND
                        else if IN_OPERATOR then
                          (if OPERATOR_CASE = X_RETURN then EXPRESSION_RETURN[?]
                           else if OPERATOR_CASE = X_ELSE then P_BRANCH
                           else if OPERATOR_CASE = X_BINARY or OPERATOR_CASE = X_THEN or OPERATOR_CASE = X_OPEN_SQUARE
                                   or OPERATOR_CASE = X_COMMA then P_OPERAND
                           else P_OPERATOR)
                        else if IN_BRANCH then P_OPERAND
                        else STATE_BEFORE
        | PARSE_STATE := NEXT_STATE
        | RETURN_STATE := if IN_INPUTS or IN_OUTPUTS or IN_PROGRAM and CODE0 /= C_CONSTANT then P_DECLARE_NAME
                          else if IN_PROGRAM then P_CONSTANT_NAME else RETURN_STATE[?]
        | ROLE := if IN_MODEL_QUESTION then ROLE_INPUT else if IN_MODEL_BANG then ROLE_OUTPUT else if IN_PROGRAM then ROLE_LOCAL else ROLE[?]
        | PENDING_MODEL_KIND := if IN_START then C_PROCESS else if IN_PROGRAM then CODE0 else PENDING_MODEL_KIND[?]
        | ARRAY_SIZE := if IN_TYPE then ulong(0) else if IN_TYPE_SIZE then ulong(SIZE_VALUE) else ARRAY_SIZE[?]
        | ARRAY_BUCKET := if IN_TYPE_NAME then BUCKET_HERE else ARRAY_BUCKET[?]
        | CANDIDATE := if IN_TYPE_NAME then ARRAY_HEAD[?][BUCKET_HERE] - 1
                       else if IN_TYPE_INTERN then ARRAY_NEXT[?][INTERN_CANDIDATE] - 1 else CANDIDATE[?]
        | ARRAY_ELEMENT := if IN_TYPE_NAME then TOKEN_TYPE else ARRAY_ELEMENT[?]
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
        | GUARD_START_TOKEN := if IN_PROCESS and CODE0 = C_ON then HERE else GUARD_START_TOKEN[?]
        | EXPRESSION_START := if STARTS_EXPRESSION then ENTRY_COUNT[?] else EXPRESSION_START[?]
        | EXPRESSION_RETURN := if not STARTS_EXPRESSION then EXPRESSION_RETURN[?]
                               else if IN_PROCESS then P_GUARD_COLONS else if IN_EQUATION then P_EQUATION_END else P_GROUP_MEMBER
        | TARGET := if IN_EQUATION then (if FOLLOWER = C_DEFINE then NAME0 else -1) else TARGET[?]
        | EQUATION_TOKEN := if IN_EQUATION then HERE else EQUATION_TOKEN[?]
        | DEPENDENCE_PREVIOUS := if IN_EQUATION then HERE else if APPENDS_DEPENDENCE then HERE + 1 else DEPENDENCE_PREVIOUS[?]
        | GROUP_MEMBER_START := if IN_EQUATION_END then MEMBER_COUNT[?] else GROUP_MEMBER_START[?]
        | CALL_HEAD := if IN_OPERAND then HERE else CALL_HEAD[?]
        | PARAMETER_START := if IN_OPERAND then HERE + 2 else PARAMETER_START[?]
        | PARAMETER_COUNT := if IN_OPERAND then 0 else if IN_PARAMETER then PARAMETER_COUNT[?] + 1 else PARAMETER_COUNT[?]
        | CURRENT_MODEL := if CREATES_MODEL then MODEL_COUNT[?] else if CLOSES_MODEL then PARENT_NOW else MODEL_NOW
        | TYPE_SLOT := if GO and (IN_COPY_TYPES or CREATES_ARRAY_TYPE or MAKES_STATE_TYPE) then TYPE_COUNT[?] else -1
        | TYPE_KIND := TYPE_KIND[?] next TYPE_SLOT
                       : (if IN_COPY_TYPES then (if COPY_IS_BUILTIN then BUILTIN_KIND[COPIED_TYPE] else USER_TYPE_KIND[COPIED_USER])
                          else if CREATES_ARRAY_TYPE then TK_ARRAY else TK_ENUM)
        | TYPE_BYTES := TYPE_BYTES[?] next TYPE_SLOT
                        : (if IN_COPY_TYPES then
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
        | LOCAL_HEAD := LOCAL_HEAD[?] next (if STALE then NAME0 else if LOCAL_SLOT >= 0 then NAME0 else -1)
                        : (if STALE then LOCAL_PREVIOUS[?][LOCAL_TOP] else LOCAL_COUNT[?] + 1)
        | LOCAL_COUNT := LOCAL_COUNT[?] + integer(LOCAL_SLOT >= 0)
        | SIGNAL_SLOT := if GO and APPENDS_SIGNAL then SIGNAL_COUNT[?] else -1
        | SIGNAL_NAME := SIGNAL_NAME[?] next SIGNAL_SLOT : NAME0
        | SIGNAL_ROLE := SIGNAL_ROLE[?] next SIGNAL_SLOT : ROLE[?]
        | SIGNAL_TYPE := SIGNAL_TYPE[?] next SIGNAL_SLOT : DECLARED_TYPE
        | SIGNAL_MODEL := SIGNAL_MODEL[?] next SIGNAL_SLOT : MODEL_NOW
        | SIGNAL_TOKEN := SIGNAL_TOKEN[?] next SIGNAL_SLOT : HERE
        | NAME_SIGNAL_EVER := NAME_SIGNAL_EVER[?] next (if SIGNAL_SLOT >= 0 then NAME0 else -1) : true
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
        | TABLE_START := TABLE_START[?] next TABLE_SLOT : (if STORES_STRING then TOKEN_START[HERE] + 1 else LIST_START[?])
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
        | LOOP_SLOT := if GO and IN_ITERATE_NAME then LOOP_COUNT[?] else -1
        | LOOP_NAME := LOOP_NAME[?] next LOOP_SLOT : NAME0
        | LOOP_TOKEN := LOOP_TOKEN[?] next LOOP_SLOT : HERE
        | LOOP_MODEL := LOOP_MODEL[?] next LOOP_SLOT : MODEL_NOW
        | LOOP_COUNT := LOOP_COUNT[?] + integer(LOOP_SLOT >= 0)
        | EQUATION_SLOT := if GO and APPENDS_EQUATION then EQUATION_COUNT[?] else -1
        | EQUATION_TARGET := EQUATION_TARGET[?] next EQUATION_SLOT : TARGET[?]
        | EQUATION_ENTRY_START := EQUATION_ENTRY_START[?] next EQUATION_SLOT : EXPRESSION_START[?]
        | EQUATION_ENTRY_COUNT := EQUATION_ENTRY_COUNT[?] next EQUATION_SLOT : ENTRY_COUNT[?] - EXPRESSION_START[?]
        | EQUATION_POSITION := EQUATION_POSITION[?] next EQUATION_SLOT : EQUATION_TOKEN[?]
        | EQUATION_LOOP := EQUATION_LOOP[?] next EQUATION_SLOT : LOOP_NOW[?]
        | EQUATION_SEED := EQUATION_SEED[?] next EQUATION_SLOT : LOOP_SEED[?] and LOOP_NOW[?] >= 0
        | EQUATION_MODEL := EQUATION_MODEL[?] next EQUATION_SLOT : MODEL_NOW
        | EQUATION_LABELS := EQUATION_LABELS[?] next EQUATION_SLOT : LABEL_NODE[?]
        | EQUATION_GUARDS := EQUATION_GUARDS[?] next EQUATION_SLOT : GUARD_NODE[?]
        | EQUATION_STATEMENT := EQUATION_STATEMENT[?] next EQUATION_SLOT : IS_STATEMENT
        | EQUATION_COUNT := EQUATION_COUNT[?] + integer(EQUATION_SLOT >= 0)
        | MEMBER_SLOT := if GO and APPENDS_MEMBER then MEMBER_COUNT[?] else -1
        | MEMBER_ENTRY_START := MEMBER_ENTRY_START[?] next MEMBER_SLOT : EXPRESSION_START[?]
        | MEMBER_ENTRY_COUNT := MEMBER_ENTRY_COUNT[?] next MEMBER_SLOT : ENTRY_COUNT[?] - EXPRESSION_START[?]
        | MEMBER_COUNT := MEMBER_COUNT[?] + integer(MEMBER_SLOT >= 0)
        | GROUP_SLOT := if GO and APPENDS_GROUP then GROUP_COUNT[?] else -1
        | GROUP_POSITION := GROUP_POSITION[?] next GROUP_SLOT : EQUATION_TOKEN[?]
        | GROUP_MODEL := GROUP_MODEL[?] next GROUP_SLOT : MODEL_NOW
        | GROUP_GUARDS := GROUP_GUARDS[?] next GROUP_SLOT : GUARD_NODE[?]
        | GROUP_MEMBER_FIRST := GROUP_MEMBER_FIRST[?] next GROUP_SLOT : GROUP_MEMBER_START[?]
        | GROUP_MEMBER_TOTAL := GROUP_MEMBER_TOTAL[?] next GROUP_SLOT : MEMBER_COUNT[?] + 1 - GROUP_MEMBER_START[?]
        | GROUP_COUNT := GROUP_COUNT[?] + integer(GROUP_SLOT >= 0)
        | DEPENDENCE_SLOT := if GO and APPENDS_DEPENDENCE then DEPENDENCE_COUNT[?] else -1
        | DEPENDENCE_FROM_NAME := DEPENDENCE_FROM_NAME[?] next DEPENDENCE_SLOT : TOKEN_NAME[DEPENDENCE_PREVIOUS[?]] - 1
        | DEPENDENCE_FROM_TOKEN := DEPENDENCE_FROM_TOKEN[?] next DEPENDENCE_SLOT : DEPENDENCE_PREVIOUS[?]
        | DEPENDENCE_TO_NAME := DEPENDENCE_TO_NAME[?] next DEPENDENCE_SLOT : NAME1
        | DEPENDENCE_TO_TOKEN := DEPENDENCE_TO_TOKEN[?] next DEPENDENCE_SLOT : HERE + 1
        | DEPENDENCE_POSITION := DEPENDENCE_POSITION[?] next DEPENDENCE_SLOT : EQUATION_TOKEN[?]
        | DEPENDENCE_MODEL := DEPENDENCE_MODEL[?] next DEPENDENCE_SLOT : MODEL_NOW
        | DEPENDENCE_GUARDS := DEPENDENCE_GUARDS[?] next DEPENDENCE_SLOT : GUARD_NODE[?]
        | DEPENDENCE_COUNT := DEPENDENCE_COUNT[?] + integer(DEPENDENCE_SLOT >= 0)
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
           | TARGET := -1 | EQUATION_TOKEN := 0 | DEPENDENCE_PREVIOUS := 0 | GROUP_MEMBER_START := 0 | CALL_HEAD := 0
           | PARAMETER_START := 0 | PARAMETER_COUNT := 0 | PATH_FROM := 0 | PATH_LEFT := 0 | PATH_APPEND := 0
           | PATH_COUNT := 0 | FRAME_DEPTH := 0 | PENDING_DEPTH := 0 | OPENER_TOP := -1 | ENTRY_COUNT := 0
           | BODY_INTRINSICS := 0 | BODY_STATEMENTS := 0 | BODY_EQUATION_START := 0 | BODY_GROUP_START := 0
           | BODY_DEPENDENCE_START := 0 | BODY_GUARD_START := 0 | BODY_USE_START := 0 | BODY_MEMBER_START := 0 | GUARD_DEPTH_MAX := 0
           | TYPE_COUNT := 0 | MODEL_COUNT := 0
           | CLOSED_COUNT := 0 | LOCAL_COUNT := 0 | SIGNAL_COUNT := 0 | LABEL_COUNT := 0 | CONSTANT_COUNT := 0
           | TABLE_COUNT := 0 | POOL_COUNT := 0 | USE_COUNT := 0 | GUARD_COUNT := 0 | LOOP_COUNT := 0 | EQUATION_COUNT := 0
           | MEMBER_COUNT := 0 | GROUP_COUNT := 0 | DEPENDENCE_COUNT := 0 | PARSE_MESSAGE := 0 | PARSE_TOKEN := 0
           | PARSE_ARGUMENT0 := 0 | PARSE_ARGUMENT1 := 0 | PARSE_ARGUMENT2 := 0 |)
     end
   | FINISH_BOUND := long(64) + long(24) * long(MODEL_COUNT) + long(LABEL_COUNT) + long(2) * long(USE_COUNT)
                     + long(4) * long(SIGNAL_COUNT) + long(16) * long(EQUATION_COUNT) + long(2) * long(MEMBER_COUNT)
                     + long(16) * long(GUARD_COUNT) + long(6) * long(ENTRY_COUNT) + long(2) * long(DEPENDENCE_COUNT)
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
        | RW_ENTRY := RW_AT[?]
        | RW_EXTENSION := RW_ENTRY - RW_REAL_END
        | RW_IS_EXTENSION := PHASE = PHASE_REWRITE_TRIGGER and RW_EXTENSION >= 0
        | RW_OP := ENTRY_OP[RW_ENTRY]
        | RW_NAME := ENTRY_NAME[RW_ENTRY]
        | RW_INTRINSIC := not RW_IS_EXTENSION and RW_OP = OP_CALL and RW_NAME >= N_INITIAL and RW_NAME <= N_ISIN
        | RW_ARGUMENTS := integer(ENTRY_VALUE[RW_ENTRY])
        | RW_PREVIOUS_NAME := ENTRY_NAME[RW_ENTRY - 1]
        | RW_NEXT_IS_ISIN := AUTOMATON_NOW and RW_ENTRY + 1 < RW_REAL_END and ENTRY_OP[RW_ENTRY + 1] = OP_CALL
                             and ENTRY_NAME[RW_ENTRY + 1] = N_ISIN
        | RW_MESSAGE := if not RW_INTRINSIC or STEP /= 0 then 0
                        else if not AUTOMATON_NOW then T_ONLY_AUTOMATON
                        else if RW_NAME /= N_ISIN then T_NO_OUTPUT
                        else if PHASE = PHASE_REWRITE_EQ and EQUATION_TARGET[WORK_ROW] < 0 and RW_ENTRY = RW_LAST[?] - 1 then T_HAS_OUTPUT
                        else if RW_ARGUMENTS /= 1 then T_WRONG_ARGUMENTS
                        else if RW_ENTRY = RW_ITEM_FIRST[?] or ENTRY_OP[RW_ENTRY - 1] /= OP_SIGNAL then T_EXPECTS_STATE
                        else if STATE_STAMP[?][RW_PREVIOUS_NAME] /= MODEL_STAMP then T_NOT_STATE
                        else 0
        | RW_ENTRY_DONE := not RW_INTRINSIC or STEP = 1
        | RW_ITEM_DONE := RW_ENTRY_DONE and RW_ENTRY + 1 >= RW_LAST[?]
        | RW_EMITS := AT_REWRITE and STEP >= 0
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
                       (if RW_IS_EXTENSION then (if RW_EXTENSION = 0 then OP_SIGNAL else OP_WHEN)
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
                         (if RW_IS_EXTENSION then N_ON_MARK + TRANSITION_GUARD[?][WORK_ROW] * NAME_CAP
                          else if RW_NEXT_IS_ISIN then N_STATE_MARK else RW_NAME)
                       else if AT_CLOCK then SIGNAL_NAME[WORK_ROW]
                       else if AT_STATE then N_CURRENT_MARK
                       else if AT_CUR or AT_CUR_TAIL then N_STATE_MARK
                       else if AT_GROUP then (if STEP = 0 then N_CURRENT_MARK else N_CLOCK_MARK)
                       else if STEP = 0 then FILTER_KEY else N_ON_MARK + GUARD_SUFFIX
        | EMIT_TOKEN := if COPIES_FINAL then FINAL_TOKEN[?][COPY_SOURCE]
                        else if AT_REWRITE then
                          (if RW_IS_EXTENSION then TRANSITION_TOKEN[?][WORK_ROW]
                           else if RW_NEXT_IS_ISIN then ENTRY_TOKEN[RW_ENTRY + 1] else ENTRY_TOKEN[RW_ENTRY])
                        else if AT_CUR then CUR_TOKEN
                        else if AT_FILTER then GUARD_AT
                        else MODEL_AT
        | EMIT_VALUE := if COPIES_FINAL then FINAL_VALUE[?][COPY_SOURCE]
                        else if AT_REWRITE then (if RW_INTRINSIC then long(STATE_ORDINAL[?][RW_PREVIOUS_NAME]) else ENTRY_VALUE[RW_ENTRY])
                        else if AT_STATE then long(INITIAL_ORDINAL[?])
                        else if AT_CUR then long(if STEP = 0 then TRANSITION_TARGET[?][WORK_ROW] else TRANSITION_SOURCE[?][WORK_ROW])
                        else long(0)
        | EMIT_TYPE := if COPIES_FINAL then FINAL_TYPE[?][COPY_SOURCE]
                       else if AT_REWRITE then (if RW_INTRINSIC then STATE_TYPE_NOW else ENTRY_TYPE[RW_ENTRY])
                       else STATE_TYPE_NOW
        | EMIT_AUX := if COPIES_FINAL then FINAL_AUX[?][COPY_SOURCE]
                      else if AT_REWRITE then (if RW_INTRINSIC or RW_IS_EXTENSION then -1 else ENTRY_AUX[RW_ENTRY])
                      else if AT_STATE then INIT_CONST
                      else -1
        | EMIT_AUX2 := if COPIES_FINAL then FINAL_AUX2[?][COPY_SOURCE]
                       else if AT_REWRITE then (if RW_INTRINSIC or RW_IS_EXTENSION then 0 else ENTRY_AUX2[RW_ENTRY])
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
        | WRITES_ROWS := CLOCK_ROWS or STATE_ROWS or CUR_ROWS or ON_ROWS or FILTER_ROWS
        | ROW_KEY := if CLOCK_ROWS then N_CLOCK_MARK else if STATE_ROWS then N_STATE_MARK else if CUR_ROWS then N_CURRENT_MARK
                     else if ON_ROWS then N_ON_MARK + GUARD_SUFFIX else FILTER_KEY + GUARD_SUFFIX
        | ROW_TYPE := if CLOCK_ROWS or ON_ROWS then BUILTIN_EVENT else if FILTER_ROWS then OWN_TYPE[?][FILTER_KEY] else STATE_TYPE_NOW
        | ROW_TOKEN := if ON_ROWS or FILTER_ROWS then GUARD_AT else MODEL_AT
        | FULL := EMITS and FINAL_COUNT[?] >= FINAL_CAP
                  or WRITES_ROWS and (FINISH_SIGNAL_COUNT[?] >= SIGNAL_CAP or FINISH_EQUATION_COUNT[?] >= EQUATION_CAP)
                  or AT_GROUP and STEP = 2 and FINISH_GROUP_COUNT[?] >= GROUP_CAP
                  or NEW_INPUT and INPUT_COUNT[?] >= SIGNAL_CAP
                  or REGISTERS_STATE and STATE_COUNT[?] >= SIGNAL_CAP
                  or RECORDS_TRANSITION and TRANSITION_COUNT[?] >= EQUATION_CAP
        | STEP_FINISH_MESSAGE := if PHASE = PHASE_DONE or PHASE = PHASE_FAILED then 0
                                 else if FULL then T_CAPACITY
                                 else if AT_USE and not USES_DONE and USE_UNDECLARED then T_LABEL_UNDECLARED
                                 else if AT_SIGNAL and SIGNALS_DONE and AUTOMATON_NOW and MODEL_INPUTS[MODEL_HERE] = 0 then T_NO_INPUT
                                 else if AT_STATEMENT and STATEMENTS_DONE and not HAS_INITIAL[?] then T_ONE_INITIAL
                                 else if AT_STATEMENT then AUTOMATON_STATEMENT_MESSAGE
                                 else if AT_REWRITE and STEP >= 0 then RW_MESSAGE
                                 else 0
        | FINISH_FAILS := STEP_FINISH_MESSAGE /= 0
        | FINISH_STEP_TOKEN := if FULL then MODEL_AT
                               else if AT_USE then USE_TOKEN[WORK_ROW]
                               else if AT_STATEMENT and not STATEMENTS_DONE then
                                 (if AUTOMATON_STATEMENT_MESSAGE = T_NOT_LABEL_OF then ST_STATE_TOKEN else ST_TOKEN)
                               else if AT_REWRITE then (if RW_MESSAGE = T_NOT_STATE then ENTRY_TOKEN[RW_ENTRY - 1] else ENTRY_TOKEN[RW_ENTRY])
                               else MODEL_AT
        | FINISH_STEP_ARGUMENT0 := if FULL then F_CAP_FINISH
                                   else if AT_USE then USE_NAME[WORK_ROW]
                                   else if STEP_FINISH_MESSAGE = T_NO_INPUT or STEP_FINISH_MESSAGE = T_ONE_INITIAL then MODEL_KEY
                                   else if STEP_FINISH_MESSAGE = T_LABEL_PLACED then USE_NAME[EQUATION_LABELS[WORK_ROW]]
                                   else if STEP_FINISH_MESSAGE = T_NOT_LABEL_OF then ST_STATE
                                   else if AT_STATEMENT then ST_NAME
                                   else if STEP_FINISH_MESSAGE = T_NOT_STATE then RW_PREVIOUS_NAME
                                   else RW_NAME
        | FINISH_STEP_ARGUMENT1 := if STEP_FINISH_MESSAGE = T_WRONG_ARGUMENTS then (if AT_STATEMENT then ST_EXPECTED else 1)
                                   else if STEP_FINISH_MESSAGE = T_LABEL_PLACED then ST_NAME
                                   else MODEL_KEY
        | FINISH_STEP_ARGUMENT2 := if AT_STATEMENT then ST_ARGUMENTS else RW_ARGUMENTS
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
                        else if AT_SIGNAL then (if not SIGNALS_DONE then PHASE_SIGNAL else if AUTOMATON_NOW then PHASE_STATEMENT else PHASE_REWRITE_EQ)
                        else if AT_STATEMENT then (if STATEMENTS_DONE then PHASE_REWRITE_EQ else PHASE_STATEMENT)
                        else if RW_PHASE_DONE then
                          (if PHASE = PHASE_REWRITE_EQ then PHASE_REWRITE_MEMBER else if PHASE = PHASE_REWRITE_MEMBER then PHASE_REWRITE_GUARD
                           else if PHASE = PHASE_REWRITE_GUARD then (if AUTOMATON_NOW then PHASE_REWRITE_TRIGGER else PHASE_GUARD_START)
                           else PHASE_CLOCK)
                        else if AT_REWRITE then PHASE
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
                       else if NEXT_PHASE = PHASE_SIGNAL or NEXT_PHASE = PHASE_CLOCK then MODEL_FIRST_SIGNAL[MODEL_HERE] - 1
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
                      else if AT_USE then WORK_ROW + 1
                      else if AT_SIGNAL then SIGNAL_NEXT[WORK_ROW] - 1
                      else if AT_STATEMENT then (if ST_IS_STATEMENT and STEP = 0 and not ST_INITIAL then WORK_ROW else WORK_ROW + 1)
                      else if AT_REWRITE then
                        (if RW_HEADER then (if RW_ITEM_COUNT = 0 then WORK_ROW + 1 else WORK_ROW) else if RW_ITEM_DONE then WORK_ROW + 1 else WORK_ROW)
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
                         else if RW_ITEM_DONE then -1 else if RW_ENTRY_DONE then 0 else 1)
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
                   else if AT_REWRITE then (if RW_ENTRY_DONE then RW_ENTRY + 1 else RW_ENTRY)
                   else if AT_CUR and STEP = 4 then TRANSITION_FINAL_START[?][WORK_ROW]
                   else if AT_CUR and STEP = 5 then RW_AT[?] + 1
                   else if READ_HEADER then READ_START
                   else if AT_READ then RW_AT[?] + 1
                   else if ON_HEADER then GUARD_FINAL_START[?][GUARD_NOW]
                   else if ON_COPYING then RW_AT[?] + 1
                   else RW_AT[?]
        | RW_LAST := if RW_HEADER then RW_ITEM_START + RW_ITEM_COUNT
                     else if AT_CUR and STEP = 4 then TRANSITION_FINAL_END[?][WORK_ROW]
                     else if READ_HEADER then READ_END
                     else if ON_HEADER then GUARD_FINAL_END[?][GUARD_NOW]
                     else RW_LAST[?]
        | RW_ITEM_FIRST := if RW_HEADER then RW_ITEM_START else RW_ITEM_FIRST[?]
        | ITEM_BEGIN := if RW_HEADER or ON_HEADER or AT_GROUP and STEP = 0 or AT_FILTER and STEP = 0
                           or NEXT_PHASE /= PHASE and (NEXT_PHASE = PHASE_CLOCK or NEXT_PHASE = PHASE_STATE or NEXT_PHASE = PHASE_CUR)
                        then FINAL_COUNT[?] else ITEM_BEGIN[?]
        | ITEM_ENDS := AT_REWRITE and (RW_HEADER and RW_ITEM_COUNT = 0 or not RW_HEADER and RW_ITEM_DONE and GOES)
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
        | FINISH_SIGNAL_SLOT := if WRITES_ROWS and GOES then FINISH_SIGNAL_COUNT[?] else -1
        | FINISH_SIGNAL_NAME := FINISH_SIGNAL_NAME[?] next FINISH_SIGNAL_SLOT : ROW_KEY
        | FINISH_SIGNAL_TYPE := FINISH_SIGNAL_TYPE[?] next FINISH_SIGNAL_SLOT : ROW_TYPE
        | FINISH_SIGNAL_MODEL := FINISH_SIGNAL_MODEL[?] next FINISH_SIGNAL_SLOT : MODEL_HERE
        | FINISH_SIGNAL_TOKEN := FINISH_SIGNAL_TOKEN[?] next FINISH_SIGNAL_SLOT : ROW_TOKEN
        | FINISH_SIGNAL_COUNT := FINISH_SIGNAL_COUNT[?] + integer(FINISH_SIGNAL_SLOT >= 0)
        | FINISH_EQUATION_SLOT := if WRITES_ROWS and GOES then FINISH_EQUATION_COUNT[?] else -1
        | FINISH_EQUATION_TARGET := FINISH_EQUATION_TARGET[?] next FINISH_EQUATION_SLOT : ROW_KEY
        | FINISH_EQUATION_FINAL_START := FINISH_EQUATION_FINAL_START[?] next FINISH_EQUATION_SLOT : ITEM_BEGIN[?]
        | FINISH_EQUATION_FINAL_END := FINISH_EQUATION_FINAL_END[?] next FINISH_EQUATION_SLOT : FINAL_COUNT[?]
        | FINISH_EQUATION_TOKEN := FINISH_EQUATION_TOKEN[?] next FINISH_EQUATION_SLOT : ROW_TOKEN
        | FINISH_EQUATION_MODEL := FINISH_EQUATION_MODEL[?] next FINISH_EQUATION_SLOT : MODEL_HERE
        | FINISH_EQUATION_LABELS := FINISH_EQUATION_LABELS[?] next FINISH_EQUATION_SLOT
                                    : (if ON_ROWS or FILTER_ROWS then GUARD_LABELS[GUARD_NOW] else -1)
        | FINISH_EQUATION_GUARDS := FINISH_EQUATION_GUARDS[?] next FINISH_EQUATION_SLOT
                                    : (if ON_ROWS or FILTER_ROWS then GUARD_CONTEXT[GUARD_NOW] else -1)
        | FINISH_EQUATION_COUNT := FINISH_EQUATION_COUNT[?] + integer(FINISH_EQUATION_SLOT >= 0)
        | FINISH_GROUP_SLOT := if AT_GROUP and STEP = 2 and GOES then FINISH_GROUP_COUNT[?] else -1
        | FINISH_GROUP_MODEL := FINISH_GROUP_MODEL[?] next FINISH_GROUP_SLOT : MODEL_HERE
        | FINISH_GROUP_FINAL := FINISH_GROUP_FINAL[?] next FINISH_GROUP_SLOT : ITEM_BEGIN[?]
        | FINISH_GROUP_COUNT := FINISH_GROUP_COUNT[?] + integer(FINISH_GROUP_SLOT >= 0)
        | FINISH_MODEL_ORDINAL := if AT_GUARD_START and GUARD_NUMBER[?] = 0 then CLOSE_RANK + 1 else CLOSE_RANK
        |)
     with (| FINISH_PHASE := PHASE_START | FINISH_MODEL_ORDINAL := 0 | FINISH_ROW := 0 | FINISH_SUB := 0 | GUARD_NUMBER := 0
           | FINAL_COUNT := 0 | RW_AT := 0 | RW_LAST := 0 | RW_ITEM_FIRST := 0 | ITEM_BEGIN := 0 | STATE_COUNT := 0
           | HAS_INITIAL := false | INITIAL_ORDINAL := 0 | TRANSITION_SOURCE_HELD := 0 | TRANSITION_FIRST := 0
           | TRANSITION_COUNT := 0 | SYNTH_COUNT := 0 | GUARD_STAMP := 0 | CHAIN_START := 0 | GUARD_INPUT_START := 0
           | INPUT_COUNT := 0 | FINISH_SIGNAL_COUNT := 0 | FINISH_EQUATION_COUNT := 0 | FINISH_GROUP_COUNT := 0
           | FINISH_MESSAGE := 0 | FINISH_TOKEN := 0 | FINISH_ARGUMENT0 := 0 | FINISH_ARGUMENT1 := 0 | FINISH_ARGUMENT2 := 0 |)
     end
   | SOURCE_TOO_BIG := USAGE_OK and ERRNO = 0 and not SOURCE_FITS
   | ERROR := if SOURCE_TOO_BIG then ERROR_SRC else LEX_ERROR
   | ERROR_LEAD := SRC[LEX_ERROR_AT]
   | ERROR_MULTIBYTE := ERROR_LEAD >= ubyte(192)
   | ERROR_FIRST_CONTINUES := ERROR_MULTIBYTE and SRC[LEX_ERROR_AT + 1] >= ubyte(128) and SRC[LEX_ERROR_AT + 1] < ubyte(192)
   | ERROR_SECOND_CONTINUES := ERROR_FIRST_CONTINUES and SRC[LEX_ERROR_AT + 2] >= ubyte(128) and SRC[LEX_ERROR_AT + 2] < ubyte(192)
   | ERROR_THIRD_CONTINUES := ERROR_SECOND_CONTINUES and SRC[LEX_ERROR_AT + 3] >= ubyte(128) and SRC[LEX_ERROR_AT + 3] < ubyte(192)
   | ERROR_CHARACTER_LENGTH := 1 + integer(ERROR_FIRST_CONTINUES) + integer(ERROR_SECOND_CONTINUES) + integer(ERROR_THIRD_CONTINUES)
   | FINISHES := PARSES and CLOSED_COUNT > 0
   | FINISH_FAILED := FINISHES and FINISH_MESSAGE /= 0
   | FINISH_INCOMPLETE := FINISHES and not FINISH_FAILED and FINISH_PHASE /= PHASE_DONE
   | PARSE_FAILED := PARSES and PARSE_MESSAGE /= 0
   | PARSE_INCOMPLETE := PARSES and not PARSE_FAILED and PARSE_STATE /= P_DONE
   | PASS_MESSAGE := if ERROR = ERROR_UNEXPECTED then T_UNEXPECTED_CHARACTER else if ERROR /= ERROR_NONE then T_CAPACITY
                else if not SOURCE_OK then 0 else if INTERN_ERROR_TOKEN >= 0 then T_CAPACITY
                else if PRESCAN_MESSAGE /= 0 then PRESCAN_MESSAGE else if FINISH_FAILED then FINISH_MESSAGE
                else if FINISH_INCOMPLETE then T_CAPACITY else if PARSE_FAILED then PARSE_MESSAGE
                else if PARSE_INCOMPLETE then T_CAPACITY else 0
   | MESSAGE_TOKEN := if INTERN_ERROR_TOKEN >= 0 then INTERN_ERROR_TOKEN else if PRESCAN_MESSAGE /= 0 then PRESCAN_TOKEN
                      else if FINISH_FAILED then FINISH_TOKEN else if PARSE_FAILED then PARSE_TOKEN
                      else if INSTANTIATE_FAILED then INSTANTIATE_TOKEN else if LOWER_FAILED then LW_TOKEN
                      else if POST_FAILED then PO_TOKEN else 0
   | MESSAGE_LINE := if SOURCE_TOO_BIG or MESSAGE_TOKEN < 0 then 1 else if ERROR /= ERROR_NONE then LEX_ERROR_LINE
                     else TOKEN_LINE[MESSAGE_TOKEN]
   | MESSAGE_COLUMN := if SOURCE_TOO_BIG or MESSAGE_TOKEN < 0 then 1 else if ERROR /= ERROR_NONE then LEX_ERROR_COLUMN
                       else TOKEN_COLUMN[MESSAGE_TOKEN]
   | PASS_ARGUMENT0 := if ERROR = ERROR_UNEXPECTED then LEX_ERROR_AT else if ERROR = ERROR_SRC then F_CAP_SRC
                          else if ERROR = ERROR_TOKENS then F_CAP_TOKENS else if INTERN_ERROR_TOKEN >= 0 then F_CAP_NAMES
                          else if PRESCAN_MESSAGE /= 0 then PRESCAN_ARGUMENT0 else if FINISH_FAILED then FINISH_ARGUMENT0
                          else if FINISH_INCOMPLETE then F_CAP_FINISH else if PARSE_FAILED then PARSE_ARGUMENT0
                          else if PARSE_INCOMPLETE then F_CAP_PARSE else if INSTANTIATE_FAILED then INSTANTIATE_ARGUMENT0
                          else if INSTANTIATE_INCOMPLETE then F_CAP_INSTANTIATE else if LOWER_FAILED then LW_ARGUMENT0
                          else if POST_FAILED then PO_ARGUMENT0 else if EXPAND_FAILED then F_CAP_ROW_DEPENDENCES
                          else F_CAP_LOWER
   | MESSAGE_ARGUMENT1 := if PRESCAN_MESSAGE /= 0 then PRESCAN_ARGUMENT1 else if FINISH_FAILED then FINISH_ARGUMENT1
                          else if PARSE_FAILED then PARSE_ARGUMENT1 else if LOWER_FAILED then LW_ARGUMENT1
                          else INSTANTIATE_ARGUMENT1
   | MESSAGE_ARGUMENT2 := if FINISH_FAILED then FINISH_ARGUMENT2 else if PARSE_FAILED then PARSE_ARGUMENT2
                          else if LOWER_FAILED then LW_ARGUMENT2 else INSTANTIATE_ARGUMENT2
   | MESSAGE_INSTANCE := if LOWER_FAILED then LW_INSTANCE else PO_INSTANCE
   | INSTANTIATES := (DUMP_PASS = 0 or DUMP_PASS = 3 or DUMP_PASS = 4) and FINISHES and PASS_MESSAGE = 0
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
        | CALLS_TYPE := E_NAME < BUILTIN_TYPE_COUNT or NAME_TYPE[E_NAME] > 0 or E_NAME = N_INDICES
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
                           else if LOOP_FAILS or TARGET_FAILS then CHECK_KEY else E_NAME
        | FAULT_ARGUMENT1 := if FAULT_MESSAGE = T_UNSAFE_CALL then MODEL_KIND[PURE_MODEL]
                           else if FAULT_MESSAGE = T_TOO_MANY_OUTPUTS then CALLEE_OUTPUTS
                           else if BUILTIN_LIVE then BUILTIN_INPUTS else CALLEE_INPUTS
        | FAULT_ARGUMENT2 := if FAULT_MESSAGE = T_UNSAFE_CALL then MODEL_NAME[PURE_MODEL] else E_COUNT
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
   | DUMP_RUNS := DUMP_PASS = 2 and FINISHES and PASS_MESSAGE = 0 or DUMP_PASS = 3 and FLAT_READY or ROWS_DUMP and ROWS_READY
   | FLAT_DUMP := DUMP_PASS = 3
   | ROWS_DUMP := DUMP_PASS = 4
   | LOWERS := FLAT_READY and (DUMP_PASS = 0 or DUMP_PASS = 4)
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
        | LW_ENUM_NAMED_TYPE := if LW_ENUM_TYPE_KEY < BUILTIN_TYPE_COUNT then LW_ENUM_TYPE_KEY else NAME_TYPE[LW_ENUM_TYPE_KEY] - 1
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
        | LK_B := if LW_SIGNAL_LIVE then long(FLAT_SIGNAL_INSTANCE[LW_I]) * long(8)
                  else if LW_LABEL_LIVE then long(FLAT_LABEL_INSTANCE[LW_I]) * long(8) + long(1 + integer(FLAT_LABEL_CALL[LW_I]))
                  else if LW_VALUE_LIVE then long(LW_I) * long(8) + long(2)
                  else if LW_ARRAY_LIVE then long(TYPE_ELEMENT[LW_I]) * long(8) + long(4)
                  else if LW_LOOP_LIVE then long(FLAT_LOOP_INSTANCE[LW_I]) * long(8)
                  else if LW_LOOKS_PAIR then (long(LW_PAIR_KEY_INSTANCE) * long(65536) + long(LW_PAIR_KEY_LOOP)) * long(8) + long(3)
                  else if LW_LOOKS_GUARD then long(LW_GUARD_INSTANCE) * long(8)
                  else if LW_EQ_STEP = 0 then long(LW_EQ_TARGET_INSTANCE) * long(8)
                  else if LW_LOOKS_SIGNAL then long(LW_INST) * long(8)
                  else if LW_ENUM_LIVE then long(LW_ENUM_TYPE) * long(8) + long(2)
                  else long(LW_ARRAY_ELEMENT) * long(8) + long(4)
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
        | FX_TYPE0 := if FX_KEY0 < 0 then -1 else if FX_KEY0 < BUILTIN_TYPE_COUNT then FX_KEY0 else NAME_TYPE[FX_KEY0] - 1
        | FX_TYPE1 := if FX_KEY1 < 0 then -1 else if FX_KEY1 < BUILTIN_TYPE_COUNT then FX_KEY1 else NAME_TYPE[FX_KEY1] - 1
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
        | FX_MESSAGE := if FX_PARAMS /= FX_EXPECTED then T_STATIC_COUNT
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
        | LW_CALL_TYPE := if LW_NAME < BUILTIN_TYPE_COUNT then LW_NAME else NAME_TYPE[LW_NAME] - 1
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
                                    else if LW_IS_NEXT and not LUB_SUBTYPE then T_NEXT_TYPE else 0)
                                 else if LW_OP = OP_DELAY and LW_ARRAY_OPERAND then T_DELAY_ARRAY
                                 else if LW_ARRAY_OPERAND and LW_OP /= OP_CALL then T_SCALAR_OPERANDS
                                 else if LW_OP = OP_PAIR then 0
                                 else if LW_OP = OP_BRANCH then (if LUB < 0 then T_IF_TYPES else 0)
                                 else if LW_OP = OP_IF then
                                   (if not LT_LOGICAL then T_IF_CONDITION else if LW_IF_EFFECT >= 0 then T_EFFECT_IN_IF else 0)
                                 else if LW_OP = OP_CALL then (if LW_CONVERTS then 0 else T_NO_CONVERSION)
                                 else if LW_POINTER_ARITHMETIC then
                                   (if LT /= BUILTIN_POINTER or not RT_INT then T_POINTER_OFFSET else 0)
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
                                 else if LW_OP = OP_CLOCK then 0
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
        | LW_OPERATOR_ARGUMENT0 := if LW_OPERATOR_MESSAGE = T_PREV_OUTSIDE or LW_OPERATOR_MESSAGE = T_PREV_UNDEFINED
                                   then LW_SIGNAL_KEY[?][LW_LEFT]
                                   else if LW_OPERATOR_MESSAGE = T_NEXT_TYPE then LT_ELEMENT
                                   else if LW_OPERATOR_MESSAGE = T_IF_TYPES or LW_OPERATOR_MESSAGE = T_NO_CONVERSION then LT
                                   else if LW_OPERATOR_MESSAGE = T_EFFECT_IN_IF then EFFECT_KIND[?][integer(ROWS_VALUE[?][LW_IF_EFFECT])]
                                   else if LW_OPERATOR_MESSAGE = LW_ENUM_MESSAGE then LW_ENUM_ARGUMENT0
                                   else LW_OP_TEXT
        | LW_OPERATOR_ARGUMENT1 := if LW_OPERATOR_MESSAGE = T_NEXT_TYPE or LW_OPERATOR_MESSAGE = T_IF_TYPES then RT
                                   else if LW_OPERATOR_MESSAGE = T_NO_CONVERSION then LW_CALL_TYPE
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
           | NEW_TYPE_COUNT := 0 | NEW_TABLE_COUNT := 0 | LW_MESSAGE := 0 | LW_TOKEN := 0 | LW_ARGUMENT0 := 0
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
                    long(PO_END_INSTANCE) * long(8) + (if PO_LOOKS_LABEL then long(1 + integer(PO_END_SIGNAL >= 0)) else long(0))
                  else long(PO_WALK_INSTANCE) * long(8) + long(1 + integer(PO_WALK_CALL))
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
   | MERGE_BOUND := long(SIGNAL_COUNT) + long(FINISH_SIGNAL_COUNT) + long(EQUATION_COUNT) + long(FINISH_EQUATION_COUNT)
                    + long(GROUP_COUNT) + long(FINISH_GROUP_COUNT) + long(3) * long(CLOSED_COUNT) + long(LABEL_COUNT)
                    + long(MODEL_COUNT) + long(USE_COUNT) + long(TABLE_COUNT) + long(8)
   | MERGE_INDEX := 0 .. (if DUMP_RUNS and not ROWS_DUMP then MERGE_BOUND else long(-1))
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
                        + long(8) * long(FLAT_LOOP_COUNT) + long(FLAT_SIGNAL_COUNT)
   | DUMP_BOUND := if ROWS_DUMP then ROWS_DUMP_BOUND else if FLAT_DUMP then FLAT_DUMP_BOUND else PROGRAM_DUMP_BOUND
   | DUMP_COLUMN_END := if ROWS_DUMP then COLUMN_TOTAL else COLUMN_COUNT
   | DUMP_INDEX := 0 .. (if DUMP_RUNS then DUMP_BOUND else long(-1))
   | iterate DUMP_INDEX of
       (| WALK_COLUMN_NOW := WALK_COLUMN[?]
        | WALK_ROW_NOW := WALK_ROW[?]
        | WALK_REL := WALK_POSITION[?]
        | WALK_INNER := WALK_INNER_POSITION[?]
        | WALK_STEP := WALK_STEP_POSITION[?]
        | WALK_MEMBER_STEP := WALK_MEMBER_POSITION[?]
        | WALKING := WALK_COLUMN_NOW < DUMP_COLUMN_END
        | COL := WALK_COLUMN_NOW
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
        | ROWS_COLUMN_ROWS := if COL <= COL_ROWS_GUARD then ROW_COUNT
                              else if COL <= COL_ROWS_GROUP_POSITIONS then FLAT_GROUP_COUNT
                              else if COL <= COL_ROWS_DEPENDENCE_TO then DEPENDENCE_TOTAL
                              else if COL = COL_ROWS_WAR then WAR_COUNT
                              else if COL = COL_ROWS_SNAPSHOTTED or COL = COL_LOOPS_SNAPSHOTS then 0
                              else if COL <= COL_ROWS_EFFECTS_PARAM then EFFECT_COUNT
                              else FLAT_LOOP_COUNT
        | COLUMN_ROWS := if ROWS_DUMP then ROWS_COLUMN_ROWS else if FLAT_DUMP then FLAT_COLUMN_ROWS else if COL = COL_NAME then 1
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
        | ROW_NUMBER_VALUE := if ROWS_DUMP then ROWS_NUMBER_VALUE
                              else if COL = COL_TYPES_BYTES then long(TYPE_BYTES[R])
                              else if COL = COL_TYPES_SIGNED then long(integer(TYPE_SIGNED[R]))
                              else if COL = COL_TYPES_ELEMENT then long(TYPE_ELEMENT[R])
                              else if COL = COL_TYPES_SIZE then long(TYPE_SIZE[R])
                              else if COL = COL_MODELS_PARENT then long(MODEL_PARENT[R])
                              else if COL = COL_MODELS_LINE then long(TOKEN_LINE[MODEL_TOKEN[R]])
                              else if COL = COL_MODELS_COLUMN then long(TOKEN_COLUMN[MODEL_TOKEN[R]])
                              else if COL = COL_SIGNAL_TYPES then
                                long(if SIGNAL_FINISHED then FINISH_SIGNAL_TYPE[SIGNAL_FINISH_ROW] else SIGNAL_TYPE[SIGNAL_SOURCE])
                              else if COL = COL_SIGNAL_MODELS then
                                long(if SIGNAL_FINISHED then FINISH_SIGNAL_MODEL[SIGNAL_FINISH_ROW] else SIGNAL_MODEL[SIGNAL_SOURCE])
                              else if COL = COL_CONSTANT_TYPES then long(CONSTANT_TYPE[R])
                              else if COL = COL_CONSTANT_VALUES then CONSTANT_VALUE[R]
                              else if COL = COL_TABLE_TYPES then long(TABLE_TYPE[R])
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
        | ROW_UNSIGNED := if ROWS_DUMP then COL = COL_LOOPS_SIZE or COL = COL_ROWS_VALUE and ROWS_TYPE[R] = BUILTIN_ULONG
                          else COL = COL_TYPES_SIZE or COL = COL_CONSTANT_VALUES and CONSTANT_TYPE[R] = BUILTIN_ULONG
        | ROW_FRAGMENT := if COL = COL_ROWS_OP then OP_FRAGMENT[ROWS_OP[R]]
                          else if COL = COL_TYPES_KIND then TYPE_KIND_FRAGMENT[TYPE_KIND[R]]
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
        | ROW_IS_ARRAY := TYPE_KIND[R] = TK_ARRAY
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
                       else if COL = COL_ROWS_WAR then 0
                       else if COL = COL_LOOPS_DEFINED then LOOP_DEF_START[R]
                       else if COL = COL_TYPES_VALUES then TYPE_VALUE_START[R]
                       else if COL = COL_MODELS_LABELS then MODEL_LABEL_OFFSET[R]
                       else if COL = COL_TABLE_VALUES then TABLE_START[R]
                       else if LIST_KIND = LIST_OPS or LIST_KIND = LIST_ARGS then ENTRY_RUN_START
                       else PATH_FIRST
        | RUN_LENGTH := if COL = COL_ROWS_GROUPS then FLAT_GROUP_MEMBER_TOTAL[R]
                        else if COL = COL_ROWS_WAR then 3
                        else if COL = COL_LOOPS_DEFINED then LOOP_DEF_TOTAL[R]
                        else if COL = COL_TYPES_VALUES then TYPE_VALUE_COUNT[R]
                        else if COL = COL_MODELS_LABELS then MODEL_LABEL_END[R] - MODEL_LABEL_OFFSET[R]
                        else if COL = COL_TABLE_VALUES then TABLE_LENGTH[R]
                        else if LIST_KIND = LIST_OPS or LIST_KIND = LIST_ARGS then ENTRY_RUN_END - ENTRY_RUN_START
                        else INHERITED_LENGTH + PATH_SIZE
        | LIST_AT := RUN_START + WALK_REL - INHERITED_LENGTH
        | NODE_ON_KEY := N_ON_MARK + (PATH_VALUE[LIST_AT] - MODEL_GUARD_START[GUARD_MODEL[PATH_VALUE[LIST_AT]]] + 1) * NAME_CAP
        | LIST_VALUE := if COL = COL_ROWS_GROUPS then long(GROUP_MEMBER_ROW[LIST_AT])
                        else if COL = COL_ROWS_WAR then
                          long(if WALK_REL = 0 then WAR_READER[R] else if WALK_REL = 1 then WAR_WRITER[R] else WAR_SIGNAL[R])
                        else if COL = COL_LOOPS_DEFINED then long(DEFINED_LIST[LIST_AT])
                        else if COL = COL_TYPES_VALUES then long(VALUE_NAME[LIST_AT])
                        else if COL = COL_MODELS_LABELS then long(LABEL_ORDERED_NAME[LIST_AT])
                        else if COL = COL_TABLE_VALUES then (if TABLE_FROM_STRING[R] then long(SRC[LIST_AT]) else POOL_VALUE[LIST_AT])
                        else if FROM_INHERITED_PATH then long(FLAT_PATH_KEY[INHERITED_AT])
                        else if FLAT_PATH_COLUMN and not PATH_OF_USE then long(NODE_ON_KEY)
                        else long(PATH_VALUE[LIST_AT])
        | LIST_INSTANCE := if not FLAT_PATH_COLUMN then 0 else if FROM_INHERITED_PATH then FLAT_PATH_INSTANCE[INHERITED_AT]
                           else PATH_CONTEXT
        | LIST_CALL := FLAT_PATH_COLUMN and FROM_INHERITED_PATH and FLAT_PATH_CALL[INHERITED_AT]
        | LIST_KIND_SHOWN := if FLAT_PATH_COLUMN then LIST_NAMES else LIST_KIND
        | LIST_UNSIGNED := COL = COL_TABLE_VALUES and TYPE_ELEMENT[TABLE_TYPE[R]] = BUILTIN_ULONG
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
        | PSEUDO_OP := if ENTRY_OP_NOW = OP_DELAY then OP_COUNT + ENTRY_AUX_NOW else ENTRY_OP_NOW
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
        | TYPE_SHOWN := if SCALAR_ATOM = SA_TYPE_ELEMENT then TYPE_ELEMENT[R] else R
        | SCALAR_CLASS := if SCALAR_ATOM = SA_NAME or SCALAR_ATOM = SA_TYPE_ELEMENT then IC_NAME
                          else if SCALAR_ATOM = SA_TYPE_HEAD then (if ROW_IS_ARRAY then IC_SIZE else IC_NAME)
                          else if SCALAR_ATOM = SA_FRAGMENT then IC_FRAGMENT else IC_NUMBER
        | SCALAR_TAG := if SCALAR_ATOM = SA_FRAGMENT then ROW_FRAGMENT
                        else if SCALAR_ATOM = SA_TYPE_HEAD or SCALAR_ATOM = SA_TYPE_ELEMENT then integer(TYPE_STATE[TYPE_SHOWN])
                        else integer(ROW_UNSIGNED)
        | SCALAR_VALUE := if SCALAR_ATOM = SA_NAME then long(WALK_ROW_KEY)
                          else if SCALAR_ATOM = SA_LINE then long(TOKEN_LINE[WALK_ROW_TOKEN])
                          else if SCALAR_ATOM = SA_COLUMN then long(TOKEN_COLUMN[WALK_ROW_TOKEN])
                          else if SCALAR_CLASS = IC_SIZE then long(TYPE_SIZE[R])
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
        | WALK_COLUMN := if WALKING and LEAVES_COLUMN then COL + 1 else COL
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
     with (| WALK_COLUMN := if ROWS_DUMP then COL_ROWS_OP else 0 | WALK_ROW := -1 | WALK_POSITION := 0 | WALK_INNER_POSITION := 0 | WALK_STEP_POSITION := 0
           | WALK_MEMBER_POSITION := 0 | DUMP_COUNT := 0 | WALK_JOINS := false | WALK_PREFIXED := false |)
     end
   | DUMP_OVERFLOW := DUMP_RUNS and (WALK_COLUMN < DUMP_COLUMN_END or DUMP_COUNT > ITEM_CAP or DUMP_SIGNAL_COUNT > SIGNAL_CAP
                                     or DUMP_EQUATION_COUNT > EQUATION_CAP or DUMP_GROUP_COUNT > GROUP_CAP)
   | FRONT_MESSAGE := if PASS_MESSAGE /= 0 then PASS_MESSAGE else if INSTANTIATE_FAILED then INSTANTIATE_MESSAGE
                      else if INSTANTIATE_INCOMPLETE then T_CAPACITY else if LOWER_FAILED then LW_MESSAGE
                      else if LOWER_INCOMPLETE then T_CAPACITY else if POST_FAILED then PO_MESSAGE
                      else if POST_INCOMPLETE or EXPAND_FAILED or EXPAND_INCOMPLETE then T_CAPACITY else 0
   | MESSAGE := if FRONT_MESSAGE /= 0 then FRONT_MESSAGE else if DUMP_OVERFLOW then T_CAPACITY else 0
   | MESSAGE_ARGUMENT0 := if FRONT_MESSAGE /= 0 then PASS_ARGUMENT0 else F_CAP_ITEMS
   | LAYOUT := if not USAGE_OK then LAYOUT_NONE else if ERRNO /= 0 then LAYOUT_OS
               else if DUMP_PASS = 1 or DUMP_PASS = 2 or DUMP_PASS = 3 or DUMP_PASS = 4 then
                 (if MESSAGE /= 0 then LAYOUT_DUMP_ERROR else if DUMP_PASS = 1 then LAYOUT_DUMP_TOKENS else LAYOUT_DUMP_PROGRAM)
               else if MESSAGE /= 0 then LAYOUT_COMPILE else LAYOUT_NONE
   | DUMPS_TOKENS := LAYOUT = LAYOUT_DUMP_TOKENS
   | DUMPS_PROGRAM := LAYOUT = LAYOUT_DUMP_PROGRAM
   | ITEM_COUNT := if DUMPS_TOKENS then 4 * (TOKEN_COUNT + 1) else if DUMPS_PROGRAM then DUMP_COUNT else LAYOUT_ITEM_COUNT[LAYOUT]
   | ITEM_INDEX := 0 .. ITEM_COUNT - 1
   | iterate ITEM_INDEX of
       (| SECTION := ITEM_INDEX / (TOKEN_COUNT + 1)
        | TOKEN := ITEM_INDEX modulo (TOKEN_COUNT + 1) - 1
        | IS_HEADER := TOKEN < 0
        | KIND := integer(TOKEN_KIND[TOKEN])
        | ROW := LAYOUT_FIRST_ROW[LAYOUT] + ITEM_INDEX
        | SLOT := if DUMPS_PROGRAM then -1 else ROW_SLOT[ROW]
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
        | IS_ROW := SLOT < 0
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
                    else if IS_ROW then ROW_PREFIX[ROW]
                    else if IS_PIECE then PIECE
                    else if not FIRST_HALF then 0
                    else if PRINTS_TYPE_SIZE then F_OPEN
                    else if ARGUMENT_KIND = A_TOKEN then (if ARGUMENT_EOF then F_END_OF_FILE else F_QUOTE)
                    else if ARGUMENT_KIND = A_FRAGMENT then ARGUMENT_VALUE
                    else if ARGUMENT_KIND = A_CODE and ARGUMENT_VALUE >= C_SYMBOL_BASE then SYMBOL_FRAGMENT[ARGUMENT_VALUE - C_SYMBOL_BASE]
                    else 0
        | SLICE_PATH := IS_ROW and ROW_SLICE[ROW] = ROW_SLICE_PATH
        | SLICE_START := if SLICES_TOKEN then SEED_LENGTH + TOKEN_START[SLICED_TOKEN]
                         else if SLICES_CHARACTER then SEED_LENGTH + ARGUMENT_VALUE
                         else if SLICES_NAME then NAME_AT[SLICED_NAME] else 0
        | SLICE_LENGTH := if SLICES_LITERAL then (if TOKEN_LENGTH[SLICED_TOKEN] > 20 then 20 else TOKEN_LENGTH[SLICED_TOKEN])
                          else if SLICES_TOKEN then TOKEN_LENGTH[SLICED_TOKEN]
                          else if SLICES_CHARACTER then ERROR_CHARACTER_LENGTH
                          else if SLICES_NAME then NAME_LENGTH[SLICED_NAME]
                          else if SLICE_PATH then PATH_LENGTH else 0
        | FOLDS := SLICES_TOKEN and not SLICES_TEXT and TOKEN_KIND[SLICED_TOKEN] = ubyte(KIND_KEYWORD)
        | INFIX := if PROGRAM_PREFIX or FLAT_PREFIX then F_HASH else if PROGRAM_NAME and PROGRAM_TAG = 1 then F_STATE_SUFFIX
                   else if PROGRAM_SUFFIXED then (if PROGRAM_BASE /= N_ON_MARK then F_QUOTE else 0)
                   else if SLICES_TYPE_NAME and TYPE_STATE[NAMED_TYPE] then F_STATE_SUFFIX
                   else if NAME_HALF and NAME_SUFFIX > 0 and NAME_BASE /= N_ON_MARK then F_QUOTE else 0
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
   | OUTPUT_INDEX := 0 .. TOTAL - 1
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
        | SLICE_BYTE := if ITEM_FROM_PATH[CURRENT] then PATH_TEXT[SLICE_AT]
                        else if SLICE_AT < SEED_LENGTH then SEED[SLICE_AT] else SRC[SLICE_AT - SEED_LENGTH]
        | DIGIT := ITEM_MAGNITUDE[CURRENT] / POWERS_OF_TEN[DIGITS_END - 1 - OFFSET] modulo ulong(10)
        | OUTPUT_BYTE := if OFFSET < SEPARATOR_END then ubyte(32)
                         else if OFFSET < PREFIX_END then FRAGMENTS[FRAGMENT_START[ITEM_PREFIX[CURRENT]] + OFFSET - SEPARATOR_END]
                         else if OFFSET < SLICE_END then
                           (if ITEM_FOLDS[CURRENT] and SLICE_BYTE >= ubyte(65) and SLICE_BYTE <= ubyte(90) then SLICE_BYTE + ubyte(32) else SLICE_BYTE)
                         else if OFFSET < INFIX_END then FRAGMENTS[FRAGMENT_START[ITEM_INFIX[CURRENT]] + OFFSET - SLICE_END]
                         else if OFFSET < SIGN_END then ubyte(45)
                         else if OFFSET < DIGITS_END then ubyte(DIGIT + ulong(48))
                         else if OFFSET < SUFFIX_END then FRAGMENTS[FRAGMENT_START[ITEM_SUFFIX[CURRENT]] + OFFSET - DIGITS_END]
                         else ubyte(10)
        | store{OUTPUT, ubyte}(OUTPUT_BASE + OUTPUT_INDEX, OUTPUT_BYTE)
        |)
     with CURRENT := 0
     end
   | OUTPUT_BASE := pointer(ulong(BUFFER_ADDRESS))
   | DUMPING := LAYOUT = LAYOUT_DUMP_TOKENS or LAYOUT = LAYOUT_DUMP_ERROR or LAYOUT = LAYOUT_DUMP_PROGRAM
   | OUTPUT_FILE := syscall{OS}(if DUMPING then 5 else 20, ARG3, 1537, 420, 0, 0, 0)
   | SOURCE_CLOSED --> OUTPUT_FILE
   | OUTPUT_FD := if DUMPING then OUTPUT_FILE else long(2)
   | WRITES := LAYOUT /= LAYOUT_NONE and OUTPUT_FD >= 0
   | WRITTEN := syscall{OS}(if WRITES then 4 else 20, OUTPUT_FD, BUFFER_ADDRESS, TOTAL, 0, 0, 0)
   | OUTPUT_BYTE --> WRITTEN
   | OUTPUT_CLOSED := syscall{OS}(if DUMPING and OUTPUT_FILE >= 0 then 6 else 20, OUTPUT_FILE, 0, 0, 0, 0, 0)
   | WRITTEN --> OUTPUT_CLOSED
   | OUTPUT_FAILED := WRITES and WRITTEN /= long(TOTAL) or DUMPING and OUTPUT_FILE < 0
   | STATUS := if not USAGE_OK then 2 else if ERRNO /= 0 or OUTPUT_FAILED or not DUMPING and MESSAGE /= 0 then 1 else 0
   | EXIT := syscall{OS}(1, STATUS, 0, 0, 0, 0, 0)
   | OUTPUT_CLOSED --> EXIT
   |)
  where
    constant integer DUMP_PASS = 0;
    constant integer ARG_CAP = 4096;
    constant integer SRC_CAP = 8388608;
    constant integer TOKEN_CAP = 2097152;
    constant integer ITEM_CAP = 16777216;
    constant long OUTPUT_CAP = 134217728;
    constant integer TRIE_NODE_CAP = 1048576;
    constant integer TRIE_CAP = 67108864;
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
        0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 6, 0, 6, 6, 3,
        0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 6, 6, 6, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
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
    constant [256] short PAIR_SECOND = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 124, 0, 0, 0, 0, 0, 46, 61, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 58, 0, 61, 0, 61, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 61, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0,
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
    constant [8] short MODE_OF_CLASS = [0, 0, 2, 1, 3, 4, 0, 0];
    constant integer KIND_KEYWORD = 0;
    constant integer KIND_NAME = 1;
    constant integer KIND_SYMBOL = 2;
    constant integer KIND_NUMBER = 3;
    constant integer KIND_EOF = 5;
    constant integer KIND_NONE = 6;
    constant [8] short OPENED_KIND_OF_CLASS = [6, 6, 3, 1, 6, 4, 2, 2];
    constant integer KEYWORD_LENGTH_MAX = 9;
    constant integer KEYWORD_MODULUS = 156;
    constant [156] ulong KEYWORD_KEYS = [
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(474245), ulong(10154581170), ulong(0),
        ulong(198245431340), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(14836), ulong(0), ulong(486), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(5969364), ulong(0), ulong(494), ulong(0), ulong(0), ulong(0), ulong(498), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(309556), ulong(0), ulong(0), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(17799681651),
        ulong(763528), ulong(0), ulong(0), ulong(0), ulong(19724), ulong(681477), ulong(0), ulong(0),
        ulong(1476), ulong(0), ulong(19730), ulong(0), ulong(119675684308), ulong(0), ulong(0), ulong(0),
        ulong(0), ulong(674469), ulong(1843057971694), ulong(0), ulong(4469085588), ulong(178861), ulong(0), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(464660), ulong(6337125), ulong(0), ulong(0),
        ulong(0), ulong(18226873521733), ulong(0), ulong(0), ulong(0), ulong(0), ulong(663726), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(24385093), ulong(0), ulong(0),
        ulong(5572), ulong(0), ulong(25074), ulong(0), ulong(0), ulong(0), ulong(229180581358), ulong(0),
        ulong(0), ulong(10340599429), ulong(0), ulong(0), ulong(0), ulong(0), ulong(762030), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(2666927150), ulong(0),
        ulong(20201044), ulong(0), ulong(294), ulong(452089231), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(176741), ulong(0), ulong(0),
        ulong(12617900), ulong(0), ulong(0), ulong(409031)];
    constant integer ERROR_NONE = 0;
    constant integer ERROR_UNEXPECTED = 1;
    constant integer ERROR_SRC = 2;
    constant integer ERROR_TOKENS = 3;
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
    constant integer SEED_LENGTH = 372;
    constant integer SEED_NAME_COUNT = 54;
    constant [372] ubyte SEED = "event boolean short integer long ubyte ushort uinteger ulong pointer load store syscall instruction Automaton_Initial_State Automaton_Transition Automaton_IsIn clock' state' cur' on' process where end init true false when default and or xor not modulo shl shr type enum constant next iterate of with if then else procedure node function automaton label on external indices";
    constant integer N_EVENT = 0;
    constant integer N_BOOLEAN = 1;
    constant integer N_UBYTE = 5;
    constant integer N_ULONG = 8;
    constant integer N_LOAD = 10;
    constant integer N_INSTRUCTION = 13;
    constant integer N_INITIAL = 14;
    constant integer N_TRANSITION = 15;
    constant integer N_ISIN = 16;
    constant integer N_CLOCK_MARK = 17;
    constant integer N_STATE_MARK = 18;
    constant integer N_CURRENT_MARK = 19;
    constant integer N_ON_MARK = 20;
    constant integer C_EVENT = 1;
    constant integer C_BOOLEAN = 2;
    constant integer C_SHORT = 3;
    constant integer C_INTEGER = 4;
    constant integer C_LONG = 5;
    constant integer C_PROCESS = 22;
    constant integer C_WHERE = 23;
    constant integer C_END = 24;
    constant integer C_INIT = 25;
    constant integer C_TRUE = 26;
    constant integer C_FALSE = 27;
    constant integer C_WHEN = 28;
    constant integer C_DEFAULT = 29;
    constant integer C_AND = 30;
    constant integer C_OR = 31;
    constant integer C_XOR = 32;
    constant integer C_NOT = 33;
    constant integer C_MODULO = 34;
    constant integer C_SHL = 35;
    constant integer C_SHR = 36;
    constant integer C_TYPE = 37;
    constant integer C_ENUM = 38;
    constant integer C_CONSTANT = 39;
    constant integer C_NEXT = 40;
    constant integer C_ITERATE = 41;
    constant integer C_OF = 42;
    constant integer C_WITH = 43;
    constant integer C_IF = 44;
    constant integer C_THEN = 45;
    constant integer C_ELSE = 46;
    constant integer C_PROCEDURE = 47;
    constant integer C_NODE = 48;
    constant integer C_FUNCTION = 49;
    constant integer C_AUTOMATON = 50;
    constant integer C_LABEL = 51;
    constant integer C_ON = 52;
    constant integer C_EXTERNAL = 53;
    constant integer C_OPEN_BAR = 64;
    constant integer C_BAR_CLOSE = 65;
    constant integer C_ARROW = 66;
    constant integer C_COLONS = 67;
    constant integer C_DEFINE = 68;
    constant integer C_CLOCK_EQUAL = 69;
    constant integer C_NOT_EQUAL = 70;
    constant integer C_LESS_EQUAL = 71;
    constant integer C_GREATER_EQUAL = 72;
    constant integer C_RANGE = 73;
    constant integer C_BAR = 74;
    constant integer C_DOLLAR = 75;
    constant integer C_PLUS = 76;
    constant integer C_MINUS = 77;
    constant integer C_STAR = 78;
    constant integer C_SLASH = 79;
    constant integer C_OPEN = 80;
    constant integer C_CLOSE = 81;
    constant integer C_EQUAL = 82;
    constant integer C_SEMICOLON = 83;
    constant integer C_COMMA = 84;
    constant integer C_QUESTION = 85;
    constant integer C_BANG = 86;
    constant integer C_LESS = 87;
    constant integer C_GREATER = 88;
    constant integer C_CARET = 89;
    constant integer C_HASH = 90;
    constant integer C_OPEN_BRACKET = 91;
    constant integer C_CLOSE_BRACKET = 92;
    constant integer C_COLON = 93;
    constant integer C_OPEN_BRACE = 94;
    constant integer C_CLOSE_BRACE = 95;
    constant integer C_EOF = 0;
    constant integer C_NAME = 100;
    constant integer C_NUMBER = 101;
    constant integer C_STRING = 102;
    constant integer C_SYMBOL_BASE = 64;
    constant [256] short NAME_CHAR = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 63, 0, 0, 0, 0, 0, 0, 0, 0,
        52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 6,
        7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 0, 0, 0, 0, 62,
        0, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48,
        49, 50, 51, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    constant [256] short SINGLE_SYMBOL = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 86, 0, 90, 75, 0, 0, 0, 80, 81, 78, 76, 84, 77, 0, 79,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 93, 83, 87, 82, 88, 85, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 91, 0, 92, 89, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 94, 74, 95, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    constant [256] short DOUBLE_SYMBOL = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 64, 0, 0, 0, 0, 0, 73, 70,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 67, 0, 71, 0, 72, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 69, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 65, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    constant [32] short SYMBOL_FRAGMENT = [
        208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231,
        232, 233, 24, 11, 12, 1, 234, 235];
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
    constant [48] short OP_FRAGMENT = [
        37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60,
        61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 23, 83];
    constant [48] short OP_IS_OPENER = [
        0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    constant [48] short OP_ARITY = [
        0, 0, 0, 2, 1, 1, 2, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
        2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2];
    constant [104] short BINARY_OP = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 14, 13, 17, 16, 15, 0, 28, 29, 30, 0, 0, 0, 31, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 19, 21,
        23, 33, 0, 0, 24, 25, 26, 27, 0, 0, 18, 0, 0, 0, 0, 20, 22, 0, 0, 0, 0, 32, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0];
    constant [104] short BINARY_PRECEDENCE = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 4, 3, 13, 12, 11, 0, 18, 18, 18, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 16,
        16, 1, 0, 0, 17, 17, 18, 18, 0, 0, 16, 0, 0, 0, 0, 16, 16, 0, 0, 0, 0, 2, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0];
    constant [104] short PREFIX_OP = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 9, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0];
    constant [104] short PREFIX_PRECEDENCE = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 8, 0, 0, 0, 0, 14, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 24, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0];
    constant [104] short MODEL_CLASS = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
        1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0];
    constant integer TK_EVENT = 0;
    constant integer TK_BOOLEAN = 1;
    constant integer TK_INT = 2;
    constant integer TK_POINTER = 3;
    constant integer TK_ENUM = 4;
    constant integer TK_ARRAY = 5;
    constant integer TK_EXTERNAL = 6;
    constant [7] short TYPE_KIND_FRAGMENT = [
        84, 85, 86, 87, 88, 89, 90];
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
        91, 92, 93];
    constant integer F_ROLE_SIGNAL = 173;
    constant integer F_ROLE_TYPE = 174;
    constant integer F_ROLE_MODEL = 175;
    constant integer F_ROLE_CONSTANT = 176;
    constant integer F_ROLE_LABEL = 177;
    constant integer COLUMN_COUNT = 54;
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
    constant [79] short COLUMN_FRAGMENT = [
        94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117,
        118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141,
        142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165,
        166, 167, 168, 169, 170, 171, 172];
    constant integer F_CAP_SRC = 178;
    constant integer F_CAP_TOKENS = 179;
    constant integer F_CAP_NAMES = 180;
    constant integer F_CAP_TYPES = 181;
    constant integer F_CAP_VALUES = 182;
    constant integer F_CAP_MODELS = 183;
    constant integer F_CAP_SIGNALS = 184;
    constant integer F_CAP_CONSTANTS = 185;
    constant integer F_CAP_TABLES = 186;
    constant integer F_CAP_EQUATIONS = 187;
    constant integer F_CAP_ENTRIES = 188;
    constant integer F_CAP_GUARDS = 189;
    constant integer F_CAP_LABELS = 190;
    constant integer F_CAP_LOOPS = 191;
    constant integer F_CAP_GROUPS = 192;
    constant integer F_CAP_DEPENDENCES = 193;
    constant integer F_CAP_STACK = 194;
    constant integer F_CAP_PATHS = 195;
    constant integer F_CAP_LOCALS = 196;
    constant integer F_CAP_PARSE = 197;
    constant integer F_CAP_FINISH = 198;
    constant integer F_CAP_ITEMS = 199;
    constant integer F_CAP_OUTPUT = 200;
    constant [4] short SECTION_FRAGMENT = [
        27, 28, 29, 30];
    constant [6] short KIND_FRAGMENT = [
        31, 32, 33, 34, 35, 36];
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
    constant integer T_EVENT_ARRAYS = 13;
    constant integer T_EXTERNAL_SIGNAL = 14;
    constant integer T_INPUT_SCALAR = 15;
    constant integer T_ARRAYS_TO_MODELS = 16;
    constant integer T_OUTPUT_ARRAY = 17;
    constant integer T_UNEXPECTED_AFTER = 18;
    constant integer T_ENUM_TWICE = 19;
    constant integer T_CONSTANT_STRING = 20;
    constant integer T_CONSTANT_LIST = 21;
    constant integer T_CONSTANT_ELEMENT = 22;
    constant integer T_CONSTANT_TYPE = 23;
    constant integer T_CONSTANT_COUNT = 24;
    constant integer T_CONVERSION = 25;
    constant integer T_CONSTANT_LITERAL = 26;
    constant integer T_ONLY_DEFINITIONS = 27;
    constant integer T_ITERATE_NESTED = 28;
    constant integer T_ITERATE_GUARDED = 29;
    constant integer T_ARROW_NAMES = 30;
    constant integer T_EXPECTED_DEFINITION = 31;
    constant integer T_DELAY_INITIAL = 32;
    constant integer T_STATIC_PARAMETER = 33;
    constant integer T_EXPECTED_EXPRESSION = 34;
    constant integer T_EXPECTED_THEN = 35;
    constant integer T_EXPECTED_ELSE = 36;
    constant integer T_UNBALANCED = 37;
    constant integer T_EXPECTED_OPERATOR = 38;
    constant integer T_LABEL_UNDECLARED = 39;
    constant integer T_NO_INPUT = 40;
    constant integer T_WRONG_ARGUMENTS = 41;
    constant integer T_LABEL_PLACED = 42;
    constant integer T_CANNOT_GUARD = 43;
    constant integer T_EXPECTS_STATE = 44;
    constant integer T_NOT_LABEL_OF = 45;
    constant integer T_ONE_INITIAL = 46;
    constant integer T_ONLY_AUTOMATON = 47;
    constant integer T_NO_OUTPUT = 48;
    constant integer T_HAS_OUTPUT = 49;
    constant integer T_NOT_STATE = 50;
    constant [115] short TEMPLATE_PIECE0 = [
        0, 236, 237, 238, 240, 0, 0, 0, 244, 246, 248, 249, 250, 251, 252, 254, 256, 257, 259, 261, 246, 246, 246, 246,
        246, 269, 270, 271, 272, 273, 274, 275, 276, 277, 278, 279, 280, 281, 282, 283, 284, 286, 283, 0, 0, 0, 284, 0,
        295, 295, 0, 299, 283, 301, 303, 304, 305, 295, 295, 295, 295, 299, 0, 313, 252, 315, 0, 313, 319, 320, 322, 323,
        325, 326, 328, 329, 0, 0, 332, 333, 334, 335, 336, 337, 339, 340, 326, 342, 344, 0, 346, 326, 326, 326, 326, 326,
        326, 354, 355, 261, 261, 252, 252, 358, 359, 299, 361, 363, 299, 254, 299, 366, 367, 299, 369];
    constant [115] short TEMPLATE_PIECE1 = [
        0, 7, 0, 239, 0, 241, 242, 4, 245, 247, 0, 0, 0, 0, 253, 255, 0, 258, 260, 243, 262, 262, 262, 262,
        262, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 247, 285, 287, 289, 290, 291, 292, 293, 294,
        296, 297, 298, 247, 300, 302, 0, 0, 306, 247, 307, 308, 309, 247, 311, 314, 247, 316, 317, 318, 0, 321, 288, 324,
        0, 327, 0, 0, 330, 331, 0, 0, 0, 0, 0, 338, 288, 0, 341, 343, 0, 345, 347, 348, 349, 350, 351, 352,
        353, 0, 0, 247, 356, 247, 357, 0, 0, 360, 362, 0, 262, 364, 365, 0, 0, 368, 0];
    constant [115] short TEMPLATE_PIECE2 = [
        0, 0, 0, 0, 0, 0, 0, 243, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 263, 264, 265, 266,
        267, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 288, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 310, 0, 312, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 343, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 266, 0, 0, 0, 0, 0, 0];
    constant [115] short TEMPLATE_PIECE3 = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        268, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    constant [115] short TEMPLATE_KIND0 = [
        0, 8, 7, 6, 1, 3, 3, 7, 2, 3, 1, 0, 1, 0, 4, 3, 0, 3, 1, 3, 3, 3, 3, 3,
        3, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 0, 0, 1, 3, 3, 3, 3, 3, 3, 3, 3, 3,
        3, 3, 3, 3, 3, 3, 0, 0, 3, 3, 3, 3, 3, 9, 3, 3, 10, 3, 3, 3, 0, 3, 4, 5,
        4, 7, 0, 0, 9, 9, 0, 0, 0, 0, 0, 11, 4, 0, 7, 4, 0, 3, 4, 7, 7, 7, 7, 7,
        7, 0, 0, 3, 3, 3, 3, 0, 9, 9, 9, 0, 9, 9, 9, 0, 0, 9, 0];
    constant [115] short TEMPLATE_KIND1 = [
        0, 0, 0, 1, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 4, 4, 4,
        4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 3, 0, 3, 3, 0, 0,
        0, 0, 3, 0, 0, 0, 0, 0, 6, 0, 0, 0, 5, 0, 5, 0, 0, 0, 10, 0, 0, 4, 4, 4,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 11, 4, 0, 0, 4, 0, 0, 4, 0, 0, 4, 0, 0,
        0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0];
    constant [115] short TEMPLATE_KIND2 = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 4,
        5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0];
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
    constant [6] short LAYOUT_ITEM_COUNT = [
        0, 2, 14, 13, 0, 0];
    constant [6] short LAYOUT_FIRST_ROW = [
        0, 0, 2, 16, 29, 29];
    constant [29] short ROW_PREFIX = [
        5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0];
    constant [29] short ROW_SLICE = [
        0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0];
    constant [29] short ROW_NUMBER = [
        3, 0, 0, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0];
    constant [29] short ROW_SUFFIX = [
        6, 0, 1, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 4, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0];
    constant [29] short ROW_NEWLINE = [
        0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 1];
    constant [29] short ROW_SLOT = [
        -1, -1, -1, -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, -1, -1, -1, 0, 1, 2, 3, 4, 5,
        6, 7, 8, 9, -1];
    constant integer MESSAGE_SLOTS = 10;
    constant [20] ulong POWERS_OF_TEN = [
        ulong(1), ulong(10), ulong(100), ulong(1000), ulong(10000), ulong(100000),
        ulong(1000000), ulong(10000000), ulong(100000000), ulong(1000000000), ulong(10000000000), ulong(100000000000),
        ulong(1000000000000), ulong(10000000000000), ulong(100000000000000), ulong(1000000000000000), ulong(10000000000000000), ulong(100000000000000000),
        ulong(1000000000000000000), ulong(-8446744073709551616)];
    constant [5669] ubyte FRAGMENTS = ":: error: error  sigc: error: [Errno ] '...'end of file'none[][[]]]]][][nonenone][CONST [[ENUMCONST ['stateDEFINESEED#.'callkinds texts lines columns keywordnamesymbolnumberstringeofCONSTSIGNALENUMCONSTCALLDELAYPREVINDEXNEGNOTUWHENCLOCKIFBRANCHDEFAULTWHENXORORANDEQNELTLEGTGEADDSUBMULDIVMODSHLSHRNEXTPAIRRANGEOPEN_PARENOPEN_SQUAREIF_MARKTHEN_MARKEFFECTINPUTCOPYCONVERTTABLEELEMENTGATHERITERARGEVENTBOOLEANINTPOINTERENUMARRAYEXTERNALinputoutputlocalname types.kind types.bytes types.signed types.name types.values types.element types.size models.name models.kind models.parent models.line models.column models.labels signal_names signal_roles signal_types signal_models signal_positions constant_names constant_types constant_values table_types table_values equation_targets equation_ops equation_args equation_positions equation_loops equation_kinds equation_models equation_labels equation_guards guard_models guard_ops guard_args guard_positions guard_context guard_labels guard_signals label_names label_uses loop_names loop_positions loop_models constraint_groups constraint_positions constraint_models constraint_guards dependence_from dependence_to dependence_positions dependence_models dependence_guards rows.op rows.left rows.right rows.value rows.type rows.ctx rows.line rows.column rows.owner rows.loop rows.guard rows.groups rows.group_positions rows.dependence_from rows.dependence_to rows.war rows.snapshotted rows.effects.kind rows.effects.resource rows.effects.param loops.index loops.size loops.defined loops.snapshots loops.count signaltypemodelconstantlabelSRCTOKENSNAMESTYPESVALUESMODELSSIGNALSCONSTANTSTABLESEQUATIONSENTRIESGUARDSLABELSLOOPSGROUPSDEPENDENCESSTACKPATHSLOCALSPARSEFINISHITEMSOUTPUTINSTANCESINSTANTIATELOOKUPSROWSROW_DEPENDENCESSEGMENTSLOWER(||)-->:::=^=/=<=>=..|$+-*/()=;,?!<>^{}unexpected character 'program exceeds compiler capacity: expected '', found expected a name, found  is a reserved name is the name of a model is declared twiceinteger literal  does not fit in longconstant  is not declaredexpected an integer constant, found array capacity must be strictly positiveexpected a type, found arrays of event are not supportedtype  is external; signals cannot have that typeinput signal  must be a scalararrays cannot be passed to modelsoutput  has an array type; outputs must be scalarunexpected  after the process modelenumerated value  has type  but its definition is a string but its definition is a list but its definition has an element of type  but its definition has type  but its definition has  elementsa conversion in a constant must name an integer typea constant must be defined by an integer literal, a conversion of one, or a list of themonly definitions are allowed inside iterateiterate cannot be nestediterate is not allowed inside a guarded process--> requires signal namesexpected ':=' or '^=', found the initial value of a delay must be a constantexpected a static parameter, found expected an expression, found expected 'then'expected 'else'unbalanced parenthesisexpected an operator, found label automaton  has no input; its control clock is the upper bound of its inputswrong number of arguments for : expected , found  cannot be placed on  cannot be guarded expects a state name of automaton  is not a label of automaton  needs exactly one Automaton_Initial_State is allowed only in an automatonmodel  has no output and cannot be used in an expression has an output and cannot be called as a process is not a state of automaton signal  cannot be used as a signalconversion to  expects one argumentindices expects a positive constantmodel calls are not allowed inside iterateunsafe model  is called from  takes no static parameters calls itself has  outputs; only models with at most one output can be called expects  static parameters, found the word of  must be an integer constantthe resource of  must be an external type accesses an integer or pointer type, found  must fit in 32 bits':' is supported only as the right operand of nextinput 1 of  must be a pointer, found input 2 of store must have type input  of syscall must be an integer or a pointer, found input 1 of instruction must have type ulong, found operator  is not allowed inside iteratean array value can only be the whole definition of a signal[?] applies only to a signal name[?] is allowed only inside iterate[?] refers to a signal the iterate body does not defineindexing a value that is not an arraya range must start at 0the bound of a range must be an integeran array index must be an integernext expects 'index : value' on its rightconstant index  is outside 0..next expects a value of type $ is not supported on arrays expects scalar operandsoperator if expects operands of comparable types, found  and the condition of if must be boolean cannot be inside an if; gate it by its clock or its inputsno conversion from  to  expects a pointer and an integer offset expects integer operands expects operands of comparable types, found  expects operands of one type expects boolean operands expects unsigned operandsthe condition of when must be booleanthe initial value of a delay must match its type is ambiguous has no value the index of iterate must be an array of integersiterate body cannot define its index  in with is not defined by the iterate bodythe initial value of  cannot read a signal the iterate defineswith initializes an array only from an array constant or an array signal cannot be defined is defined twicea range defines an array of integersan array signal must be defined by a constant, indices, a gather, or next is never defineda range can only be the index of iteratenotwhenifdefaultxororandmoduloshlshrnext";
    constant [381] short FRAGMENT_START = [
        0, 0, 1, 10, 16, 17, 37, 39, 40, 43, 56, 60, 61, 62, 64, 66, 69, 71, 76, 81, 89, 101, 107, 113,
        117, 118, 119, 124, 130, 136, 142, 150, 157, 161, 167, 173, 179, 182, 187, 193, 202, 206, 211, 215, 220, 223, 226, 231,
        236, 238, 244, 251, 255, 258, 260, 263, 265, 267, 269, 271, 273, 275, 278, 281, 284, 287, 290, 293, 296, 300, 304, 309,
        319, 330, 337, 346, 352, 357, 361, 368, 373, 380, 386, 390, 393, 398, 405, 408, 415, 419, 424, 432, 437, 443, 448, 453,
        464, 476, 489, 500, 513, 527, 538, 550, 562, 576, 588, 602, 616, 629, 642, 655, 669, 686, 701, 716, 732, 744, 757, 774,
        787, 801, 820, 835, 850, 866, 882, 898, 911, 921, 932, 948, 962, 975, 989, 1001, 1012, 1023, 1038, 1050, 1068, 1089, 1107, 1125,
        1141, 1155, 1176, 1194, 1212, 1220, 1230, 1241, 1252, 1262, 1271, 1281, 1293, 1304, 1314, 1325, 1337, 1358, 1379, 1398, 1407, 1424, 1442, 1464,
        1483, 1495, 1506, 1520, 1536, 1548, 1554, 1558, 1563, 1571, 1576, 1579, 1585, 1590, 1595, 1601, 1607, 1614, 1623, 1629, 1638, 1645, 1651, 1657,
        1662, 1668, 1679, 1684, 1689, 1695, 1700, 1706, 1711, 1717, 1726, 1737, 1744, 1748, 1763, 1771, 1776, 1778, 1780, 1783, 1785, 1787, 1789, 1791,
        1793, 1795, 1797, 1798, 1799, 1800, 1801, 1802, 1803, 1804, 1805, 1806, 1807, 1808, 1809, 1810, 1811, 1812, 1813, 1814, 1815, 1837, 1872, 1882,
        1891, 1914, 1933, 1956, 1974, 1990, 2011, 2020, 2036, 2072, 2112, 2135, 2168, 2173, 2216, 2229, 2246, 2279, 2286, 2328, 2339, 2363, 2380, 2390,
        2421, 2450, 2493, 2522, 2546, 2555, 2607, 2695, 2738, 2762, 2809, 2834, 2863, 2910, 2945, 2975, 2990, 3005, 3027, 3055, 3061, 3071, 3136, 3166,
        3177, 3185, 3206, 3224, 3259, 3288, 3330, 3362, 3368, 3418, 3466, 3495, 3502, 3529, 3543, 3564, 3599, 3641, 3654, 3670, 3697, 3710, 3715, 3774,
        3783, 3809, 3821, 3849, 3865, 3890, 3934, 3954, 4004, 4015, 4041, 4073, 4079, 4130, 4181, 4190, 4220, 4279, 4312, 4346, 4401, 4438, 4461, 4500,
        4533, 4574, 4589, 4604, 4633, 4661, 4685, 4741, 4746, 4781, 4840, 4859, 4863, 4903, 4928, 4973, 5002, 5027, 5053, 5090, 5138, 5151, 5165, 5214,
        5251, 5294, 5315, 5356, 5428, 5446, 5463, 5499, 5572, 5589, 5629, 5632, 5636, 5638, 5645, 5648, 5650, 5653, 5659, 5662, 5665];
    constant [381] short FRAGMENT_LENGTH = [
        0, 1, 9, 6, 1, 20, 2, 1, 3, 13, 4, 1, 1, 2, 2, 3, 2, 5, 5, 8, 12, 6, 6, 4,
        1, 1, 5, 6, 6, 6, 8, 7, 4, 6, 6, 6, 3, 5, 6, 9, 4, 5, 4, 5, 3, 3, 5, 5,
        2, 6, 7, 4, 3, 2, 3, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 4, 4, 5, 10,
        11, 7, 9, 6, 5, 4, 7, 5, 7, 6, 4, 3, 5, 7, 3, 7, 4, 5, 8, 5, 6, 5, 5, 11,
        12, 13, 11, 13, 14, 11, 12, 12, 14, 12, 14, 14, 13, 13, 13, 14, 17, 15, 15, 16, 12, 13, 17, 13,
        14, 19, 15, 15, 16, 16, 16, 13, 10, 11, 16, 14, 13, 14, 12, 11, 11, 15, 12, 18, 21, 18, 18, 16,
        14, 21, 18, 18, 8, 10, 11, 11, 10, 9, 10, 12, 11, 10, 11, 12, 21, 21, 19, 9, 17, 18, 22, 19,
        12, 11, 14, 16, 12, 6, 4, 5, 8, 5, 3, 6, 5, 5, 6, 6, 7, 9, 6, 9, 7, 6, 6, 5,
        6, 11, 5, 5, 6, 5, 6, 5, 6, 9, 11, 7, 4, 15, 8, 5, 2, 2, 3, 2, 2, 2, 2, 2,
        2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 22, 35, 10, 9,
        23, 19, 23, 18, 16, 21, 9, 16, 36, 40, 23, 33, 5, 43, 13, 17, 33, 7, 42, 11, 24, 17, 10, 31,
        29, 43, 29, 24, 9, 52, 88, 43, 24, 47, 25, 29, 47, 35, 30, 15, 15, 22, 28, 6, 10, 65, 30, 11,
        8, 21, 18, 35, 29, 42, 32, 6, 50, 48, 29, 7, 27, 14, 21, 35, 42, 13, 16, 27, 13, 5, 59, 9,
        26, 12, 28, 16, 25, 44, 20, 50, 11, 26, 32, 6, 51, 51, 9, 30, 59, 33, 34, 55, 37, 23, 39, 33,
        41, 15, 15, 29, 28, 24, 56, 5, 35, 59, 19, 4, 40, 25, 45, 29, 25, 26, 37, 48, 13, 14, 49, 37,
        43, 21, 41, 72, 18, 17, 36, 73, 17, 40, 3, 4, 2, 7, 3, 2, 3, 6, 3, 3, 4];
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
    constant integer P_STALL = 48;
    constant integer P_DONE = 49;
    constant integer P_FAILED = 50;
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
    constant integer PHASE_STATEMENT = 4;
    constant integer PHASE_REWRITE_EQ = 5;
    constant integer PHASE_REWRITE_MEMBER = 6;
    constant integer PHASE_REWRITE_GUARD = 7;
    constant integer PHASE_REWRITE_TRIGGER = 8;
    constant integer PHASE_CLOCK = 9;
    constant integer PHASE_STATE = 10;
    constant integer PHASE_CUR = 11;
    constant integer PHASE_CUR_TAIL = 12;
    constant integer PHASE_GROUP = 13;
    constant integer PHASE_GUARD_START = 14;
    constant integer PHASE_DEFINE_PARSE = 15;
    constant integer PHASE_DEFINE_FINISH = 16;
    constant integer PHASE_READ_PARSE = 17;
    constant integer PHASE_READ_FINISH = 18;
    constant integer PHASE_READ_MEMBERS = 19;
    constant integer PHASE_READ_DEPS = 20;
    constant integer PHASE_ON = 21;
    constant integer PHASE_FILTER = 22;
    constant integer PHASE_DONE = 23;
    constant integer PHASE_FAILED = 24;
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
    constant [79] short COLUMN_SHAPE = [
        0, 2, 1, 1, 4, 7, 1, 1, 0, 0, 1, 1, 1, 7, 0, 2, 1, 1, 3, 0, 1, 1, 1, 7,
        0, 7, 7, 3, 1, 2, 1, 7, 7, 1, 7, 7, 3, 7, 7, 0, 0, 5, 0, 3, 1, 8, 3, 1,
        7, 6, 6, 3, 1, 7, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 7, 3, 1, 1, 7, 1, 0,
        1, 1, 1, 1, 7, 1, 1];
    constant [79] short COLUMN_LIST_KIND = [
        0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2,
        0, 3, 4, 0, 0, 0, 0, 1, 2, 0, 3, 4, 0, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0,
        0, 0, 0, 0, 2, 0, 0];
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
    constant integer OP_COUNT = 48;
    constant integer ARG_WIDTH = 13;
    constant integer CALL_PARAMS_STEP = 4;
    constant integer PARAM_STEPS = 6;
    constant [51] short ARG_LENGTH = [
        4, 5, 6, 7, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
        4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 7, 4, 4, 4, 4, 4, 4, 4, 4, 4,
        5, 11, 13];
    constant [663] short ARG_PROGRAM = [
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
        0, 3, 4, 11, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 0, 12, 0, 5, 6, 1, 1, 1,
        0, 0, 0, 3, 4, 0, 13, 0, 7, 8, 9, 10, 1, 1, 1];
    constant integer F_HASH = 24;
    constant integer F_DOT = 25;
    constant integer F_CALL_SUFFIX = 26;
    constant integer N_INDICES = 53;
    constant integer OP_EFFECT = 38;
    constant integer F_CAP_INSTANCES = 201;
    constant integer F_CAP_INSTANTIATE = 202;
    constant integer T_SIGNAL_UNDECLARED = 51;
    constant integer T_LABEL_AS_SIGNAL = 52;
    constant integer T_CONVERSION_ONE = 53;
    constant integer T_INDICES_CONSTANT = 54;
    constant integer T_CALLS_IN_ITERATE = 55;
    constant integer T_UNSAFE_CALL = 56;
    constant integer T_MODEL_UNDECLARED = 57;
    constant integer T_NO_STATIC_PARAMETERS = 58;
    constant integer T_CALLS_ITSELF = 59;
    constant integer T_TOO_MANY_OUTPUTS = 60;
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
    constant [48] short OP_MONOCHRONOUS = [
        0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 1, 0, 1];
    constant [48] short OP_TEXT_FRAGMENT = [
        0, 0, 0, 0, 219, 0, 0, 221, 370, 371, 233, 372, 372, 373, 371, 374, 375, 376, 226, 214, 231, 215, 232, 216,
        220, 221, 222, 223, 377, 378, 379, 380, 1, 217, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    constant integer COLUMN_TOTAL = 79;
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
    constant integer F_CAP_LOOKUPS = 203;
    constant integer F_CAP_ROWS = 204;
    constant integer F_CAP_ROW_DEPENDENCES = 205;
    constant integer F_CAP_SEGMENTS = 206;
    constant integer F_CAP_LOWER = 207;
    constant integer A_FLAT = 9;
    constant integer A_TEXT = 10;
    constant integer A_LONG = 11;
    constant integer T_FLAT_UNDECLARED = 61;
    constant integer T_STATIC_COUNT = 62;
    constant integer T_WORD_CONSTANT = 63;
    constant integer T_TYPE_UNDECLARED_TEXT = 64;
    constant integer T_RESOURCE_EXTERNAL = 65;
    constant integer T_ACCESS_TYPE = 66;
    constant integer T_WORD_RANGE = 67;
    constant integer T_PAIR_OPERAND = 68;
    constant integer T_INPUT_POINTER = 69;
    constant integer T_STORE_TYPE = 70;
    constant integer T_SYSCALL_INPUT = 71;
    constant integer T_INSTRUCTION_INPUT = 72;
    constant integer T_NOT_IN_ITERATE = 73;
    constant integer T_ARRAY_VALUE = 74;
    constant integer T_PREV_SIGNAL = 75;
    constant integer T_PREV_OUTSIDE = 76;
    constant integer T_PREV_UNDEFINED = 77;
    constant integer T_NOT_ARRAY = 78;
    constant integer T_RANGE_START = 79;
    constant integer T_RANGE_BOUND = 80;
    constant integer T_INDEX_INTEGER = 81;
    constant integer T_NEXT_PAIR = 82;
    constant integer T_INDEX_RANGE = 83;
    constant integer T_NEXT_TYPE = 84;
    constant integer T_DELAY_ARRAY = 85;
    constant integer T_SCALAR_OPERANDS = 86;
    constant integer T_IF_TYPES = 87;
    constant integer T_IF_CONDITION = 88;
    constant integer T_EFFECT_IN_IF = 89;
    constant integer T_NO_CONVERSION = 90;
    constant integer T_POINTER_OFFSET = 91;
    constant integer T_INTEGER_OPERANDS = 92;
    constant integer T_COMPARABLE = 93;
    constant integer T_ONE_TYPE = 94;
    constant integer T_BOOLEAN_OPERANDS = 95;
    constant integer T_UNSIGNED_OPERANDS = 96;
    constant integer T_WHEN_CONDITION = 97;
    constant integer T_DELAY_MATCH = 98;
    constant integer T_ENUM_UNDECLARED = 99;
    constant integer T_ENUM_AMBIGUOUS = 100;
    constant integer T_TYPE_UNDECLARED = 101;
    constant integer T_NO_VALUE = 102;
    constant integer T_ITERATE_INDEX = 103;
    constant integer T_INDEX_DEFINED = 104;
    constant integer T_WITH_UNDEFINED = 105;
    constant integer T_WITH_READS = 106;
    constant integer T_WITH_ARRAY = 107;
    constant integer T_SIGNAL_TYPE = 108;
    constant integer T_INPUT_DEFINED = 109;
    constant integer T_DEFINED_TWICE = 110;
    constant integer T_RANGE_DEFINES = 111;
    constant integer T_ARRAY_DEFINITION = 112;
    constant integer T_NEVER_DEFINED = 113;
    constant integer T_RANGE_INDEX = 114;
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
    type ARGS = external;
    type OS = external;
    type FILE = external;
    type OUTPUT = external;
    integer ARGC, PATH_LENGTH, ERRNO, LENGTH, CLASS, PREVIOUS_MODE, SYMBOL_LENGTH, OPENED_KIND, REMAINING, MODE, COLUMN,
      CODE_POINTS, LINE_START, LINE, OPEN_AT, OPEN_LINE, OPEN_COLUMN, OPEN_KIND, PENDING, LETTER, FINISHED_LENGTH,
      FINISHED_SLOT, OPENED_SLOT, TOKEN_COUNT, FOUND, LEX_ERROR, LEX_ERROR_LINE, LEX_ERROR_COLUMN, LEX_ERROR_AT,
      ERROR, ERROR_CHARACTER_LENGTH, MESSAGE, MESSAGE_LINE, MESSAGE_COLUMN, MESSAGE_ARGUMENT0, MESSAGE_ARGUMENT1,
      MESSAGE_ARGUMENT2, LAYOUT, ITEM_COUNT, SECTION, TOKEN, KIND, ROW, SLOT, ARGUMENT, PIECE, ARGUMENT_KIND,
      ARGUMENT_VALUE, SLICED_TOKEN, ROW_NUMBER_KIND, PREFIX, SLICE_START, SLICE_LENGTH, INFIX, SUFFIX, DIGITS,
      ITEM_LENGTH, WRITE_SLOT, ITEM_POSITION, TOTAL, CURRENT, OFFSET, SEPARATOR_END, PREFIX_END, SLICE_END, INFIX_END,
      SIGN_END, DIGITS_END, SUFFIX_END, SLICE_AT, STATUS, SOURCE_AT, CURSOR, CURSOR_START, CURSOR_LENGTH, CURSOR_KIND,
      TRIE_PARENT, TRIE_SLOT, TRIE_EXISTING, TRIE_NODE, TRIE_NODE_COUNT, NAME_BEGIN, KNOWN_NAME, NAME_ID, NAME_COUNT,
      SYMBOL_CODE, CODE_VALUE, CODE_SLOT, VALUE_SLOT, INTERN_ERROR_TOKEN, SCAN_CODE, SCAN_NAME, SCAN_PREVIOUS,
      SCAN_MESSAGE, SCAN_ARGUMENT0, SCAN_ARGUMENT1, SCAN_STATE, SCAN_TYPE_NAME, SCAN_TYPE_KIND, SCAN_VALUE_START,
      VALUE_COUNT, USER_TYPE_SLOT, USER_TYPE_COUNT, PRESCAN_MESSAGE, PRESCAN_TOKEN, PRESCAN_ARGUMENT0, PRESCAN_ARGUMENT1,
      MESSAGE_TOKEN, NAME_BASE, NAME_SUFFIX, SLICED_NAME;
    pointer ARGV, ARG1, ARG2, ARG3, SOURCE_BASE, OUTPUT_BASE;
    boolean ARGUMENT_COUNT_OK, DASH_MATCHES, USAGE_OK, PATH_ENDED, OPEN_OK, READ_OK, SIZE_OK, SOURCE_FITS, MAP_WANTED,
      MAP_OK, SOURCE_OK, AT_EOF, AT_END, CONTINUES, STARTS, OPENS_TOKEN, ENDS_LINE, NOT_ALL_LETTERS, HAS_LOWER,
      HAS_UPPER, IS_KEYWORD, UNCLOSED, UNEXPECTED, FIRST_FOUND, SOURCE_TOO_BIG, ERROR_MULTIBYTE, ERROR_FIRST_CONTINUES,
      ERROR_SECOND_CONTINUES, ERROR_THIRD_CONTINUES, DUMPS_TOKENS, IS_HEADER, IS_PIECE, IS_ARGUMENT, IS_ROW, FIRST_HALF,
      ARGUMENT_EOF, QUOTES_TOKEN, SLICES_LITERAL, SLICES_TOKEN, SLICES_CHARACTER, HAS_NUMBER, SLICE_PATH, FOLDS,
      NEWLINE, SEPARATES, NEGATIVE, DUMPING, WRITES, OUTPUT_FAILED, LEXED, IN_SEED, CURSOR_ENDED, IN_TOKEN, TOKEN_BEGINS,
      TOKEN_ENDS, NAMEISH, NAME_BEGINS, NAME_ENDS, TRIE_CREATES, NEW_NAME, TOO_BIG, INTERN_OVERFLOWS, INTERNED,
      SCAN_IS_NAME, SCAN_CLASHES, SCAN_DUPLICATE, SCAN_FULL, SCAN_FAILS, SCAN_APPENDS_VALUE, SCAN_REGISTERS,
      FIRST_SCAN_FAILURE, SLICES_NAME;
    ubyte DASH_BYTE, PATH_BYTE, SOURCE_BYTE, BYTE, NEXT_BYTE, ERROR_LEAD, SLICE_BYTE, OUTPUT_BYTE, NAME_BYTE, FOLDED_BYTE;
    ulong KEY, MAGNITUDE, DIGIT, DIGIT_VALUE, ACCUMULATED;
    long BUFFER_ADDRESS, SOURCE_FD, PROBE, SIZE, MAPPED, SOURCE_CLOSED, OUTPUT_FILE, OUTPUT_FD, WRITTEN, OUTPUT_CLOSED,
      EXIT, NUMBER;
    [3] integer DASH_INDEX;
    [ARG_CAP] integer PATH_INDEX;
    [ARG_CAP] ubyte PATH_TEXT;
    [SRC_CAP] integer COPY_INDEX, LEX_INDEX, INTERN_INDEX;
    [SRC_CAP] ubyte SRC;
    [TOKEN_CAP] ubyte TOKEN_KIND;
    [TOKEN_CAP] ubyte TOKEN_CODE;
    [TOKEN_CAP] integer TOKEN_LENGTH, TOKEN_START, TOKEN_LINE, TOKEN_COLUMN, TOKEN_NAME, PRESCAN_INDEX;
    [TOKEN_CAP] long TOKEN_VALUE;
    [TOKEN_CAP] boolean TOKEN_BIG;
    [TRIE_CAP] integer TRIE_CHILD;
    [TRIE_NODE_CAP] integer TRIE_NAME;
    [NAME_CAP] integer NAME_AT, NAME_LENGTH, NAME_TYPE, VALUE_STAMP;
    [TYPE_CAP] integer USER_TYPE_NAME, USER_TYPE_KIND, USER_TYPE_VALUE_START, USER_TYPE_VALUE_COUNT;
    [VALUE_CAP] integer VALUE_NAME;
    [ITEM_CAP] integer ITEM_INDEX, ITEM_PREFIX, ITEM_SLICE_START, ITEM_SLICE_LENGTH, ITEM_INFIX, ITEM_DIGITS, ITEM_SUFFIX,
      ITEM_END;
    [ITEM_CAP] boolean ITEM_SEPARATES, ITEM_FROM_PATH, ITEM_FOLDS, ITEM_NEGATIVE, ITEM_NEWLINE;
    [ITEM_CAP] ulong ITEM_MAGNITUDE;
    [OUTPUT_CAP] integer OUTPUT_INDEX;
    [STACK_CAP] integer FRAME_KIND, FRAME_VALUE, PENDING_OP, PENDING_PRECEDENCE, PENDING_TOKEN, PENDING_COUNT,
      PENDING_PARAMETERS, PENDING_PARAMETER_COUNT, PENDING_SPLIT, PENDING_OPENER_BELOW;
    [PATH_CAP] integer PATH_VALUE;
    [ENTRY_CAP] integer ENTRY_OP, ENTRY_TOKEN, ENTRY_NAME, ENTRY_TYPE, ENTRY_AUX, ENTRY_AUX2, ENTRY_SPLIT;
    [TYPE_CAP] integer TYPE_KIND, TYPE_BYTES, TYPE_NAME, TYPE_VALUE_START, TYPE_VALUE_COUNT, TYPE_ELEMENT, ARRAY_NEXT;
    [BUCKET_CAP] integer ARRAY_HEAD;
    [MODEL_CAP] integer MODEL_NAME, MODEL_KIND, MODEL_PARENT, MODEL_TOKEN, MODEL_SIGNAL_START, MODEL_LABEL_START,
      MODEL_INPUTS, MODEL_EQUATION_START, MODEL_EQUATION_END, MODEL_GROUP_START, MODEL_GROUP_END,
      MODEL_DEPENDENCE_START, MODEL_DEPENDENCE_END, MODEL_GUARD_START, MODEL_GUARD_END, MODEL_USE_START,
      MODEL_USE_END, MODEL_MEMBER_START, MODEL_MEMBER_END, MODEL_INTRINSICS, MODEL_STATEMENTS, MODEL_CLOSE_SIGNALS,
      MODEL_CLOSE_EQUATIONS, MODEL_CLOSE_GROUPS, MODEL_CLOSE_LABELS, MODEL_STATE_TYPE, CLOSE_ORDER,
      MODEL_FIRST_SIGNAL, MODEL_LAST_SIGNAL, MODEL_FIRST_LABEL, MODEL_LAST_LABEL;
    [NAME_CAP] integer LOCAL_HEAD, NAME_CONSTANT;
    [LOCAL_CAP] integer LOCAL_MODEL, LOCAL_PREVIOUS;
    [SIGNAL_CAP] integer SIGNAL_NAME, SIGNAL_ROLE, SIGNAL_TYPE, SIGNAL_MODEL, SIGNAL_TOKEN, SIGNAL_NEXT;
    [LABEL_CAP] integer LABEL_NAME, LABEL_MODEL, LABEL_NEXT, USE_MODEL, USE_NAME, USE_TOKEN, USE_PARENT,
      USE_PATH_START, USE_PATH_LENGTH;
    [CONSTANT_CAP] integer CONSTANT_NAME, CONSTANT_TYPE;
    [TABLE_CAP] integer TABLE_TYPE, TABLE_START, TABLE_LENGTH;
    [GUARD_CAP] integer GUARD_MODEL, GUARD_ENTRY_START, GUARD_ENTRY_COUNT, GUARD_TOKEN, GUARD_CONTEXT, GUARD_LABELS,
      GUARD_PATH_START, GUARD_PATH_LENGTH, GUARD_EQUATION_FIRST, GUARD_GROUP_FIRST, GUARD_DEPENDENCE_FIRST, GUARD_END,
      GUARD_EQUATION_LAST, GUARD_GROUP_LAST, GUARD_DEPENDENCE_LAST;
    [LOOP_CAP] integer LOOP_NAME, LOOP_TOKEN, LOOP_MODEL;
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
    integer HERE, STATE_BEFORE, CODE0, CODE1, CODE2, NAME0, NAME1, NAME2, MODEL_NOW, LOCAL_TOP, LOCAL_TOP_MODEL,
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
      ENTRY_COUNT, BODY_INTRINSICS, BODY_STATEMENTS, BODY_EQUATION_START, BODY_GROUP_START, BODY_DEPENDENCE_START,
      BODY_GUARD_START, BODY_USE_START, BODY_MEMBER_START, MODEL_MESSAGE, EXPECTED_CODE, TYPE_MESSAGE,
      SEPARATOR_MESSAGE, STATEMENT_MESSAGE, BODY_MESSAGE, FULL_TABLE, STEP_MESSAGE, STEP_TOKEN, STEP_ARGUMENT0,
      STEP_ARGUMENT1, STEP_ARGUMENT2, NEXT_AT, AT, NEXT_STATE, PARSE_STATE, RETURN_STATE, ROLE, PENDING_MODEL_KIND,
      ARRAY_BUCKET, CANDIDATE, ARRAY_ELEMENT, PARSED_TYPE, DECLARE_NAME, DECLARE_TOKEN, CONSTANT_RETURN,
      CONSTANT_VALUE_TYPE, LIST_COUNT, LIST_START, LOOP_NOW, LABEL_NODE, GUARD_NODE, GUARD_START_TOKEN,
      EXPRESSION_START, EXPRESSION_RETURN, TARGET, EQUATION_TOKEN, DEPENDENCE_PREVIOUS, GROUP_MEMBER_START, CALL_HEAD,
      PARAMETER_START, PARAMETER_COUNT, CURRENT_MODEL, TYPE_SLOT, TYPE_COUNT, MODEL_SLOT, MODEL_COUNT, BODY_SLOT,
      CLOSE_SLOT, CLOSED_COUNT, LOCAL_SLOT, LOCAL_COUNT, SIGNAL_SLOT, SIGNAL_SLOT_MODEL, SIGNAL_COUNT, LABEL_SLOT,
      LABEL_COUNT, CONSTANT_SLOT, CONSTANT_COUNT, TABLE_SLOT, TABLE_COUNT, POOL_COUNT, USE_SLOT, USE_COUNT,
      GUARD_SLOT, GUARD_CLOSE_SLOT, GUARD_COUNT, GUARD_DEPTH_MAX, LOOP_SLOT, LOOP_COUNT, EQUATION_SLOT,
      EQUATION_COUNT, MEMBER_SLOT, MEMBER_COUNT, GROUP_SLOT, GROUP_COUNT, DEPENDENCE_SLOT, DEPENDENCE_COUNT,
      PARSE_MESSAGE, PARSE_TOKEN, PARSE_ARGUMENT0, PARSE_ARGUMENT1, PARSE_ARGUMENT2, BRACKET_COUNT, COLONS_COUNT;
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
      IN_PARAMETER_CLOSE, IN_OPERATOR, IN_BRANCH;
    long PARSE_BOUND, SIZE_VALUE, CONSTANT_LITERAL, SIGNED_LITERAL, MASKED, HALF_RANGE, WRAPPED, CONSTANT_VALUE_NOW,
      LITERAL_NUMBER, LITERAL_VALUE, CONSTANT_VALUE_HELD;
    ulong TARGET_MASK, ARRAY_SIZE, DECLARED_SIZE;
    [FINAL_CAP] integer FINAL_OP, FINAL_NAME, FINAL_TOKEN, FINAL_TYPE, FINAL_AUX, FINAL_AUX2;
    [FINAL_CAP] long FINAL_VALUE;
    [FINAL_CAP] integer FINAL_MODEL;
    [EQUATION_CAP] integer EQUATION_FINAL_START, EQUATION_FINAL_END, TRANSITION_FINAL_START, TRANSITION_FINAL_END,
      TRANSITION_SOURCE, TRANSITION_TARGET, TRANSITION_TRIGGER_START, TRANSITION_TRIGGER_END, TRANSITION_GUARD,
      TRANSITION_TOKEN, FINISH_EQUATION_TARGET, FINISH_EQUATION_FINAL_START, FINISH_EQUATION_FINAL_END,
      FINISH_EQUATION_TOKEN, FINISH_EQUATION_MODEL, FINISH_EQUATION_LABELS, FINISH_EQUATION_GUARDS;
    [MEMBER_CAP] integer MEMBER_FINAL_START, MEMBER_FINAL_END;
    [GUARD_CAP] integer GUARD_FINAL_START, GUARD_FINAL_END, FILTER_ROW_START;
    [NAME_CAP] integer LABEL_STAMP, OWN_STAMP, OWN_TYPE, STATE_STAMP, STATE_ORDINAL, DEFINED_STAMP, INPUT_STAMP;
    [SIGNAL_CAP] integer INPUT_LIST, FINISH_SIGNAL_NAME, FINISH_SIGNAL_TYPE, FINISH_SIGNAL_MODEL, FINISH_SIGNAL_TOKEN;
    [DEPENDENCE_CAP] integer DEPENDENCE_RENAMED_FROM, DEPENDENCE_RENAMED_TO;
    [GROUP_CAP] integer FINISH_GROUP_MODEL, FINISH_GROUP_FINAL;
    [PARSE_CAP] integer FINISH_INDEX;
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
      FINISH_GROUP_SLOT, FINISH_GROUP_COUNT, FINISH_MODEL_ORDINAL;
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
      BUILTIN_UNSAFE_FAILS, MODEL_CALL_LIVE, CALLEE_UNDECLARED_FAILS, CALLEE_PARAMS_FAILS, CALLEE_ITERATE_FAILS,
      STARTS_ANCESTRY, ANCESTRY_PASSES, SELF_CALL_FAILS, CALLEE_COUNT_FAILS, CALLEE_OUTPUTS_FAILS,
      CALLEE_PROCESS_FAILS, CALLEE_EXPRESSION_FAILS, FROM_FAILS, TO_FAILS, CALL_LABEL_ADDED, PATH_LIVE, IN_LABEL_PART,
      FROM_INHERITED, FROM_NODE, PATH_CALL_NOW, INPUT_LIVE, INPUT_COPIES, INPUT_CLOSES, CALL_FINISHES, CALLEE_ORDERED,
      EMIT_COPIES, EMIT_CLOSES, EQUATION_ROW_WANTED, MEMBER_ROW_WANTED, DEPENDENCE_ROW_WANTED, ENTRY_COPY_WANTED,
      PLAIN_ENTRY, LABEL_ROW_WANTED, GROUP_ROW_WANTED, FAILS_NOW, GOES_ON, POSTFIX_IS_MEMBER, POSTFIX_SEED,
      CALL_HAS_OUTPUT, CREATES_INSTANCE, NEW_PURE, INSTANTIATE_FAILED, INSTANTIATE_INCOMPLETE, FLAT_READY, FLAT_DUMP,
      WALK_ROW_CALL, FLAT_PATH_COLUMN, FROM_INHERITED_PATH, LIST_CALL, NAME_CALL_NOW, PREFIX_DUE, WALK_PREFIXED,
      PROGRAM_PREFIX;
    long SPAN_BOUND, INSTANTIATE_BOUND, FLAT_ROW_TOTAL, FLAT_DUMP_BOUND, PROGRAM_DUMP_BOUND, EMITTED_VALUE, ROWS_DUMP_BOUND,
      ROWS_NUMBER_VALUE;
    integer DUMP_COLUMN_END, ROWS_COLUMN_ROWS, ROWS_TOKEN_NOW, MESSAGE_INSTANCE, PREFIX_INSTANCE, LW_ENUM_ARGUMENT0,
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
      LW_NEW_TYPE_SLOT, NEW_TYPE_COUNT, LW_INTERNED, LW_IOTA_TABLE, LW_NEW_TABLE, LW_LOOP_SIGNAL, LW_LOOP_TYPE,
      LW_CONSTANT, LW_ENUM_MESSAGE, FX_STEP, FX_COUNT, FX_PARAMS, FX_P0, FX_P1, FX_KEY0, FX_KEY1, FX_TYPE0, FX_TYPE1,
      FX_EXPECTED, FX_CONSTANT1, FX_BASE, FX_O0, FX_O1, FX_O2, FX_O3, FX_O4, FX_O5, FX_O6, FX_PAIR_AT, FX_T0, FX_T1,
      FX_T2, FX_T3, FX_T4, FX_T5, FX_T6, FX_K0, FX_K1, FX_K2, FX_K3, FX_K4, FX_K5, FX_K6, FX_SYSCALL_AT,
      FX_SYSCALL_TYPE, FX_ROW_TYPE, FX_MESSAGE, FX_TOKEN, FX_ARGUMENT0, FX_ARGUMENT1, FX_OPERAND, FX_PREVIOUS,
      LW_PREV_MESSAGE, LW_INDEX_ROW, LW_INDEX_TYPE, LW_CALL_TYPE, LW_CALL_KIND, LW_IF_EFFECT, LW_INITIAL_TYPE,
      LW_OPERATOR_MESSAGE, LW_OPERATOR_TOKEN, LW_OP_TEXT, LW_OPERATOR_ARGUMENT0, LW_OPERATOR_ARGUMENT1, LUB_A, LUB_B,
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
      LW_INDEX_OUTSIDE, LW_IS_NEXT, LW_CONVERTS, LW_INTEGER_OP, LW_COMPARE_OP, LW_LOGIC_OP, LW_SHIFT_OP,
      LW_POINTER_ARITHMETIC, LUB_A_SIGNED, LUB_B_SIGNED, LUB_SUBTYPE, LW_MEMBER_NOW, LW_END_SEED, LW_END_DEFINES,
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
    ulong LT_SIZE, RT_SIZE, LW_ARRAY_SIZE;
  end;
