import math
import re
import struct
import sys
from pathlib import Path

SOURCE = Path(__file__).resolve().parent / "sigc.sig"
ANCHOR = "    type ARGS = external;\n"

SEED_WORDS = [
    "event", "boolean", "short", "integer", "long", "ubyte", "ushort", "uinteger", "ulong", "pointer",
    "load", "store", "syscall", "instruction", "abs", "left_tt",
    "Automaton_Initial_State", "Automaton_Transition", "Automaton_IsIn",
    "clock'", "state'", "cur'", "on'",
    "process", "where", "end", "init", "true", "false", "when", "default", "and", "or", "xor", "not", "modulo",
    "shl", "shr", "type", "enum", "constant", "next", "iterate", "of", "with", "if", "then", "else", "procedure",
    "node", "function", "automaton", "label", "on", "external", "indices", "pragmas", "Interrupt", "Boot", "Machine",
    "cell", "var", "after", "from", "count", "case", "in", "array", "to",
    "cell'", "zcell'", "var'", "varm'", "zvar'", "h1'", "h2'", "m'", "a'", "za'", "s'", "zs'", "n'", "i'", "zcount'", "rep'",
]
FRESH_FIRST = "cell'"
FRESH_LAST = "rep'"
KEYWORDS = {
    "process", "where", "end", "init", "integer", "boolean", "event", "true", "false", "when", "default", "and", "or",
    "xor", "not", "modulo", "short", "long", "shl", "shr", "type", "enum", "constant", "next", "iterate", "of", "with",
    "if", "then", "else", "procedure", "node", "function", "automaton", "label", "on", "external",
    "cell", "var", "after", "from", "count", "case", "in", "array", "to",
}
NAME_CONSTANTS = {
    "event": "N_EVENT", "boolean": "N_BOOLEAN", "ubyte": "N_UBYTE", "ulong": "N_ULONG", "load": "N_LOAD",
    "store": "N_STORE", "syscall": "N_SYSCALL",
    "instruction": "N_INSTRUCTION", "abs": "N_ABS", "left_tt": "N_LEFT_TT", "Automaton_Initial_State": "N_INITIAL", "Automaton_Transition": "N_TRANSITION",
    "Automaton_IsIn": "N_ISIN", "clock'": "N_CLOCK_MARK", "state'": "N_STATE_MARK", "cur'": "N_CURRENT_MARK",
    "on'": "N_ON_MARK", "indices": "N_INDICES", "pragmas": "N_PRAGMAS", "Interrupt": "N_INTERRUPT", "Boot": "N_BOOT",
    "Machine": "N_MACHINE", "rep'": "N_REPEAT_MARK",
}
SYMBOLS = [
    ("(|", "OPEN_BAR"), ("|)", "BAR_CLOSE"), ("-->", "ARROW"), ("::", "COLONS"), (":=", "DEFINE"),
    ("^=", "CLOCK_EQUAL"), ("/=", "NOT_EQUAL"), ("<=", "LESS_EQUAL"), (">=", "GREATER_EQUAL"), ("..", "RANGE"),
    ("|", "BAR"), ("$", "DOLLAR"), ("+", "PLUS"), ("-", "MINUS"), ("*", "STAR"), ("/", "SLASH"), ("(", "OPEN"),
    (")", "CLOSE"), ("=", "EQUAL"), (";", "SEMICOLON"), (",", "COMMA"), ("?", "QUESTION"), ("!", "BANG"),
    ("<", "LESS"), (">", "GREATER"), ("^", "CARET"), ("#", "HASH"), ("[", "OPEN_BRACKET"), ("]", "CLOSE_BRACKET"),
    (":", "COLON"), ("{", "OPEN_BRACE"), ("}", "CLOSE_BRACE"),
    ("^+", "CLOCK_PLUS"), ("^*", "CLOCK_TIMES"), ("^-", "CLOCK_MINUS"), ("==", "EQUAL_EQUAL"),
    ("<<=", "LESS_LESS_EQUAL"), ("[:", "OPEN_COLON"), ("[/:", "OPEN_SLASH_COLON"), ("\\\\", "BACKSLASHES"),
    ("|*", "BAR_STAR"),
]
SYMBOL_BASE = 80
OTHER_CODES = [("EOF", 0), ("NAME", 128), ("NUMBER", 129), ("STRING", 130)]
CODE_LIMIT = 132
ESCAPES = {"a": 7, "b": 8, "f": 12, "n": 10, "r": 13, "t": 9, "v": 11, "\\": 92, '"': 34, "'": 39, "?": 63, "%": 37}

OPS = [
    "CONST", "SIGNAL", "ENUMCONST", "CALL", "DELAY", "PREV", "INDEX", "NEG", "NOT", "UWHEN", "CLOCK", "IF", "BRANCH",
    "DEFAULT", "WHEN", "XOR", "OR", "AND", "EQ", "NE", "LT", "LE", "GT", "GE", "ADD", "SUB", "MUL", "DIV", "MOD",
    "SHL", "SHR", "NEXT", "PAIR", "RANGE", "OPEN_PAREN", "OPEN_SQUARE", "IF_MARK", "THEN_MARK", "EFFECT",
    "INPUT", "COPY", "CONVERT", "TABLE", "ELEMENT", "GATHER", "ITER", "SEED", "ARG",
    "CLOCK_PLUS", "CLOCK_TIMES", "OPEN_COLON", "OPEN_SLASH_COLON", "LEFT_TT", "CLOCK_MINUS", "ABS", "OPERAND", "ZERO",
    "RECOVER", "RECOVER_SQUARE", "INDEX_OPERAND", "SIZE", "SIZE_LESS", "CELL", "VAR", "AFTER", "FROM", "COUNT",
    "REPEAT", "ONE", "RIGHT_OPERAND", "TARGET_SIGNAL", "INDEX_SIGNAL", "REPEAT_RANGE", "ARRAY_RANGE", "REPEAT_BODY",
]
MONOCHRONOUS = {
    "ADD", "SUB", "MUL", "DIV", "MOD", "NEG", "LT", "LE", "GT", "GE", "EQ", "NE", "AND", "OR", "XOR", "NOT", "SHL", "SHR",
    "CONVERT", "ELEMENT", "GATHER", "PAIR", "NEXT", "PREV", "ITER", "IF", "BRANCH", "ARG", "RANGE",
}
OPENERS = {"CALL", "OPEN_PAREN", "OPEN_SQUARE", "IF_MARK", "THEN_MARK", "OPEN_COLON", "OPEN_SLASH_COLON"}
BRACKETED = {"OPEN_SQUARE", "OPEN_COLON", "OPEN_SLASH_COLON"}
COMPOSITES = {
    "CLOCK_PLUS": (["CLOCK"], ["CLOCK", "DEFAULT"]), "CLOCK_TIMES": (["CLOCK"], ["CLOCK", "WHEN"]),
    "OPEN_COLON": ([], ["UWHEN"]), "OPEN_SLASH_COLON": ([], ["NOT", "UWHEN"]), "LEFT_TT": ([], ["WHEN", "DEFAULT"]),
    "CLOCK_MINUS": (["CLOCK"], ["CLOCK", "WHEN", "NOT", "OPERAND", "CLOCK", "DEFAULT", "UWHEN"]),
    "ABS": ([], ["ZERO", "LT", "OPERAND", "NEG", "OPERAND", "BRANCH", "IF"]),
    "RECOVER": (["INDEX_OPERAND", "ZERO", "GE", "INDEX_OPERAND", "SIZE_LESS", "LE", "AND", "WHEN"], ["RIGHT_OPERAND", "EQ", "INDEX_OPERAND", "ZERO", "GE", "AND", "RIGHT_OPERAND", "RIGHT_OPERAND", "BRANCH", "IF", "DEFAULT"]),
    "RECOVER_SQUARE": ([], ["SIZE", "MOD", "SIZE", "ADD", "SIZE", "MOD", "INDEX"]),
    "REPEAT_RANGE": ([], ["ZERO", "RIGHT_OPERAND", "ONE", "SUB", "RANGE"]),
    "ARRAY_RANGE": ([], ["ZERO", "RIGHT_OPERAND", "RANGE"]),
    "REPEAT_BODY": ([], ["TARGET_SIGNAL", "PREV", "INDEX_SIGNAL", "OPERAND", "PAIR", "NEXT"]),
}
LEAVES = {"CONST", "SIGNAL", "ENUMCONST"}
TEMPLATE_ROW_KINDS = ["EMIT", "LEFT", "RIGHT", "DEFINE", "GROUP", "END"]
TEMPLATE_VALUE_REFS = ["LITERAL", "INIT", "INIT_DECL", "BOUND"]
TEMPLATE_REFS = {"TARGET": -2, "OPERAND": -3, "BOUND": -4}
TEMPLATE_KINDS = {"CELL": 1, "AFTER": 1, "FROM": 1, "COUNT": 1, "VAR": 2}
TEMPLATE_SKIPS_LEFT = {"AFTER", "FROM", "COUNT"}


def template_emit(op, name=None, value=0, ref="LITERAL", type=None):
    return ("EMIT", op, name, value, ref, type)


def define(name, type):
    return ("DEFINE", None, name, 0, "LITERAL", type)


LEFT_ROW = ("LEFT", None, None, 0, "LITERAL", None)
RIGHT_ROW = ("RIGHT", None, None, 0, "LITERAL", None)
GROUP_ROW = ("GROUP", None, None, 0, "LITERAL", None)
END_ROW = ("END", None, None, 0, "LITERAL", None)


def template_literal(value, type="short"):
    return template_emit("CONST", value=value, type=type)


def counter_rest(next_count):
    return [
        LEFT_ROW, template_emit("CLOCK"), define("h1'", "event"),
        RIGHT_ROW, template_emit("CLOCK"), define("h2'", "event"),
        template_emit("SIGNAL", "h1'"), template_emit("SIGNAL", "h2'"), template_emit("DEFAULT"), define("m'", "event"),
        template_literal(1, "boolean"), template_emit("SIGNAL", "h2'"), template_emit("WHEN"), template_emit("SIGNAL", "za'"), template_emit("DEFAULT"),
        define("a'", "boolean"),
        template_emit("SIGNAL", "a'"), template_emit("DELAY", value=0, type="boolean"), define("za'", "boolean"),
        template_emit("SIGNAL", "n'"), template_emit("SIGNAL", "zs'"), template_emit("DEFAULT"), define("s'", "TARGET"),
        template_emit("SIGNAL", "s'"), template_emit("DELAY", value=0, type="short"), define("zs'", "TARGET"),
        *next_count, define("n'", "TARGET"),
        template_emit("SIGNAL", "zs'"), template_literal(1), template_emit("ADD"), template_emit("SIGNAL", "za'"), template_emit("WHEN"), template_emit("SIGNAL", "h1'"),
        template_emit("WHEN"), define("i'", "TARGET"),
        template_emit("SIGNAL", "a'"), template_emit("SIGNAL", "m'"), GROUP_ROW,
        template_emit("SIGNAL", "s'"), template_emit("SIGNAL", "m'"), GROUP_ROW, END_ROW,
    ]


COUNTER_INLINE = [
    template_emit("SIGNAL", "n'"), template_emit("SIGNAL", "h1'"), template_emit("WHEN"), template_literal(0), template_emit("SIGNAL", "h1'"), template_emit("WHEN"),
    template_emit("DEFAULT"),
]
TEMPLATE_PROGRAMS = {
    "CELL": ([template_emit("SIGNAL", "zcell'"), template_emit("DEFAULT")], [
        template_emit("SIGNAL", "TARGET"), template_emit("DELAY", ref="INIT_DECL"), define("zcell'", "TARGET"),
        LEFT_ROW, template_emit("CLOCK"), RIGHT_ROW, template_emit("UWHEN"), template_emit("DEFAULT"), define("cell'", "event"),
        template_emit("SIGNAL", "TARGET"), template_emit("SIGNAL", "cell'"), GROUP_ROW, END_ROW,
    ]),
    "VAR": ([template_emit("SIGNAL", "varm'"), template_emit("SIGNAL", "TARGET"), template_emit("CLOCK"), template_emit("WHEN")], [
        template_emit("SIGNAL", "OPERAND"), template_emit("SIGNAL", "zvar'"), template_emit("DEFAULT"), define("varm'", "OPERAND"),
        template_emit("SIGNAL", "varm'"), template_emit("DELAY", ref="INIT_DECL"), define("zvar'", "OPERAND"),
        template_emit("SIGNAL", "OPERAND"), template_emit("CLOCK"), template_emit("SIGNAL", "TARGET"), template_emit("CLOCK"), template_emit("DEFAULT"),
        define("var'", "event"),
        template_emit("SIGNAL", "varm'"), template_emit("SIGNAL", "var'"), GROUP_ROW, END_ROW,
    ]),
    "AFTER": (COUNTER_INLINE, counter_rest([
        template_literal(0), template_emit("SIGNAL", "h2'"), template_emit("WHEN"), template_emit("SIGNAL", "i'"), template_emit("DEFAULT")])),
    "FROM": (COUNTER_INLINE, counter_rest([
        template_literal(1), template_emit("SIGNAL", "h2'"), template_emit("WHEN"), template_emit("SIGNAL", "h1'"), template_emit("WHEN"), template_literal(0),
        template_emit("SIGNAL", "h2'"), template_emit("WHEN"), template_emit("DEFAULT"), template_emit("SIGNAL", "i'"), template_emit("DEFAULT")])),
    "COUNT": ([
        template_literal(0), template_emit("SIGNAL", "zcount'"), template_emit("CONST", ref="BOUND", type="BOUND"), template_emit("GE"), template_emit("WHEN"),
        template_emit("SIGNAL", "zcount'"), template_literal(1), template_emit("ADD"), template_emit("DEFAULT")], [
        template_emit("SIGNAL", "TARGET"), template_emit("DELAY", ref="BOUND", type="BOUND"), define("zcount'", "TARGET"),
        LEFT_ROW, template_emit("CLOCK"), define("h1'", "event"),
        template_emit("SIGNAL", "TARGET"), template_emit("SIGNAL", "h1'"), GROUP_ROW, END_ROW,
    ]),
}
UNARY = {"NEG", "NOT", "UWHEN", "CLOCK", "DELAY", "PREV", "VAR"}
BINARY = [
    ("default", "DEFAULT", 3), ("when", "WHEN", 4), ("xor", "XOR", 11), ("or", "OR", 12), ("and", "AND", 13),
    ("=", "EQ", 16), ("/=", "NE", 16), ("<", "LT", 16), ("<=", "LE", 16), (">", "GT", 16), (">=", "GE", 16),
    ("+", "ADD", 17), ("-", "SUB", 17), ("*", "MUL", 18), ("/", "DIV", 18), ("modulo", "MOD", 18),
    ("shl", "SHL", 18), ("shr", "SHR", 18), ("next", "NEXT", 1), (":", "PAIR", 2), ("..", "RANGE", 1),
    ("^+", "CLOCK_PLUS", 6), ("^*", "CLOCK_TIMES", 7), ("^-", "CLOCK_MINUS", 6), ("==", "EQ", 15), ("<<=", "LE", 15),
    ("\\\\", "RECOVER", 23), ("cell", "CELL", 21), ("after", "AFTER", 5), ("from", "FROM", 5), ("count", "COUNT", 5),
    ("|*", "REPEAT", 18),
]
PREFIX = [
    ("when", "UWHEN", 8), ("not", "NOT", 14), ("-", "NEG", 20), ("^", "CLOCK", 24),
    ("[:", "OPEN_COLON", 1), ("[/:", "OPEN_SLASH_COLON", 1), ("var", "VAR", 21),
]
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
    ("DELAY_INITIAL", "the initial value of a delay must be a literal or a constant name", []),
    ("STATIC_PARAMETER", "expected a static parameter, found #", ["TOKEN"]),
    ("EXPECTED_EXPRESSION", "expected an expression, found #", ["TOKEN"]),
    ("EXPECTED_THEN", "expected 'then'", []),
    ("EXPECTED_ELSE", "expected 'else'", []),
    ("UNBALANCED", "unbalanced parenthesis", []),
    ("EXPECTED_OPERATOR", "expected an operator, found #", ["TOKEN"]),
    ("RECOVERY_ACCESS", "expected an array access before #", ["TOKEN"]),
    ("ABS_SIGNED", "abs expects a signed integer, found #", ["TYPE"]),
    ("CASE_VALUE", "a case value must be a literal, found #", ["TOKEN"]),
    ("CASE_DUPLICATE", "value # is listed twice in this case", ["TOKEN"]),
    ("CLASS_NEEDS_OUTPUT", "# # must declare at least one output", ["CODE", "NAME"]),
    ("FUNCTION_MEMORY", "function # cannot contain #", ["NAME", "TOKEN"]),
    ("FUNCTION_CALL", "function # cannot call # #", ["NAME", "CODE", "NAME"]),
    ("WHOLE_DEFINITION", "# can only be the whole definition of a signal", ["TOKEN"]),
    ("VAR_NAME", "var takes a signal name", []),
    ("VAR_CONTEXT", "var is supported only where its context clock is the defined signal's clock", []),
    ("TEMPLATE_GUARDED", "# cannot be used inside a guard, case branch, label or state action", ["TOKEN"]),
    ("CONSTANT_BOUND", "the bound of # must be a positive integer literal or constant name", ["TOKEN"]),
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
    ("ARRAYS_ADDRESS", "arrays need more than 2^64 bytes of address space", []),
    ("PRAGMA_TOP_ONLY", "pragma # is allowed on the top model only", ["NAME"]),
    ("PRAGMAS_END", "expected 'end pragmas', found #", ["TOKEN"]),
    ("INTERRUPT_STATEMENT", "Interrupt expects an interrupt number in quotes, found #", ["TOKEN"]),
    ("INTERRUPT_NUMBER", "interrupt number # must be a decimal from 16 to 31", ["TOKEN"]),
    ("INTERRUPT_TWICE", "interrupt # is used twice", ["NUMBER"]),
    ("BOOT_TWICE", "pragma Boot is used twice", []),
    ("PRAGMA_INPUT", "pragma object # is not an input signal", ["NAME"]),
    ("PRAGMA_EVENT", "input signal # named by a pragma must be event", ["NAME"]),
    ("PRAGMA_TWICE", "input signal # is named by two pragmas", ["NAME"]),
    ("INPUT_UNNAMED", "input signal # must be named by an Interrupt or Boot pragma", ["NAME"]),
    ("VIRT_ROOT", "the root clock of # is not the clock of an Interrupt or Boot input", ["CLOCK"]),
    ("SYSCALL_VIRT", "syscall is not available on QEMU virt", []),
    ("BOOT_MISSING", "a program with Interrupt pragmas needs a Boot pragma to enable them", []),
    ("INPUT_SHARED", "input signals # and # share one root clock; each Interrupt or Boot input needs its own", ["NAME", "NAME"]),
    ("MACHINE_UNKNOWN", "machine # is not supported; use mps2-an385", ["TOKEN"]),
    ("MACHINE_TWICE", "pragma Machine is used twice", []),
    ("INTERRUPT_NUMBER_MPS2", "interrupt number # must be a decimal from 15 to 47", ["TOKEN"]),
    ("SYSCALL_MPS2", "syscall is not available on mps2-an385", []),
    ("IMAGE_SIZE", "the program needs more than the 4 MiB of RAM on mps2-an385", []),
    ("ESCAPE", "unknown escape '#' in a string", ["CHARACTER"]),
    ("ESCAPE_RANGE", "escape value # does not fit in a byte", ["NUMBER"]),
    ("HIDES_OUTPUT", "signal # is an # of # and cannot be hidden", ["NAME", "FRAGMENT", "NAME"]),
    ("MODEL_IN_INNER_WHERE", "a model cannot be declared in an inner where", []),
    ("INIT_UNUSED", "initial value of # is unused: # is not defined by $, cell or var", ["NAME", "NAME"]),
    ("REPEAT_TYPE", "'|*' expects a value of type #, found #", ["TYPE", "TYPE"]),
    ("COUNTER_EVENT", "operator # expects event operands, found #", ["FRAGMENT", "TYPE"]),
    ("REPEAT_SIZE", "'|*' produces # elements but the array has #", ["NUMBER", "NUMBER"]),
    ("RANGE_FIT", "the index range has # elements but the array has #", ["NUMBER", "NUMBER"]),
]
CAPACITY_TABLES = [
    "SRC", "TOKENS", "NAMES", "TYPES", "VALUES", "MODELS", "SIGNALS", "CONSTANTS", "TABLES", "EQUATIONS", "ENTRIES",
    "GUARDS", "LABELS", "LOOPS", "GROUPS", "DEPENDENCES", "STACK", "PATHS", "LOCALS", "PARSE", "FINISH", "ITEMS",
    "OUTPUT", "INSTANCES", "INSTANTIATE", "LOOKUPS", "ROWS", "ROW_DEPENDENCES", "SEGMENTS", "LOWER",
    "CLOCKS", "DEFINITIONS", "OBLIGATIONS", "PAIRS", "CLOCK_NAMES", "CLOCK_TEXT", "CLOCK_SORT",
    "EDGES", "SCHEDULE_NODES", "EFFECTS", "EFFECT_ORDER", "UNITS", "MICRO_OPS", "CODE", "CODE_LABELS", "DATA", "CODE_TEXT",
]
NAMED_FRAGMENTS = [
    ("COLON", ":"), ("ERROR_SEPARATOR", ": error: "), ("ERROR_WORD", "error "), ("SPACE", " "),
    ("ERRNO_PREFIX", "sigc: error: [Errno "), ("ERRNO_SUFFIX", "] "), ("QUOTE", "'"), ("ELLIPSIS", "..."),
    ("END_OF_FILE", "'end of file'"), ("NONE", "none"), ("OPEN", "["), ("CLOSE", "]"), ("OPEN_TWO", "[["),
    ("CLOSE_TWO", "]]"), ("CLOSE_THREE", "]]]"), ("EMPTY_LIST", "[]"), ("OPEN_NONE", "[none"),
    ("NONE_CLOSE", "none]"), ("CONST_OPEN", "[CONST ["), ("ENUMCONST_OPEN", "[ENUMCONST ["), ("SIZE_CLOSE", "] "),
    ("STATE_SUFFIX", "'state"), ("DEFINE", "DEFINE"), ("SEED", "SEED"),
    ("HASH", "#"), ("DOT", "."), ("CALL_SUFFIX", "'call"), ("EXPRESSION_AT", "[expression at "),
    ("AT", " at "), ("OUTPUT_FULL", "error 1 1 program exceeds compiler capacity: OUTPUT"),
    ("ENCODE_POSITION", ":0:0: error: "), ("OUT_OF_RANGE", " operand out of range: ["), ("LIST_SEPARATOR", ", "),
    ("PRESENCE_PREFIX", "presence inputs: "),
    ("UTF8_BYTE_PREFIX", "sigc: error: 'utf-8' codec can't decode byte 0x"),
    ("UTF8_BYTES_PREFIX", "sigc: error: 'utf-8' codec can't decode bytes in position "), ("IN_POSITION", " in position "),
    ("COLON_SPACE", ": "), ("DASH", "-"), ("RESERVATION_FAILED", "memory reservation failed"),
]
UTF8_REASONS = [
    ("INVALID_START", "invalid start byte"), ("INVALID_CONTINUATION", "invalid continuation byte"),
    ("UNEXPECTED_END", "unexpected end of data"),
]
ROLE_WORDS = ["signal", "type", "model", "constant", "label"]

LAYOUTS = [
    "NONE", "OS", "COMPILE", "DUMP_ERROR", "DUMP_TOKENS", "DUMP_PROGRAM", "DUMP_CODE", "ENCODE", "OS_OUTPUT", "PRESENCE",
    "UTF8_BYTE", "UTF8_BYTES",
]
SLICES = ["NONE", "PATH", "OUTPUT_PATH", "CLOCK"]
NUMBERS = [
    "NONE", "ERROR_LINE", "ERROR_COLUMN", "ERRNO", "ENCODE_OP0", "ENCODE_OP1", "ENCODE_OP2", "ENCODE_OP3", "OUTPUT_ERRNO",
    "UTF8_START", "UTF8_LAST",
]
COMPUTED_PREFIXES = ["FORM_NAME", "HEX_BYTE", "UTF8_REASON"]
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
    "ENCODE": [
        ("", "PATH", "NONE", "ENCODE_POSITION", 0, -1),
        ("FORM_NAME", "NONE", "NONE", "OUT_OF_RANGE", 0, -1),
        ("", "NONE", "ENCODE_OP0", "LIST_SEPARATOR", 0, -1),
        ("", "NONE", "ENCODE_OP1", "LIST_SEPARATOR", 0, -1),
        ("", "NONE", "ENCODE_OP2", "LIST_SEPARATOR", 0, -1),
        ("", "NONE", "ENCODE_OP3", "CLOSE", 1, -1),
    ],
    "OS_OUTPUT": [("ERRNO_PREFIX", "NONE", "OUTPUT_ERRNO", "ERRNO_SUFFIX", 0, -1), ("", "OUTPUT_PATH", "NONE", "", 1, -1)],
    "PRESENCE": [("PRESENCE_PREFIX", "CLOCK", "NONE", "", 1, -1)],
    "UTF8_BYTE": [
        ("UTF8_BYTE_PREFIX", "NONE", "NONE", "", 0, -1),
        ("HEX_BYTE", "NONE", "NONE", "IN_POSITION", 0, -1),
        ("", "NONE", "UTF8_START", "COLON_SPACE", 0, -1),
        ("UTF8_REASON", "NONE", "NONE", "", 1, -1),
    ],
    "UTF8_BYTES": [
        ("UTF8_BYTES_PREFIX", "NONE", "UTF8_START", "DASH", 0, -1),
        ("", "NONE", "UTF8_LAST", "COLON_SPACE", 0, -1),
        ("UTF8_REASON", "NONE", "NONE", "", 1, -1),
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
    "OPERAND", "PARAMETER", "PARAMETER_CLOSE", "OPERATOR", "BRANCH", "PRAGMA_NAME", "PRAGMA_OPEN", "PRAGMA_OBJECT",
    "PRAGMA_CLOSE", "PRAGMA_STATEMENT", "PRAGMA_OTHER", "PRAGMA_SKIP", "PRAGMA_TEXT", "SET_NAME", "SET_SEPARATOR",
    "SET_EMIT", "ALIAS_END", "HIDE_NAME", "HIDE_SEPARATOR", "DECLARE_INIT", "TUPLE_NAME", "TUPLE_SEPARATOR", "CASE_IN",
    "CASE_BRANCH", "CASE_COPY", "CASE_LITERAL", "CASE_SCAN", "CASE_ELSE_VALUE", "CASE_COMPARE", "CASE_JOIN",
    "CASE_SEPARATOR", "CASE_WHEN", "CASE_GUARD", "STATE_SIGNAL", "STATE_CALL", "STATE_WHEN", "STATE_GUARD", "SYNC",
    "REPEAT_START", "INDEX_EMIT", "REPEAT_EMIT", "ARRAY_TO", "INDEX_TYPE", "INDEX_DECLARE", "STALL", "DONE", "FAILED",
]
OPERAND_CASES = ["EMPTY_CALL", "LITERAL", "CALL", "PARAMETERS", "SIGNAL", "OPEN_PAREN", "IF", "PREFIX", "PLUS", "FAIL"]
OPERATOR_CASES = ["REDUCE", "BINARY", "THEN", "ELSE", "DELAY", "PREVIOUS", "OPEN_SQUARE", "CLOSE", "COMMA", "RETURN", "INIT"]
FRAMES = ["COMPOSE", "LABEL", "GUARD", "ITERATE", "CASE"]
DELAY_INITS = ["NONE", "CONST", "ENUMCONST", "NAME", "SIZE"]
FINISH_PHASES = [
    "START", "LABEL", "USE", "SIGNAL", "HIDE", "INITS", "STATEMENT", "REWRITE_EQ", "REWRITE_MEMBER", "REWRITE_GUARD",
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


FORMS = [
    "MOVZ_X", "MOVZ_W", "MOVK_X", "MOVK_W", "ADD_X_IMM", "ADD_W_IMM", "SUB_X_IMM", "SUB_W_IMM", "SUBS_X_IMM",
    "SUBS_W_IMM", "ADD_X", "ADDS_X", "SUB_X", "SUBS_X", "AND_X", "AND_W", "ORR_X", "ORR_W", "EOR_X", "ORN_X",
    "EOR_X_ONE", "LSLV_X", "LSRV_X", "SDIV_X", "UDIV_X", "MUL_X", "MSUB_X", "UMULH_X", "CSEL_X", "CSINC_W", "CSNEG_X",
    "LDR_X", "LDR_W", "LDRSW_X", "LDRH_W", "LDRSH_X", "LDRB_W", "STR_X", "STR_W", "STRH_W", "STRB_W",
    "LDR_X_REG", "LDR_W_REG", "LDRSW_X_REG", "LDRH_W_REG", "LDRSH_X_REG", "LDRB_W_REG", "STR_X_REG", "STR_W_REG",
    "STRH_W_REG", "STRB_W_REG", "LDR_X_POST", "STR_X_POST", "STR_W_POST", "STRB_W_POST", "LDRB_W_PRE",
    "B", "BL", "B_COND", "CBZ_W", "CBZ_X", "CBNZ_X", "ADRP", "RET", "SVC_80", "WORD", "WFI",
]
MOVE_X = ((0, 0, 5, 0), (2, 0, 16, 5), (3, 0, 2, 21))
MOVE_W = ((0, 0, 5, 0), (2, 0, 16, 5), (3, 0, 1, 21))
IMM12 = ((0, 0, 5, 0), (1, 0, 5, 5), (2, 0, 12, 10))
REG2 = ((0, 0, 5, 0), (1, 0, 5, 5))
REG3 = ((0, 0, 5, 0), (1, 0, 5, 5), (2, 0, 5, 16))
REG4 = ((0, 0, 5, 0), (1, 0, 5, 5), (2, 0, 5, 16), (3, 0, 5, 10))
SELECT = ((0, 0, 5, 0), (1, 0, 5, 5), (2, 0, 5, 16), (3, 0, 4, 12))
SCALED = tuple(((0, 0, 5, 0), (1, 0, 5, 5), (2, scale, 12, 10)) for scale in range(4))
INDEXED = ((0, 0, 5, 0), (1, 0, 5, 5), (2, 0, 9, 12))
BRANCH26 = ((2, 2, 26, 0),)
BRANCH19 = ((3, 0, 4, 0), (2, 2, 19, 5))
COMPARE_BRANCH = ((0, 0, 5, 0), (2, 2, 19, 5))
PAGE21 = ((0, 0, 5, 0), (2, 12, 2, 29), (2, 14, 19, 5))
WORD32 = ((2, 0, 32, 0),)
FIELD_KINDS = ["NONE", "PCREL", "PAGE", "PAGEOFF", "THUMB_PCREL", "ABS_LO", "ABS_HI"]
FORM_SPECS = [
    ("movz x", 0xD2800000, MOVE_X, False, "NONE"),
    ("movz w", 0x52800000, MOVE_W, False, "NONE"),
    ("movk x", 0xF2800000, MOVE_X, False, "NONE"),
    ("movk w", 0x72800000, MOVE_W, False, "NONE"),
    ("add x imm", 0x91000000, IMM12, False, "PAGEOFF"),
    ("add w imm", 0x11000000, IMM12, False, "NONE"),
    ("sub x imm", 0xD1000000, IMM12, False, "NONE"),
    ("sub w imm", 0x51000000, IMM12, False, "NONE"),
    ("subs x imm", 0xF1000000, IMM12, False, "NONE"),
    ("subs w imm", 0x71000000, IMM12, False, "NONE"),
    ("add x", 0x8B000000, REG3, False, "NONE"),
    ("adds x", 0xAB000000, REG3, False, "NONE"),
    ("sub x", 0xCB000000, REG3, False, "NONE"),
    ("subs x", 0xEB000000, REG3, False, "NONE"),
    ("and x", 0x8A000000, REG3, False, "NONE"),
    ("and w", 0x0A000000, REG3, False, "NONE"),
    ("orr x", 0xAA000000, REG3, False, "NONE"),
    ("orr w", 0x2A000000, REG3, False, "NONE"),
    ("eor x", 0xCA000000, REG3, False, "NONE"),
    ("orn x", 0xAA200000, REG3, False, "NONE"),
    ("eor x one", 0xD2400000, REG2, False, "NONE"),
    ("lslv x", 0x9AC02000, REG3, False, "NONE"),
    ("lsrv x", 0x9AC02400, REG3, False, "NONE"),
    ("sdiv x", 0x9AC00C00, REG3, False, "NONE"),
    ("udiv x", 0x9AC00800, REG3, False, "NONE"),
    ("mul x", 0x9B007C00, REG3, False, "NONE"),
    ("msub x", 0x9B008000, REG4, False, "NONE"),
    ("umulh x", 0x9BC07C00, REG3, False, "NONE"),
    ("csel x", 0x9A800000, SELECT, False, "NONE"),
    ("csinc w", 0x1A800400, SELECT, False, "NONE"),
    ("csneg x", 0xDA800400, SELECT, False, "NONE"),
    ("ldr x", 0xF9400000, SCALED[3], False, "PAGEOFF"),
    ("ldr w", 0xB9400000, SCALED[2], False, "PAGEOFF"),
    ("ldrsw x", 0xB9800000, SCALED[2], False, "PAGEOFF"),
    ("ldrh w", 0x79400000, SCALED[1], False, "PAGEOFF"),
    ("ldrsh x", 0x79800000, SCALED[1], False, "PAGEOFF"),
    ("ldrb w", 0x39400000, SCALED[0], False, "PAGEOFF"),
    ("str x", 0xF9000000, SCALED[3], False, "PAGEOFF"),
    ("str w", 0xB9000000, SCALED[2], False, "PAGEOFF"),
    ("strh w", 0x79000000, SCALED[1], False, "PAGEOFF"),
    ("strb w", 0x39000000, SCALED[0], False, "PAGEOFF"),
    ("ldr x reg", 0xF8607800, REG3, False, "NONE"),
    ("ldr w reg", 0xB8607800, REG3, False, "NONE"),
    ("ldrsw x reg", 0xB8A07800, REG3, False, "NONE"),
    ("ldrh w reg", 0x78607800, REG3, False, "NONE"),
    ("ldrsh x reg", 0x78A07800, REG3, False, "NONE"),
    ("ldrb w reg", 0x38606800, REG3, False, "NONE"),
    ("str x reg", 0xF8207800, REG3, False, "NONE"),
    ("str w reg", 0xB8207800, REG3, False, "NONE"),
    ("strh w reg", 0x78207800, REG3, False, "NONE"),
    ("strb w reg", 0x38206800, REG3, False, "NONE"),
    ("ldr x post", 0xF8400400, INDEXED, True, "NONE"),
    ("str x post", 0xF8000400, INDEXED, True, "NONE"),
    ("str w post", 0xB8000400, INDEXED, True, "NONE"),
    ("strb w post", 0x38000400, INDEXED, True, "NONE"),
    ("ldrb w pre", 0x38400C00, INDEXED, True, "NONE"),
    ("b", 0x14000000, BRANCH26, True, "PCREL"),
    ("bl", 0x94000000, BRANCH26, True, "PCREL"),
    ("b.cond", 0x54000000, BRANCH19, True, "PCREL"),
    ("cbz w", 0x34000000, COMPARE_BRANCH, True, "PCREL"),
    ("cbz x", 0xB4000000, COMPARE_BRANCH, True, "PCREL"),
    ("cbnz x", 0xB5000000, COMPARE_BRANCH, True, "PCREL"),
    ("adrp", 0x90000000, PAGE21, True, "PAGE"),
    ("ret", 0xD65F03C0, (), False, "NONE"),
    ("svc 0x80", 0xD4001001, (), False, "NONE"),
    ("word", 0x00000000, WORD32, False, "NONE"),
    ("wfi", 0xD503207F, (), False, "NONE"),
]


def memory_order(word):
    return ((word & 0xFFFF) << 16) | (word >> 16)


def memory_field(field):
    slot, low, width, at = field
    assert at + width <= 16 or at >= 16
    return (slot, low, width, at - 16 if at >= 16 else at + 16)


THUMB_IMM16 = ((0, 0, 4, 8), (2, 0, 8, 0), (2, 8, 3, 12), (2, 11, 1, 26), (2, 12, 4, 16))
THUMB_IMM12 = ((0, 0, 4, 8), (1, 0, 4, 16), (2, 0, 8, 0), (2, 8, 3, 12), (2, 11, 1, 26))
THUMB_IMM8 = ((0, 0, 4, 8), (1, 0, 4, 16), (2, 0, 8, 0))
THUMB_REG3 = ((0, 0, 4, 8), (1, 0, 4, 16), (2, 0, 4, 0))
THUMB_REG3_SHIFT = THUMB_REG3 + ((3, 0, 2, 6), (3, 2, 3, 12))
THUMB_REG2 = ((0, 0, 4, 8), (1, 0, 4, 0))
THUMB_SHIFT_IMM = ((0, 0, 4, 8), (1, 0, 4, 0), (2, 0, 2, 6), (2, 2, 3, 12))
THUMB_MULTIPLY = ((0, 0, 4, 8), (1, 0, 4, 16), (2, 0, 4, 0), (3, 0, 4, 12))
THUMB_LONG_MULTIPLY = ((0, 0, 4, 12), (1, 0, 4, 16), (2, 0, 4, 0), (3, 0, 4, 8))
THUMB_OFFSET12 = ((0, 0, 4, 12), (1, 0, 4, 16), (2, 0, 12, 0))
THUMB_OFFSET8 = ((0, 0, 4, 12), (1, 0, 4, 16), (2, 0, 8, 0))
THUMB_DUAL = ((0, 0, 4, 12), (1, 0, 4, 16), (2, 2, 8, 0), (3, 0, 4, 8))
THUMB_BRANCH = ((2, 1, 11, 0), (2, 12, 10, 16), (2, 22, 1, 26))
THUMB_SKIP = ((3, 0, 4, 24),)
THUMB_WORD = ((2, 0, 16, 0), (2, 16, 16, 16))
THUMB_SPECS = [
    ("MOVW_T", "movw", 0xF2400000, THUMB_IMM16, False, "NONE"),
    ("MOVT_T", "movt", 0xF2C00000, THUMB_IMM16, False, "NONE"),
    ("MOVW_ABS_T", "movw address", 0xF2400000, THUMB_IMM16, False, "ABS_LO"),
    ("MOVT_ABS_T", "movt address", 0xF2C00000, THUMB_IMM16, False, "ABS_HI"),
    ("ADDW_T", "addw", 0xF2000000, THUMB_IMM12, False, "NONE"),
    ("SUBW_T", "subw", 0xF2A00000, THUMB_IMM12, False, "NONE"),
    ("AND_T", "and.w", 0xEA000000, THUMB_REG3, False, "NONE"),
    ("ORR_T", "orr.w", 0xEA400000, THUMB_REG3, False, "NONE"),
    ("ORRS_T", "orrs.w", 0xEA500000, THUMB_REG3, False, "NONE"),
    ("EOR_T", "eor.w", 0xEA800000, THUMB_REG3, False, "NONE"),
    ("ADD_SHIFT_T", "add.w shifted", 0xEB000000, THUMB_REG3_SHIFT, False, "NONE"),
    ("ADDS_T", "adds.w", 0xEB100000, THUMB_REG3, False, "NONE"),
    ("ADC_T", "adc.w", 0xEB400000, THUMB_REG3, False, "NONE"),
    ("ADCS_T", "adcs.w", 0xEB500000, THUMB_REG3, False, "NONE"),
    ("SBC_T", "sbc.w", 0xEB600000, THUMB_REG3, False, "NONE"),
    ("SBCS_T", "sbcs.w", 0xEB700000, THUMB_REG3, False, "NONE"),
    ("SUBS_T", "subs.w", 0xEBB00000, THUMB_REG3, False, "NONE"),
    ("MOV_T", "mov.w", 0xEA4F0000, THUMB_REG2, False, "NONE"),
    ("MVN_T", "mvn.w", 0xEA6F0000, THUMB_REG2, False, "NONE"),
    ("LSL_T", "lsl.w", 0xFA00F000, THUMB_REG3, False, "NONE"),
    ("LSR_T", "lsr.w", 0xFA20F000, THUMB_REG3, False, "NONE"),
    ("LSL_IMM_T", "lsl.w imm", 0xEA4F0000, THUMB_SHIFT_IMM, False, "NONE"),
    ("LSR_IMM_T", "lsr.w imm", 0xEA4F0010, THUMB_SHIFT_IMM, False, "NONE"),
    ("ASR_IMM_T", "asr.w imm", 0xEA4F0020, THUMB_SHIFT_IMM, False, "NONE"),
    ("UMULL_T", "umull", 0xFBA00000, THUMB_LONG_MULTIPLY, False, "NONE"),
    ("MLA_T", "mla", 0xFB000000, THUMB_MULTIPLY, False, "NONE"),
    ("SUBS_IMM_T", "subs.w imm", 0xF1B00000, THUMB_IMM8, False, "NONE"),
    ("ADDS_IMM_T", "adds.w imm", 0xF1100000, THUMB_IMM8, False, "NONE"),
    ("ADC_IMM_T", "adc.w imm", 0xF1400000, THUMB_IMM8, False, "NONE"),
    ("SBCS_IMM_T", "sbcs.w imm", 0xF1700000, THUMB_IMM8, False, "NONE"),
    ("RSB_IMM_T", "rsb.w imm", 0xF1C00000, THUMB_IMM8, False, "NONE"),
    ("EOR_IMM_T", "eor.w imm", 0xF0800000, THUMB_IMM8, False, "NONE"),
    ("ORR_IMM_T", "orr.w imm", 0xF0400000, THUMB_IMM8, False, "NONE"),
    ("LDR_T", "ldr.w", 0xF8D00000, THUMB_OFFSET12, False, "NONE"),
    ("LDRB_T", "ldrb.w", 0xF8900000, THUMB_OFFSET12, False, "NONE"),
    ("LDRH_T", "ldrh.w", 0xF8B00000, THUMB_OFFSET12, False, "NONE"),
    ("LDRSH_T", "ldrsh.w", 0xF9B00000, THUMB_OFFSET12, False, "NONE"),
    ("STR_T", "str.w", 0xF8C00000, THUMB_OFFSET12, False, "NONE"),
    ("STRB_T", "strb.w", 0xF8800000, THUMB_OFFSET12, False, "NONE"),
    ("STRH_T", "strh.w", 0xF8A00000, THUMB_OFFSET12, False, "NONE"),
    ("LDRD_T", "ldrd", 0xE9D00000, THUMB_DUAL, False, "NONE"),
    ("STRD_T", "strd", 0xE9C00000, THUMB_DUAL, False, "NONE"),
    ("LDRD_POST_T", "ldrd post", 0xE8F00000, THUMB_DUAL, False, "NONE"),
    ("STRD_POST_T", "strd post", 0xE8E00000, THUMB_DUAL, False, "NONE"),
    ("STRB_POST_T", "strb post", 0xF8000B00, THUMB_OFFSET8, False, "NONE"),
    ("LDRB_POST_T", "ldrb post", 0xF8100B00, THUMB_OFFSET8, False, "NONE"),
    ("LDRB_PRE_DEC_T", "ldrb pre", 0xF8100D00, THUMB_OFFSET8, False, "NONE"),
    ("STR_PRE_DEC_T", "str pre", 0xF8400D00, THUMB_OFFSET8, False, "NONE"),
    ("LDR_POST_T", "ldr post", 0xF8500B00, THUMB_OFFSET8, False, "NONE"),
    ("B_W_T", "b.w", 0xF000B800, THUMB_BRANCH, True, "THUMB_PCREL"),
    ("BL_T", "bl", 0xF000F800, THUMB_BRANCH, True, "THUMB_PCREL"),
    ("SKIP_T", "b.n skip", 0xD002BF00, THUMB_SKIP, False, "NONE"),
    ("BX_LR_T", "bx lr", 0x4770BF00, (), False, "NONE"),
    ("WFI_T", "wfi.w", 0xF3AF8003, (), False, "NONE"),
    ("MSR_PRIMASK_T", "msr primask", 0xF3808810, (), False, "NONE"),
    ("WORD_T", "thumb word", 0x00000000, THUMB_WORD, False, "NONE"),
]
FORMS += [name for name, _, _, _, _, _ in THUMB_SPECS]
FORM_SPECS += [
    (text, memory_order(base), tuple(memory_field(field) for field in fields), signed, kind)
    for _, text, base, fields, signed, kind in THUMB_SPECS
]
FORM_FIELD_SLOTS = 5
MACHO_BASE = 0x100000000
TEXT_OFFSET = 392
COMMAND_BYTES = 360
SEGMENT_BYTES = 16384
ELF_VARIABLES = ["CONSTANT", "SIGNED_BYTES", "MEMORY_BYTES"]
HEADER_VARIABLES = ["CONSTANT", "TEXT_BYTES", "DATA_BYTES", "SIGNED_BYTES", "LINKEDIT_BYTES", "SIGNATURE_BYTES"]
SIGNATURE_VARIABLES = ["CONSTANT", "SIGNATURE_BYTES", "DIRECTORY_BYTES", "PAGES", "SIGNED_BYTES"]
SUPERBLOB_HEADER_BYTES = 20
CODE_DIRECTORY_HEADER_BYTES = 48
HASH_BYTES = 32
MARKER_BASE = 0xF0000000
CONDITIONS = {"EQ": 0, "NE": 1, "HS": 2, "LO": 3, "HI": 8, "LS": 9, "GE": 10, "LT": 11, "GT": 12, "LE": 13}
XZR = 31
SP = 31
UINTEGER_TYPE = 7
LOAD_FORMS = {
    (1, 0): ("LDRB_W", "LDRB_W_REG"), (2, 0): ("LDRH_W", "LDRH_W_REG"), (2, 1): ("LDRSH_X", "LDRSH_X_REG"),
    (4, 0): ("LDR_W", "LDR_W_REG"), (4, 1): ("LDRSW_X", "LDRSW_X_REG"), (8, 0): ("LDR_X", "LDR_X_REG"),
    (8, 1): ("LDR_X", "LDR_X_REG"),
}
STORE_FORMS = {1: ("STRB_W", "STRB_W_REG"), 2: ("STRH_W", "STRH_W_REG"), 4: ("STR_W", "STR_W_REG"), 8: ("STR_X", "STR_X_REG")}
OP_INSTRUCTIONS = {"ADD": "ADD_X", "SUB": "SUB_X", "MUL": "MUL_X", "AND": "AND_X", "OR": "ORR_X", "XOR": "EOR_X"}
OP_CONDITIONS = {
    "EQ": ("EQ", "EQ"), "NE": ("NE", "NE"), "LT": ("LT", "LO"), "LE": ("LE", "LS"), "GT": ("GT", "HI"), "GE": ("GE", "HS"),
}
OP_SHIFTS = {"SHL": "LSLV_X", "SHR": "LSRV_X"}
GLOBAL_LABELS = [
    "malformed", "reserve_failed", "read_value", "put_int", "put_uint", "put_bool", "step", "read_done", "wait", "complete",
    "divide",
]
EMIT_SOURCES = [
    "row", "left", "right", "right_left", "right_right", "param", "value_row",
    "arg0", "arg1", "arg2", "arg3", "arg4", "arg5", "arg6",
    "type_row", "size_left", "size_row", "words_row",
    "key_left", "key_right", "key_owner", "key_a_right", "key_a_row", "key_p_row",
    "clock_row", "clock_left", "clock_loop", "node_parent", "node_left", "node_right", "root_position",
    "input_root_position", "input_bound", "loop_count", "loop_size", "loop_size_less_one", "loop_condition",
    "window_offset", "window_bytes", "reservation", "line_capacity", "root_count",
    "load_param", "store_param", "load_indexed_row", "load_indexed_index", "load_indexed_element",
    "store_indexed_element", "instruction_op", "shift_op", "pair_form", "signed_condition", "unsigned_condition",
    "loop_start", "loop_end", "local0", "local1", "local2", "local3", "local4", "put_output", "root_irq",
    "binary_lo", "binary_hi", "pair_form_thumb", "signed_condition_thumb", "unsigned_condition_thumb", "element_row",
    "index_element",
] + GLOBAL_LABELS
EMIT_PREDICATES = [
    "always", "flag", "has_arg1", "has_arg2", "has_arg3", "has_arg4", "has_arg5", "has_arg6", "right_loads",
    "counted", "uncounted", "bounded", "keys_differ", "mul", "not_mul", "compare_equal", "compare_direct", "compare_swapped",
    "shift_left", "shift_right",
]
MICRO_KINDS = ["EMIT", "LI", "LOAD", "STORE", "OPERAND", "ADDRESS", "PLACE", "LOAD_AT", "STORE_AT"]
TARGET_KINDS = ["NONE", "LABEL", "TABLE", "WINDOW", "SIG", "MEM", "CLK", "IN", "OUT", "MALFORMED_TEXT", "RESERVE_TEXT", "TAIL", "STACK"]
SOURCE_BASE = 1 << 20
CC = CONDITIONS
CODE_COLUMNS = [
    "form", "op0", "op1", "op2", "op3", "target_section", "target_offset", "data_offsets", "data_alignments", "data",
]
EMIT_TEXT = "presence input malformed at step memory reservation failed"
UNIT_PHASES = [
    "PROLOGUE", "RESERVE", "WINDOW", "JUMP_STEP", "BOOT", "WAIT", "DISPATCH", "WAIT_TAIL", "RESERVE_FAILED", "READ_VALUE",
    "STEP", "READ_LINE", "VALUE_INPUT", "READ_TAIL", "ORDER", "DELAY", "OUTPUT_HEAD", "OUTPUT", "OUTPUT_TAIL", "FINISH",
]
VIRT_SUFFIX = "_VIRT"
VIRT_BASE = 0x40000000
VIRT_TEXT_OFFSET = 120
BOOT_ID = 1024
SPECIAL_ID = 1020
GICC_PAGE = 0x0801
GICC_IAR = 0x0C
GICC_EOIR = 0x10
UART_PAGE = 0x0900


def step(kind, when, form=0, a0=0, a1=0, a2=0, a3=0, target=("NONE", 0)):
    return (kind, when, form, a0, a1, a2, a3, target[0], target[1])


def emit(form, a0=0, a1=0, a2=0, a3=0, to=("NONE", 0), when="always"):
    return step("EMIT", when, form, a0, a1, a2, a3, to)


def li(register, value, when="always"):
    return step("LI", when, 0, register, value)


def ld(register, target, type_source, when="always"):
    return step("LOAD", when, 0, register, type_source, target=target)


def st(register, target, type_source, when="always"):
    return step("STORE", when, 0, register, type_source, target=target)


def operand(register, row, when="always"):
    return step("OPERAND", when, 0, register, row)


def address(register, key, when="always"):
    return step("ADDRESS", when, 0, register, key)


def place(label, when="always"):
    return step("PLACE", when, 0, label)


def label(name):
    return ("LABEL", name)


def copy_words(source_key, destination_key, words, loop_label, when="always"):
    return [
        address(12, source_key, when), address(13, destination_key, when), li(15, words, when), place(loop_label, when),
        emit("LDR_X_POST", 9, 12, 8, when=when), emit("STR_X_POST", 9, 13, 8, when=when),
        emit("SUBS_X_IMM", 15, 15, 1, when=when), emit("B_COND", a3=CC["NE"], to=label(loop_label), when=when),
    ]


def gated(body, stores=True):
    return (
        [ld(9, ("CLK", "clock_row"), UINTEGER_TYPE, "flag"), emit("CBZ_W", 9, to=label("local0"), when="flag")]
        + body + ([st(9, ("SIG", "row"), "type_row")] if stores else []) + [place("local0", "flag")]
    )


def generic(*tail):
    return [operand(9, "left"), operand(10, "right", "right_loads"), *tail]


def loop_bound(when):
    return [
        operand(11, "loop_count", when), li(12, "loop_size_less_one", when), emit("SUBS_X", XZR, 11, 12, when=when),
        emit("CSEL_X", 11, 11, 12, "loop_condition", when=when), emit("ADD_X_IMM", 11, 11, 1, when=when),
    ]


def system_call(number):
    return [emit("MOVZ_X", 16, 0, number), emit("SVC_80")]


PUT_NUMBER = [
    place("put_int"), emit("SUBS_X_IMM", XZR, 0, 0),
    emit("B_COND", a3=CC["GE"], to=label("put_uint")), emit("MOVZ_W", 10, 0, 45), emit("STRB_W_POST", 10, 20, 1),
    emit("SUB_X", 0, XZR, 0), place("put_uint"), emit("ORR_X", 9, XZR, 0), emit("SUB_X_IMM", SP, SP, 32),
    emit("ADD_X_IMM", 11, SP, 0), emit("ADD_X_IMM", 15, SP, 0), emit("MOVZ_X", 12, 0, 10), place("local0"),
    emit("UDIV_X", 13, 9, 12), emit("MSUB_X", 14, 13, 12, 9), emit("ADD_W_IMM", 14, 14, 48),
    emit("STRB_W_POST", 14, 11, 1), emit("ORR_X", 9, XZR, 13), emit("CBNZ_X", 9, to=label("local0")), place("local1"),
    emit("LDRB_W_PRE", 14, 11, -1), emit("STRB_W_POST", 14, 20, 1), emit("SUBS_X", XZR, 11, 15),
    emit("B_COND", a3=CC["NE"], to=label("local1")), emit("ADD_X_IMM", SP, SP, 32), emit("RET"),
]


EMIT_TEMPLATES = [
    ("PROLOGUE", [emit("ORR_X", 25, XZR, 0), emit("ORR_X", 26, XZR, 1), emit("MOVZ_X", 22)]),
    ("RESERVE", [
        emit("MOVZ_X", 0), li(1, "reservation"), emit("MOVZ_X", 2), emit("MOVZ_X", 3, 0, 0x1002), emit("ORN_X", 4, XZR, XZR),
        emit("MOVZ_X", 5), *system_call(197), emit("B_COND", a3=CC["HS"], to=label("reserve_failed")),
        emit("ORR_X", 24, XZR, 0),
    ]),
    ("WINDOW", [
        li(9, "window_offset"), emit("ADD_X", 0, 24, 9), emit("ADRP", 8, to=("WINDOW", "row")),
        emit("STR_X", 0, 8, to=("WINDOW", "row")), li(1, "window_bytes"), emit("MOVZ_X", 2, 0, 3), *system_call(74),
        emit("B_COND", a3=CC["HS"], to=label("reserve_failed")),
    ]),
    ("JUMP_STEP", [emit("B", to=label("step"))]),
    ("RESERVE_FAILED", [
        place("reserve_failed"), emit("MOVZ_X", 0, 0, 2), emit("ADRP", 1, to=("RESERVE_TEXT", 0)),
        emit("ADD_X_IMM", 1, 1, to=("RESERVE_TEXT", 0)), emit("MOVZ_X", 2, 0, 26), *system_call(4), emit("MOVZ_X", 0, 0, 3),
        *system_call(1),
    ]),
    ("READ_VALUE", [
        place("read_value"), emit("LDRB_W_REG", 9, 21, 19), emit("SUBS_W_IMM", XZR, 9, 32),
        emit("B_COND", a3=CC["NE"], to=label("malformed")), emit("ADD_X_IMM", 19, 19, 1), emit("MOVZ_X", 11),
        emit("LDRB_W_REG", 9, 21, 19), emit("SUBS_W_IMM", XZR, 9, 45), emit("B_COND", a3=CC["NE"], to=label("local0")),
        emit("MOVZ_X", 11, 0, 1), emit("ADD_X_IMM", 19, 19, 1), place("local0"), emit("MOVZ_X", 0), emit("MOVZ_X", 12),
        emit("MOVZ_X", 13, 0, 10), place("local1"), emit("LDRB_W_REG", 9, 21, 19), emit("SUB_W_IMM", 9, 9, 48),
        emit("SUBS_W_IMM", XZR, 9, 9), emit("B_COND", a3=CC["HI"], to=label("local2")), emit("UMULH_X", 14, 0, 13),
        emit("CBNZ_X", 14, to=label("malformed")), emit("MUL_X", 0, 0, 13), emit("ADDS_X", 0, 0, 9),
        emit("B_COND", a3=CC["HS"], to=label("malformed")), emit("ADD_X_IMM", 19, 19, 1), emit("ADD_X_IMM", 12, 12, 1),
        emit("B", to=label("local1")), place("local2"), emit("CBZ_X", 12, to=label("malformed")),
        emit("SUBS_X_IMM", XZR, 12, 20), emit("B_COND", a3=CC["HI"], to=label("malformed")),
        emit("CBZ_X", 11, to=label("local3")), emit("SUB_X", 0, XZR, 0), place("local3"), emit("RET"),
    ]),
    ("STEP", [place("step"), emit("ADD_X_IMM", 22, 22, 1)]),
    ("READ_LINE", [
        emit("ADRP", 21, to=("IN", 0)), emit("ADD_X_IMM", 21, 21, to=("IN", 0)), emit("MOVZ_X", 19), place("local0"),
        emit("MOVZ_X", 0), emit("ADD_X", 1, 21, 19), emit("MOVZ_X", 2, 0, 1), *system_call(3),
        emit("B_COND", a3=CC["HS"], to=label("malformed")), emit("CBNZ_X", 0, to=label("local1")),
        emit("CBNZ_X", 19, to=label("malformed")), emit("MOVZ_X", 0), *system_call(1), place("local1"),
        emit("LDRB_W_REG", 9, 21, 19), emit("SUBS_W_IMM", XZR, 9, 10), emit("B_COND", a3=CC["EQ"], to=label("local2")),
        emit("ADD_X_IMM", 19, 19, 1), li(11, "line_capacity"), emit("SUBS_X", XZR, 19, 11),
        emit("B_COND", a3=CC["LS"], to=label("local0")), emit("B", to=label("malformed")), place("local2"),
        li(11, "root_count"), emit("SUBS_X", XZR, 19, 11), emit("B_COND", a3=CC["LO"], to=label("malformed")),
        emit("MOVZ_X", 19), place("local3"), emit("SUBS_X", XZR, 19, 11), emit("B_COND", a3=CC["EQ"], to=label("local4")),
        emit("LDRB_W_REG", 9, 21, 19), emit("SUB_W_IMM", 9, 9, 48), emit("SUBS_W_IMM", XZR, 9, 1),
        emit("B_COND", a3=CC["HI"], to=label("malformed")), emit("ADD_X_IMM", 19, 19, 1), emit("B", to=label("local3")),
        place("local4"),
    ]),
    ("VALUE_INPUT", [
        li(10, "input_root_position"), emit("LDRB_W_REG", 9, 21, 10), emit("SUBS_W_IMM", XZR, 9, 49),
        emit("B_COND", a3=CC["NE"], to=label("local0")), emit("BL", to=label("read_value")),
        emit("CBNZ_X", 11, to=label("malformed"), when="bounded"), li(12, "input_bound", "bounded"),
        emit("SUBS_X", XZR, 0, 12, when="bounded"), emit("B_COND", a3=CC["HS"], to=label("malformed"), when="bounded"),
        st(0, ("SIG", "row"), "type_row"), place("local0"),
    ]),
    ("READ_TAIL", [
        emit("LDRB_W_REG", 9, 21, 19), emit("SUBS_W_IMM", XZR, 9, 10), emit("B_COND", a3=CC["EQ"], to=label("read_done")),
        place("malformed"), emit("MOVZ_X", 0, 0, 2), emit("ADRP", 1, to=("MALFORMED_TEXT", 0)),
        emit("ADD_X_IMM", 1, 1, to=("MALFORMED_TEXT", 0)), emit("MOVZ_X", 2, 0, 33), *system_call(4),
        emit("ADRP", 20, to=("OUT", 0)), emit("ADD_X_IMM", 20, 20, to=("OUT", 0)), emit("ORR_X", 0, XZR, 22),
        emit("BL", to=label("put_int")), emit("MOVZ_W", 10, 0, 10), emit("STRB_W_POST", 10, 20, 1), emit("MOVZ_X", 0, 0, 2),
        emit("ADRP", 1, to=("OUT", 0)), emit("ADD_X_IMM", 1, 1, to=("OUT", 0)), emit("SUB_X", 2, 20, 1), *system_call(4),
        emit("MOVZ_X", 0, 0, 2), *system_call(1), place("read_done"),
    ]),
    ("LOOP_HEAD", [ld(9, ("CLK", "clock_loop"), UINTEGER_TYPE), emit("CBZ_W", 9, to=label("loop_end"))]),
    ("LOOP_MID", [
        emit("MOVZ_X", 23), *loop_bound("counted"), emit("SUBS_X", XZR, 23, 11, when="counted"),
        emit("B_COND", a3=CC["GE"], to=label("loop_end"), when="counted"), place("loop_start"),
    ]),
    ("SNAPSHOT", copy_words("key_a_row", "key_p_row", "words_row", "local0")),
    ("LOOP_TAIL", [
        emit("ADD_X_IMM", 23, 23, 1), *loop_bound("counted"), li(11, "loop_size", "uncounted"), emit("SUBS_X", XZR, 23, 11),
        emit("B_COND", a3=CC["LO"], to=label("loop_start")), place("loop_end"),
    ]),
    ("CLOCK_ROOT_READ", [
        li(10, "root_position"), emit("LDRB_W_REG", 9, 21, 10), emit("SUBS_W_IMM", XZR, 9, 49),
        emit("CSINC_W", 9, XZR, XZR, CC["EQ"] ^ 1), st(9, ("CLK", "row"), UINTEGER_TYPE),
    ]),
    ("CLOCK_ROOT", [emit("MOVZ_W", 9, 0, 1), st(9, ("CLK", "row"), UINTEGER_TYPE)]),
    ("CLOCK_SAMPLE", [
        ld(9, ("CLK", "node_parent"), UINTEGER_TYPE), operand(10, "node_left"), emit("AND_W", 9, 9, 10),
        st(9, ("CLK", "row"), UINTEGER_TYPE),
    ]),
    ("CLOCK_PAIR", [
        ld(9, ("CLK", "node_left"), UINTEGER_TYPE), ld(10, ("CLK", "node_right"), UINTEGER_TYPE),
        emit("pair_form", 9, 9, 10), st(9, ("CLK", "row"), UINTEGER_TYPE),
    ]),
    ("ROW_SEED_ARRAY", gated(copy_words("key_left", "key_a_right", "words_row", "local1"), False)),
    ("ROW_SEED", gated([operand(9, "left"), st(9, ("SIG", "right"), "type_row")], False)),
    ("ROW_LOAD", gated([operand(9, "arg0"), emit("load_param", 9, 9, 0)])),
    ("ROW_STORE", gated([operand(9, "arg0"), operand(10, "arg1"), emit("store_param", 10, 9, 0)], False)),
    ("ROW_SYSCALL", gated([
        *[operand(register, f"arg{register + 1}", f"has_arg{register + 1}") for register in range(6)],
        operand(16, "arg0"), emit("SVC_80"), emit("CSNEG_X", 9, 0, 0, CC["HS"] ^ 1),
    ])),
    ("ROW_INSTRUCTION", gated([operand(0, "arg0"), emit("WORD", a2="param"), emit("ORR_X", 9, XZR, 0)])),
    ("ROW_ITER_RANGE", gated([emit("ORR_X", 9, XZR, 23)])),
    ("ROW_ITER", gated([address(12, "key_left"), emit("load_indexed_row", 9, 12, 23)])),
    ("ROW_PREV", gated([ld(9, ("SIG", "left"), "type_row")])),
    ("ROW_ELEMENT", gated([
        address(12, "key_left"), operand(10, "right"), li(11, "size_left"), emit("MOVZ_X", 9), emit("SUBS_X", XZR, 10, 11),
        emit("B_COND", a3=CC["HS"], to=label("local1")), emit("load_indexed_row", 9, 12, 10), place("local1"),
    ])),
    ("ROW_GATHER", gated([
        address(12, "key_left"), address(13, "key_right"), address(14, "key_owner"), emit("MOVZ_X", 15), place("local1"),
        emit("load_indexed_index", 10, 13, 15), emit("MOVZ_X", 9), li(11, "size_left"), emit("SUBS_X", XZR, 10, 11),
        emit("B_COND", a3=CC["HS"], to=label("local2")), emit("load_indexed_element", 9, 12, 10), place("local2"),
        emit("store_indexed_element", 9, 14, 15), emit("ADD_X_IMM", 15, 15, 1), li(17, "size_row"),
        emit("SUBS_X", XZR, 15, 17), emit("B_COND", a3=CC["LO"], to=label("local1")),
    ], False)),
    ("ROW_NEXT", gated([
        *copy_words("key_left", "key_owner", "words_row", "local1", "keys_differ"), address(12, "key_owner"),
        operand(10, "right_left"), operand(9, "right_right"), li(11, "size_row"), emit("SUBS_X", XZR, 10, 11),
        emit("B_COND", a3=CC["HS"], to=label("local2")), emit("store_indexed_element", 9, 12, 10), place("local2"),
    ], False)),
    ("ROW_CONST", gated([operand(9, "row")])),
    ("ROW_DELAY", gated([ld(9, ("MEM", "row"), "type_row")])),
    ("ROW_ONE", gated([emit("MOVZ_X", 9, 0, 1)])),
    ("ROW_IF", gated([
        operand(9, "left"), operand(10, "right_left"), operand(11, "right_right"), emit("SUBS_X_IMM", XZR, 9, 0),
        emit("CSEL_X", 9, 10, 11, CC["NE"]),
    ])),
    ("ROW_DEFAULT", gated([
        ld(11, ("CLK", "clock_left"), UINTEGER_TYPE), operand(9, "left"), operand(10, "right"),
        emit("SUBS_W_IMM", XZR, 11, 0), emit("CSEL_X", 9, 9, 10, CC["NE"]),
    ])),
    ("ROW_PLAIN", gated(generic())),
    ("ROW_NEG", gated(generic(emit("SUB_X", 9, XZR, 9)))),
    ("ROW_NOT_LOGICAL", gated(generic(emit("EOR_X_ONE", 9, 9)))),
    ("ROW_NOT", gated(generic(emit("ORN_X", 9, XZR, 9)))),
    ("ROW_BINARY", gated(generic(emit("instruction_op", 9, 9, 10)))),
    ("ROW_DIV_SIGNED", gated(generic(emit("SDIV_X", 9, 9, 10)))),
    ("ROW_DIV", gated(generic(emit("UDIV_X", 9, 9, 10)))),
    ("ROW_COMPARE_SIGNED", gated(generic(emit("SUBS_X", XZR, 9, 10), emit("CSINC_W", 9, XZR, XZR, "signed_condition")))),
    ("ROW_COMPARE", gated(generic(emit("SUBS_X", XZR, 9, 10), emit("CSINC_W", 9, XZR, XZR, "unsigned_condition")))),
    ("ROW_MOD_SIGNED", gated(generic(
        emit("SDIV_X", 11, 9, 10), emit("MSUB_X", 11, 11, 10, 9), emit("SUBS_X_IMM", XZR, 10, 0),
        emit("CSNEG_X", 12, 10, 10, CC["LT"] ^ 1), emit("ADD_X", 12, 11, 12), emit("SUBS_X_IMM", XZR, 11, 0),
        emit("CSEL_X", 9, 12, 11, CC["LT"]),
    ))),
    ("ROW_MOD", gated(generic(emit("UDIV_X", 11, 9, 10), emit("MSUB_X", 9, 11, 10, 9)))),
    ("ROW_SHIFT", gated(generic(
        emit("SUBS_X_IMM", XZR, 10, 64), emit("shift_op", 11, 9, 10), emit("CSEL_X", 9, 11, XZR, CC["LO"]),
    ))),
    ("DELAY", [
        ld(9, ("CLK", "clock_row"), UINTEGER_TYPE), emit("CBZ_W", 9, to=label("local0")),
        ld(9, ("SIG", "left"), "type_row"), st(9, ("MEM", "row"), "type_row"), place("local0"),
    ]),
    ("OUTPUT_HEAD", [emit("ADRP", 20, to=("OUT", 0)), emit("ADD_X_IMM", 20, 20, to=("OUT", 0))]),
    ("OUTPUT", [
        emit("MOVZ_W", 10, 0, 32, when="flag"), emit("STRB_W_POST", 10, 20, 1, when="flag"),
        ld(9, ("CLK", "clock_row"), UINTEGER_TYPE), emit("CBZ_W", 9, to=label("local0")), ld(0, ("SIG", "row"), "type_row"),
        emit("BL", to=label("put_output")), emit("B", to=label("local1")), place("local0"), emit("MOVZ_W", 10, 0, 45),
        emit("STRB_W_POST", 10, 20, 1), place("local1"),
    ]),
    ("OUTPUT_TAIL", [
        emit("MOVZ_W", 10, 0, 10), emit("STRB_W_POST", 10, 20, 1), emit("ADRP", 1, to=("OUT", 0)),
        emit("ADD_X_IMM", 1, 1, to=("OUT", 0)), emit("SUB_X", 2, 20, 1), emit("MOVZ_X", 0, 0, 1), *system_call(4),
    ]),
    ("FINISH", [
        emit("B", to=label("step")), *PUT_NUMBER, place("put_bool"),
        emit("CBZ_W", 0, to=label("local2")), emit("MOVZ_W", 9, 0, 0x7274), emit("MOVK_W", 9, 0, 0x6575, 1),
        emit("STR_W_POST", 9, 20, 4), emit("RET"), place("local2"), emit("MOVZ_W", 9, 0, 0x6166),
        emit("MOVK_W", 9, 0, 0x736C, 1), emit("STR_W_POST", 9, 20, 4), emit("MOVZ_W", 9, 0, 101),
        emit("STRB_W_POST", 9, 20, 1), emit("RET"),
    ]),
]



def put_bytes(text):
    return [step_row for byte in text.encode() for step_row in (emit("MOVZ_W", 9, 0, byte), emit("STRB_W_POST", 9, 20, 1))]


EMIT_TEMPLATES += [
    ("PROLOGUE_VIRT", [
        emit("ADRP", 9, to=("STACK", 0)), emit("ADD_X_IMM", 9, 9, to=("STACK", 0)), emit("ADD_X_IMM", SP, 9, 0),
        emit("MOVZ_X", 22),
    ]),
    ("WINDOW_VIRT", [
        emit("ADRP", 0, to=("TAIL", "row")), emit("ADD_X_IMM", 0, 0, to=("TAIL", "row")), emit("ADRP", 8, to=("WINDOW", "row")),
        emit("STR_X", 0, 8, to=("WINDOW", "row")),
    ]),
    ("BOOT", [emit("MOVZ_X", 21, 0, BOOT_ID), emit("B", to=label("step"))]),
    ("WAIT", [place("wait"), emit("WFI"), emit("MOVZ_X", 9, 0, GICC_PAGE, 1), emit("LDR_W", 21, 9, GICC_IAR)]),
    ("DISPATCH", [
        emit("SUBS_W_IMM", XZR, 21, "row", when="flag"), emit("B_COND", a3=CC["EQ"], to=label("step"), when="flag"),
    ]),
    ("WAIT_TAIL", [
        place("complete"), emit("SUBS_W_IMM", XZR, 21, SPECIAL_ID), emit("B_COND", a3=CC["HS"], to=label("wait")),
        emit("MOVZ_X", 9, 0, GICC_PAGE, 1), emit("STR_W", 21, 9, GICC_EOIR), emit("B", to=label("wait")),
    ]),
    ("CLOCK_ROOT_VIRT", [
        emit("SUBS_W_IMM", XZR, 21, "root_irq"), emit("CSINC_W", 9, XZR, XZR, CC["EQ"] ^ 1),
        st(9, ("CLK", "row"), UINTEGER_TYPE),
    ]),
    ("OUTPUT_TAIL_VIRT", [
        emit("MOVZ_W", 10, 0, 10), emit("STRB_W_POST", 10, 20, 1), emit("ADRP", 1, to=("OUT", 0)),
        emit("ADD_X_IMM", 1, 1, to=("OUT", 0)), emit("SUB_X", 2, 20, 1), emit("MOVZ_X", 9, 0, UART_PAGE, 1), emit("MOVZ_X", 11),
        place("local0"), emit("LDRB_W_REG", 10, 1, 11), emit("STR_W", 10, 9, 0), emit("ADD_X_IMM", 11, 11, 1),
        emit("SUBS_X", XZR, 11, 2), emit("B_COND", a3=CC["NE"], to=label("local0")),
    ]),
    ("FINISH_VIRT", [
        emit("B", to=label("complete")), *PUT_NUMBER,
        place("put_bool"), emit("CBZ_W", 0, to=label("local2")), *put_bytes("true"), emit("RET"), place("local2"),
        *put_bytes("false"), emit("RET"),
    ]),
]


THUMB_SUFFIX = "_THUMB"
LR = 14
SP_T = 13
PC_T = 15
UART0 = 0x40004000
ICSR = 0xE000ED04
NVIC_ICPR0 = 0xE000E280
PENDSTCLR = 0x02000000
MPS2_UNLOADED = 84
MPS2_HEADER_BYTES = 92
MPS2_RAM_BYTES = 0x400000
MPS2_STACK_BYTES = 64
VIRT_STACK_BYTES = 32
PLATFORMS = ["MACOS", "VIRT", "MPS2"]
MACHINE_TEXT = "mps2-an385"
THUMB_LOAD_FORMS = {(1, 0): "LDRB_T", (1, 1): "LDRB_T", (2, 0): "LDRH_T", (2, 1): "LDRSH_T", (4, 0): "LDR_T", (4, 1): "LDR_T",
                    (8, 0): "LDRD_T", (8, 1): "LDRD_T"}
THUMB_STORE_FORMS = {1: "STRB_T", 2: "STRH_T", 4: "STR_T", 8: "STRD_T"}
THUMB_BINARY = {"ADD": ("ADDS_T", "ADC_T"), "SUB": ("SUBS_T", "SBC_T"), "AND": ("AND_T", "AND_T"), "OR": ("ORR_T", "ORR_T"),
                "XOR": ("EOR_T", "EOR_T")}
THUMB_CONDITIONS = {
    "EQ": ("EQ", "EQ"), "NE": ("NE", "NE"), "LT": ("LT", "LO"), "GE": ("GE", "HS"), "GT": ("LT", "LO"), "LE": ("GE", "HS"),
}


def li1(register, value, when="always"):
    return step("LI", when, 0, register, value)


def li2(register, value, when="always"):
    return step("LI", when, 1, register, value)


def ld1(register, target, type_source, when="always"):
    return step("LOAD", when, 0, register, type_source, target=target)


def ld2(register, target, type_source, when="always"):
    return step("LOAD", when, 1, register, type_source, target=target)


def st1(register, target, type_source, when="always"):
    return step("STORE", when, 0, register, type_source, target=target)


def st2(register, target, type_source, when="always"):
    return step("STORE", when, 1, register, type_source, target=target)


def operand1(register, row, when="always"):
    return step("OPERAND", when, 0, register, row)


def operand2(register, row, when="always"):
    return step("OPERAND", when, 1, register, row)


def load_at(register, type_source, base, index, when="always"):
    return step("LOAD_AT", when, 1, register, type_source, base, index)


def store_at(register, type_source, base, index, when="always"):
    return step("STORE_AT", when, 1, register, type_source, base, index)


def movw(register, value, when="always"):
    return emit("MOVW_T", register, 0, value, when=when)


def mov(destination, source, when="always"):
    return emit("MOV_T", destination, source, when=when)


def literal(register, value):
    return [movw(register, value & 0xFFFF), emit("MOVT_T", register, 0, value >> 16)]


def absolute(register, target):
    return [emit("MOVW_ABS_T", register, to=target), emit("MOVT_ABS_T", register, to=target)]


def only_if(condition, when="always"):
    return emit("SKIP_T", a3=CC[condition] ^ 1, when=when)


def branch_if(condition, name, when="always"):
    return [only_if(condition, when), emit("B_W_T", to=label(name), when=when)]


def branch(name, when="always"):
    return emit("B_W_T", to=label(name), when=when)


def compare(register, value, when="always"):
    return emit("SUBS_IMM_T", PC_T, register, value, when=when)


def compare_registers(left, right, when="always"):
    return emit("SUBS_T", PC_T, left, right, when=when)


def compare_pairs(left, right, when="always"):
    return [emit("SUBS_T", LR, left, right, when=when), emit("SBCS_T", LR, left + 1, right + 1, when=when)]


def put_byte(register):
    return emit("STRB_POST_T", register, 10, 1)


def apply_sign(register, sign):
    return [
        emit("EOR_T", register, register, sign), emit("EOR_T", register + 1, register + 1, sign),
        emit("SUBS_T", register, register, sign), emit("SBC_T", register + 1, register + 1, sign),
    ]


def copy_pairs(source_key, destination_key, words, loop_label, when="always"):
    return [
        address(6, source_key, when), address(7, destination_key, when), li1(9, words, when), place(loop_label, when),
        emit("LDRD_POST_T", 0, 6, 8, 1, when=when), emit("STRD_POST_T", 0, 7, 8, 1, when=when),
        emit("SUBS_IMM_T", 9, 9, 1, when=when), *branch_if("NE", loop_label, when),
    ]


def gated_thumb(body, stores=True):
    return (
        [ld1(0, ("CLK", "clock_row"), UINTEGER_TYPE, "flag"), compare(0, 0, "flag"), *branch_if("EQ", "local0", "flag")]
        + body + ([st2(0, ("SIG", "row"), "type_row")] if stores else []) + [place("local0", "flag")]
    )


def generic_thumb(*tail):
    return [operand2(0, "left"), operand2(2, "right", "right_loads"), *tail]


def loop_bound_thumb(when):
    return [
        operand2(4, "loop_count", when), li2(2, "loop_size_less_one", when), *compare_pairs(4, 2, when),
        emit("SKIP_T", a3="loop_condition", when=when), mov(4, 2, when),
        emit("SKIP_T", a3="loop_condition", when=when), mov(5, 3, when),
        emit("ADDS_IMM_T", 4, 4, 1, when=when), emit("ADC_IMM_T", 5, 5, 0, when=when),
    ]


def put_bytes_thumb(text):
    return [step_row for byte in text.encode() for step_row in (movw(2, byte), put_byte(2))]


SIGNS = [emit("ASR_IMM_T", 8, 1, 31), emit("ASR_IMM_T", 9, 3, 31), *apply_sign(0, 8), *apply_sign(2, 9)]
SHIFT_LEFT = [
    emit("LSL_T", 4, 1, 2), emit("RSB_IMM_T", 5, 2, 32), emit("LSR_T", 6, 0, 5), emit("ORR_T", 4, 4, 6),
    emit("SUBW_T", 5, 2, 32), emit("LSL_T", 6, 0, 5), emit("ORR_T", 1, 4, 6), emit("LSL_T", 0, 0, 2),
]
SHIFT_RIGHT = [
    emit("LSR_T", 4, 0, 2), emit("RSB_IMM_T", 5, 2, 32), emit("LSL_T", 6, 1, 5), emit("ORR_T", 4, 4, 6),
    emit("SUBW_T", 5, 2, 32), emit("LSR_T", 6, 1, 5), emit("ORR_T", 0, 4, 6), emit("LSR_T", 1, 1, 2),
]
PUT_NUMBER_THUMB = [
    place("put_int"), compare(1, 0), *branch_if("GE", "put_uint"), movw(2, 45), put_byte(2), movw(2, 0),
    emit("SUBS_T", 0, 2, 0), emit("SBC_T", 1, 2, 1),
    place("put_uint"), emit("STR_PRE_DEC_T", LR, SP_T, 8), emit("SUBW_T", SP_T, SP_T, 24), emit("ADDW_T", 12, SP_T, 0),
    place("local0"), movw(2, 10), movw(3, 0), emit("BL_T", to=label("divide")), emit("ADDW_T", 2, 2, 48),
    emit("STRB_POST_T", 2, 12, 1), emit("ORRS_T", 4, 0, 1), *branch_if("NE", "local0"),
    place("local1"), emit("LDRB_PRE_DEC_T", 2, 12, 1), put_byte(2), compare_registers(SP_T, 12), *branch_if("NE", "local1"),
    emit("ADDW_T", SP_T, SP_T, 24), emit("LDR_POST_T", PC_T, SP_T, 8),
]
DIVIDE_THUMB = [
    place("divide"), emit("ORRS_T", 4, 2, 3), only_if("EQ"), mov(2, 0), only_if("EQ"), mov(3, 1), only_if("EQ"), movw(0, 0),
    only_if("EQ"), movw(1, 0), only_if("EQ"), emit("BX_LR_T"), movw(4, 0), movw(5, 0), movw(9, 64), place("local3"),
    emit("ADDS_T", 0, 0, 0), emit("ADCS_T", 1, 1, 1), emit("ADCS_T", 4, 4, 4), emit("ADCS_T", 5, 5, 5), movw(8, 0),
    emit("ADC_IMM_T", 8, 8, 0), emit("SUBS_T", 6, 4, 2), emit("SBCS_T", 7, 5, 3), emit("SBCS_IMM_T", 8, 8, 0),
    only_if("HS"), mov(4, 6), only_if("HS"), mov(5, 7), only_if("HS"), emit("ORR_IMM_T", 0, 0, 1),
    emit("SUBS_IMM_T", 9, 9, 1), *branch_if("NE", "local3"), mov(2, 4), mov(3, 5), emit("BX_LR_T"),
]
COMPARE_FLAGS = [
    emit("EOR_T", 4, 0, 2, when="compare_equal"), emit("EOR_T", 5, 1, 3, when="compare_equal"),
    emit("ORRS_T", 4, 4, 5, when="compare_equal"), *compare_pairs(0, 2, "compare_direct"), *compare_pairs(2, 0, "compare_swapped"),
]


EMIT_TEMPLATES += [
    ("PROLOGUE_THUMB", [
        movw(0, 1), emit("MSR_PRIMASK_T"), *literal(6, UART0), movw(0, 16), emit("STR_T", 0, 6, 16), movw(0, 1),
        emit("STR_T", 0, 6, 8),
    ]),
    ("WINDOW_THUMB", [*absolute(0, ("TAIL", "row")), *absolute(LR, ("WINDOW", "row")), emit("STR_T", 0, LR, 0)]),
    ("BOOT_THUMB", [movw(11, BOOT_ID), branch("step")]),
    ("WAIT_THUMB", [
        place("wait"), emit("WFI_T"), *literal(6, ICSR), emit("LDR_T", 11, 6, 0), emit("LSL_IMM_T", 11, 11, 11),
        emit("LSR_IMM_T", 11, 11, 23), compare(11, 15), *branch_if("LO", "wait"),
    ]),
    ("DISPATCH_THUMB", [compare(11, "row", "flag"), *branch_if("EQ", "step", "flag")]),
    ("WAIT_TAIL_THUMB", [
        place("complete"), compare(11, 15), *branch_if("NE", "local0"), *literal(6, ICSR), *literal(0, PENDSTCLR),
        emit("STR_T", 0, 6, 0), branch("wait"), place("local0"), compare(11, 48), *branch_if("HS", "wait"),
        emit("SUBW_T", 0, 11, 16), movw(1, 1), emit("LSL_T", 1, 1, 0), *literal(6, NVIC_ICPR0), emit("STR_T", 1, 6, 0),
        branch("wait"),
    ]),
    ("STEP_THUMB", [place("step")]),
    ("LOOP_HEAD_THUMB", [ld1(0, ("CLK", "clock_loop"), UINTEGER_TYPE), compare(0, 0), *branch_if("EQ", "loop_end")]),
    ("LOOP_MID_THUMB", [
        movw(12, 0), *loop_bound_thumb("counted"), emit("SUBS_IMM_T", LR, 4, 1, when="counted"),
        emit("SBCS_IMM_T", LR, 5, 0, when="counted"), *branch_if("LT", "loop_end", "counted"), place("loop_start"),
    ]),
    ("SNAPSHOT_THUMB", copy_pairs("key_a_row", "key_p_row", "words_row", "local0")),
    ("LOOP_TAIL_THUMB", [
        emit("ADDW_T", 12, 12, 1), *loop_bound_thumb("counted"), li1(4, "loop_size", "uncounted"), compare_registers(12, 4),
        *branch_if("LO", "loop_start"), place("loop_end"),
    ]),
    ("CLOCK_ROOT_THUMB", [
        li1(6, "root_irq"), compare_registers(11, 6), movw(0, 0), only_if("EQ"), movw(0, 1),
        st1(0, ("CLK", "row"), UINTEGER_TYPE),
    ]),
    ("CLOCK_SAMPLE_THUMB", [
        ld1(0, ("CLK", "node_parent"), UINTEGER_TYPE), operand1(2, "node_left"), emit("AND_T", 0, 0, 2),
        st1(0, ("CLK", "row"), UINTEGER_TYPE),
    ]),
    ("CLOCK_PAIR_THUMB", [
        ld1(0, ("CLK", "node_left"), UINTEGER_TYPE), ld1(2, ("CLK", "node_right"), UINTEGER_TYPE),
        emit("pair_form_thumb", 0, 0, 2), st1(0, ("CLK", "row"), UINTEGER_TYPE),
    ]),
    ("ROW_SEED_ARRAY_THUMB", gated_thumb(copy_pairs("key_left", "key_a_right", "words_row", "local1"), False)),
    ("ROW_SEED_THUMB", gated_thumb([operand2(0, "left"), st2(0, ("SIG", "right"), "type_row")], False)),
    ("ROW_LOAD_THUMB", gated_thumb([operand1(0, "arg0"), load_at(0, "param", 0, -1)])),
    ("ROW_STORE_THUMB", gated_thumb([operand1(6, "arg0"), operand2(2, "arg1"), store_at(2, "param", 6, -1)], False)),
    ("ROW_INSTRUCTION_THUMB", gated_thumb([operand2(0, "arg0"), emit("WORD_T", a2="param")])),
    ("ROW_ITER_RANGE_THUMB", gated_thumb([mov(0, 12), movw(1, 0)])),
    ("ROW_ITER_THUMB", gated_thumb([address(6, "key_left"), load_at(0, "type_row", 6, 12)])),
    ("ROW_PREV_THUMB", gated_thumb([ld2(0, ("SIG", "left"), "type_row")])),
    ("ROW_ELEMENT_THUMB", gated_thumb([
        address(6, "key_left"), operand2(2, "right"), li2(4, "size_left"), movw(0, 0), movw(1, 0), *compare_pairs(2, 4),
        *branch_if("HS", "local1"), load_at(0, "type_row", 6, 2), place("local1"),
    ])),
    ("ROW_GATHER_THUMB", gated_thumb([
        address(6, "key_left"), address(7, "key_right"), address(8, "key_owner"), movw(9, 0), place("local1"),
        load_at(2, "index_element", 7, 9), movw(0, 0), movw(1, 0), li2(4, "size_left"), *compare_pairs(2, 4),
        *branch_if("HS", "local2"), load_at(0, "element_row", 6, 2), place("local2"), store_at(0, "element_row", 8, 9),
        emit("ADDW_T", 9, 9, 1), li1(LR, "size_row"), compare_registers(9, LR), *branch_if("LO", "local1"),
    ], False)),
    ("ROW_NEXT_THUMB", gated_thumb([
        *copy_pairs("key_left", "key_owner", "words_row", "local1", "keys_differ"), address(6, "key_owner"),
        operand2(2, "right_left"), operand2(0, "right_right"), li2(4, "size_row"), *compare_pairs(2, 4),
        *branch_if("HS", "local2"), store_at(0, "element_row", 6, 2), place("local2"),
    ], False)),
    ("ROW_CONST_THUMB", gated_thumb([operand2(0, "row")])),
    ("ROW_DELAY_THUMB", gated_thumb([ld2(0, ("MEM", "row"), "type_row")])),
    ("ROW_ONE_THUMB", gated_thumb([movw(0, 1), movw(1, 0)])),
    ("ROW_IF_THUMB", gated_thumb([
        operand1(0, "left"), operand2(2, "right_left"), operand2(4, "right_right"), compare(0, 0), mov(0, 4), mov(1, 5),
        only_if("NE"), mov(0, 2), only_if("NE"), mov(1, 3),
    ])),
    ("ROW_DEFAULT_THUMB", gated_thumb([
        ld1(4, ("CLK", "clock_left"), UINTEGER_TYPE), operand2(0, "left"), operand2(2, "right"), compare(4, 0),
        only_if("EQ"), mov(0, 2), only_if("EQ"), mov(1, 3),
    ])),
    ("ROW_PLAIN_THUMB", gated_thumb(generic_thumb())),
    ("ROW_NEG_THUMB", gated_thumb(generic_thumb(movw(LR, 0), emit("SUBS_T", 0, LR, 0), emit("SBC_T", 1, LR, 1)))),
    ("ROW_NOT_LOGICAL_THUMB", gated_thumb(generic_thumb(emit("EOR_IMM_T", 0, 0, 1)))),
    ("ROW_NOT_THUMB", gated_thumb(generic_thumb(emit("MVN_T", 0, 0), emit("MVN_T", 1, 1)))),
    ("ROW_BINARY_THUMB", gated_thumb(generic_thumb(
        emit("binary_lo", 0, 0, 2, when="not_mul"), emit("binary_hi", 1, 1, 3, when="not_mul"),
        emit("UMULL_T", 4, 0, 2, 5, when="mul"), emit("MLA_T", 5, 0, 3, 5, when="mul"), emit("MLA_T", 5, 1, 2, 5, when="mul"),
        mov(0, 4, "mul"), mov(1, 5, "mul"),
    ))),
    ("ROW_DIV_SIGNED_THUMB", gated_thumb(generic_thumb(
        *SIGNS, emit("EOR_T", 8, 8, 9), emit("STR_PRE_DEC_T", 8, SP_T, 8), emit("BL_T", to=label("divide")),
        emit("LDR_POST_T", 8, SP_T, 8), *apply_sign(0, 8),
    ))),
    ("ROW_DIV_THUMB", gated_thumb(generic_thumb(emit("BL_T", to=label("divide"))))),
    ("ROW_COMPARE_SIGNED_THUMB", gated_thumb(generic_thumb(
        *COMPARE_FLAGS, movw(0, 0), movw(1, 0), emit("SKIP_T", a3="signed_condition_thumb"), movw(0, 1),
    ))),
    ("ROW_COMPARE_THUMB", gated_thumb(generic_thumb(
        *COMPARE_FLAGS, movw(0, 0), movw(1, 0), emit("SKIP_T", a3="unsigned_condition_thumb"), movw(0, 1),
    ))),
    ("ROW_MOD_SIGNED_THUMB", gated_thumb(generic_thumb(
        *SIGNS, emit("STR_PRE_DEC_T", 3, SP_T, 4), emit("STR_PRE_DEC_T", 2, SP_T, 4), emit("STR_PRE_DEC_T", 8, SP_T, 8), emit("BL_T", to=label("divide")),
        emit("LDR_POST_T", 8, SP_T, 8), emit("LDRD_POST_T", 4, SP_T, 8, 5), mov(0, 2), mov(1, 3), *apply_sign(0, 8),
        compare(1, 0), *branch_if("GE", "local1"), emit("ADDS_T", 0, 0, 4), emit("ADC_T", 1, 1, 5), place("local1"),
    ))),
    ("ROW_MOD_THUMB", gated_thumb(generic_thumb(emit("BL_T", to=label("divide")), mov(0, 2), mov(1, 3)))),
    ("ROW_SHIFT_THUMB", gated_thumb(generic_thumb(
        *[step_row[:1] + ("shift_left",) + step_row[2:] for step_row in SHIFT_LEFT],
        *[step_row[:1] + ("shift_right",) + step_row[2:] for step_row in SHIFT_RIGHT],
        emit("SUBS_IMM_T", LR, 2, 64), emit("SBCS_IMM_T", LR, 3, 0), only_if("HS"), movw(0, 0), only_if("HS"), movw(1, 0),
    ))),
    ("DELAY_THUMB", [
        ld1(0, ("CLK", "clock_row"), UINTEGER_TYPE), compare(0, 0), *branch_if("EQ", "local0"),
        ld2(0, ("SIG", "left"), "type_row"), st2(0, ("MEM", "row"), "type_row"), place("local0"),
    ]),
    ("OUTPUT_HEAD_THUMB", absolute(10, ("OUT", 0))),
    ("OUTPUT_THUMB", [
        movw(2, 32, "flag"), emit("STRB_POST_T", 2, 10, 1, when="flag"), ld1(0, ("CLK", "clock_row"), UINTEGER_TYPE),
        compare(0, 0), *branch_if("EQ", "local0"), ld2(0, ("SIG", "row"), "type_row"), emit("BL_T", to=label("put_output")),
        branch("local1"), place("local0"), movw(2, 45), put_byte(2), place("local1"),
    ]),
    ("OUTPUT_TAIL_THUMB", [
        movw(2, 10), put_byte(2), *absolute(6, ("OUT", 0)), *literal(7, UART0), place("local0"), emit("LDRB_POST_T", 2, 6, 1),
        emit("STR_T", 2, 7, 0), compare_registers(6, 10), *branch_if("NE", "local0"),
    ]),
    ("FINISH_THUMB", [
        branch("complete"), *PUT_NUMBER_THUMB, place("put_bool"), compare(0, 0), *branch_if("EQ", "local2"),
        *put_bytes_thumb("true"), emit("BX_LR_T"), place("local2"), *put_bytes_thumb("false"), emit("BX_LR_T"), *DIVIDE_THUMB,
    ]),
]


def emit_template_rows():
    starts, lengths, label_counts, rows = [], [], [], []
    for _, steps in EMIT_TEMPLATES:
        starts.append(len(rows))
        lengths.append(len(steps))
        locals_used = [
            int(name[5:]) for step_row in steps for name in (step_row[3], step_row[8])
            if isinstance(name, str) and name.startswith("local")
        ]
        label_counts.append(max(locals_used) + 1 if locals_used else 0)
        for kind, when, form, a0, a1, a2, a3, target_kind, target in steps:
            sources = []

            def spec(value):
                if isinstance(value, int):
                    assert -1 <= value < SOURCE_BASE
                    return value
                if value in FORMS:
                    return FORMS.index(value)
                sources.append(EMIT_SOURCES.index(value))
                return SOURCE_BASE + len(sources) - 1

            slots = [spec(value) for value in (form, a0, a1, a2, a3, target)]
            assert len(sources) <= 2
            sources += [-1] * (2 - len(sources))
            rows.append((MICRO_KINDS.index(kind), EMIT_PREDICATES.index(when), *slots, TARGET_KINDS.index(target_kind), *sources))
    return starts, lengths, label_counts, rows


def packed_words(text, count):
    data = text.encode() + bytes(8 * count - len(text))
    return [int.from_bytes(data[8 * k:8 * k + 8], "little") for k in range(count)]


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


def segment(name, vmaddr, vmsize, fileoff, filesize, protection):
    return struct.pack("<II16sQQQQiiII", 0x19, 72, name, vmaddr, vmsize, fileoff, filesize, protection, protection, 0, 0)


def macho_header_words():
    text_bytes, data_bytes, signed_bytes, linkedit_bytes, signature_bytes = (MARKER_BASE + k for k in range(1, 6))
    header = (
        struct.pack("<IiiIIIII", 0xFEEDFACF, 0x0100000C, 0, 2, 7, COMMAND_BYTES, 0x00200004, 0)
        + segment(b"__PAGEZERO", 0, MACHO_BASE, 0, 0, 0)
        + segment(b"__TEXT", MACHO_BASE, text_bytes, 0, text_bytes, 5)
        + segment(b"__DATA", MACHO_BASE + text_bytes, data_bytes, text_bytes, data_bytes, 3)
        + segment(b"__LINKEDIT", MACHO_BASE + signed_bytes, linkedit_bytes, signed_bytes, signature_bytes, 1)
        + struct.pack("<III20s", 0xE, 32, 12, b"/usr/lib/dyld")
        + struct.pack("<IIQQ", 0x80000028, 24, TEXT_OFFSET, 0)
        + struct.pack("<IIII", 0x1D, 16, signed_bytes, signature_bytes)
    )
    assert len(header) == TEXT_OFFSET
    return [struct.unpack_from("<I", header, 4 * k)[0] for k in range(len(header) // 4)]


def elf_header_words():
    signed_bytes, memory_bytes = (MARKER_BASE + k for k in range(1, 3))
    header = (
        b"\x7fELF\x02\x01\x01" + bytes(9)
        + struct.pack("<HHIQQQIHHHHHH", 2, 183, 1, VIRT_BASE + VIRT_TEXT_OFFSET, 64, 0, 0, 64, 56, 1, 0, 0, 0)
        + struct.pack("<IIQQQQQQ", 1, 7, 0, VIRT_BASE, VIRT_BASE, signed_bytes, memory_bytes, SEGMENT_BYTES)
    )
    assert len(header) == VIRT_TEXT_OFFSET
    return [struct.unpack_from("<I", header, 4 * k)[0] for k in range(len(header) // 4)]


def elf32_header_words():
    signed_bytes, memory_bytes = (MARKER_BASE + k for k in range(1, 3))
    entry = MPS2_HEADER_BYTES - MPS2_UNLOADED + 1
    header = (
        b"\x7fELF\x01\x01\x01" + bytes(9)
        + struct.pack("<HHIIIIIHHHHHH", 2, 40, 1, entry, 52, 0, 0x05000200, 52, 32, 1, 40, 0, 0)
        + struct.pack("<IIIIIIII", 1, MPS2_UNLOADED, 0, 0, signed_bytes, memory_bytes, 7, 4)
        + struct.pack("<II", memory_bytes, entry)
    )
    assert len(header) == MPS2_HEADER_BYTES
    return [struct.unpack_from("<I", header, 4 * k)[0] for k in range(len(header) // 4)]


def signature_header_words():
    signature_bytes, directory_bytes, pages, signed_bytes = (MARKER_BASE + k for k in range(1, 5))
    header = struct.pack(">IIIII", 0xFADE0CC0, signature_bytes, 1, 0, SUPERBLOB_HEADER_BYTES) + struct.pack(
        ">IIIIIIIIIBBBBII", 0xFADE0C02, directory_bytes, 0x20100, 0x2, CODE_DIRECTORY_HEADER_BYTES + 1,
        CODE_DIRECTORY_HEADER_BYTES, 0, pages, signed_bytes, HASH_BYTES, 2, 0, SEGMENT_BYTES.bit_length() - 1, 0, 0,
    )
    assert len(header) == SUPERBLOB_HEADER_BYTES + CODE_DIRECTORY_HEADER_BYTES
    return [struct.unpack_from(">I", header, 4 * k)[0] for k in range(len(header) // 4)]


def split_markers(words, variables):
    fields = [word - MARKER_BASE if MARKER_BASE < word < MARKER_BASE + len(variables) else 0 for word in words]
    assert sorted(set(fields)) == list(range(len(variables)))
    return [0 if field else word for word, field in zip(words, fields)], fields


def first_primes(count):
    primes = []
    candidate = 2
    while len(primes) < count:
        if all(candidate % prime for prime in primes):
            primes.append(candidate)
        candidate += 1
    return primes


def integer_cube_root(value):
    root = int(round(value ** (1 / 3)))
    while root ** 3 > value:
        root -= 1
    while (root + 1) ** 3 <= value:
        root += 1
    return root


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
    symbol_ids = [0 if "\\" in text else fragments.add(text) for text, _ in SYMBOLS]
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
    for continuation in range(0x80, 0xC0):
        name_char[continuation] = len(alphabet) + continuation - 0x80
    table("NAME_CHAR", "short", name_char)
    integer("NAME_FANOUT", len(alphabet) + 0x40)
    single = [0] * 256
    for index, (text, _) in enumerate(SYMBOLS):
        if len(text) == 1:
            single[ord(text)] = SYMBOL_BASE + index
    table("SINGLE_SYMBOL", "short", single)
    pairs = [(text, SYMBOL_BASE + index) for index, (text, _) in enumerate(SYMBOLS) if len(text) == 2]
    firsts = sorted({text[0] for text, _ in pairs})
    seconds = sorted({text[1] for text, _ in pairs})
    pair_row = [0] * 256
    pair_column = [0] * 256
    for row, character in enumerate(firsts, 1):
        pair_row[ord(character)] = row
    for column, character in enumerate(seconds, 1):
        pair_column[ord(character)] = column
    pair_width = len(seconds) + 1
    pair_code = [0] * ((len(firsts) + 1) * pair_width)
    for text, code in pairs:
        pair_code[pair_row[ord(text[0])] * pair_width + pair_column[ord(text[1])]] = code
    table("PAIR_ROW", "short", pair_row)
    table("PAIR_COLUMN", "short", pair_column)
    integer("PAIR_WIDTH", pair_width)
    table("PAIR_CODE", "short", pair_code)
    triple_second = [0] * 256
    triple_third = [0] * 256
    triple_code = [0] * 256
    for index, (text, _) in enumerate(SYMBOLS):
        if len(text) == 3:
            assert triple_code[ord(text[0])] == 0
            triple_second[ord(text[0])] = ord(text[1])
            triple_third[ord(text[0])] = ord(text[2])
            triple_code[ord(text[0])] = SYMBOL_BASE + index
    table("TRIPLE_SECOND", "short", triple_second)
    table("TRIPLE_THIRD", "short", triple_third)
    table("TRIPLE_CODE", "short", triple_code)
    escape_value = [0] * 256
    for character, value in ESCAPES.items():
        escape_value[ord(character)] = value
    table("ESCAPE_VALUE", "short", escape_value)
    hex_digit = [0] * 256
    for value, character in enumerate("0123456789abcdef"):
        hex_digit[ord(character)] = value + 1
        hex_digit[ord(character.upper())] = value + 1
    table("HEX_DIGIT", "short", hex_digit)
    keyword_keys = {}
    for word in KEYWORDS:
        key = 0
        for character in word:
            key = key * 32 + ord(character) - ord("a") + 1
        keyword_keys[word] = key
    modulus = next(m for m in range(len(KEYWORDS), 4096) if len({key % m for key in keyword_keys.values()}) == len(KEYWORDS))
    slots = [0] * modulus
    for key in keyword_keys.values():
        slots[key % modulus] = key
    integer("KEYWORD_LENGTH_MAX", max(len(word) for word in KEYWORDS))
    integer("KEYWORD_MODULUS", modulus)
    table("KEYWORD_KEYS", "ulong", slots, lambda key: f"ulong({key})")
    table("SYMBOL_FRAGMENT", "short", symbol_ids)

    for index, op in enumerate(OPS):
        integer(f"OP_{op}", index)
    table("OP_FRAGMENT", "short", op_ids)
    table("OP_IS_OPENER", "short", [int(op in OPENERS) for op in OPS])
    table("OP_ARITY", "short", [0 if op in LEAVES else 1 if op in UNARY else 2 for op in OPS])
    table("OP_MONOCHRONOUS", "short", [int(op in MONOCHRONOUS) for op in OPS])
    table("OP_BRACKETED", "short", [int(op in BRACKETED) for op in OPS])
    tp_rows = []
    tp_inline_start, tp_inline_length, tp_rest_start = [], [], []
    for op in OPS:
        inline, rest = TEMPLATE_PROGRAMS.get(op, ([], []))
        tp_inline_start.append(len(tp_rows))
        tp_inline_length.append(len(inline))
        tp_rows.extend(inline)
        tp_rest_start.append(len(tp_rows))
        tp_rows.extend(rest)
    def template_ref(ref):
        if ref is None:
            return -1
        if ref in TEMPLATE_REFS:
            return TEMPLATE_REFS[ref]
        return SEED_WORDS.index(ref)
    table("OP_TEMPLATE_KIND", "short", [TEMPLATE_KINDS.get(op, 0) for op in OPS])
    table("OP_TEMPLATE_SKIPS_LEFT", "short", [int(op in TEMPLATE_SKIPS_LEFT) for op in OPS])
    table("OP_TEMPLATE_INLINE_START", "short", tp_inline_start)
    table("OP_TEMPLATE_INLINE_LENGTH", "short", tp_inline_length)
    table("OP_TEMPLATE_REST_START", "short", tp_rest_start)
    table("TEMPLATE_ROW_KIND", "short", [TEMPLATE_ROW_KINDS.index(row[0]) for row in tp_rows])
    table("TEMPLATE_ROW_OP", "short", [OPS.index(row[1]) if row[1] else -1 for row in tp_rows])
    table("TEMPLATE_ROW_NAME", "integer", [template_ref(row[2]) for row in tp_rows])
    table("TEMPLATE_ROW_VALUE", "integer", [row[3] for row in tp_rows])
    table("TEMPLATE_ROW_REF", "short", [TEMPLATE_VALUE_REFS.index(row[4]) for row in tp_rows])
    table("TEMPLATE_ROW_TYPE", "integer", [template_ref(row[5]) for row in tp_rows])
    for index, name in enumerate(TEMPLATE_ROW_KINDS):
        integer(f"TPK_{name}", index)
    for index, name in enumerate(TEMPLATE_VALUE_REFS):
        integer(f"TPV_{name}", index)
    for name, value in TEMPLATE_REFS.items():
        integer(f"TPR_{name}", value)
    integer("N_FRESH_FIRST", SEED_WORDS.index(FRESH_FIRST))
    integer("N_FRESH_LAST", SEED_WORDS.index(FRESH_LAST))
    stage_ops = []
    for side, label in enumerate(["PRE", "POST"]):
        starts = []
        for op in OPS:
            starts.append(len(stage_ops))
            stage_ops.extend(OPS.index(part) for part in COMPOSITES.get(op, ([], []))[side])
        table(f"OP_{label}_START", "short", starts)
        table(f"OP_{label}_LENGTH", "short", [len(COMPOSITES.get(op, ([], []))[side]) for op in OPS])
    table("STAGE_OP", "short", stage_ops)
    op_text = {}
    for text, op, _ in BINARY + PREFIX:
        op_text.setdefault(op, text)
    op_text.update({"DELAY": "$", "IF": "if", "BRANCH": "if"})
    table("OP_TEXT_FRAGMENT", "short", [fragments.add(op_text[op]) if op in op_text and op not in COMPOSITES else 0 for op in OPS])

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
    table("ROW_PREFIX", "short", [-1 - COMPUTED_PREFIXES.index(row[0]) if row[0] in COMPUTED_PREFIXES
                                  else named[row[0]] if row[0] else 0 for row in layout_rows])
    for index, name in enumerate(COMPUTED_PREFIXES):
        integer(f"ROW_PREFIX_{name}", -1 - index)
    for index, (name, _) in enumerate(UTF8_REASONS):
        integer(f"UTF8_{name}", index)
    table("UTF8_REASON_FRAGMENT", "short", [fragments.add(text) for _, text in UTF8_REASONS])
    table("HEX_FRAGMENT", "short", [fragments.add(f"{value:02x}") for value in range(256)])
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
    integer("OP_TOTAL", len(OPS))
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

    for index, name in enumerate(FORMS):
        integer(f"FORM_{name}", index)
    assert len(FORM_SPECS) == len(FORMS)
    assert all(len(fields) <= FORM_FIELD_SLOTS for _, _, fields, _, _ in FORM_SPECS)
    for index, name in enumerate(FIELD_KINDS):
        integer(f"FIELD_{name}", index)
    table("FORM_BASE", "long", [base for _, base, _, _, _ in FORM_SPECS])
    table("FORM_SIGNED", "short", [int(signed) for _, _, _, signed, _ in FORM_SPECS])
    table("FORM_KIND", "short", [FIELD_KINDS.index(kind) for _, _, _, _, kind in FORM_SPECS])
    table("FORM_TOP2", "short", [max([low + width for slot, low, width, _ in fields if slot == 2], default=0)
                                 for _, _, fields, _, _ in FORM_SPECS])
    padded = [list(fields) + [(0, 0, 0, 0)] * (FORM_FIELD_SLOTS - len(fields)) for _, _, fields, _, _ in FORM_SPECS]
    for column, name in enumerate(["SLOT", "LOW", "WIDTH", "AT"]):
        table(f"FORM_FIELD_{name}", "short", [field[column] for fields in padded for field in fields])
    integer("FORM_FIELD_SLOTS", FORM_FIELD_SLOTS)
    table("FORM_NAME_FRAGMENT", "short", [fragments.add(name) for name, _, _, _, _ in FORM_SPECS])
    constants.append(("MACHO_BASE", f"constant long MACHO_BASE = {MACHO_BASE};"))
    integer("TEXT_OFFSET", TEXT_OFFSET)
    integer("SEGMENT_BYTES", SEGMENT_BYTES)
    integer("SUPERBLOB_HEADER_BYTES", SUPERBLOB_HEADER_BYTES)
    integer("CODE_DIRECTORY_HEADER_BYTES", CODE_DIRECTORY_HEADER_BYTES)
    integer("HASH_BYTES", HASH_BYTES)
    header_words, header_fields = split_markers(macho_header_words(), HEADER_VARIABLES)
    integer("HEADER_WORD_COUNT", len(header_words))
    table("HEADER_WORD", "uinteger", header_words, lambda v: f"uinteger({v})")
    table("HEADER_FIELD", "short", header_fields)
    for index, name in enumerate(HEADER_VARIABLES):
        integer(f"HV_{name}", index)
    elf_words, elf_fields = split_markers(elf_header_words(), ELF_VARIABLES)
    integer("ELF_WORD_COUNT", len(elf_words))
    table("ELF_WORD", "uinteger", elf_words, lambda v: f"uinteger({v})")
    table("ELF_FIELD", "short", elf_fields)
    for index, name in enumerate(ELF_VARIABLES):
        integer(f"EV_{name}", index)
    elf32_words, elf32_fields = split_markers(elf32_header_words(), ELF_VARIABLES)
    table("ELF32_WORD", "uinteger", elf32_words, lambda v: f"uinteger({v})")
    table("ELF32_FIELD", "short", elf32_fields)
    integer("MPS2_HEADER_BYTES", MPS2_HEADER_BYTES)
    integer("MPS2_UNLOADED", MPS2_UNLOADED)
    integer("MPS2_RAM_BYTES", MPS2_RAM_BYTES)
    integer("MPS2_STACK_BYTES", MPS2_STACK_BYTES)
    integer("VIRT_STACK_BYTES", VIRT_STACK_BYTES)
    for index, name in enumerate(PLATFORMS):
        integer(f"PLATFORM_{name}", index)
    integer("MACHINE_TEXT_LENGTH", len(MACHINE_TEXT))
    constants.append(("MACHINE_TEXT", f'constant [{len(MACHINE_TEXT)}] ubyte MACHINE_TEXT = "{MACHINE_TEXT}";'))
    constants.append(("VIRT_BASE", f"constant long VIRT_BASE = {VIRT_BASE};"))
    integer("VIRT_TEXT_OFFSET", VIRT_TEXT_OFFSET)
    integer("BOOT_ID", BOOT_ID)
    signature_words, signature_fields = split_markers(signature_header_words(), SIGNATURE_VARIABLES)
    integer("SIGNATURE_HEADER_BYTES", 4 * len(signature_words))
    table("SIGNATURE_WORD", "uinteger", signature_words, lambda v: f"uinteger({v})")
    table("SIGNATURE_FIELD", "short", signature_fields)
    for index, name in enumerate(SIGNATURE_VARIABLES):
        integer(f"SV_{name}", index)
    primes = first_primes(64)
    table("SHA_K", "uinteger", [integer_cube_root(prime << 96) & 0xFFFFFFFF for prime in primes], lambda v: f"uinteger({v})")
    table("SHA_IV", "uinteger", [math.isqrt(prime << 64) & 0xFFFFFFFF for prime in primes[:8]], lambda v: f"uinteger({v})")
    for name, value in CONDITIONS.items():
        integer(f"CC_{name}", value)
    for prefix, names in (("MK", MICRO_KINDS), ("TG", TARGET_KINDS), ("GL", GLOBAL_LABELS)):
        for index, name in enumerate(names):
            integer(f"{prefix}_{name.upper()}", index)
    for prefix, names in (("ES", EMIT_SOURCES), ("EP", EMIT_PREDICATES), ("ET", [name for name, _ in EMIT_TEMPLATES])):
        for index, name in enumerate(names):
            integer(f"{prefix}_{name.upper()}", index)
    integer("GLOBAL_LABEL_COUNT", len(GLOBAL_LABELS))
    integer("STEP_SOURCE_BASE", SOURCE_BASE)
    integer("ET_COUNT", len(EMIT_TEMPLATES))
    template_names = [name for name, _ in EMIT_TEMPLATES]
    for index, name in enumerate(UNIT_PHASES):
        integer(f"UPH_{name}", index)
    integer("UPH_DONE", len(UNIT_PHASES))
    table("UNIT_PHASE_TEMPLATE", "integer", [template_names.index(name) if name in template_names else -1 for name in UNIT_PHASES])
    table("UNIT_PHASE_TEMPLATE_VIRT", "integer", [
        template_names.index(name + VIRT_SUFFIX) if name + VIRT_SUFFIX in template_names
        else template_names.index(name) if name in template_names else -1 for name in UNIT_PHASES
    ])
    thumb_template = []
    for name in template_names:
        base = name[:-len(VIRT_SUFFIX)] if name.endswith(VIRT_SUFFIX) else name
        thumb_name = base + THUMB_SUFFIX
        thumb_template.append(template_names.index(thumb_name) if thumb_name in template_names
                              else template_names.index(name) if name.endswith(THUMB_SUFFIX) else -1)
    assert all(name + THUMB_SUFFIX in template_names for name in template_names if name.startswith("ROW_") and name != "ROW_SYSCALL"
               and not name.endswith(THUMB_SUFFIX))
    table("THUMB_TEMPLATE", "integer", thumb_template)
    table("THUMB_LOAD_FORM", "integer", [FORMS.index(THUMB_LOAD_FORMS[key]) if key in THUMB_LOAD_FORMS else 0
                                         for key in ((index // 2, index % 2) for index in range(18))])
    table("THUMB_STORE_FORM", "integer", [FORMS.index(THUMB_STORE_FORMS[size]) if size in THUMB_STORE_FORMS else 0
                                          for size in range(9)])
    table("THUMB_BINARY_LO", "integer", [FORMS.index(THUMB_BINARY[op][0]) if op in THUMB_BINARY else -1 for op in OPS])
    table("THUMB_BINARY_HI", "integer", [FORMS.index(THUMB_BINARY[op][1]) if op in THUMB_BINARY else -1 for op in OPS])
    table("THUMB_SIGNED_SKIP", "integer", [CONDITIONS[THUMB_CONDITIONS[op][0]] ^ 1 if op in THUMB_CONDITIONS else -1 for op in OPS])
    table("THUMB_UNSIGNED_SKIP", "integer", [CONDITIONS[THUMB_CONDITIONS[op][1]] ^ 1 if op in THUMB_CONDITIONS else -1
                                             for op in OPS])
    starts, lengths, label_counts, step_rows = emit_template_rows()
    table("ET_START", "integer", starts)
    table("ET_LENGTH", "integer", lengths)
    table("ET_LABELS", "integer", label_counts)
    step_columns = ["KIND", "WHEN", "FORM", "A0", "A1", "A2", "A3", "TARGET", "TARGET_KIND", "SOURCE0", "SOURCE1"]
    for column, name in enumerate(step_columns):
        table(f"STEP_{name}", "integer", [row[column] for row in step_rows])
    table("LOAD_OFFSET_FORM", "integer", [FORMS.index(LOAD_FORMS[key][0]) if key in LOAD_FORMS else 0
                                          for key in ((index // 2, index % 2) for index in range(18))])
    table("LOAD_INDEXED_FORM", "integer", [FORMS.index(LOAD_FORMS[key][1]) if key in LOAD_FORMS else 0
                                           for key in ((index // 2, index % 2) for index in range(18))])
    table("STORE_OFFSET_FORM", "integer", [FORMS.index(STORE_FORMS[size][0]) if size in STORE_FORMS else 0 for size in range(9)])
    table("STORE_INDEXED_FORM", "integer", [FORMS.index(STORE_FORMS[size][1]) if size in STORE_FORMS else 0 for size in range(9)])
    table("OP_INSTRUCTION_FORM", "integer", [FORMS.index(OP_INSTRUCTIONS[op]) if op in OP_INSTRUCTIONS else -1 for op in OPS])
    table("OP_SHIFT_FORM", "integer", [FORMS.index(OP_SHIFTS[op]) if op in OP_SHIFTS else -1 for op in OPS])
    table("OP_SIGNED_CONDITION", "integer", [CONDITIONS[OP_CONDITIONS[op][0]] ^ 1 if op in OP_CONDITIONS else -1 for op in OPS])
    table("OP_UNSIGNED_CONDITION", "integer", [CONDITIONS[OP_CONDITIONS[op][1]] ^ 1 if op in OP_CONDITIONS else -1 for op in OPS])
    headers = [column + " " for column in CODE_COLUMNS]
    assert all(len(header) <= 16 for header in headers)
    integer("CODE_COLUMN_COUNT", len(CODE_COLUMNS))
    for word in range(2):
        table(f"CODE_HEADER_WORD{word}", "ulong", [packed_words(header, 2)[word] for header in headers],
              lambda v: f"ulong({signed64(v)})")
    table("CODE_HEADER_LENGTH", "integer", [len(header) for header in headers])
    constants.append(("EMIT_TEXT", f'constant [{len(EMIT_TEXT)}] ubyte EMIT_TEXT = "{EMIT_TEXT}";'))
    integer("MALFORMED_TEXT_LENGTH", EMIT_TEXT.index("memory"))

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
    names = [name for name, _ in constants]
    duplicates = sorted({name for name in names if names.count(name) > 1})
    if duplicates:
        raise SystemExit(f"tables.py: constants generated twice: {', '.join(duplicates)}")
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
