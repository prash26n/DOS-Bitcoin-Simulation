defmodule Project4.Exchange do
  use GenServer

  def start_link(_p) do
    GenServer.start_link(__MODULE__, nil, name: Project4.Exchange)
  end

  def init(_p) do

    #default values for things can be changed or grown later
    data = %{numNodes: 100, activeMiners: 8, gval: 4, wallets: Map.new(),
            miners: Map.new()}
    {:ok, data}
  end

  #make list of randomly selected things
  def genlist(list, res, n, x) when n < x  do
    if (length(list) > 0) do
      i = Enum.at(list, :rand.uniform(length(list) - 1))
      list = Enum.filter(list, fn(x) -> x == i end)
      res = [i | res]
      genlist(list, res, length(res), x)
    else
      res
    end
  end
  def genlist(_, res,_,_) do res end

  #select random wallet to exchange with
  #node communication
  def handle_cast({:getwalletinfo, info}, data) do
    [btc, addr] = info
    wallets = data.wallets
    wallets = Map.put(wallets, addr, btc)
    {:noreply, %{data | wallets: wallets}}
  end

  def handle_cast({:getminerinfo, info}, data) do
    [btc, mId] = info
    mlist = data.miners
    mlist = Map.put(mlist, mId, btc)
    {:noreply, %{data | miners: mlist}}
  end
  #-----------------------------------------
  #user interface
  def handle_cast({:setcfg, cfg}, data) do
    [miners, gval] = cfg

    miners = if (miners > 2*System.schedulers_online()) do
        2*System.schedulers_online()
      else
        miners
      end

    gval = if (gval > 9) do 9 else gval end

    GenServer.cast(Project4.Network, {:setcfg, [miners,gval]})
    {:noreply, data}
  end
  #-----------------------------------------
  #web interface medium

  def handle_call({:getvar, var}, _, data) do
    case var do
      :numNodes -> {:reply, data.numNodes, data}
      :gval -> {:reply, data.gval, data}
      :activeMiners -> {:reply, data.activeMiners, data}

      #large data value  retrieval
      :walletInfo ->
        wallet_list = Map.to_list(data.wallets)
        wallet_list = for x <- wallet_list, do: elem(x,1)
        wallet_list = Enum.join(wallet_list, ",")
        {:reply, wallet_list, data}

      :minerInfo ->
        mlist = Map.to_list(data.miners)
        mlist = for x <- mlist, do: elem(x,1)
        mlist = Enum.join(mlist,",")
        {:reply, mlist, data}
    end
  end
end
