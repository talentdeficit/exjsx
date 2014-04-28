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

  def handle_event({ :literal, :null }, config) do
    :jsx_to_term.insert(:nil, config)
  end

  def handle_event(event, config) do
    :jsx_to_term.handle_event(event, config)
  end
end

defprotocol JSEX.Encoder do
  def json(term)
end

defimpl JSEX.Encoder, for: HashDict do
  def json(dict), do: JSEX.Encoder.json(HashDict.to_list(dict))
end

defimpl JSEX.Encoder, for: List do
  def json([]), do: [:start_array, :end_array]
  def json([{}]), do: [:start_object, :end_object]
  def json([first|tail] = list) when is_tuple(first) do
    case first do
      {key, _} ->
        if is_atom(key) && function_exported?(key, :__record__, 1) do
          [:start_array] ++ JSEX.Encoder.json(first) ++ flatten(for term <- tail, do: JSEX.Encoder.json(term)) ++ [:end_array]
        else
          [:start_object] ++ flatten(for term <- list, do: JSEX.Encoder.json(term)) ++ [:end_object]
        end
      _ -> [:start_array] ++ JSEX.Encoder.json(first) ++ flatten(for term <- tail, do: JSEX.Encoder.json(term)) ++ [:end_array]
    end
  end
  def json(list) do
    [:start_array] ++ flatten(for term <- list, do: JSEX.Encoder.json(term)) ++ [:end_array]
  end
end

defimpl JSEX.Encoder, for: Tuple do
  def json(record) when is_record(record) do
    if function_exported?(elem(record, 0), :__record__, 1) do
      JSEX.Encoder.json Enum.map(
        record.__record__(:fields),
        fn({ key, _ }) -> { key, elem(record, record.__record__(:index, key)) } end
      )
    else
      # Tuple is not actually a record
      { key, value } = record
      [{ :key, key }] ++ JSEX.Encoder.json(value)
    end
  end
  def json({ key, value }) when is_bitstring(key) or is_atom(key) do
    [{ :key, key }] ++ JSEX.Encoder.json(value)
  end
  def json(_), do: raise ArgumentError
end

defimpl JSEX.Encoder, for: Atom do
  def json(nil), do: [:null]
  def json(true), do: [true]
  def json(false), do: [false]
  def json(_), do: raise ArgumentError
end

defimpl JSEX.Encoder, for: [Number, Integer, Float, BitString] do
  def json(value), do: [value]
end

defimpl JSEX.Encoder, for: [PID, Any] do
  def json(_), do: raise ArgumentError
end
