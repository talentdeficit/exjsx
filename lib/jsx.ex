defmodule JSX do
  def encode(term, opts // []) do
    parser_opts = :jsx_config.extract_config(opts ++ [:escaped_strings])
    :jsx.parser(:jsx_to_json, opts, parser_opts).(List.flatten(JSX.Encode.json(term) ++ [:end_json]))
  end
  
  def decode(json, opts // []) do
    :jsx.decoder(JSX.Decoder, [], opts).(json)
  end
  
  def format(json, opts // []) do
    :jsx.format(json, opts)
  end

  def minify(json) do
    :jsx.minify(json)
  end
  
  def prettify(json) do
    :jsx.prettify(json)
  end
  
  def is_json(json, opts // []) do
    try do
      :jsx.is_json(json, opts)
    catch
      :error, :badarg -> :false
    end
  end
  
  def is_term(term, opts // []) do
    parser_opts = :jsx_config.extract_config(opts)
    try do
      :jsx.parser(:jsx_verify, opts, parser_opts).(List.flatten(JSX.Encode.json(term) ++ [:end_json]))
    catch
      :error, :badarg -> :false
    end
  end
   
  defmodule Decoder do
    def init(_) do
      :jsx_to_term.init([])
    end

    def handle_event({:key, key}, {terms, config}) do
      {[{:key, format_key(key)}] ++ terms, config}
    end

    def handle_event({:literal, :null}, {[{:key, key}, last|terms], config}) do
      {[[{key, :nil}] ++ last] ++ terms, config}
    end
  
    def handle_event({:literal, :null}, {[last|terms], config}) do
      {[[:nil] ++ last] ++ terms, config}
    end
  
    def handle_event(event, config) do
      :jsx_to_term.handle_event(event, config)
    end
    
    defp format_key(key) do
      :erlang.binary_to_atom(key, :utf8)
    end
  end
  
  defprotocol Encode do
    @only [List, Tuple, Atom, Number, BitString, Any]
    def json(term)
  end
  
  defimpl Encode, for: List do
    def json([]), do: [:start_array, :end_array]
    def json([{}]), do: [:start_object, :end_object]
    def json([first|_] = list) when is_tuple(first) do
      [:start_object] ++ List.flatten(Enum.map(list, fn(term) -> JSX.Encode.json(term) end)) ++ [:end_object]
    end
    def json(list) do
      [:start_array] ++ List.flatten(Enum.map(list, fn(term) -> JSX.Encode.json(term) end)) ++ [:end_array]
    end
  end
  
  defimpl Encode, for: Tuple do
    def json({key, value}) when is_atom(key), do: [{:key, key}] ++ JSX.Encode.json(value)
    def json(_), do: raise ArgumentError
  end
  
  defimpl Encode, for: Atom do
    def json(:true), do: [:true]
    def json(:false), do: [:false]
    def json(:nil), do: [:null]
    def json(_), do: raise ArgumentError
  end
  
  defimpl Encode, for: Number do
    def json(number) when is_integer(number), do: [number]
    def json(number) when is_float(number), do: [number]
  end
  
  defimpl Encode, for: BitString do
    def json(string), do: [string]
  end
  
  defimpl Encode, for: Any do
    def json(_), do: raise ArgumentError
  end
end
