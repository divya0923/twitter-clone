defmodule Twitter do
    def main(args) do
    process(args)
    end
    
    def process([]) do
    IO.puts "No arguments given"
    end
    
    def process(args) do
    if length(args) != 1 do
    IO.puts "Run as ./twitter <server-ip-address>"
    else
    _ = System.cmd("epmd", ['-daemon'])
    #Node.start(String.to_atom("server@" <> Enum.at(args, 0)))
    Node.start(String.to_atom("server@" <> "127.0.0.1"))
    Node.set_cookie(:dsiuvryaaj)
    #{:ok, client1} = Client.start_link() 
    #{:ok, client2} = Client.start_link()
    {:ok, hEngine} = HashtagEngine.start_link(%{})
    {:ok, mEngine} = MentionsEngine.start_link(%{})
    :global.register_name(:hashtagEngine, hEngine)
    :global.register_name(:mentionsEngine, mEngine)
    :global.sync()
    
    {:ok, userEngine} = UserEngine.start_link([], %{}, %{})
    {:ok, rcdEngine} = RCDEngine.start_link(userEngine)
    
    :global.register_name(:userEngine, userEngine)
    IO.puts "uEng" <> inspect(userEngine)
    :global.register_name(:rcdEngine, rcdEngine)
    :global.sync()
    loop()
    end 
  end 

    def loop() do 
      loop()
    end
  end
  
    """
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
    GenServer.call userEngine, {:postTweet, 1, "Go Gators! #gators @2"} #1
    GenServer.call userEngine, {:postTweet, 2, "Go Gators!"} #2
    GenServer.call userEngine, {:postTweet, 3, "Go Gators! @3 #great #awesome"}
    
    #GenServer.call userEngine, {:test, 1}
    #GenServer.call userEngine, {:test, 2}    
    #GenServer.call userEngine, {:test, 3}

    {:ok, tweetList} = GenServer.call hEngine, {:getTweets, "#gators"}
    IO.puts "retrieved tweet list" <> inspect(tweetList)
      
    {:ok, tweetList1} = GenServer.call mEngine, {:getTweets, 3}
    IO.puts "retrieved tweet list" <> inspect(tweetList1) 

  end  
  """


