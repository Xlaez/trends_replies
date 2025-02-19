defmodule TrendsReplies.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TrendsRepliesWeb.Telemetry,
      TrendsReplies.Repo,
      {DNSCluster, query: Application.get_env(:trends_replies, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: TrendsReplies.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: TrendsReplies.Finch},
      # Start a worker by calling: TrendsReplies.Worker.start_link(arg)
      # {TrendsReplies.Worker, arg},
      # Start to serve requests, typically the last entry
      TrendsRepliesWeb.Endpoint,
      TrendsReplies.Redis
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TrendsReplies.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TrendsRepliesWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
