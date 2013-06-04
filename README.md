# exjsx (v0.1) #

an elixir application for consuming, producing and manipulating [json][json]. 
based on [jsx][jsx]

exjsx is built via mix and continuous integration testing provided courtesy [travis][travis]

exjsx is released under the terms of the [MIT][MIT] license

copyright 2013 alisdair sullivan

## index ##

* [quickstart](#quickstart)
* [description](#description)
  - [json <-> elixir mapping](#json---elixir-mapping)
* [fma](#frequently-made-accusations)
* [options](#options)
* [exports](#exports)
  - [`decode`](#decodejson-opts)
  - [`encode`](#encodeterm-opts)
  - [`format`](#formatjson-opts)
  - [`minify`](#minifyjson)
  - [`prettify`](#prettifyjson)
  - [`is_json`](#is_jsonjson-opts)
  - [`is_term`](#is_termterm-opts)
* [acknowledgements](#acknowledgements)


## quickstart ##

#### to build the library and run tests ####

```bash
$ mix compile
$ mix test
```

#### to convert a utf8 binary containing a json string into an elixir keyword list ####

```erlang
iex(1)> JSX.decode "{\"library\": \"jsx\", \"awesome\": true}"
[library: "jsx", awesome: true]
iex(2)> JSX.decode "[\"a\",\"list\",\"of\",\"words\"]"
["a","list","of","words"]
```

#### to convert an elixir keyword list into a utf8 binary containing a json string ####

```erlang
iex(1)> JSX.encode [library: "jsx", awesome: true]
"{\"library\":\"jsx\",\"awesome\":true}"
iex(2)> JSX.encode ["a","list","of","words"]
"[\"a\",\"list\",\"of\",\"words\"]"
```

#### to check if a binary or a term is valid json ####

```erlang
iex(1)> JSX.is_json? "[\"this is json\"]"
true
iex(2)> JSX.is_json? [\"this is not\"]
false
iex(3)> JSX.is_term? ["this is a term"]
true
iex(4)> JSX.is_term? [:this, :is, :not]
false
```

#### to minify some json ####

```erlang
iex(1)> JSX.minify "{
...(1)>   \"a list\": [
...(1)>     1,
...(1)>     2,
...(1)>     3
...(1)>   ]
...(1)> }"
"{\"a list\":[1,2,3]}"
```

#### to prettify some json ####

```erlang
iex(1)> JSX.prettify "{\"a list\":[1,2,3]}"
"{
  \"a list\": [
    1,
    2,
    3
  ]
}"
```


## description ##


exjsx is an elixir application for consuming, producing and manipulating 
[json][json]

json has a [spec][rfc4627] but common usage differs subtly. it's common 
usage exjsx attempts to address, with guidance from the spec

all json produced and consumed by exjsx should be `utf8` encoded text or a 
reasonable approximation thereof. ascii works too, but anything beyond that 
i'm not going to make any promises. **especially** not latin1

the [spec][rfc4627] thinks json values must be wrapped in a json array or 
object but everyone else disagrees so exjsx allows naked json values by default.

here is a table of how various json values map to erlang:

### json &lt;-> elixir mapping ###

**json**                        | **elixir**
--------------------------------|--------------------------------
`number`                        | `Number`
`string`                        | `BitString`
`true`, `false` and `null`      | `:true`, `:false` and `:nil`
`array`                         | `List`
`object`                        | `[{}]`, `Keyword` and `Record`

*   numbers

    javascript and thus json represent all numeric values with floats. as 
    this is woefully insufficient for many uses, **exjsx**, just like elixir, 
    supports bigints. whenever possible, this library will interpret json 
    numbers that look like integers as integers. other numbers will be converted 
    to elixir's floating point type, which is nearly but not quite iee754. 
    negative zero is not representable in elixir (zero is unsigned in elixir and 
    `0` is equivalent to `-0`) and will be interpreted as regular zero. numbers 
    not representable are beyond the concern of this implementation, and will 
    result in parsing errors

    when converting from elixir to json, numbers are represented with their 
    shortest representation that will round trip without loss of precision. this 
    means that some floats may be superficially dissimilar (although 
    functionally equivalent). for example, `1.0000000000000001` will be 
    represented by `1.0`

*   strings

    the json [spec][rfc4627] is frustratingly vague on the exact details of json 
    strings. json must be unicode, but no encoding is specified. javascript 
    explicitly allows strings containing codepoints explicitly disallowed by 
    unicode. json allows implementations to set limits on the content of 
    strings. other implementations attempt to resolve this in various ways. this 
    implementation, in default operation, only accepts strings that meet the 
    constraints set out in the json spec (strings are sequences of unicode 
    codepoints deliminated by `"` (`u+0022`) that may not contain control codes 
    unless properly escaped with `\` (`u+005c`)) and that are encoded in `utf8`

    the utf8 restriction means improperly paired surrogates are explicitly 
    disallowed. `u+d800` to `u+dfff` are allowed, but only when they form valid 
    surrogate pairs. surrogates encountered otherwise result in errors

    json string escapes of the form `\uXXXX` will be converted to their 
    equivalent codepoints during parsing. this means control characters and 
    other codepoints disallowed by the json spec may be encountered in resulting 
    strings, but codepoints disallowed by the unicode spec will not be. in the 
    interest of pragmatism there is an [option](#options) for looser parsing

    all elixir strings are represented by BitStrings. the encoder will check
    strings for conformance. noncharacters (like `u+ffff`)  are allowed in elixir 
    utf8 encoded binaries, but not in strings passed to  the encoder (although,
    again, see [options](#options))

    this implementation performs no normalization on strings beyond that 
    detailed here. be careful when comparing strings as equivalent strings 
    may have different `utf8` encodings

*   true, false and null

    the json primitives `true`, `false` and `null` are represented by the 
    elixir atoms `:true`, `:false` and `:nil`

*   arrays

    json arrays are represented with elixir lists of json values as described 
    in this section

*   objects

    json objects are represented by elixir keyword lists. the empty object has
    the special representation `[{}]` to differentiate it from the empty list. 
    all keys must be atoms with valid utf8 representations (which will be escaped 
    and converted to binaries for presentation to handlers). values should be 
    valid json values. records (with 2 or more fields) are serialized to objects
    automagically but there is currently no way to perform the reverse. stay tuned
    tho


## frequently made accusations ##

#### your lib sucks and encodes my records wrong ####

so you have this record:

```erlang
defrecord Character, name: nil, rank: nil
```

```erlang
iex(1)> JSX.encode Character.new(name: "Walder Frey", rank: "Lord")
{:ok,"{\"name\":\"Walder Frey\",\"rank\":\"Lord\"}"}
```

but you don't like that encoding. ok. do this:

```erlang
defimpl JSXEncoder, for: Character do
  def json(record) do
    [:start_object, "name", record.rank <> " " <> record.name, :end_object]
end
```

```erlang
iex(1)> JSX.encode Character.new(name: "Walder Frey", rank: "Lord")
{:ok,"{\"name\":\"Lord Walder Frey\"}"}
```

along with the [jsx][jsx] internal format you can also generate you own json
and pass it to the encoder with `[{:raw, "{\"name\": \"Lord Walder Frey\"}"}]`

someone should write a macro that does this and make a pull request


## options ##

jsx functions all take a common set of options. not all flags have meaning 
in all contexts, but they are always valid options. functions may have 
additional options beyond these. see 
[individual function documentation](#exports) for details

- `:replaced_bad_utf8`

    json text input and json strings SHOULD be utf8 encoded binaries, 
    appropriately escaped as per the json spec. attempts are made to replace 
    invalid codepoints with `u+FFFD` as per the unicode spec when this option is 
    present. this applies both to malformed unicode and disallowed codepoints

- `:escaped_forward_slashes`

    json strings are escaped according to the json spec. this means forward 
    slashes (solidus) are only escaped when this flag is present. otherwise they 
    are left unescaped. you may want to use this if you are embedding json 
    directly into a html or xml document

- `:single_quoted_strings`

    some parsers allow double quotes (`u+0022`) to be replaced by single quotes 
    (`u+0027`) to delimit keys and strings. this option allows json containing 
    single quotes as structural characters to be parsed without errors. note 
    that the parser expects strings to be terminated by the same quote type that 
    opened it and that single quotes must, obviously, be escaped within strings 
    delimited by single quotes

    double quotes must **always** be escaped, regardless of what kind of quotes 
    delimit the string they are found in

    the parser will never emit json with keys or strings delimited by single 
    quotes

- `:unescaped_jsonp`

    javascript interpreters treat the codepoints `u+2028` and `u+2029` as 
    significant whitespace. json strings that contain either of these codepoints 
    will be parsed incorrectly by some javascript interpreters. by default, 
    these codepoints are escaped (to `\u2028` and `\u2029`, respectively) to 
    retain compatibility. this option simply removes that escaping

- `:comments`

    json has no official comments but some parsers allow c/c++ style comments. 
    anywhere whitespace is allowed this flag allows comments (both `// ...` and 
    `/* ... */`)

- `:escaped_strings`

    by default both the encoder and decoder return strings as utf8 binaries 
    appropriate for use in elixir. escape sequences that were present in decoded 
    terms are converted into the appropriate codepoint while encoded terms are 
    unaltered. this flag escapes strings as if for output in json, removing 
    control codes and problematic codepoints and replacing them with the 
    appropriate escapes

- `:ignored_bad_escapes`

    during decoding ignore unrecognized escape sequences and leave them as is in 
    the stream. note that combining this option with `:escaped_strings` will 
    result in the escape character itself being escaped

- `:dirty_strings`

    json escaping is lossy; it mutates the json string and repeated application 
    can result in unwanted behaviour. if your strings are already escaped (or 
    you'd like to force invalid strings into "json" you monster) use this flag 
    to bypass escaping. this can also be used to read in **really** invalid json 
    strings. everything but escaped quotes are passed as is to the resulting 
    string term. note that this overrides `:ignored_bad_escapes`, 
    `:unescaped_jsonp` and `:escaped_strings`

- `:relax`

    relax is a synonym for `[:replaced_bad_utf8, :single_quoted_strings, :comments, 
    :ignored_bad_escapes]` for when you don't care how absolutely terrible your 
    json input is, you just want the parser to do the best it can

- `:incomplete_handler` & `:error_handler`

    the default incomplete and error handlers can be replaced with user defined 
    handlers. if options include `{:error_handler, f}` and/or 
    `{:incomplete_handler, f}` where `f` is a function of arity 3 they will be 
    called instead of the default handler. the spec for `f` is as follows
    ```erlang
    f(remaining, internalState, config) -> Any
    
      remaining = Any
      internalState = Any
      config = List
    ```
    `remaining` is the binary fragment or term that caused the error
    
    `internalState` is an opaque structure containing the internal state of the 
    parser/decoder/encoder
    
    `config` is a list of options/flags in use by the parser/decoder/encoder
    
    these functions should be considered experimental for now


## exports ##


#### `decode(json, opts)` ####

`decode` parses a json text (a `BitString`) and produces an elixir term

`opts` has the default value `[]` and can be a list containing any of the
standard `jsx` [options](#options)

##### examples #####

```erlang
iex(1)> JSX.decode "[true, false, null]"
{:ok,[true,false,nil]}
iex(2)> JSX.decode "invalid json"
{:error,:badarg}
```


#### `encode(term, opts)` ####

`encode` converts an elixir term into a json text (a BitString)

`opts` has the default value `[]` and can be a list containing any of the
standard `jsx` [options](#options) plus the following

* `{space, n}`
    inserts `n` spaces after every comma and colon in your  json output.
    `space` is an alias for `{space, 1}`. the default is `{space, 0}`

* `{indent, n}`
    inserts a newline and `n` spaces for each level of indentation in your
    json output. note that this overrides spaces inserted after a comma.
    `indent` is an alias for `{indent, 1}`. the default is `{indent, 0}`

##### examples #####

```erlang
iex(1)> JSX.encode [:true, :false, :nil]
{:ok,"[true,false,null]"}
iex(2)> JSX.encode [:a, :b, :c]
{:error,:badarg}
iex(3)> JSX.encode! [:true, :false, :nil]
"[true,false,null]"
```


#### `format(json, opts)` ####


`format` parses a json text and produces a formatted json text

`opts` has the default value `[]` and can be a list containing any of the
standard `jsx` [options](#options) plus the following

* `{space, n}`
    inserts `n` spaces after every comma and colon in your  json output.
    `space` is an alias for `{space, 1}`. the default is `{space, 0}`

* `{indent, n}`
    inserts a newline and `n` spaces for each level of indentation in your
    json output. note that this overrides spaces inserted after a comma.
    `indent` is an alias for `{indent, 1}`. the default is `{indent, 0}`

##### examples #####

```erlang
iex(1)> JSX.format("[ true,false,null ]", [space: 2]
{:ok,"[true,  false,  null]"}
```


#### `minify(json)` ####

`minify` parses a json text and produces a new json text stripped of whitespace

##### examples #####

```erlang
iex(1)> JSX.minify("[ true, false, null ]")
{:ok,"[true,false,null]"}
```


#### `prettify(json)` ####

`prettify` parses a json text and produces a new json 
text equivalent to `format(json, [space: 1, indent: 2])`

##### examples #####

```erlang
iex(1)> JSX.prettify("[ true, false, null ]")
{:ok,"[
  true,
  false,
  null
]"}
```


#### `is_json?(json, opts)` ####

returns true if input is a valid json text, false if not

`opts` has the default value `[]` and can be a list containing any of the
standard `jsx` [options](#options)

what exactly constitutes valid json may be [altered](#option)

##### examples #####

```erlang
iex(1)> JSX.is_json?("[ true, false, null ]")
true
```


#### `is_term?(term, opts)` ####

returns true if input is an elixir term that can be safely converted to json,
false if not

`opts` has the default value `[]` and can be a list containing any of the
standard `jsx` [options](#options)

what exactly constitutes valid json may be [altered](#option)

##### examples #####

```erlang
iex(1)> JSX.is_term?([ :true, :false, :nil ])
true
```


`decode!`, `encode!`, `format!`, `minify!` and `prettify!` are all variants that return
unwrapped results or throw an `ArgumentError` when presented with bad input


## acknowledgements ##

jsx wouldn't be what it is without the contributions of [paul davis](https://github.com/davisp), [lloyd hilaiel](https://github.com/lloyd), [john engelhart](https://github.com/johnezang), [bob ippolito](https://github.com/etrepum), [fernando benavides](https://github.com/elbrujohalcon), [alex kropivny](https://github.com/amtal), [steve strong](https://github.com/srstrong), [michael truog](https://github.com/okeuday), [dmitry kolesnikov](https://github.com/fogfish) and [emptytea](https://github.com/emptytea)

[json]: http://json.org
[jsx]: http://github.com/talentdeficit/jsx
[MIT]: http://www.opensource.org/licenses/mit-license.html
[rfc4627]: http://tools.ietf.org/html/rfc4627
[travis]: https://travis-ci.org/
