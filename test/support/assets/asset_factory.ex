defmodule Mintacoin.AssetFactory do
  @moduledoc """
  Allow the creation of asset while testing.
  """

  alias Ecto.UUID
  alias Mintacoin.Asset

  defmacro __using__(_opts) do
    quote do
      @spec asset_factory(attrs :: map()) :: Asset.t()
      def asset_factory(attrs) do
        code = Map.get(attrs, :code, sequence(:code, &"MTK#{&1}"))
        supply = Map.get(attrs, :supply, "1000")

        %Asset{
          id: UUID.generate(),
          code: code,
          supply: supply
        }
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
