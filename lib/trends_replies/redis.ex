defmodule TrendsReplies.Redis do
  require Logger

  def child_spec(_opts) do
    children = [
      {Redix,
       host: "localhost",
       port: 6379,
       name: :redix,
       sync_connect: true,
       backoff_max: 5000,
       backoff_initial: 1000}
    ]

    %{
      id: RedixSupervisor,
      type: :supervisor,
      start: {Supervisor, :start_link, [children, [strategy: :one_for_one]]}
    }
  end

  def store_message(channel, message, sender, parentId) do
    # Generate unique Id for each message being stored in the database
    message_id = :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)

    message_data = %{
      id: message_id,
      sender: sender,
      content: message,
      parent: parentId,
      timestamp: DateTime.utc_now() |> DateTime.to_unix()
    }

    json_data = Jason.encode!(message_data)

    with {:ok, _} <-
           Redix.command(:redix, ["SETEX", "chat:#{channel}:#{message_id}", 86400, json_data]),
         {:ok, _} <-
           Redix.command(:redix, [
             "ZADD",
             "chat:#{channel}:messages",
             message_data.timestamp,
             message_id
           ]) do
      {:ok, message_id}
    else
      {:error, %Redix.ConnectionError{}} ->
        Logger.error("Redis connection error while storing message")
        {:error, :redis_connection_error}

      error ->
        Logger.error("Error storing message: #{inspect(error)}")
        {:error, :storage_error}
    end
  end

  def get_recent_messages(channel, limit \\ 50) do
    with {:ok, message_ids} <-
           Redix.command(:redix, ["ZREVRANGE", "chat:#{channel}:messages", 0, limit - 1]),
         messages <- fetch_messages(channel, message_ids) do
      {:ok, messages}
    else
      {:error, %Redix.ConnectionError{}} ->
        Logger.error("Redis connection error while fetching messages")
        {:error, :redis_connection_error}

      error ->
        Logger.error("Error fetching messages: #{inspect(error)}")
        {:error, :fetch_error}
    end
  end

  defp fetch_messages(channel, message_ids) do
    message_ids
    |> Enum.map(fn id ->
      case Redix.command(:redix, ["GET", "chat:#{channel}:#{id}"]) do
        {:ok, nil} -> nil
        {:ok, json} -> Jason.decode!(json)
        {:error, _} -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end
end
