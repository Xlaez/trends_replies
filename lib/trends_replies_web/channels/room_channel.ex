defmodule TrendsRepliesWeb.RoomChannel do
  use Phoenix.Channel
  require Logger
  alias TrendsReplies.Redis

  @impl true
  def join("room:lobby", payload, socket) do
    if authorized?(payload) do
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

  defp authorized?(_payload) do
    true
  end
end
