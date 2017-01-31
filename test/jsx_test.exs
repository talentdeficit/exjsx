Code.require_file "test_helper.exs", __DIR__

defmodule JSX.Tests.Helpers do
  def numbers(:ex), do: [-18446744073709551617, -1.0, -1, 0, 0.0, 1, 1.0, 18446744073709551617]
  def numbers(:json), do: "[-18446744073709551617,-1.0,-1,0,0.0,1,1.0,18446744073709551617]"

  def compoundobj(:ex) do
    %{
      "a" => [true,false,nil],
      "b" => "hallo world",
      "c" => %{
        "x" => [1,2,3],
        "y" => %{},
        "z" => [[[]]]
      }
    }
  end
  def compoundobj(:json), do: "{\"a\":[true,false,null],\"b\":\"hallo world\",\"c\":{\"x\":[1,2,3],\"y\":{},\"z\":[[[]]]}}"
end

defmodule JSX.Tests.Decode do
  use ExUnit.Case
  import JSX.Tests.Helpers

  test "decode empty object" do
    assert(JSX.decode("{}") == { :ok, %{} })
  end

  test "decode! empty object" do
    assert(JSX.decode!("{}") == %{})
  end

  test "decode empty list" do
    assert(JSX.decode("[]") == { :ok, [] })
  end

  test "decode! empty list" do
    assert(JSX.decode!("[]") == [])
  end

  test "decode literals" do
    assert(JSX.decode("[true, false, null]") == { :ok, [true, false, nil] })
  end

  test "decode! literals" do
    assert(JSX.decode!("[true, false, null]") == [true, false, nil])
  end

  test "decode numbers" do
    assert(JSX.decode(numbers(:json)) == { :ok, numbers(:ex) })
  end

  test "decode! numbers" do
    assert(JSX.decode!(numbers(:json)) == numbers(:ex))
  end

  test "decode strings" do
    assert(JSX.decode("[\"hallo\", \"world\"]") == { :ok, ["hallo", "world"] })
  end

  test "decode! strings" do
    assert(JSX.decode!("[\"hallo\", \"world\"]") == ["hallo", "world"])
  end

  test "decode simple object" do
    assert(JSX.decode("{\"key\": true}") == { :ok, %{"key" => true} })
  end

  test "decode! simple object" do
    assert(JSX.decode!("{\"key\": true}") == %{"key" => true})
  end

  test "decode compound object" do
    assert(JSX.decode(compoundobj(:json)) == { :ok, compoundobj(:ex) })
  end

  test "decode! compound object" do
    assert(JSX.decode!(compoundobj(:json)) == compoundobj(:ex))
  end
end

defmodule JSX.Tests.Encode do
  use ExUnit.Case
  import JSX.Tests.Helpers

  test "encode empty object (list)" do
    assert(JSX.encode([{}]) == { :ok, "{}" })
  end

  test "encode! empty object (list)" do
    assert(JSX.encode!([{}]) == "{}")
  end

  test "encode empty object (map)" do
    assert(JSX.encode(%{}) == { :ok, "{}" })
  end

  test "encode! empty object (map)" do
    assert(JSX.encode!(%{}) == "{}")
  end

  test "encode empty list" do
    assert(JSX.encode([]) == { :ok, "[]" })
  end

  test "encode! empty list" do
    assert(JSX.encode!([]) == "[]")
  end

  test "encode list of empty lists" do
    assert(JSX.encode([[], [], []]) == { :ok, "[[],[],[]]" })
  end

  test "encode! list of empty lists" do
    assert(JSX.encode!([[], [], []]) == "[[],[],[]]")
  end

  test "encode list of empty objects" do
    assert(JSX.encode([%{}, %{}, %{}]) == { :ok, "[{},{},{}]" })
  end

  test "encode! list of empty objects" do
    assert(JSX.encode!([%{}, %{}, %{}]) == "[{},{},{}]")
  end

  test "encode literals" do
    assert(JSX.encode([true, false, nil]) == { :ok, "[true,false,null]" })
  end

  test "encode! literals" do
    assert(JSX.encode!([true, false, nil]) == "[true,false,null]")
  end

  test "encode numbers" do
    assert(JSX.encode(numbers(:ex)) == { :ok, numbers(:json) })
  end

  test "encode! numbers" do
    assert(JSX.encode!(numbers(:ex)) == numbers(:json))
  end

  test "encode strings" do
    assert(JSX.encode(["hallo", "world"]) == { :ok, "[\"hallo\",\"world\"]" })
  end

  test "encode! strings" do
    assert(JSX.encode!(["hallo", "world"]) == "[\"hallo\",\"world\"]")
  end

  test "encode keylist" do
    assert(JSX.encode([key: true]) == { :ok, "{\"key\":true}" })
  end

  test "encode! keylist" do
    assert(JSX.encode!([key: true]) == "{\"key\":true}")
  end

  test "encode map" do
    assert(JSX.encode(%{ "key" => true }) == { :ok, "{\"key\":true}" })
  end

  test "encode! map" do
    assert(JSX.encode!(%{ "key" => true }) == "{\"key\":true}")
  end

  test "encode range" do
    assert(JSX.encode(0..9) == { :ok, "[0,1,2,3,4,5,6,7,8,9]" })
  end

  test "encode! range" do
    assert(JSX.encode!(0..9) == "[0,1,2,3,4,5,6,7,8,9]")
  end

  test "encode MapSet as sorted array" do
    assert(JSX.encode(Enum.into([1, 2, 3], MapSet.new)) == { :ok, "[1,2,3]" })
  end

  test "encode! MapSet as sorted array" do
    assert(JSX.encode!(Enum.into([1, 2, 3], MapSet.new)) == "[1,2,3]")
  end

  test "encode object with bitstring key" do
    assert(JSX.encode(%{ "key" => true }) == { :ok, "{\"key\":true}" })
  end

  test "encode! object with bitstring key" do
    assert(JSX.encode!(%{ "key" => true }) == "{\"key\":true}")
  end

  test "encode object with atom key" do
    assert(JSX.encode(%{ :key => true }) == { :ok, "{\"key\":true}" })
  end

  test "encode! object with atom key" do
    assert(JSX.encode!(%{ :key => true }) == "{\"key\":true}")
  end

  test "encode compound object" do
    assert(JSX.encode(compoundobj(:ex)) == { :ok, compoundobj(:json) })
  end

  test "encode! compound object" do
    assert(JSX.encode!(compoundobj(:ex)) == compoundobj(:json))
  end

  test "encode keylist with key `nil`" do
    assert(JSX.encode([nil: nil]) == { :ok, "{\"nil\":null}" })
  end

  test "encode map with key `nil`" do
    assert(JSX.encode(%{ nil => nil }) == { :ok, "{\"nil\":null}" })
  end
end

defmodule User do
  defstruct name: "jose", age: 27
end

defmodule FancyUser do
  defstruct name: "jose", age: 27
end

defimpl JSX.Encoder, for: FancyUser do
  def json(user) do
    [Map.get(user, :name) <> " is " <> to_string(Map.get(user, :age)) <> " years old!"]
  end
end

defmodule JSX.Tests.Structs do
  use ExUnit.Case

  test "encode a simple struct" do
    assert(JSX.encode(%User{}) == { :ok, "{\"age\":27,\"name\":\"jose\"}" })
  end

  test "encode a list of simple structs" do
    assert(JSX.encode([%User{}]) == { :ok, "[{\"age\":27,\"name\":\"jose\"}]" })
  end

  test "encode a struct with a protocol defined" do
    assert(JSX.encode(%FancyUser{}) == { :ok, "\"jose is 27 years old!\"" })
  end
end

defmodule JSX.Tests.Is do
  use ExUnit.Case

  test "is_json? {}", do: assert(JSX.is_json?("{}") == true)
  test "is_json? {", do: assert(JSX.is_json?("{") == false)
  test "is_json? :error", do: assert(JSX.is_json?(:error) == false)

  test "is_term? [{}]", do: assert(JSX.is_term?([{}]) == true)
  test "is_term? %{}", do: assert(JSX.is_term?(%{}) == true)
  test "is_term? {}", do: assert(JSX.is_term?({}) == false)
  test "is_term? self", do: assert(JSX.is_term?(self()) == false)
end

defmodule JSX.Tests.Errors do
  use ExUnit.Case

  test "decode {", do: assert(JSX.decode("{") == { :error, :badarg })
  test "decode! {", do: assert_raise(ArgumentError, fn -> JSX.decode!("{") end)

  test "format {", do: assert(JSX.format("{") == { :error, :badarg })
  test "format! {", do: assert_raise(ArgumentError, fn -> JSX.format!("{") end)

  test "decode :error", do: assert(JSX.decode(:error) == { :error, :badarg })
  test "decode! :error", do: assert_raise(ArgumentError, fn -> JSX.decode!(:error) end)

  test "format :error", do: assert(JSX.format(:error) == { :error, :badarg })
  test "format! :error", do: assert_raise(ArgumentError, fn -> JSX.format!(:error) end)

  test "encode self", do: assert(JSX.encode(self()) == { :error, :badarg })
  test "encode! self", do: assert_raise(ArgumentError, fn -> JSX.encode!(self()) end)
end
