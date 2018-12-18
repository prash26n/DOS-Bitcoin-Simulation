defmodule Project4Web.PanelController do
  use Project4Web, :controller

  def index(conn, _params) do
  #  conn 
  #  |> assign(:numWallets, GenServer.call(Monitor, {:data, :numWallets}))
  #  |> assign(:numMiners, GenServer.call(Monitor, {:data, :numMiners}))
  #  |> assign(:walletData, GenServer.call(Monitor, {:data, :walletData}))
    render(conn, "index.html")
  end
end
