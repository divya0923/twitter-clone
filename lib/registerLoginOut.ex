defmodule RCDEngine do 
    use GenServer

    def start_link(userEngine) do
        GenServer.start_link(__MODULE__, [userEngine])              
    end

    def handle_call({:login, userId, userPid}, _from, [userEngine]) do
        IO.puts "login user:" <> inspect(userId)
        #initialFeed = GenServer.call userEngine, {:test, userId}
        initialFeed = getFeed(userId, 1, [])
        IO.puts "initial feed: " <> inspect(initialFeed)
        GenServer.cast userPid, {:recieveTweet, initialFeed}
        :global.register_name(userId, userPid)
        :global.sync()
        {:reply, :ok, [userEngine]}
    end 

    def handle_call({:logout, userId}, _from, [userEngine]) do
        :global.unregister_name(userId)
        :global.sync()
        {:reply, :ok, [userEngine]}
    end

    def getFeed(userId, count, itList) do
        if count == 11 do 
            itList
        else
            tempList = GenServer.call :global.whereis_name("actor" <> Integer.to_string(count)), {:getTweets, userId}
            tempList = Enum.reduce tempList, itList, fn(tweet, itList) -> 
                {id, ts, rt} = tweet 
                [{id, text, user}] = :ets.lookup(:tweetsTable, id)
                if rt == true do 
                    text = "ReTweet- " <> Integer.to_string(user) <> " : " <> text 
                else 
                    text = Integer.to_string(user) <> " : " <> text
                end                                  
                itList = [{ts, id, text}] ++ itList
                itList
            end 
        end
        
    end 
end