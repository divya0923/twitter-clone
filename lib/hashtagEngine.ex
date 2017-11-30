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
end    