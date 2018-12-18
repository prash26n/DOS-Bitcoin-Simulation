defmodule Project4.Node do
use GenServer

alias Project4.Wallet

defmodule Address do
  defstruct pub: nil, pvt: nil, addr: nil
end

defmodule WalletObj do
  defstruct wallet: nil, val: nil
end

def start_link(p) do
  GenServer.start_link(__MODULE__, p,
  name: {:via, Registry, {Project4.Registry, "node#{p}"}})
end

def init(p) do
  {pub, pvt} = Project4.Wallet.Key.genkey()
  m_addr = Project4.Wallet.Addr.agen(pvt)

  addr_struct = %Address{pub: pub, pvt: pvt, addr: m_addr}

  btc = 5

  data = %{id: "node#{p}", wallet: nil, val: btc, uaddr: addr_struct}

  Registry.register(Project4.Registry, "node#{p}", :node)

  GenServer.cast(Project4.Exchange, {:getwalletinfo, ["node#{p}", btc]})

  {:ok,data}
end

def handle_call({:get_addr}, _, data) do
  addr_s = data.uaddr
  address = addr_s.addr
  {:reply, address, data}
end

def handle_call(:get_chain, _, data) do
  {:reply, data.chain, data}
end

def handle_call(:status, _, data) do
  {:reply, data.status, data}
end

def handle_cast({:bplus, b}, data) do
  btcx = data.val + b
  balanceChange(btcx, data.id)
  {:noreply, %{data | val: btcx}}
end

def handle_cast({:relaydata}, data) do
  btcx = data.val
  addr_struct = data.uaddr
  m_addr = addr_struct.addr
  GenServer.cast(Project4.Exchange, {:getwalletinfo, [btcx, m_addr]})
  {:noreply, data}
end

def handle_cast({:makeTX, to, to_id}, data) do

    #can make data.val directly trace to chain and calculate
    #how many bitcoins owned thru the ledger
    nb = if (data.val > 0) do

    wallet = data.wallet
    addr_struct = data.uaddr
    {pub,pvt} = {addr_struct.pub, addr_struct.pvt}
    bal = :rand.uniform(data.val)

    sig = Project4.Wallet.Addr.gen(pvt, "message")
    utxo = Project4.Network.genTransaction(bal, pub, to, sig)
    txpack = [utxo, to_id]

    GenServer.cast(Project4.Network, {:add_utxo, txpack})

    balanceChange(data.val - bal, data.id)

    data.val - bal
    end

    #move value change to transaction finalization call instead
    {:noreply, %{data | val: nb}}
end

#receive and no reply
def handle_cast(:exit, data) do
  Process.exit(data.status, :kill)
  GenServer.cast(Network, {:deln, data.id})
  {:stop, :normal, %{data | status: nil, utxo: nil}}
end

def balanceChange(btc, id) do
  GenServer.cast(Project4.Exchange, {:getwalletinfo, [btc,id]})
end

end
