Some words in CrustOS refer to particular concepts that we try to keep
consistent across code and documentation.

# Range

A range is an area of memory with a defined start address and size. On PS, it
is represented as two elements, starting with the address and then the size.

Words like `move` operate on ranges.

In word signature, a range will often look like `( a u -- )`, but sometimes
letters are added to `a` to indicate the type of data in the range. For example
an **unpacked** string (a string upon which we've read the first length byte)
will be shown as `( sa sl -- )` - for `string addresses` and `string length`. This
is a range too.

In words, ranges are represented as the characters `[]`.

# String

Strings in CrustOS are ranges where the first byte of the range contains its
length. On the PS, they are passed around as a single element, the address of the
length byte. It will often look like `( str -- )` or `( s -- )`

# Entry

An entry into a dictionary, usually the system dictionary.
They contain a name, a pointer to the next entry and some data.

# Word

An entry that can be executed.

# Annotation

A type of entry that conveys information about the word following it in
the dictionary. Used for things like doc comments.

Has a name that starts with the Ascii DEL Character (DEC. 127), followed by
a letter that denotes the type of annotation.