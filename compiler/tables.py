import re
import sys
from pathlib import Path

SOURCE = Path(__file__).resolve().parent / "sigc.sig"
ANCHOR = "    type ARGS = external;\n"

SEED_WORDS = [
    "event", "boolean", "short", "integer", "long", "ubyte", "ushort", "uinteger", "ulong", "pointer",
    "load", "store", "syscall", "instruction",
    "Automaton_Initial_State", "Automaton_Transition", "Automaton_IsIn",
    "clock'", "state'", "cur'", "on'",
    "process", "where", "end", "init", "true", "false", "when", "default", "and", "or", "xor", "not", "modulo",
    "shl", "shr", "type", "enum", "constant", "next", "iterate", "of", "with", "if", "then", "else", "procedure",
    "node", "function", "automaton", "label", "on", "external", "indices",
]
KEYWORDS = {
    "process", "where", "end", "init", "integer", "boolean", "event", "true", "false", "when", "default", "and", "or",
    "xor", "not", "modulo", "short", "long", "shl", "shr", "type", "enum", "constant", "next", "iterate", "of", "with",
    "if", "then", "else", "procedure", "node", "function", "automaton", "label", "on", "external",
}
NAME_CONSTANTS = {
    "event": "N_EVENT", "boolean": "N_BOOLEAN", "ubyte": "N_UBYTE", "ulong": "N_ULONG", "load": "N_LOAD",
    "store": "N_STORE", "syscall": "N_SYSCALL",
    "instruction": "N_INSTRUCTION", "Automaton_Initial_State": "N_INITIAL", "Automaton_Transition": "N_TRANSITION",
    "Automaton_IsIn": "N_ISIN", "clock'": "N_CLOCK_MARK", "state'": "N_STATE_MARK", "cur'": "N_CURRENT_MARK",
    "on'": "N_ON_MARK", "indices": "N_INDICES",
}
SYMBOLS = [
    ("(|", "OPEN_BAR"), ("|)", "BAR_CLOSE"), ("-->", "ARROW"), ("::", "COLONS"), (":=", "DEFINE"),
    ("^=", "CLOCK_EQUAL"), ("/=", "NOT_EQUAL"), ("<=", "LESS_EQUAL"), (">=", "GREATER_EQUAL"), ("..", "RANGE"),
    ("|", "BAR"), ("$", "DOLLAR"), ("+", "PLUS"), ("-", "MINUS"), ("*", "STAR"), ("/", "SLASH"), ("(", "OPEN"),
    (")", "CLOSE"), ("=", "EQUAL"), (";", "SEMICOLON"), (",", "COMMA"), ("?", "QUESTION"), ("!", "BANG"),
    ("<", "LESS"), (">", "GREATER"), ("^", "CARET"), ("#", "HASH"), ("[", "OPEN_BRACKET"), ("]", "CLOSE_BRACKET"),
    (":", "COLON"), ("{", "OPEN_BRACE"), ("}", "CLOSE_BRACE"),
]
SYMBOL_BASE = 64
OTHER_CODES = [("EOF", 0), ("NAME", 100), ("NUMBER", 101), ("STRING", 102)]
CODE_LIMIT = 104

OPS = [
    "CONST", "SIGNAL", "ENUMCONST", "CALL", "DELAY", "PREV", "INDEX", "NEG", "NOT", "UWHEN", "CLOCK", "IF", "BRANCH",
    "DEFAULT", "WHEN", "XOR", "OR", "AND", "EQ", "NE", "LT", "LE", "GT", "GE", "ADD", "SUB", "MUL", "DIV", "MOD",
    "SHL", "SHR", "NEXT", "PAIR", "RANGE", "OPEN_PAREN", "OPEN_SQUARE", "IF_MARK", "THEN_MARK", "EFFECT",
    "INPUT", "COPY", "CONVERT", "TABLE", "ELEMENT", "GATHER", "ITER", "SEED", "ARG",
]
MONOCHRONOUS = {
    "ADD", "SUB", "MUL", "DIV", "MOD", "NEG", "LT", "LE", "GT", "GE", "EQ", "NE", "AND", "OR", "XOR", "NOT", "SHL", "SHR",
    "CONVERT", "ELEMENT", "GATHER", "PAIR", "NEXT", "PREV", "ITER", "IF", "BRANCH", "ARG", "RANGE",
}
OPENERS = {"CALL", "OPEN_PAREN", "OPEN_SQUARE", "IF_MARK", "THEN_MARK"}
LEAVES = {"CONST", "SIGNAL", "ENUMCONST"}
UNARY = {"NEG", "NOT", "UWHEN", "CLOCK", "DELAY", "PREV"}
BINARY = [
    ("default", "DEFAULT", 3), ("when", "WHEN", 4), ("xor", "XOR", 11), ("or", "OR", 12), ("and", "AND", 13),
    ("=", "EQ", 16), ("/=", "NE", 16), ("<", "LT", 16), ("<=", "LE", 16), (">", "GT", 16), (">=", "GE", 16),
    ("+", "ADD", 17), ("-", "SUB", 17), ("*", "MUL", 18), ("/", "DIV", 18), ("modulo", "MOD", 18),
    ("shl", "SHL", 18), ("shr", "SHR", 18), ("next", "NEXT", 1), (":", "PAIR", 2), ("..", "RANGE", 1),
]
PREFIX = [("when", "UWHEN", 8), ("not", "NOT", 14), ("-", "NEG", 20), ("^", "CLOCK", 24)]
MODEL_CLASSES = ["process", "procedure", "node", "function", "automaton"]

TYPE_KINDS = ["EVENT", "BOOLEAN", "INT", "POINTER", "ENUM", "ARRAY", "EXTERNAL"]
BUILTIN_KIND = [0, 1, 2, 2, 2, 2, 2, 2, 2, 3]
BUILTIN_BYTES = [1, 1, 2, 4, 8, 1, 2, 4, 8, 8]
BUILTIN_SIGNED = [0, 0, 1, 1, 1, 0, 0, 0, 0, 0]
ROLES = ["input", "output", "local"]
TOKEN_KIND_NAMES = ["keyword", "name", "symbol", "number", "string", "eof"]
TOKEN_SECTIONS = ["kinds ", "texts ", "lines ", "columns "]

COLUMNS = [
    "name", "types.kind", "types.bytes", "types.signed", "types.name", "types.values", "types.element", "types.size",
    "models.name", "models.kind", "models.parent", "models.line", "models.column", "models.labels",
    "signal_names", "signal_roles", "signal_types", "signal_models", "signal_positions",
    "constant_names", "constant_types", "constant_values", "table_types", "table_values",
    "equation_targets", "equation_ops", "equation_args", "equation_positions", "equation_loops", "equation_kinds",
    "equation_models", "equation_labels", "equation_guards",
    "guard_models", "guard_ops", "guard_args", "guard_positions", "guard_context", "guard_labels", "guard_signals",
    "label_names", "label_uses", "loop_names", "loop_positions", "loop_models",
    "constraint_groups", "constraint_positions", "constraint_models", "constraint_guards",
    "dependence_from", "dependence_to", "dependence_positions", "dependence_models", "dependence_guards",
]
ROW_COLUMNS = [
    "rows.op", "rows.left", "rows.right", "rows.value", "rows.type", "rows.ctx", "rows.line", "rows.column",
    "rows.owner", "rows.loop", "rows.guard", "rows.groups", "rows.group_positions", "rows.dependence_from",
    "rows.dependence_to", "rows.war", "rows.snapshotted", "rows.effects.kind", "rows.effects.resource",
    "rows.effects.param", "loops.index", "loops.size", "loops.defined", "loops.snapshots", "loops.count",
]
CLOCK_COLUMNS = [
    "parent", "sample_rows", "def_kind", "def_target", "def_left", "def_right", "def_line", "def_column", "def_pending",
    "ob_small", "ob_big", "ob_line", "ob_column", "node_kind", "node_parent", "node_depth", "node_root", "node_left",
    "node_right", "roots",
]
SCHEDULE_COLUMNS = ["order", "loop_orders", "snapshots", "snapshotted"]
ALL_COLUMNS = COLUMNS + ROW_COLUMNS + CLOCK_COLUMNS + SCHEDULE_COLUMNS
TYPE_COLUMNS = [column for column in COLUMNS if column.startswith("types.")]
DUMP_ORDERS = [
    ("PROGRAM", COLUMNS), ("ROWS", ROW_COLUMNS + TYPE_COLUMNS + ["table_types", "table_values"]), ("CLOCKS", CLOCK_COLUMNS),
    ("SCHEDULE", SCHEDULE_COLUMNS),
]
CLOCK_KINDS = ["NONE", "ROOT", "SAMPLE", "PRODUCT", "SUM"]

ARGUMENT_KINDS = [
    "NONE", "TOKEN", "LITERAL", "NAME", "TYPE", "NUMBER", "CODE", "FRAGMENT", "CHARACTER", "FLAT", "TEXT", "LONG", "CLOCK",
]
TEMPLATES = [
    ("UNEXPECTED_CHARACTER", "unexpected character '#'", ["CHARACTER"]),
    ("CAPACITY", "program exceeds compiler capacity: #", ["FRAGMENT"]),
    ("EXPECTED_FOUND", "expected '#', found #", ["CODE", "TOKEN"]),
    ("EXPECTED_NAME", "expected a name, found #", ["TOKEN"]),
    ("RESERVED", "# is a reserved name", ["NAME"]),
    ("NAME_OF_MODEL", "# is the name of a model", ["NAME"]),
    ("DECLARED_TWICE", "# # is declared twice", ["FRAGMENT", "NAME"]),
    ("LITERAL_BIG", "integer literal # does not fit in long", ["LITERAL"]),
    ("CONSTANT_UNDECLARED", "constant # is not declared", ["NAME"]),
    ("EXPECTED_INTEGER_CONSTANT", "expected an integer constant, found #", ["TOKEN"]),
    ("CAPACITY_POSITIVE", "array capacity must be strictly positive", []),
    ("EXPECTED_TYPE", "expected a type, found #", ["TOKEN"]),
    ("EVENT_ARRAYS", "arrays of event are not supported", []),
    ("EXTERNAL_SIGNAL", "type # is external; signals cannot have that type", ["TYPE"]),
    ("INPUT_SCALAR", "input signal # must be a scalar", ["NAME"]),
    ("ARRAYS_TO_MODELS", "arrays cannot be passed to models", []),
    ("OUTPUT_ARRAY", "output # has an array type; outputs must be scalar", ["NAME"]),
    ("UNEXPECTED_AFTER", "unexpected # after the process model", ["TOKEN"]),
    ("ENUM_TWICE", "enumerated value # is declared twice", ["NAME"]),
    ("CONSTANT_STRING", "constant # has type # but its definition is a string", ["NAME", "TYPE"]),
    ("CONSTANT_LIST", "constant # has type # but its definition is a list", ["NAME", "TYPE"]),
    ("CONSTANT_ELEMENT", "constant # has type # but its definition has an element of type #", ["NAME", "TYPE", "TYPE"]),
    ("CONSTANT_TYPE", "constant # has type # but its definition has type #", ["NAME", "TYPE", "TYPE"]),
    ("CONSTANT_COUNT", "constant # has type # but its definition has # elements", ["NAME", "TYPE", "NUMBER"]),
    ("CONVERSION", "a conversion in a constant must name an integer type", []),
    ("CONSTANT_LITERAL", "a constant must be defined by an integer literal, a conversion of one, or a list of them", []),
    ("ONLY_DEFINITIONS", "only definitions are allowed inside iterate", []),
    ("ITERATE_NESTED", "iterate cannot be nested", []),
    ("ITERATE_GUARDED", "iterate is not allowed inside a guarded process", []),
    ("ARROW_NAMES", "--> requires signal names", []),
    ("EXPECTED_DEFINITION", "expected ':=' or '^=', found #", ["TOKEN"]),
    ("DELAY_INITIAL", "the initial value of a delay must be a constant", []),
    ("STATIC_PARAMETER", "expected a static parameter, found #", ["TOKEN"]),
    ("EXPECTED_EXPRESSION", "expected an expression, found #", ["TOKEN"]),
    ("EXPECTED_THEN", "expected 'then'", []),
    ("EXPECTED_ELSE", "expected 'else'", []),
    ("UNBALANCED", "unbalanced parenthesis", []),
    ("EXPECTED_OPERATOR", "expected an operator, found #", ["TOKEN"]),
    ("LABEL_UNDECLARED", "label # is not declared", ["NAME"]),
    ("NO_INPUT", "automaton # has no input; its control clock is the upper bound of its inputs", ["NAME"]),
    ("WRONG_ARGUMENTS", "wrong number of arguments for #: expected #, found #", ["NAME", "NUMBER", "NUMBER"]),
    ("LABEL_PLACED", "label # cannot be placed on #", ["NAME", "NAME"]),
    ("CANNOT_GUARD", "# cannot be guarded", ["NAME"]),
    ("EXPECTS_STATE", "# expects a state name of automaton #", ["NAME", "NAME"]),
    ("NOT_LABEL_OF", "# is not a label of automaton #", ["NAME", "NAME"]),
    ("ONE_INITIAL", "automaton # needs exactly one Automaton_Initial_State", ["NAME"]),
    ("ONLY_AUTOMATON", "# is allowed only in an automaton", ["NAME"]),
    ("NO_OUTPUT", "model # has no output and cannot be used in an expression", ["NAME"]),
    ("HAS_OUTPUT", "model # has an output and cannot be called as a process", ["NAME"]),
    ("NOT_STATE", "# is not a state of automaton #", ["NAME", "NAME"]),
    ("SIGNAL_UNDECLARED", "signal # is not declared", ["NAME"]),
    ("LABEL_AS_SIGNAL", "label # cannot be used as a signal", ["NAME"]),
    ("CONVERSION_ONE", "conversion to # expects one argument", ["NAME"]),
    ("INDICES_CONSTANT", "indices expects a positive constant", []),
    ("CALLS_IN_ITERATE", "model calls are not allowed inside iterate", []),
    ("UNSAFE_CALL", "unsafe model # is called from # #", ["NAME", "CODE", "NAME"]),
    ("MODEL_UNDECLARED", "model # is not declared", ["NAME"]),
    ("NO_STATIC_PARAMETERS", "model # takes no static parameters", ["NAME"]),
    ("CALLS_ITSELF", "model # calls itself", ["NAME"]),
    ("TOO_MANY_OUTPUTS", "model # has # outputs; only models with at most one output can be called", ["NAME", "NUMBER"]),
    ("FLAT_UNDECLARED", "signal # is not declared", ["FLAT"]),
    ("STATIC_COUNT", "# expects # static parameters, found #", ["NAME", "NUMBER", "NUMBER"]),
    ("WORD_CONSTANT", "the word of # must be an integer constant", ["NAME"]),
    ("TYPE_UNDECLARED_TEXT", "type # is not declared", ["TEXT"]),
    ("RESOURCE_EXTERNAL", "the resource of # must be an external type", ["NAME"]),
    ("ACCESS_TYPE", "# accesses an integer or pointer type, found #", ["NAME", "TEXT"]),
    ("WORD_RANGE", "the word of # must fit in 32 bits", ["NAME"]),
    ("PAIR_OPERAND", "':' is supported only as the right operand of next", []),
    ("INPUT_POINTER", "input 1 of # must be a pointer, found #", ["NAME", "TYPE"]),
    ("STORE_TYPE", "input 2 of store must have type #, found #", ["TYPE", "TYPE"]),
    ("SYSCALL_INPUT", "input # of syscall must be an integer or a pointer, found #", ["NUMBER", "TYPE"]),
    ("INSTRUCTION_INPUT", "input 1 of instruction must have type ulong, found #", ["TYPE"]),
    ("NOT_IN_ITERATE", "operator # is not allowed inside iterate", ["FRAGMENT"]),
    ("ARRAY_VALUE", "an array value can only be the whole definition of a signal", []),
    ("PREV_SIGNAL", "[?] applies only to a signal name", []),
    ("PREV_OUTSIDE", "#[?] is allowed only inside iterate", ["FLAT"]),
    ("PREV_UNDEFINED", "#[?] refers to a signal the iterate body does not define", ["FLAT"]),
    ("NOT_ARRAY", "indexing a value that is not an array", []),
    ("RANGE_START", "a range must start at 0", []),
    ("RANGE_BOUND", "the bound of a range must be an integer", []),
    ("INDEX_INTEGER", "an array index must be an integer", []),
    ("NEXT_PAIR", "next expects 'index : value' on its right", []),
    ("INDEX_RANGE", "constant index # is outside 0..#", ["LONG", "LONG"]),
    ("NEXT_TYPE", "next expects a value of type #, found #", ["TYPE", "TYPE"]),
    ("DELAY_ARRAY", "$ is not supported on arrays", []),
    ("SCALAR_OPERANDS", "operator # expects scalar operands", ["FRAGMENT"]),
    ("IF_TYPES", "operator if expects operands of comparable types, found # and #", ["TYPE", "TYPE"]),
    ("IF_CONDITION", "the condition of if must be boolean", []),
    ("EFFECT_IN_IF", "# cannot be inside an if; gate it by its clock or its inputs", ["NAME"]),
    ("NO_CONVERSION", "no conversion from # to #", ["TYPE", "TYPE"]),
    ("POINTER_OFFSET", "operator # expects a pointer and an integer offset", ["FRAGMENT"]),
    ("INTEGER_OPERANDS", "operator # expects integer operands", ["FRAGMENT"]),
    ("COMPARABLE", "operator # expects operands of comparable types, found # and #", ["FRAGMENT", "TYPE", "TYPE"]),
    ("ONE_TYPE", "operator # expects operands of one type", ["FRAGMENT"]),
    ("BOOLEAN_OPERANDS", "operator # expects boolean operands", ["FRAGMENT"]),
    ("UNSIGNED_OPERANDS", "operator # expects unsigned operands", ["FRAGMENT"]),
    ("WHEN_CONDITION", "the condition of when must be boolean", []),
    ("DELAY_MATCH", "the initial value of a delay must match its type", []),
    ("ENUM_UNDECLARED", "enumerated value # is not declared", ["NAME"]),
    ("ENUM_AMBIGUOUS", "enumerated value # is ambiguous", ["NAME"]),
    ("TYPE_UNDECLARED", "type # is not declared", ["NAME"]),
    ("NO_VALUE", "type # has no value #", ["NAME", "NAME"]),
    ("ITERATE_INDEX", "the index of iterate must be an array of integers", []),
    ("INDEX_DEFINED", "iterate body cannot define its index #", ["FLAT"]),
    ("WITH_UNDEFINED", "signal # in with is not defined by the iterate body", ["FLAT"]),
    ("WITH_READS", "the initial value of # cannot read a signal the iterate defines", ["FLAT"]),
    ("WITH_ARRAY", "with initializes an array only from an array constant or an array signal", []),
    ("SIGNAL_TYPE", "signal # has type # but its definition has type #", ["FLAT", "TYPE", "TYPE"]),
    ("INPUT_DEFINED", "input signal # cannot be defined", ["FLAT"]),
    ("DEFINED_TWICE", "signal # is defined twice", ["FLAT"]),
    ("RANGE_DEFINES", "a range defines an array of integers", []),
    ("ARRAY_DEFINITION", "an array signal must be defined by a constant, indices, a gather, or next", []),
    ("NEVER_DEFINED", "signal # is never defined", ["FLAT"]),
    ("RANGE_INDEX", "a range can only be the index of iterate", []),
    ("NO_CLOCK", "a constant has no clock", []),
    ("DELAY_CONSTANT", "the argument of $ cannot be a constant", []),
    ("FITS_NO_TREE", "clock of # fits no tree: it relates root clocks # and #", ["CLOCK", "CLOCK", "CLOCK"]),
    ("TWO_DEFINITIONS", "clock of # has two definitions that cannot be shown equal", ["CLOCK"]),
    ("CLOCK_CYCLE", "clocks of # are defined in terms of each other", ["CLOCK"]),
    ("GUARD_CYCLE", "the clocks of guards # depend on each other", ["CLOCK"]),
    ("NOT_INSIDE", "clock of # cannot be shown inside the clock #", ["CLOCK", "CLOCK"]),
    ("INPUT_ROOT", "input signal # must have a root of its own", ["FLAT"]),
    ("SIGNAL_CYCLE", "causality cycle between signals #", ["CLOCK"]),
    ("EFFECT_CYCLE", "causality cycle between effects at #", ["CLOCK"]),
    ("CLOCK_CAUSALITY", "causality cycle between clocks", []),
    ("EFFECTS_UNORDERED", "effects # and # on resource # have no order between them; order them with -->", ["CLOCK", "CLOCK", "TYPE"]),
]
CAPACITY_TABLES = [
    "SRC", "TOKENS", "NAMES", "TYPES", "VALUES", "MODELS", "SIGNALS", "CONSTANTS", "TABLES", "EQUATIONS", "ENTRIES",
    "GUARDS", "LABELS", "LOOPS", "GROUPS", "DEPENDENCES", "STACK", "PATHS", "LOCALS", "PARSE", "FINISH", "ITEMS",
    "OUTPUT", "INSTANCES", "INSTANTIATE", "LOOKUPS", "ROWS", "ROW_DEPENDENCES", "SEGMENTS", "LOWER",
    "CLOCKS", "DEFINITIONS", "OBLIGATIONS", "CLOCK_ROUNDS", "PAIRS", "CLOCK_NAMES",
    "EDGES", "SCHEDULE_NODES", "EFFECTS",
]
NAMED_FRAGMENTS = [
    ("COLON", ":"), ("ERROR_SEPARATOR", ": error: "), ("ERROR_WORD", "error "), ("SPACE", " "),
    ("ERRNO_PREFIX", "sigc: error: [Errno "), ("ERRNO_SUFFIX", "] "), ("QUOTE", "'"), ("ELLIPSIS", "..."),
    ("END_OF_FILE", "'end of file'"), ("NONE", "none"), ("OPEN", "["), ("CLOSE", "]"), ("OPEN_TWO", "[["),
    ("CLOSE_TWO", "]]"), ("CLOSE_THREE", "]]]"), ("EMPTY_LIST", "[]"), ("OPEN_NONE", "[none"),
    ("NONE_CLOSE", "none]"), ("CONST_OPEN", "[CONST ["), ("ENUMCONST_OPEN", "[ENUMCONST ["), ("SIZE_CLOSE", "] "),
    ("STATE_SUFFIX", "'state"), ("DEFINE", "DEFINE"), ("SEED", "SEED"),
    ("HASH", "#"), ("DOT", "."), ("CALL_SUFFIX", "'call"), ("EXPRESSION_AT", "[expression at "),
    ("AT", " at "),
]
ROLE_WORDS = ["signal", "type", "model", "constant", "label"]

LAYOUTS = ["NONE", "OS", "COMPILE", "DUMP_ERROR", "DUMP_TOKENS", "DUMP_PROGRAM"]
SLICES = ["NONE", "PATH"]
NUMBERS = ["NONE", "ERROR_LINE", "ERROR_COLUMN", "ERRNO"]
MESSAGE_SLOTS = 10
LAYOUT_ROWS = {
    "OS": [("ERRNO_PREFIX", "NONE", "ERRNO", "ERRNO_SUFFIX", 0, -1), ("", "PATH", "NONE", "", 1, -1)],
    "COMPILE": [
        ("", "PATH", "NONE", "COLON", 0, -1),
        ("", "NONE", "ERROR_LINE", "COLON", 0, -1),
        ("", "NONE", "ERROR_COLUMN", "ERROR_SEPARATOR", 0, -1),
        *[("", "NONE", "NONE", "", 0, slot) for slot in range(MESSAGE_SLOTS)],
        ("", "NONE", "NONE", "", 1, -1),
    ],
    "DUMP_ERROR": [
        ("ERROR_WORD", "NONE", "ERROR_LINE", "SPACE", 0, -1),
        ("", "NONE", "ERROR_COLUMN", "SPACE", 0, -1),
        *[("", "NONE", "NONE", "", 0, slot) for slot in range(MESSAGE_SLOTS)],
        ("", "NONE", "NONE", "", 1, -1),
    ],
}

POWERS = [10 ** k for k in range(20)]

PARSE_STATES = [
    "COPY_TYPES", "START", "MODEL_NAME", "MODEL_EQUAL", "MODEL_OPEN", "MODEL_QUESTION", "INPUTS", "MODEL_BANG",
    "OUTPUTS", "MODEL_CLOSE", "MODEL_BODY", "MODEL_AFTER", "PROGRAM", "END_SEMICOLON", "END_CHECK", "TYPE_STATEMENT",
    "TYPE_SKIP", "TYPE", "TYPE_SIZE", "TYPE_CLOSE", "TYPE_NAME", "TYPE_INTERN", "DECLARE_NAME", "DECLARE_SEPARATOR",
    "CONSTANT_NAME", "CONSTANT_EQUAL", "CONSTANT_DEFINITION", "INTEGER_CONSTANT", "CONSTANT_ELEMENT",
    "CONSTANT_SCALAR", "CONSTANT_SEPARATOR", "LABEL_NAME", "LABEL_SEPARATOR", "PROCESS", "PATH_COPY",
    "GUARD_COLONS", "ITERATE_NAME", "ITERATE_OF", "EQUATION", "DEPENDENCE", "EQUATION_END", "GROUP_MEMBER", "POP",
    "OPERAND", "PARAMETER", "PARAMETER_CLOSE", "OPERATOR", "BRANCH", "STALL", "DONE", "FAILED",
]
OPERAND_CASES = ["EMPTY_CALL", "LITERAL", "CALL", "PARAMETERS", "SIGNAL", "OPEN_PAREN", "IF", "PREFIX", "PLUS", "FAIL"]
OPERATOR_CASES = ["REDUCE", "BINARY", "THEN", "ELSE", "DELAY", "PREVIOUS", "OPEN_SQUARE", "CLOSE", "COMMA", "RETURN"]
FRAMES = ["COMPOSE", "LABEL", "GUARD", "ITERATE"]
DELAY_INITS = ["NONE", "CONST", "ENUMCONST"]
FINISH_PHASES = [
    "START", "LABEL", "USE", "SIGNAL", "STATEMENT", "REWRITE_EQ", "REWRITE_MEMBER", "REWRITE_GUARD",
    "REWRITE_TRIGGER", "CLOCK", "STATE", "CUR", "CUR_TAIL", "GROUP", "GUARD_START", "DEFINE_PARSE", "DEFINE_FINISH",
    "READ_PARSE", "READ_FINISH", "READ_MEMBERS", "READ_DEPS", "ON", "FILTER", "DONE", "FAILED",
]
LOWER_STATES = [
    "SIGNAL", "LABEL", "VALUE", "ARRAY", "TABLE", "LOOP", "EQUATION", "GROUP", "START", "SCAN", "ENTRY", "NEVER",
    "MEMBERS", "DONE", "FAILED",
]
POST_STATES = ["DEPENDENCE", "ROWS", "PREFIX", "PLACE", "WALK", "LABELSUM", "SIZE", "DONE", "FAILED"]
EXPAND_STATES = ["PLACE", "PAIRS", "PREV", "DONE", "FAILED"]
CLOCK_STATES = ["ROWS", "SAMPLES", "GROUPS", "REWRITE", "TARGETS", "GUARDS", "SCAN", "DEFS", "WAIT", "DONE", "FAILED"]
OBLIGATION_STATES = ["START", "WALK", "DONE", "FAILED"]
KEY_FAMILIES = ["SIGNAL", "LABEL", "CALL_LABEL", "VALUE", "PAIR", "ARRAY"]
KEY_STRIDE = 8
INSTANTIATE_PHASES = [
    "ROOT", "INSTANCE", "LABEL", "SIGNAL", "FINISH_SIGNAL", "LOOP", "EQUATION", "FINISH_EQUATION", "GROUP",
    "FINISH_GROUP", "DEPENDENCE", "ENTRY", "ANCESTRY", "PATH", "INPUT", "EMIT", "DONE", "FAILED",
]
SHAPES = ["NAME", "NUMBER", "FRAGMENT", "POSITION", "TYPE", "USE", "END_POINT", "LIST", "GROUP"]
SCALAR_ATOMS = ["NAME", "NUMBER", "FRAGMENT", "LINE", "COLUMN", "TYPE_HEAD", "TYPE_ELEMENT"]
SCALAR_PROGRAMS = {
    "NAME": ["NAME"], "NUMBER": ["NUMBER"], "FRAGMENT": ["FRAGMENT"], "POSITION": ["LINE", "COLUMN"],
    "TYPE": ["TYPE_HEAD", "TYPE_ELEMENT"], "USE": ["NUMBER", "NAME", "LINE", "COLUMN"],
    "END_POINT": ["NAME", "LINE", "COLUMN"],
}
SCALAR_WIDTH = 4
LIST_KINDS = ["NONE", "NAMES", "NUMBERS", "OPS", "ARGS"]
COLUMN_SHAPES = {
    "name": "NAME", "types.kind": "FRAGMENT", "types.name": "TYPE", "types.values": "LIST NAMES",
    "models.name": "NAME", "models.kind": "NAME", "models.labels": "LIST NAMES", "signal_names": "NAME",
    "signal_roles": "FRAGMENT", "signal_positions": "POSITION", "constant_names": "NAME", "table_values": "LIST NUMBERS",
    "equation_targets": "NAME", "equation_ops": "LIST OPS", "equation_args": "LIST ARGS",
    "equation_positions": "POSITION", "equation_kinds": "FRAGMENT", "equation_labels": "LIST NAMES",
    "equation_guards": "LIST NUMBERS", "guard_ops": "LIST OPS", "guard_args": "LIST ARGS",
    "guard_positions": "POSITION", "guard_context": "LIST NUMBERS", "guard_labels": "LIST NAMES",
    "guard_signals": "NAME", "label_names": "NAME", "label_uses": "USE", "loop_names": "NAME",
    "loop_positions": "POSITION", "constraint_groups": "GROUP", "constraint_positions": "POSITION",
    "constraint_guards": "LIST NUMBERS", "dependence_from": "END_POINT", "dependence_to": "END_POINT",
    "dependence_positions": "POSITION", "dependence_guards": "LIST NUMBERS",
    "rows.op": "FRAGMENT", "rows.groups": "LIST NUMBERS", "rows.group_positions": "POSITION",
    "rows.war": "LIST NUMBERS", "loop_orders": "LIST NUMBERS", "snapshots": "LIST NUMBERS", "rows.effects.kind": "NAME", "loops.defined": "LIST NUMBERS",
    "def_kind": "FRAGMENT", "node_kind": "FRAGMENT",
}
ITEM_CLASSES = ["HEADER", "NEWLINE", "OPEN", "CLOSE", "NAME", "TOKEN", "NUMBER", "FRAGMENT", "SIZE", "PREFIX"]
ARG_ATOMS = [
    "OPEN", "CLOSE", "NAME", "LINE", "COLUMN", "VALUE", "TYPE_NUMBER", "TYPE_NAME", "VALUE_NAME", "INIT_LINE",
    "INIT_COLUMN", "NONE", "CONST", "ENUMCONST", "PARAMS", "COUNT",
]
DELAY_VARIANTS = ["DELAY_NONE", "DELAY_CONST", "DELAY_ENUMCONST"]
ARG_PROGRAMS = {
    "CONST": ["OPEN", "VALUE", "TYPE_NUMBER", "CLOSE"],
    "SIGNAL": ["OPEN", "NAME", "LINE", "COLUMN", "CLOSE"],
    "ENUMCONST": ["OPEN", "TYPE_NAME", "VALUE_NAME", "LINE", "COLUMN", "CLOSE"],
    "CALL": ["OPEN", "LINE", "COLUMN", "NAME", "PARAMS", "COUNT", "CLOSE"],
    "EFFECT": ["OPEN", "LINE", "COLUMN", "NAME", "PARAMS", "COUNT", "CLOSE"],
    "DELAY_NONE": ["OPEN", "LINE", "COLUMN", "NONE", "CLOSE"],
    "DELAY_CONST": ["OPEN", "LINE", "COLUMN", "OPEN", "CONST", "OPEN", "VALUE", "TYPE_NUMBER", "CLOSE", "CLOSE", "CLOSE"],
    "DELAY_ENUMCONST": [
        "OPEN", "LINE", "COLUMN", "OPEN", "ENUMCONST", "OPEN", "TYPE_NAME", "VALUE_NAME", "INIT_LINE", "INIT_COLUMN",
        "CLOSE", "CLOSE", "CLOSE",
    ],
}
POSITION_PROGRAM = ["OPEN", "LINE", "COLUMN", "CLOSE"]
ARG_WIDTH = 13
CALL_PARAMS_STEP = 4
PARAM_STEPS = 6
CONDITION_PRECEDENCE = 9
DELAY_PRECEDENCE = 21


class Fragments:
    def __init__(self):
        self.texts = [""]

    def add(self, text):
        if text not in self.texts:
            self.texts.append(text)
        return self.texts.index(text)


def template_pieces(text):
    pieces = text.split("#")
    return pieces + [""] * (4 - len(pieces))


def signed64(value):
    return value - (1 << 64) if value >> 63 else value


def build():
    fragments = Fragments()
    constants = []

    def integer(name, value):
        constants.append((name, f"constant integer {name} = {value};"))

    def table(name, element, values, render=str):
        rendered = [render(v) for v in values]
        width = 24 if element in ("short", "integer") else 6
        rows = [", ".join(rendered[i:i + width]) for i in range(0, len(rendered), width)]
        body = ",\n        ".join(rows)
        constants.append((name, f"constant [{len(values)}] {element} {name} = [\n        {body}];"))

    named = {}
    for name, text in NAMED_FRAGMENTS:
        named[name] = fragments.add(text)
        integer(f"F_{name}", named[name])
    section_ids = [fragments.add(text) for text in TOKEN_SECTIONS]
    kind_ids = [fragments.add(text) for text in TOKEN_KIND_NAMES]
    op_ids = [fragments.add(op) for op in OPS]
    type_kind_ids = [fragments.add(kind) for kind in TYPE_KINDS]
    role_ids = [fragments.add(role) for role in ROLES]
    column_ids = [fragments.add(column + " ") for column in ALL_COLUMNS]
    role_word_ids = [fragments.add(word) for word in ROLE_WORDS]
    capacity_ids = [fragments.add(name) for name in CAPACITY_TABLES]
    symbol_ids = [fragments.add(text) for text, _ in SYMBOLS]
    piece_ids = [[fragments.add(piece) for piece in template_pieces(text)] for _, text, _ in TEMPLATES]

    seed = " ".join(SEED_WORDS)
    integer("SEED_LENGTH", len(seed))
    integer("SEED_NAME_COUNT", len(SEED_WORDS))
    constants.append(("SEED", f'constant [{len(seed)}] ubyte SEED = "{seed}";'))
    for word, name in NAME_CONSTANTS.items():
        integer(name, SEED_WORDS.index(word))
    for index, word in enumerate(SEED_WORDS):
        if word in KEYWORDS:
            integer(f"C_{word.upper()}", index + 1)
    for index, (_, name) in enumerate(SYMBOLS):
        integer(f"C_{name}", SYMBOL_BASE + index)
    for name, value in OTHER_CODES:
        integer(f"C_{name}", value)
    integer("C_SYMBOL_BASE", SYMBOL_BASE)

    name_char = [0] * 256
    alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_'"
    for code, character in enumerate(alphabet):
        name_char[ord(character)] = code
    table("NAME_CHAR", "short", name_char)
    single = [0] * 256
    double = [0] * 256
    for index, (text, _) in enumerate(SYMBOLS):
        code = SYMBOL_BASE + index
        if len(text) == 1:
            single[ord(text)] = code
        elif len(text) == 2 and text != ":=":
            double[ord(text[0])] = code
    table("SINGLE_SYMBOL", "short", single)
    table("DOUBLE_SYMBOL", "short", double)
    table("SYMBOL_FRAGMENT", "short", symbol_ids)

    for index, op in enumerate(OPS):
        integer(f"OP_{op}", index)
    table("OP_FRAGMENT", "short", op_ids)
    table("OP_IS_OPENER", "short", [int(op in OPENERS) for op in OPS])
    table("OP_ARITY", "short", [0 if op in LEAVES else 1 if op in UNARY else 2 for op in OPS])
    table("OP_MONOCHRONOUS", "short", [int(op in MONOCHRONOUS) for op in OPS])
    op_text = {op: text for text, op, _ in BINARY}
    op_text.update({op: text for text, op, _ in PREFIX})
    op_text.update({"DELAY": "$", "IF": "if", "BRANCH": "if"})
    table("OP_TEXT_FRAGMENT", "short", [fragments.add(op_text[op]) if op in op_text else 0 for op in OPS])

    def code_of(text):
        if text in KEYWORDS:
            return SEED_WORDS.index(text) + 1
        return SYMBOL_BASE + [symbol for symbol, _ in SYMBOLS].index(text)

    binary_op = [0] * CODE_LIMIT
    binary_precedence = [0] * CODE_LIMIT
    for text, op, precedence in BINARY:
        binary_op[code_of(text)] = OPS.index(op)
        binary_precedence[code_of(text)] = precedence
    table("BINARY_OP", "short", binary_op)
    table("BINARY_PRECEDENCE", "short", binary_precedence)
    prefix_op = [0] * CODE_LIMIT
    prefix_precedence = [0] * CODE_LIMIT
    for text, op, precedence in PREFIX:
        prefix_op[code_of(text)] = OPS.index(op)
        prefix_precedence[code_of(text)] = precedence
    table("PREFIX_OP", "short", prefix_op)
    table("PREFIX_PRECEDENCE", "short", prefix_precedence)
    class_codes = [code_of(word) for word in MODEL_CLASSES]
    table("MODEL_CLASS", "short", [int(code in class_codes) for code in range(CODE_LIMIT)])

    for index, kind in enumerate(TYPE_KINDS):
        integer(f"TK_{kind}", index)
    table("TYPE_KIND_FRAGMENT", "short", type_kind_ids)
    table("CLOCK_KIND_FRAGMENT", "short", [named["NONE"]] + [fragments.add(kind) for kind in CLOCK_KINDS[1:]])
    table("BUILTIN_KIND", "short", BUILTIN_KIND)
    table("BUILTIN_BYTES", "short", BUILTIN_BYTES)
    table("BUILTIN_SIGNED", "short", BUILTIN_SIGNED)
    for index, role in enumerate(ROLES):
        integer(f"ROLE_{role.upper()}", index)
    table("ROLE_FRAGMENT", "short", role_ids)
    for index, word in enumerate(ROLE_WORDS):
        integer(f"F_ROLE_{word.upper()}", role_word_ids[index])
    dump_order = []
    for name, columns in DUMP_ORDERS:
        integer(f"ORDER_{name}_START", len(dump_order))
        dump_order.extend(ALL_COLUMNS.index(column) for column in columns)
        integer(f"ORDER_{name}_END", len(dump_order))
    table("DUMP_ORDER", "short", dump_order)
    for index, column in enumerate(ALL_COLUMNS):
        integer(f"COL_{column.upper().replace('.', '_')}", index)
    table("COLUMN_FRAGMENT", "short", column_ids)
    for index, name in enumerate(CAPACITY_TABLES):
        integer(f"F_CAP_{name}", capacity_ids[index])
    table("SECTION_FRAGMENT", "short", section_ids)
    table("KIND_FRAGMENT", "short", kind_ids)

    for index, kind in enumerate(ARGUMENT_KINDS):
        integer(f"A_{kind}", index)
    for index, (name, _, _) in enumerate(TEMPLATES, 1):
        integer(f"T_{name}", index)
    rows = [[0, 0, 0, 0]] + piece_ids
    kinds = [[0, 0, 0]] + [[ARGUMENT_KINDS.index(k) for k in ks] + [0] * (3 - len(ks)) for _, _, ks in TEMPLATES]
    for slot in range(4):
        table(f"TEMPLATE_PIECE{slot}", "short", [row[slot] for row in rows])
    for slot in range(3):
        table(f"TEMPLATE_KIND{slot}", "short", [row[slot] for row in kinds])

    for index, name in enumerate(LAYOUTS):
        integer(f"LAYOUT_{name}", index)
    for index, name in enumerate(SLICES):
        integer(f"ROW_SLICE_{name}", index)
    for index, name in enumerate(NUMBERS):
        integer(f"ROW_NUMBER_{name}", index)
    layout_rows = []
    first_rows = []
    counts = []
    for name in LAYOUTS:
        first_rows.append(len(layout_rows))
        counts.append(len(LAYOUT_ROWS.get(name, [])))
        layout_rows.extend(LAYOUT_ROWS.get(name, []))
    table("LAYOUT_ITEM_COUNT", "short", counts)
    table("LAYOUT_FIRST_ROW", "short", first_rows)
    table("ROW_PREFIX", "short", [named[row[0]] if row[0] else 0 for row in layout_rows])
    table("ROW_SLICE", "short", [SLICES.index(row[1]) for row in layout_rows])
    table("ROW_NUMBER", "short", [NUMBERS.index(row[2]) for row in layout_rows])
    table("ROW_SUFFIX", "short", [named[row[3]] if row[3] else 0 for row in layout_rows])
    table("ROW_NEWLINE", "short", [row[4] for row in layout_rows])
    table("ROW_SLOT", "short", [row[5] for row in layout_rows])
    integer("MESSAGE_SLOTS", MESSAGE_SLOTS)

    table("POWERS_OF_TEN", "ulong", POWERS, lambda v: f"ulong({signed64(v)})")

    for index, word in enumerate(SEED_WORDS[:len(BUILTIN_KIND)]):
        integer(f"BUILTIN_{word.upper()}", index)
    for prefix, names in (("P", PARSE_STATES), ("X", OPERAND_CASES + OPERATOR_CASES), ("FRAME", FRAMES),
                          ("INIT", DELAY_INITS), ("PHASE", FINISH_PHASES),
                          ("IP", INSTANTIATE_PHASES), ("LS", LOWER_STATES), ("PS", POST_STATES),
                          ("XS", EXPAND_STATES), ("KS", CLOCK_STATES), ("OS", OBLIGATION_STATES), ("CLK", CLOCK_KINDS)):
        for index, name in enumerate(names):
            integer(f"{prefix}_{name}", index)
    integer("CONDITION_PRECEDENCE", CONDITION_PRECEDENCE)
    assert len(KEY_FAMILIES) <= KEY_STRIDE
    integer("KEY_STRIDE", KEY_STRIDE)
    for index, name in enumerate(KEY_FAMILIES):
        integer(f"KEY_{name}", index)
    for prefix, names in (("SHAPE", SHAPES), ("SA", SCALAR_ATOMS), ("LIST", LIST_KINDS), ("IC", ITEM_CLASSES),
                          ("AA", ARG_ATOMS)):
        for index, name in enumerate(names):
            integer(f"{prefix}_{name}", index)
    shapes = [COLUMN_SHAPES.get(column, "NUMBER").split() for column in ALL_COLUMNS]
    table("COLUMN_SHAPE", "short", [SHAPES.index(shape[0]) for shape in shapes])
    table("COLUMN_LIST_KIND", "short", [LIST_KINDS.index(shape[1]) if len(shape) > 1 else 0 for shape in shapes])
    integer("SCALAR_WIDTH", SCALAR_WIDTH)
    scalar_programs = [SCALAR_PROGRAMS.get(shape, []) for shape in SHAPES]
    table("SCALAR_LENGTH", "short", [len(program) for program in scalar_programs])
    table("SCALAR_PROGRAM", "short", [
        SCALAR_ATOMS.index(program[step]) if step < len(program) else 0
        for program in scalar_programs for step in range(SCALAR_WIDTH)])
    integer("OP_COUNT", len(OPS))
    integer("ARG_WIDTH", ARG_WIDTH)
    integer("CALL_PARAMS_STEP", CALL_PARAMS_STEP)
    integer("PARAM_STEPS", PARAM_STEPS)
    arg_programs = [ARG_PROGRAMS.get(name, POSITION_PROGRAM) for name in OPS + DELAY_VARIANTS]
    assert ARG_PROGRAMS["CALL"].index("PARAMS") == CALL_PARAMS_STEP
    assert all(len(program) <= ARG_WIDTH for program in arg_programs)
    table("ARG_LENGTH", "short", [len(program) for program in arg_programs])
    table("ARG_PROGRAM", "short", [
        ARG_ATOMS.index(program[step]) if step < len(program) else 0
        for program in arg_programs for step in range(ARG_WIDTH)])
    integer("DELAY_PRECEDENCE", DELAY_PRECEDENCE)

    text = "".join(fragments.texts)
    assert '"' not in text and "\n" not in text
    fragment_starts = []
    position = 0
    for fragment in fragments.texts:
        fragment_starts.append(position)
        position += len(fragment.encode())
    constants.append(("FRAGMENTS", f'constant [{len(text.encode())}] ubyte FRAGMENTS = "{text}";'))
    table("FRAGMENT_START", "short", fragment_starts)
    table("FRAGMENT_LENGTH", "short", [len(fragment.encode()) for fragment in fragments.texts])
    return constants


def declaration_pattern(name):
    return re.compile(r"    constant [^=;\"]*\b" + re.escape(name) + r' = (?:"[^"]*"|[^;"]*);\n')


def rewrite(source_text, constants):
    for name, declaration in constants:
        pattern = declaration_pattern(name)
        replacement = "    " + declaration + "\n"
        if pattern.search(source_text):
            source_text = pattern.sub(lambda _: replacement, source_text, count=1)
        else:
            source_text = source_text.replace(ANCHOR, replacement + ANCHOR, 1)
    return source_text


def main():
    original = SOURCE.read_text()
    updated = rewrite(original, build())
    if updated != original:
        SOURCE.write_text(updated)
    return 0


if __name__ == "__main__":
    sys.exit(main())
