defmodule TrendsRepliesWeb.RoomChannel do
  use Phoenix.Channel
  require Logger
  alias TrendsReplies.Redis
  alias TrendsReplies.Account

  @impl true
  def join("room:lobby", payload, socket) do
    %{"id" => id} = payload

    if authorized?(id) do
      case Redis.get_recent_messages(socket.topic) do
        {:ok, messages} ->
          {:ok, %{messages: messages}, socket}

        {:error, :redis_connection_error} ->
          Logger.warning("Redis connection error during join, proceeding with empty message list")
          {:ok, %{messages: [], error: "Could not fetch messages"}, socket}

        {:error, _reason} ->
          {:error, %{reason: "Failed to load messages"}}
      end
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_in(
        "new_message",
        %{"message" => message, "sender" => sender, "parentId" => parentId},
        socket
      ) do
    case Redis.store_message(socket.topic, message, sender, parentId) do
      {:ok, message_id} ->
        message_data = %{
          id: message_id,
          message: message,
          sender: sender,
          parentId: parentId,
          timestamp: DateTime.utc_now() |> DateTime.to_unix()
        }

        broadcast!(socket, "new_message", message_data)
        {:reply, {:ok, message_data}, socket}

      {:error, _reason} ->
        {:reply, {:error, %{reason: "Failed to store message"}}, socket}
    end
  end

  defp authorized?(id) do
    case Account.get_user_by_id(id) do
      {:ok, user} ->
        Logger.debug("User data retrieved: #{inspect(user)}")

        cond do
          user.is_banned ->
            Logger.warning("Access denied: User #{id} is banned")
            false

          user.is_deactivated ->
            Logger.warning("Access denied: User #{id} is deactivated")
            false

          not user.is_verified ->
            Logger.warning("Access denied: User #{id} is not verified")
            false

          true ->
            Logger.info("User #{id} authorized successfully")
            true
        end

      {:error, reason} ->
        Logger.error("Failed to retrieve user #{id}: #{inspect(reason)}")
        false
    end
  end
end
