***Settings***

import re
from fnmatch import fnmatchcase
from random import randint
from string import ascii_lowercase, ascii_uppercase, digits

from robot.version import get_version


class Strings:

    """A test library for string manipulation and verification.

    `String` is Robot Framework's standard library for manipulating
    strings (e.g. `Replace String Using Regexp`, `Split To Lines`) and
    verifying their contents (e.g. `Should Be String`).

    Following keywords from the BuiltIn library can also be used with
    strings:
    - `Catenate`
    - `Get Length`
    - `Length Should Be`
    - `Should (Not) Match (Regexp)`
    - `Should (Not) Be Empty`
    - `Should (Not) Be Equal (As Strings/Integers/Numbers)`
    - `Should (Not) Contain`
    - `Should (Not) Start With`
    - `Should (Not) End With`
    """

    ROBOT_LIBRARY_SCOPE = 'GLOBAL'
    ROBOT_LIBRARY_VERSION = get_version()

    def get_line_count(self, string):
        """Returns and logs the number of lines in the given `string`."""
        count = len(string.splitlines())
        print('*INFO* %d lines' % count)
        return count

    def split_to_lines(self, string, start=0, end=None):
        """Converts the `string` into a list of lines.

        It is possible to get only a selection of lines from `start`
        to `end` so that `start` index is inclusive and `end` is
        exclusive. Line numbering starts from 0, and it is possible to
        use negative indices to refer to lines from the end.

        Lines are returned without the newlines. The number of
        returned lines is automatically logged.

        Examples:
        | @{lines} =        | Split To Lines | ${manylines} |    |    |
        | @{ignore first} = | Split To Lines | ${manylines} | 1  |    |
        | @{ignore last} =  | Split To Lines | ${manylines} |    | -1 |
        | @{5th to 10th} =  | Split To Lines | ${manylines} | 4  | 10 |
        | @{first two} =    | Split To Lines | ${manylines} |    | 1  |
        | @{last two} =     | Split To Lines | ${manylines} | -2 |    |

        Use `Get Line` if you only need to get a single line.
        """
        start = self._convert_to_index(start, 'start')
        end = self._convert_to_index(end, 'end')
        lines = string.splitlines()[start:end]
        print('*INFO* %d lines returned' % len(lines))
        return lines

    def get_line(self, string, line_number):
        """Returns the specified line from the given `string`.

        Line numbering starts from 0 and it is possible to use
        negative indices to refer to lines from the end. The line is
        returned without the newline character.

        Examples:
        | ${first} =    | Get Line | ${string} | 0  |
        | ${2nd last} = | Get Line | ${string} | -2 |
        """
        line_number = self._convert_to_integer(line_number, 'line_number')
        return string.splitlines()[line_number]

    def get_lines_containing_string(self, string, pattern, case_insensitive=False):
        """Returns lines of the given `string` that contain the `pattern`.

        The `pattern` is always considered to be a normal string and a
        line matches if the `pattern` is found anywhere in it. By
        default the match is case-sensitive, but setting
        `case_insensitive` to any value makes it case-insensitive.

        Lines are returned as one string catenated back together with
        newlines. Possible trailing newline is never returned. The
        number of matching lines is automatically logged.

        Examples:
        | ${lines} = | Get Lines Containing String | ${result} | An example |
        | ${ret} =   | Get Lines Containing String | ${ret} | FAIL | case-insensitive |

        See `Get Lines Matching Pattern` and `Get Lines Matching Regexp`
        if you need more complex pattern matching.
        """
        if case_insensitive:
            pattern = pattern.lower()
            def contains(line): return pattern in line.lower()
        else:
            def contains(line): return pattern in line
        return self._get_matching_lines(string, contains)

    def get_lines_matching_pattern(self, string, pattern, case_insensitive=False):
        """Returns lines of the given `string` that match the `pattern`.

        The `pattern` is a _glob pattern_ where:
        | *        | matches everything |
        | ?        | matches any single character |
        | [chars]  | matches any character inside square brackets (e.g. '[abc]' matches either 'a', 'b' or 'c') |
        | [!chars] | matches any character not inside square brackets |

        A line matches only if it matches the `pattern` fully.  By
        default the match is case-sensitive, but setting
        `case_insensitive` to any value makes it case-insensitive.

        Lines are returned as one string catenated back together with
        newlines. Possible trailing newline is never returned. The
        number of matching lines is automatically logged.

        Examples:
        | ${lines} = | Get Lines Matching Pattern | ${result} | Wild???? example |
        | ${ret} = | Get Lines Matching Pattern | ${ret} | FAIL: * | case-insensitive |

        See `Get Lines Matching Regexp` if you need more complex
        patterns and `Get Lines Containing String` if searching
        literal strings is enough.
        """
        if case_insensitive:
            pattern = pattern.lower()
            def matches(line): return fnmatchcase(line.lower(), pattern)
        else:
            def matches(line): return fnmatchcase(line, pattern)
        return self._get_matching_lines(string, matches)

    def get_lines_matching_regexp(self, string, pattern):
        """Returns lines of the given `string` that match the regexp `pattern`.

        See `BuiltIn.Should Match Regexp` for more information about
        Python regular expression syntax in general and how to use it
        in Robot Framework test data in particular. A line matches
        only if it matches the `pattern` fully. Notice that to make
        the match case-insensitive, you need to embed case-insensitive
        flag into the pattern.

        Lines are returned as one string catenated back together with
        newlines. Possible trailing newline is never returned. The
        number of matching lines is automatically logged.

        Examples:
        | ${lines} = | Get Lines Matching Regexp | ${result} | Reg\\\\w{3} example |
        | ${ret} = | Get Lines Matching Regexp | ${ret} | (?i)FAIL: .* |

        See `Get Lines Matching Pattern` and `Get Lines Containing
        String` if you do not need full regular expression powers (and
        complexity).
        """
        regexp = re.compile('^%s$' % pattern)
        return self._get_matching_lines(string, regexp.match)

    def _get_matching_lines(self, string, matches):
        lines = string.splitlines()
        matching = [line for line in lines if matches(line)]
        print('*INFO* %d out of %d lines matched' % (len(matching), len(lines)))
        return '\n'.join(matching)

    def replace_string(self, string, search_for, replace_with, count=-1):
        """Replaces `search_for` in the given `string` with `replace_with`.

        `search_for` is used as a literal string. See `Replace String
        Using Regexp` if more powerful pattern matching is needed.

        If the optional argument `count` is given, only that many
        occurrences from left are replaced. Negative `count` means
        that all occurrences are replaced (default behaviour) and zero
        means that nothing is done.

        A modified version of the string is returned and the original
        string is not altered.

        Examples:
        | ${str} = | Replace String | ${str} | Hello | Hi     |   |
        | ${str} = | Replace String | ${str} | world | tellus | 1 |
        """
        count = self._convert_to_integer(count, 'count')
        return string.replace(search_for, replace_with, count)

    def replace_string_using_regexp(self, string, pattern, replace_with, count=-1):
        """Replaces `pattern` in the given `string` with `replace_with`.

        This keyword is otherwise identical to `Replace String`, but
        the `pattern` to search for is considered to be a regular
        expression.  See `BuiltIn.Should Match Regexp` for more
        information about Python regular expression syntax in general
        and how to use it in Robot Framework test data in particular.

        Examples:
        | ${str} = | Replace String Using Regexp | ${str} | (Hello|Hi) | Hei  |   |
        | ${str} = | Replace String Using Regexp | ${str} | 20\\\\d\\\\d-\\\\d\\\\d-\\\\d\\\\d | <DATE>  | 2  |
        """
        count = self._convert_to_integer(count, 'count')
        # re.sub handles 0 and negative counts differently than string.replace
        if count == 0:
            return string
        return re.sub(pattern, replace_with, string, max(count, 0))

    def split_string(self, string, separator=None, max_split=-1):
        """Splits the `string` using `separator` as a delimiter string.

        If a `separator` is not given, any whitespace string is a
        separator. In that case also possible consecutive whitespace
        as well as leading and trailing whitespace is ignored.

        Split words are returned as a list. If the optional
        `max_split` is given, at most `max_split` splits are done, and
        the returned list will have maximum `max_split + 1` elements.

        Examples:
        | @{words} =         | Split String | ${string} |
        | @{words} =         | Split String | ${string} | ,${SPACE} |
        | ${pre} | ${post} = | Split String | ${string} | ::    | 1 |

        See `Split String From Right` if you want to start splitting
        from right, and `Fetch From Left` and `Fetch From Right` if
        you only want to get first/last part of the string.
        """
        if separator == '':
            separator = None
        max_split = self._convert_to_integer(max_split, 'max_split')
        return string.split(separator, max_split)

    def split_string_from_right(self, string, separator=None, max_split=-1):
        """Splits the `string` using `separator` starting from right.

        Same as `Split String`, but splitting is started from right. This has
        an effect only when `max_split` is given.

        Examples:
        | ${first} | ${others} = | Split String | ${string} | - | 1 |
        | ${others} | ${last} = | Split String From Right | ${string} | - | 1 |
        """
        # Strings in Jython 2.2 don't have 'rsplit' methods
        reversed = self.split_string(string[::-1], separator, max_split)
        return [r[::-1] for r in reversed][::-1]

    def split_string_to_characters(self, string):
        """Splits the string` to characters.

        Example:
        | @{characters} = | Split String To Characters | ${string} |
        """
        return list(string)

    def fetch_from_left(self, string, marker):
        """Returns contents of the `string` before the first occurrence of `marker`.

        If the `marker` is not found, whole string is returned.

        See also `Fetch From Right`, `Split String` and `Split String
        From Right`.
        """
        return string.split(marker)[0]

    def fetch_from_right(self, string, marker):
        """Returns contents of the `string` after the last occurrence of `marker`.

        If the `marker` is not found, whole string is returned.

        See also `Fetch From Left`, `Split String` and `Split String
        From Right`.
        """
        return string.split(marker)[-1]
    
    def get_substring(self, string, start, end=None):
        """Returns a substring from `start` index to `end` index.

        The `start` index is inclusive and `end` is exclusive.
        Indexing starts from 0, and it is possible to use
        negative indices to refer to characters from the end.

        Examples:
        | ${ignore first} = | Get Substring | ${string} | 1  |    |
        | ${ignore last} =  | Get Substring | ${string} |    | -1 |
        | ${5th to 10th} =  | Get Substring | ${string} | 4  | 10 |
        | ${first two} =    | Get Substring | ${string} |    | 1  |
        | ${last two} =     | Get Substring | ${string} | -2 |    |
        """
        start = self._convert_to_index(start, 'start')
        end = self._convert_to_index(end, 'end')
        return string[start:end]
 
    def should_be_lowercase(self, string, msg=None):
        """Fails if the given `string` is not in lowercase.

        The default error message can be overridden with the optional
        `msg` argument.

        For example 'string' and 'with specials!' would pass, and 'String', ''
        and ' ' would fail.

        See also `Should Be Uppercase` and `Should Be Titlecase`.
        All these keywords were added in Robot Framework 2.1.2.
        """
        if not string.islower():
            raise AssertionError(msg or "'%s' is not lowercase" % string)

    def should_be_uppercase(self, string, msg=None):
        """Fails if the given `string` is not in uppercase.

        The default error message can be overridden with the optional
        `msg` argument.

        For example 'STRING' and 'WITH SPECIALS!' would pass, and 'String', ''
        and ' ' would fail.

        See also `Should Be Titlecase` and `Should Be Lowercase`.
        All these keywords were added in Robot Framework 2.1.2.
        """
        if not string.isupper():
            raise AssertionError(msg or "'%s' is not uppercase" % string)

    def should_be_titlecase(self, string, msg=None):
        """Fails if given `string` is not title.

        `string` is a titlecased string if there is at least one
        character in it, uppercase characters only follow uncased
        characters and lowercase characters only cased ones.

        The default error message can be overridden with the optional
        `msg` argument.

        For example 'This Is Title' would pass, and 'Word In UPPER',
        'Word In lower', '' and ' ' would fail.

        See also `Should Be Uppercase` and `Should Be Lowercase`.
        All theses keyword were added in Robot Framework 2.1.2.
        """
        if not string.istitle():
            raise AssertionError(msg or "'%s' is not titlecase" % string)

    def _convert_to_index(self, value, name):
        if value == '':
            return 0
        if value is None:
            return None
        return self._convert_to_integer(value, name)

    def _convert_to_integer(self, value, name):
        try:
            return int(value)
        except ValueError:
            raise ValueError("Cannot convert '%s' argument '%s' to an integer"
                             % (name, value))
