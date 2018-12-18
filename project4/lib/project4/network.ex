defmodule Project4.Network do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: Project4.Network)
  end

  def init(_p) do
    #empty data
    genBlock = initBlock()
    data = %{chain: [genBlock], miners: nil}
    {:ok,data}
  end

  #######----------messages----------########
  def handle_cast({:set_chain, blockid}, data) do
    data = %{data | chain: [blockid]}
    {:noreply, data}
  end

  def handle_cast({:initTX, [numTX, iBal]}, data) do
    {:noreply, data}
  end

  def handle_cast({:finished_block, txpack}, data) do
    [utxo, id] = txpack
    pub1 = Enum.at(utxo,2)
    sig1 = Enum.at(utxo,3)
    Project4.Wallet.Addr.validate(pub1,sig1,"message")

      #relay transaction to to_id node
      amt = Enum.at(utxo,0)
      GenServer.cast(id, {:bplus, amt})
       chain = add_block(utxo, data.chain)
       {:noreply, %{data | chain: chain}}
  end

  def handle_cast({:ping}, data) do
    IO.puts("Network alive")
    {:noreply, data}
  end

  #just get the pid themselves since it'll be called so much
  def handle_cast({:set_mlist, m}, data) do

    list = try do

    Enum.map(m, fn(n) ->
      keypair = Registry.lookup(Project4.Registry, n)

      {pid,_} = Enum.at(keypair,0)
      pid
    end)

  rescue
    _ ->
    IO.puts("mining nodes not found...retrying")
    Process.sleep(1000)
    GenServer.cast(self(), {:set_mlist, m})
  end

    data = %{data | miners: list}
    {:noreply, data}
  end

  #use registry to lookup miners and relay utxo to them
  def handle_cast({:add_utxo, txpack}, data) do
    miners = data.miners
    if (miners != nil) do
      Enum.each(miners, fn(n)-> GenServer.cast(n,{:get_utxo,txpack}) end)
    else
      IO.puts("error: miner list null") #should never happen
    end
    {:noreply, data}
  end

  #######----------user communication----------########
  def handle_cast({:setcfg, info}, data) do
    [active, gval] = info
    toggleCfg(data.miners, active, gval, length(data.miners), 0)
    {:noreply, data}
  end

  #go thru all the miners and change things accordingly
  def toggleCfg(list, active, gval, x, i) when (i < x) do
    flag = if (i < active) do 0 else 1 end
    GenServer.cast(Enum.at(list,i), {:setcfg, [flag, gval]})
    toggleCfg(list,active,gval,x,i+1)
  end
  def toggleCfg(_,_,_,_,_) do end

  def add_block(utx, chain) do
    hash = hashBlock(utx)

      chain = if (check(hash,chain,length(chain) - 1) == false) do
        block = genBlock(Enum.at(chain,length(chain)-1),utx)

        #print here
        #IO.puts("New Block")
        #IO.inspect(block)

        chain ++ [block]
      else
        chain
      end#endif
  end

  def check(hash, data, i) when i >= 0 do
    blk = Enum.at(data,i)
    other = elem(blk,2)
    if (other == hash) do
      true
    else
      check(hash,data,i-1)
    end
  end
  def check(_,_,_) do false end

  #generate hash of a block
  def hashBlock(data) do
    data = Enum.join(data)
    :crypto.hash(:sha256, data) |> Base.encode16
  end

  #returns initialization block
  def initBlock() do
    time = NaiveDateTime.utc_now
    {[],"","","",time,""}
  end

  #block =
  def genBlock(prev, utx) do
    prv_hash = elem(prev,1)
    [amt,to,from,sig,time] = utx
    hash = hashBlock(utx)
    txdata = [amt,to]
    {txdata,prv_hash,hash,sig,time,from}
  end

  #create transaction data, send to server
  def genTransaction(amt, from, to, sig) do
    time = NaiveDateTime.utc_now
    [amt,to,from,sig,time]
  end

  ###########----blockchain----############
  def handle_cast({:f_block, [pid, block]}, data) do
      GenServer.cast(pid, {:last_block, block})
      {:noreply, data}
  end
end
