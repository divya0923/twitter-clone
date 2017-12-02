defmodule MentionsEngine do 
    use GenServer

    def start_link(mMap) do
        GenServer.start_link(__MODULE__, [mMap])                              
    end 

    def handle_cast({:addMentions, userList, tweetId}, [mMap]) do 
        IO.puts "addMentions" <> inspect(userList) <> inspect(tweetId)
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
        IO.puts "mentionsMap" <> inspect(mMap)
        {:noreply, [mMap]}   
    end

    def handle_call({:getTweets, mention}, _from, [mMap]) do
        tweetList = []
        #mention = "@" <> mention
        if Map.fetch(mMap, mention) == :error do
            IO.puts "tweets list empty"                        
        else 
            {:ok, list} = Map.fetch(mMap, mention)           
            tweetList = Enum.reduce list, tweetList, fn(id, tweetList) -> 
                [{id, text, user}] = :ets.lookup(:tweetsTable, id)
                tweetList = [Integer.to_string(user) <> " : " <> text] ++ tweetList
                tweetList
            end 
        end
        {:reply, {:ok, tweetList}, [mMap]}             
    end 
end    