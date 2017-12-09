defmodule RCDEngine do 
    use GenServer
    @numPoolActor 11
    def start_link(userEngine) do
        GenServer.start_link(__MODULE__, [userEngine])              
    end

    def handle_cast({:login, userId, userPid}, [userEngine]) do
        #IO.puts "login user:" <> inspect(userId)
        #initialFeed = GenServer.call userEngine, {:test, userId}
        #initialFeed = getFeed(userId, 1, [])
        :global.register_name(userId, userPid)
        :global.sync()
        getFeed1(userId, 1)
        #IO.puts "initial feed: " <> inspect(initialFeed)
        #GenServer.cast userPid, {:recieveTweet, initialFeed}
        IO.puts "Login user: " <> inspect(userId)
        
        {:noreply, [userEngine]}
    end 

    def handle_cast({:logout, userId}, [userEngine]) do
        IO.puts "Logout user: " <> inspect(userId) 
        :global.unregister_name(userId)
        :global.sync()
        {:noreply, [userEngine]}
    end

    def getFeed(userId, count, itList) do
        if count == @numPoolActor do 
            itList
        else
            #IO.puts "engineactor: " <> inspect(:global.whereis_name("actor" <> Integer.to_string(count))) <> " u: " <> inspect(count)
            tempList = GenServer.call :global.whereis_name("actor" <> Integer.to_string(count)), {:getTweets, userId}
            #IO.puts "got: " <> inspect(tempList)
            if length(tempList) != 0 do
                tempList = Enum.reduce tempList, itList, fn(tweet, itList) -> 
                    {id, ts, rt} = tweet 
                    [{tid, text, user}] = :ets.lookup(:tweetsTable, id)
                    if rt != 0 do 
                        text = Integer.to_string(rt) <> " ReTweeted- " <> Integer.to_string(user) <> " : " <> text 
                        #text = Integer.to_string(rt) <> " ReTweeted- " <> text 
                    else 
                        text = Integer.to_string(user) <> " : " <> text
                        #text = text
                    end                                  
                    itList = [{id, ts, text}] ++ itList
                end 
            end
            getFeed(userId, (count+1), itList)
        end
    end 

    def getFeed1(userId, count) do
        if count == @numPoolActor do 
            :ok
        else
            GenServer.cast :global.whereis_name("actor" <> Integer.to_string(count)), {:getTweets1, userId}
            getFeed1(userId, (count+1))
        end
    end
end