defmodule MentionsEngine do 
    use GenServer

    def start_link(mMap) do
        GenServer.start_link(__MODULE__, [mMap, 0])                              
    end 

    def handle_cast({:addMentions, userList, tweetId}, [mMap, lastRecord]) do 
        #sIO.puts "addMentions" <> inspect(userList) <> inspect(tweetId)
        mMap = Enum.reduce userList, mMap, fn(user, mMap) -> 
            {id, mMap} = Map.get_and_update(mMap, user, 
                 fn uList -> 
                    if uList == nil do 
                        {user, [tweetId]}                   
                    else
                        {user, uList ++ [tweetId]}
                    end
                 end
                 )       
            mMap
        end
        #IO.puts "mentionsMap" <> inspect(mMap)
        {:noreply, [mMap, (lastRecord+1)]}   
    end

    """
    def handle_call({:getTweets, mention}, _from, [mMap, lastRecord]) do
        tweetList = []
        #mention = "@" <> mention
        if Map.fetch(mMap, mention) == :error do
            IO.puts "tweets list empty"
            mention = :ok               
        else 
            {:ok, list} = Map.fetch(mMap, mention)           
            tweetList = Enum.reduce list, tweetList, fn(id, tweetList) -> 
                [{id, text, user}] = :ets.lookup(:tweetsTable, id)
                tweetList = [Integer.to_string(user) <> " : " <> text] ++ tweetList
                tweetList
            end 
        end
        IO.puts "mentions sending: " <> inspect(tweetList)
        {:reply, {mention, tweetList}, [mMap, (lastRecord+1)]} 
    end
    """
    def handle_cast({:getTweets, mention}, [mMap, lastRecord]) do
        tweetList = []
        #mention = "@" <> mention
        if Map.fetch(mMap, mention) == :error do
            #IO.puts "tweets list empty"
            mention = :ok               
        else 
            {:ok, list} = Map.fetch(mMap, mention)           
            tweetList = Enum.reduce list, tweetList, fn(id, tweetList) -> 
                [{id, text, user}] = :ets.lookup(:tweetsTable, id)
                #tweetList = [Integer.to_string(user) <> " : " <> text] ++ tweetList
                tweetList = [text] ++ tweetList
                tweetList
            end 
            pidClient = :global.whereis_name(mention)
            #IO.puts "msearch eng" <> inspect(mention) <> " " <> inspect(pidClient)
            IO.puts "User " <> inspect(mention) <> " searched for his mentions"
            if pidClient != :undefined do            
                GenServer.cast pidClient, {:recievemSearch, tweetList, mention}
            end 
        end
        
        #IO.puts "mentions sending: " <> inspect(tweetList)
        {:noreply, [mMap, (lastRecord+1)]} 
    end

    def handle_info(msg, [mMap, lastRecord]) do 
        {:ok, file} = File.open("data.log", [:append]) 
        uEngStat = GenServer.cast :global.whereis_name(:userEngine), :getStat
        hEngStat = GenServer.cast :global.whereis_name(:hashtagEngine), :getStat
        IO.binwrite(file, " Log: " <> Integer.to_string(lastRecord+uEngStat+hEngStat))   
        Process.send_after self(), :record, 10000    
        {:noreply, [mMap, 0]} 
    end 
end    