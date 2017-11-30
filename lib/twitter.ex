defmodule Twitter do
  def main(args) do
    process(args)
  end

  def process([]) do
    {:ok, client1} = Client.start_link() 
    {:ok, client2} = Client.start_link()
    
    {:ok, userEngine} = UserEngine.start_link([], %{}, %{})
    
    IO.puts "userEngine " <> inspect(userEngine)
    GenServer.cast userEngine, {:register, 1}
    GenServer.cast userEngine, {:register, 2}  
    GenServer.cast userEngine, {:register, 3}        
    
    GenServer.cast userEngine, {:subscribe, 1, [2,3]}
    GenServer.cast userEngine, {:subscribe, 2, [3]} 
    GenServer.cast userEngine, {:subscribe, 3, [1]} 
    
    GenServer.call userEngine, {:postTweet, 1, "Hello Gators! #gogators #gators #gatorsaregreat"}
    GenServer.call userEngine, {:postTweet, 1, "Go Gators! @2"}
    GenServer.call userEngine, {:postTweet, 2, "Go Gators! @1 @3"}
    GenServer.call userEngine, {:postTweet, 3, "Go Gators! @3 #great #awesome"}
    
    GenServer.call userEngine, {:test, 1}
    GenServer.call userEngine, {:test, 2}    
    GenServer.call userEngine, {:test, 3}
    
   # IO.inspect(GenServer.call writer, {:writeTweet, "test"})
   #{:ok, writer} = Writer.start_link(0)
   #IO.inspect writer 
   #GenServer.call writer, {:writeTweet, "test2sdfdjfksdjfj"}    
    
    #IO.inspect(GenServer.call writer, {:findTweet, 2})

    IO.inspect(:ets.lookup(:tweetsTable, 2))
    
  end  
end
