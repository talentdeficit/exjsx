import :lists, only: [flatten: 1]

defmodule JSX do
  def encode!(term, opts \\ []) do
    parser_opts = :jsx_config.extract_config(opts ++ [:escaped_strings])
    parser(:jsx_to_json, opts, parser_opts).(JSX.Encoder.json(term) ++ [:end_json])
  end

  def encode(term, opts \\ []) do
    { :ok, encode!(term, opts) }
  rescue
    ArgumentError -> { :error, :badarg }
  end

  def decode!(json, opts \\ []) do
    decoder_opts = :jsx_config.extract_config(opts)
    case decoder(JSX.Decoder, opts, decoder_opts).(json) do
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
    parser(:jsx_verify, opts, parser_opts).(flatten(JSX.Encoder.json(term) ++ [:end_json]))
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

defmodule JSX.Decoder do
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

  defp format_key(key, { _, :binary, _ }), do: key
  defp format_key(key, { _, :atom, _ }), do: :erlang.binary_to_atom(key, :utf8)
  defp format_key(key, { _, :existing_atom, _ }), do: :erlang.binary_to_existing_atom(key, :utf8)
  defp format_key(key, { _, :attempt_atom, _ }) do
    :erlang.binary_to_existing_atom(key, :utf8)
  rescue
    ArgumentError -> key
  end
  
  defp start_object({ stack, config }), do: { [{ :object, %{} }] ++ stack, config }
  
  defp start_array({ stack, config }), do: { [{ :array, [] }] ++ stack, config }
    
  defp finish({ [{ :object, emptyMap }], config }) when is_map(emptyMap) and map_size(emptyMap) < 1 do
    { %{}, config }
  end
  defp finish({ [{ :object, emptyMap }|rest], config }) when is_map(emptyMap) and map_size(emptyMap) < 1 do
    insert(%{}, { rest, config })
  end
  defp finish({ [{ :object, pairs }], config }), do: { pairs, config }
  defp finish({ [{ :object, pairs}|rest], config }), do: insert(pairs, { rest, config })
  defp finish({ [{ :array, values }], config }), do: { Enum.reverse(values), config }
  defp finish({ [{ :array, values}|rest], config}), do: insert(Enum.reverse(values), { rest, config })
  defp finish(_), do: raise ArgumentError

  defp insert(value, { [], config }), do: { value, config }
  defp insert(key, { [{ :object, pairs }|rest], config }) do
    { [{ :object, key, pairs }] ++ rest, config }
  end
  defp insert(value, { [{ :object, key, pairs }|rest], config }) do
    { [{ :object, Map.put(pairs, key, value) }] ++ rest, config }
  end
  defp insert(value, { [{ :array, values}|rest], config }) do
    { [{ :array, [value] ++ values}] ++ rest, config }
  end
  defp insert(_, _), do: raise ArgumentError

  defp get_value({ value, _config }), do: value
  defp get_value(_), do: raise ArgumentError
end

defprotocol JSX.Encoder do
  @fallback_to_any true
  def json(term)
end

defimpl JSX.Encoder, for: Map do
  def json(map) do
    [:start_object] ++ unpack(map, Map.keys(map))
  end

  defp unpack(map, [k|rest]) when is_integer(k) or is_binary(k) or is_atom(k) do
    [k] ++ JSX.Encoder.json(Map.get(map, k)) ++ unpack(map, rest)
  end
  defp unpack(_, []), do: [:end_object]
end

defimpl JSX.Encoder, for: List do
  def json([]), do: [:start_array, :end_array]
  def json([{}]), do: [:start_object, :end_object]
  def json([{ _, _ }|_] = list) do
    [:start_object] ++ unzip(list)
  end
  def json(list) do
    [:start_array] ++ unhitch(list)
  end

  defp unzip([{k, v}|rest]) when is_integer(k) or is_binary(k) or is_atom(k) do
    [k] ++ JSX.Encoder.json(v) ++ unzip(rest)
  end
  defp unzip([]), do: [:end_object]

  defp unhitch([v|rest]) do
    JSX.Encoder.json(v) ++ unhitch(rest)
  end
  defp unhitch([]), do: [:end_array]
end

defimpl JSX.Encoder, for: HashDict do
  def json(dict), do: JSX.Encoder.json(HashDict.to_list(dict))
end

defimpl JSX.Encoder, for: Atom do
  def json(nil), do: [:null]
  def json(true), do: [true]
  def json(false), do: [false]
  def json(atom), do: [atom]
end

defimpl JSX.Encoder, for: [Integer, Float, BitString] do
  def json(value), do: [value]
end

defimpl JSX.Encoder, for: [Tuple, PID, Port, Reference, Function, Any] do
  def json(map) when is_map(map), do: JSX.Encoder.Map.json(Map.delete(map, :__struct__))
  def json(_), do: raise ArgumentError
end
