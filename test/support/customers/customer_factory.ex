defmodule Mintacoin.CustomerFactory do
  @moduledoc """
  Allow the creation of Customer while testing.
  """

  alias Ecto.UUID
  alias Mintacoin.Customer

  defmacro __using__(_opts) do
    quote do
      @spec customer_factory(attrs :: map()) :: Customer.t()
      def customer_factory(attrs) do
        default_api_key =
          "SFMyNTY.g2gDdAAAAAFkAAphY2NvdW50X2lkbQAAACQ4ZDkzYTkyOC05ZjM5LTQ4ZWMtOGIyNy0xZTdmN2NiZmE3NGVuBgDZmfYPhAFiAFxJAA.SRlUgdy7igREKsUdMM3POiqKZMr5bke9xAq8qa_ad_A"

        default_encrypted_api_key =
          "q62e5ySEDrlclOdrEi+7gmtp7qRNCDkCEHFFmjpsm0ATNPSXzexcrd3NEyDPI2TbnRuRV1nqXt51gofMNd5r2Yzbnul33HZjy11dtJoT7M7gl6VtOY597mT4bs5v2DgrgTEjo3omub/GfasqAVHHBGBDjycKrKMc2/vEoY0X0CpXt+muWZLa1zR58PxH+NfZa0b52j+dKB2Hb4zpzkbw5ghmnjUC9b265UZDydS0wxQ"

        name = Map.get(attrs, :name, "Customer")
        email = Map.get(attrs, :email, sequence(:email, &"customer_#{&1}@mintacoin.co"))
        api_key = Map.get(attrs, :api_key, default_api_key)
        encrypted_api_key = Map.get(attrs, :encrypted_api_key, default_encrypted_api_key)

        %Customer{
          id: UUID.generate(),
          email: email,
          name: name,
          api_key: api_key,
          encrypted_api_key: encrypted_api_key
        }
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
