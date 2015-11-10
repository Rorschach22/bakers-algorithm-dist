#Ryan McArthur and Mitch Finzel


#borrowed this fib function from https://gist.github.com/kyanny/2026028

defmodule Fib do
  def fib(0) do 0 end
  def fib(1) do 1 end
  def fib(n) do fib(n-1) + fib(n-2) end
end

defmodule Manager do
  def thing([], []) do
    receive do
      {:addCustomer, sender} ->
        thing([sender] ,[])
      {:addServer, sender} ->
        thing([],[sender])
    end
  end
  def thing([c|customer],[]) do
    receive do
      {:addCustomer, sender} ->
        thing([c] ++ customer ++ [sender], [])
      {:addServer, sender} ->
        send(c, {:getFib, sender})
        thing(customer, [])
    end
  end
  def thing([], [s|server]) do
    receive do
      {:addCustomer, sender} ->
        send(sender, {:getFib, s})
        thing([], server)
      {:addServer, sender} ->
        thing([], [s] ++ server ++ [sender])
    end
  end
end

defmodule Customer do
  def start(node) do
    wait = :random.uniform(1000)
    :timer.sleep(wait)
    customer = Node.spawn(node, &__MODULE__.loop/0)
    send(customer, {:wakeUp})
  end
  def loop do
    receive do
      {:wakeUp} ->
        manager = :global.whereis_name(:manager)
        send(manager, {:addCustomer, self()})
        loop
      {:heresYourFib, fibReturn} ->
        IO.puts("Customer #{inspect self()} received the number #{fibReturn}")
      {:getFib, sender} ->
        :random.seed(:os.timestamp)
        fib = (:random.uniform(5) + 35)
        send(sender, {:computeFib, self(), fib})
        loop
    end
  end
end

defmodule Server do
  def start(node) do
    server = Node.spawn(node, &__MODULE__.loop/0)
    manager = :global.whereis_name(:manager)
    send(manager, {:addServer, server})
  end
  def loop do
    receive do
      {:computeFib, customer, fib} ->
        IO.puts("Server #{inspect self()} computing fib of #{fib} for #{inspect customer}")
        send(customer, {:heresYourFib, Fib.fib(fib)})
        manager = :global.whereis_name(:manager)
        send(manager, {:addServer, self()})
        loop
    end
  end
end

defmodule Thingy do
  def startServers(node, num) do
    Server.start(node)
    if num-1 > 0 do
      startServers(node, num-1)
    end
  end

  def startCustomers(node, num) do
    Customer.start(node)
    if num-1 > 0 do
      startCustomers(node, num-1)
    end
  end
end

defmodule Run do
  def simulation(firstNode, secondNode, thirdNode, numServers, numCustomers) do
    pid = spawn(Manager, :thing, [[], []])
    :global.register_name(:manager, pid)

    firstNumServers = (numServers/3)
    secondNumServers = (numServers/3)
    thirdNumServeers = (numServers - firstNumServers - secondNumServers)
    firstNumCustomers = (numCustomers/3)
    secondNumCustomers = (numCustomers/3)
    thirdNumCustomers = (numCustomers - firstNumCustomers - secondNumCustomers)

    Thingy.startServers(firstNode, firstNumServers)
    Thingy.startServers(secondNode, secondNumServers)
    Thingy.startServers(thirdNode, thirdNumServeers)
    Thingy.startCustomers(firstNode, firstNumCustomers)
    Thingy.startCustomers(secondNode, secondNumCustomers)
    Thingy.startCustomers(thirdNode, thirdNumCustomers)
  end
end


#To run use Run.simulation("firstnode", "secondnode", "thirdnode", number of servers, number of customers)
