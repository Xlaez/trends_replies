defmodule TrendsReplies.Account do
  import Ecto.Query, warn: false
  require Logger
  alias TrendsReplies.Repo

  defmodule Account do
    use Ecto.Schema
    @primary_key {:id, :binary_id, autogenerate: true}

    schema "account" do
      field :gist_id, :string
      field :is_banned, :boolean
      field :is_deactivated, :boolean
      field :is_verified, :boolean
      field :avatar, :string
    end
  end

  def get_user_by_id(id) when is_binary(id) do
    case Ecto.UUID.cast(id) do
      {:ok, uuid} ->
        query =
          from(a in Account,
            where: a.id == ^uuid,
            select: %{
              id: a.id,
              gist_id: a.gist_id,
              is_banned: a.is_banned,
              is_deactivated: a.is_deactivated,
              is_verified: a.is_verified,
              avatar: a.avatar
            },
            limit: 1
          )

        case Repo.one(query) do
          nil -> {:error, :not_found}
          user -> {:ok, user}
        end

      :error ->
        {:error, :invalid_uuid}
    end
  end

  def get_user_by_id(_), do: {:error, :invalid_uuid}
end
