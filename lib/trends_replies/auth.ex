defmodule TrendsReplies.Auth do
  use Joken.Config

  def token_config do
    default_claims(skip: [:exp, :aud])
  end

  def verify_token(token) do
    secret = Application.get_env(:trends_replies, TrendsReplies.Auth)[:jwt_secret]

    signer = Joken.Signer.create("HS256", secret)

    case Joken.decode_and_verify(token, signer) do
      {:ok, claims} ->
        {:ok,
         %{
           user_id: claims["sub"]
         }}

      {:error, _reason} ->
        {:error, :invalid_token}
    end
  end
end
