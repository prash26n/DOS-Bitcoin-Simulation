defmodule Project4.Miner do
  @gval 4 #difficulty

  use GenServer

  def start_link(p) do
      GenServer.start_link(__MODULE__, p,
      name: {:via, Registry, {Project4.Registry, "miner#{p}"}})
  end

  def init(p) do
    data = %{id: "miner#{p}", btc: 0, gval: @gval, status: 0}
    Registry.register(Project4.Registry, "miner#{p}", :miner)

    GenServer.cast(Project4.Exchange, {:getminerinfo, [0,"miner#{p}"]})
    GenServer.cast(self(), {:mine})
    {:ok,data}
  end

  #verify if hash meets requirements for bitcoin discovery
  def verify(hash,g) do
    if (String.slice(hash,0,g) == String.duplicate("0",g)) do
      true
    else
      false
    end
  end

  #hash transaction data
  def hashTX(data) do
    data = Enum.join(data) <> rand()
    :crypto.hash(:sha256, data) |> Base.encode16 |> String.downcase
  end

  def rand() do
    :crypto.strong_rand_bytes(9) |> Base.url_encode64 |>
    binary_part(0,9) |> String.downcase()
  end

  #list [g,btc,block]
  def mine_utxo(txpack,g) do
      [utxo, id] = txpack
      hash = hashTX(utxo)
      if (verify(hash,g)) do
        GenServer.cast(Project4.Network,{:finished_block, txpack})
      else
        mine_utxo(txpack,g)
      end
  end

#######----------net communication----------########
def handle_cast({:setcfg, [active,gval]}, data) do
{:noreply, %{data | gval: gval, status: active}}
end

  def handle_cast({:get_utxo, txpack}, data) do
    mine_utxo(txpack,data.gval)
    GenServer.cast(self(), {:mine})
    {:noreply, data}
  end

  def handle_cast({:mine}, data) do
    g = data.gval
    btc = data.btc

    #status wrapper
    x = if (data.status == 0) do

    code = "x" <> rand()
    hash = :crypto.hash(:sha256, code) |> Base.encode16 |> String.downcase

      if (verify(hash,g)) do
      #found a bitcoin
      #IO.puts(code <> "\n" <> hash) #can make printing button here
      GenServer.cast(Project4.Exchange, {:getminerinfo, [btc+1,data.id]})
      1
      else
      0
      end
    else
      0
    end

    btc = data.btc
    #change value in list
    btc = btc + x

    GenServer.cast(self(), {:mine})
    {:noreply, %{data | btc: btc}}
  end


end
