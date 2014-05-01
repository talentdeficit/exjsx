import :lists, only: [flatten: 1]

defmodule JSEX do
  def encode!(term, opts \\ []) do
    parser_opts = :jsx_config.extract_config(opts ++ [:escaped_strings])
    parser(:jsx_to_json, opts, parser_opts).(flatten(JSEX.Encoder.json(term) ++ [:end_json]))
  end

  def encode(term, opts \\ []) do
    { :ok, encode!(term, opts) }
  rescue
    ArgumentError -> { :error, :badarg }
  end

  def decode!(json, opts \\ []) do
    decoder_opts = :jsx_config.extract_config(opts)
    case decoder(JSEX.Decoder, opts, decoder_opts).(json) do
      { :incomplete, _ } -> raise ArgumentError
      result -> result
    end
  end

  def decode(term, opts \\ []) do
    { :ok, decode!(term, opts) }
  rescue
    ArgumentError -> { :error, :badarg }
  end

  def format!(json, opts \\ []) do
    case :jsx.format(json, opts) do
      { :incomplete, _ } -> raise ArgumentError
      result -> result
    end
  end

  def format(json, opts \\ []) do
    { :ok, format!(json, opts) }
  rescue
    ArgumentError -> { :error, :badarg }
  end

  def minify!(json), do: format!(json, [space: 0, indent: 0])

  def minify(json) do
    { :ok, minify!(json) }
  rescue
    ArgumentError -> { :error, :badarg }
  end

  def prettify!(json), do: format!(json, [space: 1, indent: 2])

  def prettify(json) do
    { :ok, prettify!(json) }
  rescue
    ArgumentError -> { :error, :badarg }
  end

  def is_json?(json, opts \\ []) do
    case :jsx.is_json(json, opts) do
      { :incomplete, _ } -> false
      result -> result
    end
  rescue
    _ -> false
  end

  def is_term?(term, opts \\ []) do
    parser_opts = :jsx_config.extract_config(opts)
    parser(:jsx_verify, opts, parser_opts).(flatten(JSEX.Encoder.json(term) ++ [:end_json]))
  rescue
    _ -> false
  end
  
  def encoder(handler, initialstate, opts) do
    :jsx.encoder(handler, initialstate, opts)
  end
  
  def decoder(handler, initialstate, opts) do
    :jsx.decoder(handler, initialstate, opts)
  end
  
  def parser(handler, initialstate, opts) do
    :jsx.parser(handler, initialstate, opts)
  end
end

defmodule JSEX.Decoder do
  def init(opts) do
    :jsx_to_term.init(opts)
  end

  def handle_event(:end_json, state), do: get_value(state)
  def handle_event(:start_object, state), do: start_object(state)
  def handle_event(:end_object, state), do: finish(state)
  def handle_event(:start_array, state), do: start_array(state)
  def handle_event(:end_array, state), do: finish(state)
  def handle_event({ :key, key }, { _, config } = state), do: insert(format_key(key, config), state)
  def handle_event({ :literal, :null }, state), do: insert(:nil, state)
  def handle_event({ _, event }, state), do: insert(event, state)

  def format_key(key, { _, :binary }), do: key
  def format_key(key, { _, :atom }), do: :erlang.binary_to_atom(key, :utf8)
  def format_key(key, { _, :existing_atom }), do: :erlang.binary_to_existing_atom(key, :utf8)
  def format_key(key, { _, :attempt_atom }) do
    :erlang.binary_to_existing_atom(key, :utf8)
  rescue
    ArgumentError -> key
  end
  
  def start_object({ stack, config }), do: { [{ :object, %{} }] ++ stack, config }
  
  def start_array({ stack, config }), do: { [{ :array, [] }] ++ stack, config }
    
  def finish({ [{ :object, emptyMap }], config }) when is_map(emptyMap) and map_size(emptyMap) < 1 do
    { %{}, config }
  end
  def finish({ [{ :object, emptyMap }|rest], config }) when is_map(emptyMap) and map_size(emptyMap) < 1 do
    insert(%{}, { rest, config })
  end
  def finish({ [{ :object, pairs }], config }), do: { pairs, config }
  def finish({ [{ :object, pairs}|rest], config }), do: insert(pairs, { rest, config })
  def finish({ [{ :array, values }], config }), do: { Enum.reverse(values), config }
  def finish({ [{ :array, values}|rest], config}), do: insert(Enum.reverse(values), { rest, config })
  def finish(_), do: raise ArgumentError

  def insert(value, { [], config }), do: { value, config }
  def insert(key, { [{ :object, pairs }|rest], config }) do
    { [{ :object, key, pairs }] ++ rest, config }
  end
  def insert(value, { [{ :object, key, pairs }|rest], config }) do
    { [{ :object, Map.put(pairs, key, value) }] ++ rest, config }
  end
  def insert(value, { [{ :array, values}|rest], config }) do
    { [{ :array, [value] ++ values}] ++ rest, config }
  end
  def insert(_, _), do: raise ArgumentError

  def get_value({ value, _config }), do: value
  def get_value(_), do: raise ArgumentError
end

defprotocol JSEX.Encoder do
  def json(term)
end

defimpl JSEX.Encoder, for: Map do
  def json(map) do
    [:start_object] ++ flatten(for key <- Map.keys(map) do
      JSEX.Encoder.json(key) ++ JSEX.Encoder.json(map[key])
    end) ++ [:end_object]
  end
end

defimpl JSEX.Encoder, for: List do
  def json([]), do: [:start_array, :end_array]
  def json([{}]), do: [:start_object, :end_object]
  def json([{ key, _ }|_] = list) do
    [:start_object] ++
      flatten(for term <- unzip(list), do: JSEX.Encoder.json(term)) ++
    [:end_object]
  end
  def json(list) do
    [:start_array] ++ flatten(for term <- list, do: JSEX.Encoder.json(term)) ++ [:end_array]
  end
  
  def unzip(list), do: unzip(list, [])
    
  def unzip([], acc), do: Enum.reverse(acc)
  def unzip([{ key, value }|rest], acc)
  when is_binary(key) or is_atom(key) or is_integer(key) do
    unzip(rest, [value, key] ++ acc)
  end
end

defimpl JSEX.Encoder, for: HashDict do
  def json(dict), do: JSEX.Encoder.json(HashDict.to_list(dict))
end

defimpl JSEX.Encoder, for: Atom do
  def json(nil), do: [:null]
  def json(true), do: [true]
  def json(false), do: [false]
  def json(atom), do: [:erlang.atom_to_binary(atom, :utf8)]
end

defimpl JSEX.Encoder, for: [Number, Integer, Float, BitString] do
  def json(value), do: [value]
end

defimpl JSEX.Encoder, for: [Tuple, PID, Any] do
  def json(_), do: raise ArgumentError
end
