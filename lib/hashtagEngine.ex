defmodule HashtagEngine do 
    use GenServer

    def start_link(hMap) do
        GenServer.start_link(__MODULE__, [hMap])                      
    end 

    def handle_cast({:addTags, tagList, tweetId}, [hMap]) do 
        IO.puts "tags in hashTagEngine " <> inspect(tagList) <> " tweetId " <> inspect(tweetId) 
        hMap = Enum.reduce tagList, hMap, fn(tag, hMap) -> 
            {id, hMap} = Map.get_and_update(hMap, tag, 
                 fn tList -> 
                    if tList == nil do 
                        {tag, [tweetId]}                   
                    else
                        {tag, tList ++ [tweetId]}
                    end
                 end
                 )       
            hMap
        end
        IO.puts "tags map" <> inspect(hMap)
        {:noreply, [hMap]}        
    end

    def handle_call({:getTweets, hashTag}, _from, [hMap]) do
        tweetList = []
        if Map.fetch(hMap, hashTag) == :error do
            IO.puts "tweets list empty"                        
        else 
            {:ok, list} = Map.fetch(hMap, hashTag)
            IO.puts "tweet list" <> inspect(list) 
           
            tweetList = Enum.reduce list, tweetList, fn(id, tweetList) -> 
                [{id, text, user}] = :ets.lookup(:tweetsTable, id)
                IO.puts "tweet" <> inspect(text)
                tweetList = [text] ++ tweetList
                tweetList
            end 
        end
        {:reply, {:ok, tweetList}, [hMap]}             
    end 
end    