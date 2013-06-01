defmodule JSX do
  def json_to_list(json) do
    decode(json)
  end
  
  def decode(json) do
    :jsx.decoder(JSX.Decoder, [], []).(json)
  end
   
  defmodule Decoder do
    def init(_) do
      :jsx_to_term.init([])
    end

    # this is the main deviation from `jsx'. all keys are returned as utf8 atoms
    # to ensure the returned object representation can be used with the `Keyword'
    # module
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
end
