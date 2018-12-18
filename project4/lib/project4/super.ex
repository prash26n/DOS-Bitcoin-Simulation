defmodule Project4.Super do
  use GenServer

  @delay 5000

  alias Project4.Wallet
  alias Project4.Miner
  alias Project4.Node

  defmodule ServData do
    defstruct wallets: nil, chain: [], miners: nil
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: Project4.Super)
  end

  def init(_p) do
    data = %ServData{wallets: nil, chain: [], miners: nil}
    {:ok, data}
  end

##########----initialization----##########
def handle_cast({:initialize}, data) do
  wallets = gen_wallets(100) #can be changed to param if needed
  miners = gen_miners(2*System.schedulers_online())

  Process.sleep(1000) #delay to register all

  #send miner list to network
  GenServer.cast(Project4.Network, {:set_mlist, miners})

  GenServer.cast(self(), {:ping}) #begins wallet comm.

  {:noreply, %{data | wallets: wallets, miners: miners}}
end

def uniquelist(list,n,x) when n < x do
  i = :rand.uniform(10000)
  list = if (Enum.find_value(list, fn(n)->i==n end) == nil) do
    uniquelist([i | list], n + 1, x)
  else
    uniquelist(list,n,x)
  end
end
def uniquelist(list,_,_) do list end

def gen_wallets(n) do
  ids = uniquelist([],0,n)

  #IO.puts("spawning wallets...")
  spawn_link(fn-> Enum.each(ids, fn(x)->
      DynamicSupervisor.start_child(Project4.DynamicSupervisor,
      Supervisor.child_spec({Node, x}, id: {Node, x}, restart: :temporary)) end)
    end)

    for x <- ids, do: "node#{x}"
end

def gen_miners(n) do
  mlist = for x <- 1..n, do: x

spawn_link(fn-> Enum.each(mlist, fn(x)->
    DynamicSupervisor.start_child(Project4.DynamicSupervisor,
    Supervisor.child_spec({Miner, x}, id: {Miner, x}, restart: :temporary)) end)
  end)

  for x <- mlist, do: "miner#{x}"
end

###########----transactions----############
def randpair(list) do
  a = Enum.at(list, :rand.uniform( length(list) - 1))
  b = Enum.at(list, :rand.uniform( length(list) - 1))
  if (a == b) do randpair(list) else [a,b] end
end

def handle_cast({:ping}, data) do
  #instigate transaction
  nodes = data.wallets
  [to, from] = randpair(nodes)

  topk = Registry.lookup(Project4.Registry, to)
  frompk = Registry.lookup(Project4.Registry, from)

  if (topk != nil && frompk != nil) do

  {to_pid, _} = if (length(topk) > 0) do Enum.at(topk, 0) else {0,0} end
  {from_pid, _} = if (length(frompk) > 0) do Enum.at(frompk, 0) else {0,0} end

  if (to_pid != 0 && from_pid != 0) do
  to_addr = GenServer.call(to_pid, {:get_addr})
  GenServer.cast(from_pid, {:makeTX, to_addr, to_pid})
  else
    IO.inspect(to_pid)
    IO.inspect(from_pid)
    IO.puts("No relay. Retrying")
  end #end inner if
  else
    IO.puts("No registry. Retrying")
  end #outer if

  Process.sleep(@delay)
  GenServer.cast(self(), {:ping}) #uncomment after testing!

  {:noreply, data}
end

end
