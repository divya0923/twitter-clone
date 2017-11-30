defmodule MentionsEngine do 
    use GenServer

    def start_link(mMap) do
        GenServer.start_link(__MODULE__, [mMap])                              
    end 

    def handle_cast({:addMentions, userList, tweetId}, [mMap]) do 
        IO.puts "mentions " <> inspect(userList) <> " tweetId " <> inspect(tweetId) 
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
        IO.puts "mentions map" <> inspect(mMap)
        {:noreply, [mMap]}   
    end
end    