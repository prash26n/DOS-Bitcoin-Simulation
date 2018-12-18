defmodule Project4Web.DashboardController do

  use Project4Web, :controller

  def dashboard(conn,  %{"miners" => miners,"difficulty" => difficulty}) do

    miners = String.to_integer(miners)
    difficulty = String.to_integer(difficulty)

    if (miners > 0 && difficulty > 0) do
      IO.puts("Sending new config [miners = #{miners}, difficulty = #{difficulty}]")
      GenServer.cast(Project4.Exchange, {:setcfg, [miners, difficulty]})
    end

    index(conn, nil)
   end

  def index(conn,  _params) do
  conn
  |> assign(:numNodes, GenServer.call(Project4.Exchange, {:getvar, :numNodes}))
  |> assign(:gval, GenServer.call(Project4.Exchange, {:getvar, :gval}))
  |> assign(:activeMiners, GenServer.call(Project4.Exchange, {:getvar, :activeMiners}))
  |> assign(:walletInfo, GenServer.call(Project4.Exchange, {:getvar, :walletInfo}))
  |> assign(:minerInfo, GenServer.call(Project4.Exchange, {:getvar, :minerInfo}))
  |> render("dashboard.html")
   end
end
