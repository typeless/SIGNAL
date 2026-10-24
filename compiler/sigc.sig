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
                      else if FINISH_FAILED then FINISH_TOKEN else if PARSE_FAILED then PARSE_TOKEN else 0
   | MESSAGE_LINE := if SOURCE_TOO_BIG then 1 else if ERROR /= ERROR_NONE then LEX_ERROR_LINE else TOKEN_LINE[MESSAGE_TOKEN]
   | MESSAGE_COLUMN := if SOURCE_TOO_BIG then 1 else if ERROR /= ERROR_NONE then LEX_ERROR_COLUMN else TOKEN_COLUMN[MESSAGE_TOKEN]
   | PASS_ARGUMENT0 := if ERROR = ERROR_UNEXPECTED then LEX_ERROR_AT else if ERROR = ERROR_SRC then F_CAP_SRC
                          else if ERROR = ERROR_TOKENS then F_CAP_TOKENS else if INTERN_ERROR_TOKEN >= 0 then F_CAP_NAMES
                          else if PRESCAN_MESSAGE /= 0 then PRESCAN_ARGUMENT0 else if FINISH_FAILED then FINISH_ARGUMENT0
                          else if FINISH_INCOMPLETE then F_CAP_FINISH else if PARSE_FAILED then PARSE_ARGUMENT0
                          else F_CAP_PARSE
   | MESSAGE_ARGUMENT1 := if PRESCAN_MESSAGE /= 0 then PRESCAN_ARGUMENT1 else if FINISH_FAILED then FINISH_ARGUMENT1
                          else PARSE_ARGUMENT1
   | MESSAGE_ARGUMENT2 := if FINISH_FAILED then FINISH_ARGUMENT2 else PARSE_ARGUMENT2
   | DUMP_RUNS := DUMP_PASS = 2 and FINISHES and PASS_MESSAGE = 0
   | MERGE_BOUND := long(SIGNAL_COUNT) + long(FINISH_SIGNAL_COUNT) + long(EQUATION_COUNT) + long(FINISH_EQUATION_COUNT)
                    + long(GROUP_COUNT) + long(FINISH_GROUP_COUNT) + long(3) * long(CLOSED_COUNT) + long(LABEL_COUNT)
                    + long(MODEL_COUNT) + long(USE_COUNT) + long(TABLE_COUNT) + long(8)
   | MERGE_INDEX := 0 .. (if DUMP_RUNS then MERGE_BOUND else long(-1))
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
   | DUMP_BOUND := long(1024) + long(5) * DUMP_ROW_TOTAL + long(VALUE_COUNT) + long(LABEL_COUNT) + long(TABLE_ELEMENT_TOTAL)
                   + long(PATH_DEPTH_MAX) * long(2 * DUMP_EQUATION_COUNT + 2 * GUARD_COUNT + DUMP_GROUP_COUNT + DEPENDENCE_COUNT)
                   + long(20) * long(FINAL_COUNT) + long(6) * long(MEMBER_COUNT + 2 * FINISH_GROUP_COUNT)
                   + long(6) * long(TOKEN_COUNT)
   | DUMP_INDEX := 0 .. (if DUMP_RUNS then DUMP_BOUND else long(-1))
   | iterate DUMP_INDEX of
       (| WALK_COLUMN_NOW := WALK_COLUMN[?]
        | WALK_ROW_NOW := WALK_ROW[?]
        | WALK_REL := WALK_POSITION[?]
        | WALK_INNER := WALK_INNER_POSITION[?]
        | WALK_STEP := WALK_STEP_POSITION[?]
        | WALK_MEMBER_STEP := WALK_MEMBER_POSITION[?]
        | WALKING := WALK_COLUMN_NOW < COLUMN_COUNT
        | COL := WALK_COLUMN_NOW
        | SHAPE := COLUMN_SHAPE[COL]
        | LIST_KIND := COLUMN_LIST_KIND[COL]
        | COLUMN_ROWS := if COL = COL_NAME then 1
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
        | SIGNAL_SOURCE := MERGED_SIGNAL[R]
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
                       (if EQUATION_FINISHED then FINISH_EQUATION_TARGET[EQUATION_FINISH_ROW] else EQUATION_TARGET[EQUATION_SOURCE])
                     else if COL = COL_GUARD_SIGNALS then N_ON_MARK + (R - MODEL_GUARD_START[GUARD_MODEL[R]] + 1) * NAME_CAP
                     else if COL = COL_LABEL_USES then USE_NAME[R]
                     else if COL = COL_LOOP_NAMES then LOOP_NAME[R]
                     else if COL = COL_DEPENDENCE_FROM then
                       (if DEPENDENCE_RENAMED_FROM[R] > 0 then DEPENDENCE_RENAMED_FROM[R] - 1 else DEPENDENCE_FROM_NAME[R])
                     else if DEPENDENCE_RENAMED_TO[R] > 0 then DEPENDENCE_RENAMED_TO[R] - 1 else DEPENDENCE_TO_NAME[R]
        | ROW_NUMBER_VALUE := if COL = COL_TYPES_BYTES then long(TYPE_BYTES[R])
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
                              else if COL = COL_EQUATION_LOOPS then long(if EQUATION_FINISHED then -1 else EQUATION_LOOP[EQUATION_SOURCE])
                              else if COL = COL_EQUATION_MODELS then
                                long(if EQUATION_FINISHED then FINISH_EQUATION_MODEL[EQUATION_FINISH_ROW] else EQUATION_MODEL[EQUATION_SOURCE])
                              else if COL = COL_GUARD_MODELS then long(GUARD_MODEL[R])
                              else if COL = COL_LABEL_USES then long(USE_MODEL[R])
                              else if COL = COL_LOOP_MODELS then long(LOOP_MODEL[R])
                              else if COL = COL_CONSTRAINT_MODELS then
                                long(if GROUP_FINISHED then FINISH_GROUP_MODEL[GROUP_FINISH_ROW] else GROUP_MODEL[GROUP_SOURCE])
                              else long(DEPENDENCE_MODEL[R])
        | ROW_UNSIGNED := COL = COL_CONSTANT_VALUES and CONSTANT_TYPE[R] = BUILTIN_ULONG
        | ROW_FRAGMENT := if COL = COL_TYPES_KIND then TYPE_KIND_FRAGMENT[TYPE_KIND[R]]
                          else if COL = COL_SIGNAL_ROLES then
                            ROLE_FRAGMENT[if SIGNAL_FINISHED then ROLE_LOCAL else SIGNAL_ROLE[SIGNAL_SOURCE]]
                          else if not EQUATION_FINISHED and EQUATION_SEED[EQUATION_SOURCE] then F_SEED else F_DEFINE
        | WALK_ROW_TOKEN := if COL = COL_SIGNAL_POSITIONS then
                         (if SIGNAL_FINISHED then FINISH_SIGNAL_TOKEN[SIGNAL_FINISH_ROW] else SIGNAL_TOKEN[SIGNAL_SOURCE])
                       else if COL = COL_EQUATION_POSITIONS then
                         (if EQUATION_FINISHED then FINISH_EQUATION_TOKEN[EQUATION_FINISH_ROW] else EQUATION_POSITION[EQUATION_SOURCE])
                       else if COL = COL_GUARD_POSITIONS then GUARD_TOKEN[R]
                       else if COL = COL_LABEL_USES then USE_TOKEN[R]
                       else if COL = COL_LOOP_POSITIONS then LOOP_TOKEN[R]
                       else if COL = COL_CONSTRAINT_POSITIONS then
                         (if GROUP_FINISHED then MODEL_TOKEN[FINISH_GROUP_MODEL[GROUP_FINISH_ROW]] else GROUP_POSITION[GROUP_SOURCE])
                       else if COL = COL_DEPENDENCE_FROM then DEPENDENCE_FROM_TOKEN[R]
                       else if COL = COL_DEPENDENCE_TO then DEPENDENCE_TO_TOKEN[R]
                       else DEPENDENCE_POSITION[R]
        | ROW_IS_ARRAY := TYPE_KIND[R] = TK_ARRAY
        | ROW_SCALAR_LENGTH := if SHAPE = SHAPE_TYPE and not ROW_IS_ARRAY then 1 else SCALAR_LENGTH[SHAPE]
        | PATH_NODE := if COL = COL_EQUATION_LABELS then
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
        | ENTRIES_OF_EQUATION := COL = COL_EQUATION_OPS or COL = COL_EQUATION_ARGS
        | ENTRY_RUN_START := if ENTRIES_OF_EQUATION then
                               (if EQUATION_FINISHED then FINISH_EQUATION_FINAL_START[EQUATION_FINISH_ROW]
                                else EQUATION_FINAL_START[EQUATION_SOURCE])
                             else GUARD_FINAL_START[R]
        | ENTRY_RUN_END := if ENTRIES_OF_EQUATION then
                             (if EQUATION_FINISHED then FINISH_EQUATION_FINAL_END[EQUATION_FINISH_ROW]
                              else EQUATION_FINAL_END[EQUATION_SOURCE])
                           else GUARD_FINAL_END[R]
        | RUN_START := if COL = COL_TYPES_VALUES then TYPE_VALUE_START[R]
                       else if COL = COL_MODELS_LABELS then MODEL_LABEL_OFFSET[R]
                       else if COL = COL_TABLE_VALUES then TABLE_START[R]
                       else if LIST_KIND = LIST_OPS or LIST_KIND = LIST_ARGS then ENTRY_RUN_START
                       else PATH_FIRST
        | RUN_LENGTH := if COL = COL_TYPES_VALUES then TYPE_VALUE_COUNT[R]
                        else if COL = COL_MODELS_LABELS then MODEL_LABEL_END[R] - MODEL_LABEL_OFFSET[R]
                        else if COL = COL_TABLE_VALUES then TABLE_LENGTH[R]
                        else if LIST_KIND = LIST_OPS or LIST_KIND = LIST_ARGS then ENTRY_RUN_END - ENTRY_RUN_START
                        else PATH_SIZE
        | LIST_AT := RUN_START + WALK_REL
        | LIST_VALUE := if COL = COL_TYPES_VALUES then long(VALUE_NAME[LIST_AT])
                        else if COL = COL_MODELS_LABELS then long(LABEL_ORDERED_NAME[LIST_AT])
                        else if COL = COL_TABLE_VALUES then (if TABLE_FROM_STRING[R] then long(SRC[LIST_AT]) else POOL_VALUE[LIST_AT])
                        else long(PATH_VALUE[LIST_AT])
        | LIST_UNSIGNED := COL = COL_TABLE_VALUES and TYPE_ELEMENT[TABLE_TYPE[R]] = BUILTIN_ULONG
        | MEMBER_TOTAL := if GROUP_FINISHED then 2 else GROUP_MEMBER_TOTAL[GROUP_SOURCE]
        | MEMBER_NOW := GROUP_MEMBER_FIRST[GROUP_SOURCE] + WALK_REL
        | WALK_MEMBER_ENTRY_START := if GROUP_FINISHED then FINISH_GROUP_FINAL[GROUP_FINISH_ROW] + WALK_REL else MEMBER_FINAL_START[MEMBER_NOW]
        | WALK_MEMBER_ENTRY_LENGTH := if GROUP_FINISHED then 1 else MEMBER_FINAL_END[MEMBER_NOW] - MEMBER_FINAL_START[MEMBER_NOW]
        | IN_GROUP := SHAPE = SHAPE_GROUP
        | OPS_MODE := LIST_KIND = LIST_OPS or IN_GROUP and WALK_MEMBER_STEP = 2
        | ARGS_MODE := LIST_KIND = LIST_ARGS or IN_GROUP and WALK_MEMBER_STEP = 5
        | CONTENT_LENGTH := if SHAPE = SHAPE_LIST then RUN_LENGTH else if IN_GROUP then MEMBER_TOTAL else ROW_SCALAR_LENGTH
        | AT_NEWLINE := not AT_HEADER and WALK_REL >= CONTENT_LENGTH
        | ENTRY_NOW := if IN_GROUP then WALK_MEMBER_ENTRY_START + WALK_INNER else LIST_AT
        | ENTRY_OP_NOW := FINAL_OP[ENTRY_NOW]
        | ENTRY_AUX_NOW := FINAL_AUX[ENTRY_NOW]
        | ENTRY_TOKEN_NOW := FINAL_TOKEN[ENTRY_NOW]
        | ENTRY_TYPE_NOW := FINAL_TYPE[ENTRY_NOW]
        | ENTRY_VALUE_NOW := FINAL_VALUE[ENTRY_NOW]
        | IS_CALL_ENTRY := ENTRY_OP_NOW = OP_CALL
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
                       else if ARG_ATOM = AA_NAME then long(FINAL_NAME[ENTRY_NOW])
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
                            else if SHAPE = SHAPE_LIST then (if LIST_KIND = LIST_NAMES then IC_NAME else IC_NUMBER)
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
        | INNER_LAST := WALK_INNER >= WALK_MEMBER_ENTRY_LENGTH - 1
        | MEMBER_FINISHES := WALK_MEMBER_STEP = 7
        | ELEMENT_FINISHES := if IN_GROUP then MEMBER_FINISHES else if ARGS_MODE then ENTRY_FINISHES else true
        | ROW_ENDS := AT_HEADER or AT_NEWLINE
        | FOLLOWING_ROW := if AT_HEADER then 0 else R + 1
        | LEAVES_COLUMN := ROW_ENDS and FOLLOWING_ROW >= COLUMN_ROWS
        | WALK_COLUMN := if WALKING and LEAVES_COLUMN then COL + 1 else COL
        | WALK_ROW := if not WALKING or not ROW_ENDS then WALK_ROW_NOW else if LEAVES_COLUMN then -1 else FOLLOWING_ROW
        | WALK_POSITION := if ROW_ENDS then 0 else WALK_REL + integer(ELEMENT_FINISHES)
        | WALK_STEP_POSITION := if ROW_ENDS or not ARGS_MODE or ENTRY_FINISHES then 0 else WALK_STEP + 1
        | WALK_MEMBER_POSITION := if ROW_ENDS or not IN_GROUP or MEMBER_FINISHES then 0
                                  else if WALK_MEMBER_STEP = 2 then (if INNER_LAST then 3 else 2)
                                  else if WALK_MEMBER_STEP = 5 then (if ENTRY_FINISHES and INNER_LAST then 6 else 5)
                                  else WALK_MEMBER_STEP + 1
        | WALK_INNER_POSITION := if ROW_ENDS or not IN_GROUP then 0
                                 else if WALK_MEMBER_STEP = 2 or WALK_MEMBER_STEP = 5 and ENTRY_FINISHES then
                                   (if INNER_LAST then 0 else WALK_INNER + 1)
                                 else WALK_INNER
        | DUMP_SLOT := if WALKING then DUMP_COUNT[?] else -1
        | DUMP_CLASS := DUMP_CLASS[?] next DUMP_SLOT : ITEM_CLASS_NOW
        | DUMP_TAG := DUMP_TAG[?] next DUMP_SLOT : ITEM_TAG_NOW
        | DUMP_VALUE := DUMP_VALUE[?] next DUMP_SLOT : ITEM_VALUE_NOW
        | DUMP_SEPARATES := DUMP_SEPARATES[?] next DUMP_SLOT
                            : WALK_JOINS[?] and ITEM_CLASS_NOW /= IC_HEADER and ITEM_CLASS_NOW /= IC_NEWLINE and ITEM_CLASS_NOW /= IC_CLOSE
        | DUMP_COUNT := DUMP_COUNT[?] + integer(WALKING)
        | WALK_JOINS := if not WALKING then WALK_JOINS[?]
                        else ITEM_CLASS_NOW /= IC_HEADER and ITEM_CLASS_NOW /= IC_NEWLINE and ITEM_CLASS_NOW /= IC_OPEN
                             and ITEM_CLASS_NOW /= IC_SIZE
        |)
     with (| WALK_COLUMN := 0 | WALK_ROW := -1 | WALK_POSITION := 0 | WALK_INNER_POSITION := 0 | WALK_STEP_POSITION := 0
           | WALK_MEMBER_POSITION := 0 | DUMP_COUNT := 0 | WALK_JOINS := false |)
     end
   | DUMP_OVERFLOW := DUMP_RUNS and (WALK_COLUMN < COLUMN_COUNT or DUMP_COUNT > ITEM_CAP or DUMP_SIGNAL_COUNT > SIGNAL_CAP
                                     or DUMP_EQUATION_COUNT > EQUATION_CAP or DUMP_GROUP_COUNT > GROUP_CAP)
   | MESSAGE := if PASS_MESSAGE /= 0 then PASS_MESSAGE else if DUMP_OVERFLOW then T_CAPACITY else 0
   | MESSAGE_ARGUMENT0 := if PASS_MESSAGE /= 0 then PASS_ARGUMENT0 else F_CAP_ITEMS
   | LAYOUT := if not USAGE_OK then LAYOUT_NONE else if ERRNO /= 0 then LAYOUT_OS
               else if DUMP_PASS = 1 or DUMP_PASS = 2 then
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
        | PROGRAM_BASE := PROGRAM_KEY modulo NAME_CAP
        | PROGRAM_SUFFIX := PROGRAM_KEY / NAME_CAP
        | PROGRAM_SUFFIXED := PROGRAM_NAME and PROGRAM_SUFFIX > 0
        | PROGRAM_NUMBERED := PROGRAM_CLASS = IC_HEADER or PROGRAM_CLASS = IC_NUMBER or PROGRAM_CLASS = IC_SIZE
        | PROGRAM_UNSIGNED := PROGRAM_CLASS = IC_NUMBER and PROGRAM_TAG = 1
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
        | ARGUMENT_TYPE_ARRAY := TYPE_ARGUMENT and TYPE_KIND[ARGUMENT_VALUE] = TK_ARRAY
        | NAMED_TYPE := if ARGUMENT_TYPE_ARRAY then TYPE_ELEMENT[ARGUMENT_VALUE] else ARGUMENT_VALUE
        | NAMED_TYPE_NAME := if TYPE_STATE[NAMED_TYPE] then MODEL_NAME[TYPE_NAME[NAMED_TYPE]] else TYPE_NAME[NAMED_TYPE]
        | SLICES_TYPE_NAME := TYPE_ARGUMENT and IS_ARGUMENT and FIRST_HALF /= ARGUMENT_TYPE_ARRAY
        | PRINTS_TYPE_SIZE := ARGUMENT_TYPE_ARRAY and FIRST_HALF
        | SLICES_NAME := FIRST_HALF and (ARGUMENT_KIND = A_NAME or ARGUMENT_KIND = A_CODE and ARGUMENT_VALUE < C_SYMBOL_BASE)
                         or SLICES_TYPE_NAME or PROGRAM_NAME
        | SLICED_NAME := if PROGRAM_NAME then PROGRAM_BASE else if ARGUMENT_KIND = A_CODE then ARGUMENT_VALUE - 1
                         else if TYPE_ARGUMENT then NAMED_TYPE_NAME else NAME_BASE
        | QUOTES_TOKEN := FIRST_HALF and ARGUMENT_KIND = A_TOKEN and not ARGUMENT_EOF
        | SLICES_LITERAL := FIRST_HALF and ARGUMENT_KIND = A_LITERAL
        | SLICES_TOKEN := DUMPS_TOKENS and not IS_HEADER and SECTION = 1 or QUOTES_TOKEN or SLICES_LITERAL or PROGRAM_CLASS = IC_TOKEN
        | SLICED_TOKEN := if DUMPS_TOKENS then TOKEN else if DUMPS_PROGRAM then PROGRAM_KEY else ARGUMENT_VALUE
        | SLICES_CHARACTER := FIRST_HALF and ARGUMENT_KIND = A_CHARACTER
        | ROW_NUMBER_KIND := if IS_ROW then ROW_NUMBER[ROW] else ROW_NUMBER_NONE
        | HAS_NUMBER := DUMPS_TOKENS and (IS_HEADER or SECTION >= 2) or ROW_NUMBER_KIND /= ROW_NUMBER_NONE
                        or FIRST_HALF and (ARGUMENT_KIND = A_NUMBER or ARGUMENT_KIND = A_NAME and NAME_SUFFIX > 0) or PRINTS_TYPE_SIZE
                        or PROGRAM_NUMBERED or PROGRAM_SUFFIXED
        | NUMBER := if DUMPS_TOKENS then
                      (if IS_HEADER then long(TOKEN_COUNT) else if SECTION = 2 then long(TOKEN_LINE[TOKEN]) else long(TOKEN_COLUMN[TOKEN]))
                    else if PROGRAM_NUMBERED then PROGRAM_VALUE
                    else if PROGRAM_SUFFIXED then long(PROGRAM_SUFFIX)
                    else if ROW_NUMBER_KIND = ROW_NUMBER_ERROR_LINE then long(MESSAGE_LINE)
                    else if ROW_NUMBER_KIND = ROW_NUMBER_ERROR_COLUMN then long(MESSAGE_COLUMN)
                    else if ROW_NUMBER_KIND = ROW_NUMBER_ERRNO then long(ERRNO)
                    else if ARGUMENT_KIND = A_NAME then long(NAME_SUFFIX)
                    else if TYPE_ARGUMENT then long(TYPE_SIZE[ARGUMENT_VALUE])
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
        | FOLDS := SLICES_TOKEN and TOKEN_KIND[SLICED_TOKEN] = ubyte(KIND_KEYWORD)
        | INFIX := if PROGRAM_NAME and PROGRAM_TAG = 1 then F_STATE_SUFFIX
                   else if PROGRAM_SUFFIXED then (if PROGRAM_BASE /= N_ON_MARK then F_QUOTE else 0)
                   else if SLICES_TYPE_NAME and TYPE_STATE[NAMED_TYPE] then F_STATE_SUFFIX
                   else if FIRST_HALF and ARGUMENT_KIND = A_NAME and NAME_SUFFIX > 0 and NAME_BASE /= N_ON_MARK then F_QUOTE else 0
        | SUFFIX := if DUMPS_TOKENS then 0 else if DUMPS_PROGRAM then (if PROGRAM_CLASS = IC_SIZE then F_SIZE_CLOSE else 0)
                    else if IS_ROW then ROW_SUFFIX[ROW]
                    else if QUOTES_TOKEN then F_QUOTE
                    else if PRINTS_TYPE_SIZE then F_SIZE_CLOSE
                    else if SLICES_LITERAL and TOKEN_LENGTH[SLICED_TOKEN] > 20 then F_ELLIPSIS else 0
        | NEWLINE := DUMPS_TOKENS or IS_ROW and ROW_NEWLINE[ROW] = 1 or PROGRAM_CLASS = IC_HEADER or PROGRAM_CLASS = IC_NEWLINE
        | SEPARATES := DUMPS_PROGRAM and DUMP_SEPARATES[ITEM_INDEX]
        | NEGATIVE := HAS_NUMBER and NUMBER < long(0) and not PROGRAM_UNSIGNED
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
    constant integer SEED_LENGTH = 364;
    constant integer SEED_NAME_COUNT = 53;
    constant [364] ubyte SEED = "event boolean short integer long ubyte ushort uinteger ulong pointer load store syscall instruction Automaton_Initial_State Automaton_Transition Automaton_IsIn clock' state' cur' on' process where end init true false when default and or xor not modulo shl shr type enum constant next iterate of with if then else procedure node function automaton label on external";
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
        164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187,
        188, 189, 190, 11, 12, 1, 191, 192];
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
    constant [38] short OP_FRAGMENT = [
        34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57,
        58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71];
    constant [38] short OP_IS_OPENER = [
        0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1];
    constant [38] short OP_ARITY = [
        0, 0, 0, 2, 1, 1, 2, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
        2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2];
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
        72, 73, 74, 75, 76, 77, 78];
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
        79, 80, 81];
    constant integer F_ROLE_SIGNAL = 136;
    constant integer F_ROLE_TYPE = 137;
    constant integer F_ROLE_MODEL = 138;
    constant integer F_ROLE_CONSTANT = 139;
    constant integer F_ROLE_LABEL = 140;
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
    constant [54] short COLUMN_FRAGMENT = [
        82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105,
        106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129,
        130, 131, 132, 133, 134, 135];
    constant integer F_CAP_SRC = 141;
    constant integer F_CAP_TOKENS = 142;
    constant integer F_CAP_NAMES = 143;
    constant integer F_CAP_TYPES = 144;
    constant integer F_CAP_VALUES = 145;
    constant integer F_CAP_MODELS = 146;
    constant integer F_CAP_SIGNALS = 147;
    constant integer F_CAP_CONSTANTS = 148;
    constant integer F_CAP_TABLES = 149;
    constant integer F_CAP_EQUATIONS = 150;
    constant integer F_CAP_ENTRIES = 151;
    constant integer F_CAP_GUARDS = 152;
    constant integer F_CAP_LABELS = 153;
    constant integer F_CAP_LOOPS = 154;
    constant integer F_CAP_GROUPS = 155;
    constant integer F_CAP_DEPENDENCES = 156;
    constant integer F_CAP_STACK = 157;
    constant integer F_CAP_PATHS = 158;
    constant integer F_CAP_LOCALS = 159;
    constant integer F_CAP_PARSE = 160;
    constant integer F_CAP_FINISH = 161;
    constant integer F_CAP_ITEMS = 162;
    constant integer F_CAP_OUTPUT = 163;
    constant [4] short SECTION_FRAGMENT = [
        24, 25, 26, 27];
    constant [6] short KIND_FRAGMENT = [
        28, 29, 30, 31, 32, 33];
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
    constant [51] short TEMPLATE_PIECE0 = [
        0, 193, 194, 195, 197, 0, 0, 0, 201, 203, 205, 206, 207, 208, 209, 211, 213, 214, 216, 218, 203, 203, 203, 203,
        203, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239, 240, 241, 243, 240, 0, 0, 0, 241, 0,
        252, 252, 0];
    constant [51] short TEMPLATE_PIECE1 = [
        0, 7, 0, 196, 0, 198, 199, 4, 202, 204, 0, 0, 0, 0, 210, 212, 0, 215, 217, 200, 219, 219, 219, 219,
        219, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 204, 242, 244, 246, 247, 248, 249, 250, 251,
        253, 254, 255];
    constant [51] short TEMPLATE_PIECE2 = [
        0, 0, 0, 0, 0, 0, 0, 200, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 220, 221, 222, 223,
        224, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 245, 0, 0, 0, 0, 0, 0,
        0, 0, 0];
    constant [51] short TEMPLATE_PIECE3 = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        225, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0];
    constant [51] short TEMPLATE_KIND0 = [
        0, 8, 7, 6, 1, 3, 3, 7, 2, 3, 1, 0, 1, 0, 4, 3, 0, 3, 1, 3, 3, 3, 3, 3,
        3, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 0, 0, 1, 3, 3, 3, 3, 3, 3, 3, 3, 3,
        3, 3, 3];
    constant [51] short TEMPLATE_KIND1 = [
        0, 0, 0, 1, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 4, 4, 4,
        4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 3, 0, 3, 3, 0, 0,
        0, 0, 3];
    constant [51] short TEMPLATE_KIND2 = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 4,
        5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0,
        0, 0, 0];
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
    constant [3047] ubyte FRAGMENTS = ":: error: error  sigc: error: [Errno ] '...'end of file'none[][[]]]]][][nonenone][CONST [[ENUMCONST ['stateDEFINESEEDkinds texts lines columns keywordnamesymbolnumberstringeofCONSTSIGNALENUMCONSTCALLDELAYPREVINDEXNEGNOTUWHENCLOCKIFBRANCHDEFAULTWHENXORORANDEQNELTLEGTGEADDSUBMULDIVMODSHLSHRNEXTPAIRRANGEOPEN_PARENOPEN_SQUAREIF_MARKTHEN_MARKEVENTBOOLEANINTPOINTERENUMARRAYEXTERNALinputoutputlocalname types.kind types.bytes types.signed types.name types.values types.element types.size models.name models.kind models.parent models.line models.column models.labels signal_names signal_roles signal_types signal_models signal_positions constant_names constant_types constant_values table_types table_values equation_targets equation_ops equation_args equation_positions equation_loops equation_kinds equation_models equation_labels equation_guards guard_models guard_ops guard_args guard_positions guard_context guard_labels guard_signals label_names label_uses loop_names loop_positions loop_models constraint_groups constraint_positions constraint_models constraint_guards dependence_from dependence_to dependence_positions dependence_models dependence_guards signaltypemodelconstantlabelSRCTOKENSNAMESTYPESVALUESMODELSSIGNALSCONSTANTSTABLESEQUATIONSENTRIESGUARDSLABELSLOOPSGROUPSDEPENDENCESSTACKPATHSLOCALSPARSEFINISHITEMSOUTPUT(||)-->:::=^=/=<=>=..|$+-*/()=;,?!<>^#{}unexpected character 'program exceeds compiler capacity: expected '', found expected a name, found  is a reserved name is the name of a model is declared twiceinteger literal  does not fit in longconstant  is not declaredexpected an integer constant, found array capacity must be strictly positiveexpected a type, found arrays of event are not supportedtype  is external; signals cannot have that typeinput signal  must be a scalararrays cannot be passed to modelsoutput  has an array type; outputs must be scalarunexpected  after the process modelenumerated value  has type  but its definition is a string but its definition is a list but its definition has an element of type  but its definition has type  but its definition has  elementsa conversion in a constant must name an integer typea constant must be defined by an integer literal, a conversion of one, or a list of themonly definitions are allowed inside iterateiterate cannot be nestediterate is not allowed inside a guarded process--> requires signal namesexpected ':=' or '^=', found the initial value of a delay must be a constantexpected a static parameter, found expected an expression, found expected 'then'expected 'else'unbalanced parenthesisexpected an operator, found label automaton  has no input; its control clock is the upper bound of its inputswrong number of arguments for : expected , found  cannot be placed on  cannot be guarded expects a state name of automaton  is not a label of automaton  needs exactly one Automaton_Initial_State is allowed only in an automatonmodel  has no output and cannot be used in an expression has an output and cannot be called as a process is not a state of automaton ";
    constant [256] short FRAGMENT_START = [
        0, 0, 1, 10, 16, 17, 37, 39, 40, 43, 56, 60, 61, 62, 64, 66, 69, 71, 76, 81, 89, 101, 107, 113,
        117, 123, 129, 135, 143, 150, 154, 160, 166, 172, 175, 180, 186, 195, 199, 204, 208, 213, 216, 219, 224, 229, 231, 237,
        244, 248, 251, 253, 256, 258, 260, 262, 264, 266, 268, 271, 274, 277, 280, 283, 286, 289, 293, 297, 302, 312, 323, 330,
        339, 344, 351, 354, 361, 365, 370, 378, 383, 389, 394, 399, 410, 422, 435, 446, 459, 473, 484, 496, 508, 522, 534, 548,
        562, 575, 588, 601, 615, 632, 647, 662, 678, 690, 703, 720, 733, 747, 766, 781, 796, 812, 828, 844, 857, 867, 878, 894,
        908, 921, 935, 947, 958, 969, 984, 996, 1014, 1035, 1053, 1071, 1087, 1101, 1122, 1140, 1158, 1164, 1168, 1173, 1181, 1186, 1189, 1195,
        1200, 1205, 1211, 1217, 1224, 1233, 1239, 1248, 1255, 1261, 1267, 1272, 1278, 1289, 1294, 1299, 1305, 1310, 1316, 1321, 1327, 1329, 1331, 1334,
        1336, 1338, 1340, 1342, 1344, 1346, 1348, 1349, 1350, 1351, 1352, 1353, 1354, 1355, 1356, 1357, 1358, 1359, 1360, 1361, 1362, 1363, 1364, 1365,
        1366, 1367, 1389, 1424, 1434, 1443, 1466, 1485, 1508, 1526, 1542, 1563, 1572, 1588, 1624, 1664, 1687, 1720, 1725, 1768, 1781, 1798, 1831, 1838,
        1880, 1891, 1915, 1932, 1942, 1973, 2002, 2045, 2074, 2098, 2107, 2159, 2247, 2290, 2314, 2361, 2386, 2415, 2462, 2497, 2527, 2542, 2557, 2579,
        2607, 2613, 2623, 2688, 2718, 2729, 2737, 2758, 2776, 2811, 2840, 2882, 2914, 2920, 2970, 3018];
    constant [256] short FRAGMENT_LENGTH = [
        0, 1, 9, 6, 1, 20, 2, 1, 3, 13, 4, 1, 1, 2, 2, 3, 2, 5, 5, 8, 12, 6, 6, 4,
        6, 6, 6, 8, 7, 4, 6, 6, 6, 3, 5, 6, 9, 4, 5, 4, 5, 3, 3, 5, 5, 2, 6, 7,
        4, 3, 2, 3, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 4, 4, 5, 10, 11, 7, 9,
        5, 7, 3, 7, 4, 5, 8, 5, 6, 5, 5, 11, 12, 13, 11, 13, 14, 11, 12, 12, 14, 12, 14, 14,
        13, 13, 13, 14, 17, 15, 15, 16, 12, 13, 17, 13, 14, 19, 15, 15, 16, 16, 16, 13, 10, 11, 16, 14,
        13, 14, 12, 11, 11, 15, 12, 18, 21, 18, 18, 16, 14, 21, 18, 18, 6, 4, 5, 8, 5, 3, 6, 5,
        5, 6, 6, 7, 9, 6, 9, 7, 6, 6, 5, 6, 11, 5, 5, 6, 5, 6, 5, 6, 2, 2, 3, 2,
        2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 22, 35, 10, 9, 23, 19, 23, 18, 16, 21, 9, 16, 36, 40, 23, 33, 5, 43, 13, 17, 33, 7, 42,
        11, 24, 17, 10, 31, 29, 43, 29, 24, 9, 52, 88, 43, 24, 47, 25, 29, 47, 35, 30, 15, 15, 22, 28,
        6, 10, 65, 30, 11, 8, 21, 18, 35, 29, 42, 32, 6, 50, 48, 29];
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
    constant [54] short COLUMN_SHAPE = [
        0, 2, 1, 1, 4, 7, 1, 1, 0, 0, 1, 1, 1, 7, 0, 2, 1, 1, 3, 0, 1, 1, 1, 7,
        0, 7, 7, 3, 1, 2, 1, 7, 7, 1, 7, 7, 3, 7, 7, 0, 0, 5, 0, 3, 1, 8, 3, 1,
        7, 6, 6, 3, 1, 7];
    constant [54] short COLUMN_LIST_KIND = [
        0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2,
        0, 3, 4, 0, 0, 0, 0, 1, 2, 0, 3, 4, 0, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        2, 0, 0, 0, 0, 2];
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
    constant integer OP_COUNT = 38;
    constant integer ARG_WIDTH = 13;
    constant integer CALL_PARAMS_STEP = 4;
    constant integer PARAM_STEPS = 6;
    constant [41] short ARG_LENGTH = [
        4, 5, 6, 7, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
        4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 11, 13];
    constant [533] short ARG_PROGRAM = [
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
        0, 0, 3, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 11, 1, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 3, 4, 0, 12, 0, 5, 6, 1, 1, 1, 0, 0, 0, 3, 4, 0, 13, 0, 7, 8,
        9, 10, 1, 1, 1];
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
  end;
