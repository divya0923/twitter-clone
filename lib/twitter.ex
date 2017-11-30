defmodule Twitter do
  def main(args) do
    process(args)
  end

  def process([]) do
    {:ok, client1} = Client.start_link() 
    {:ok, client2} = Client.start_link()
    
    {:ok, hEngine} = HashtagEngine.start_link(%{})
    {:ok, mEngine} = MentionsEngine.start_link(%{})       
  
    :global.register_name(:hashtagEngine, hEngine)
    :global.register_name(:mentionsEngine, mEngine)
    :global.sync()

    {:ok, userEngine} = UserEngine.start_link([], %{}, %{})

    GenServer.cast userEngine, {:register, 1}
    GenServer.cast userEngine, {:register, 2}  
    GenServer.cast userEngine, {:register, 3}        
    
    GenServer.cast userEngine, {:subscribe, 1, [2,3]}
    GenServer.cast userEngine, {:subscribe, 2, [3]} 
    GenServer.cast userEngine, {:subscribe, 3, [1]} 
    
    GenServer.call userEngine, {:postTweet, 1, "Hello Gators! #gogators #gators #gatorsaregreat #great"}
    GenServer.call userEngine, {:postTweet, 1, "Go Gators! @2"}
    GenServer.call userEngine, {:postTweet, 2, "Go Gators! @1 @3"}
    GenServer.call userEngine, {:postTweet, 3, "Go Gators! @3 #great #awesome"}
    
    GenServer.call userEngine, {:test, 1}
    GenServer.call userEngine, {:test, 2}    
    GenServer.call userEngine, {:test, 3}

    {:ok, tweetList} = GenServer.call hEngine, {:getTweets, "#great"}
    IO.puts "retrieved tweet list" <> inspect(tweetList)
      
    {:ok, tweetList1} = GenServer.call mEngine, {:getTweets, "3"}
    IO.puts "retrieved tweet list" <> inspect(tweetList1)

  end  
end
