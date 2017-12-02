defmodule UserActor do
    use GenServer

    def start_link(fMap, tMap) do
        hashtagEngine = :global.whereis_name(:hashtagEngine)
        mentionsEngine = :global.whereis_name(:mentionsEngine) 
        writer = :global.whereis_name(:writerEngine)
        GenServer.start_link(__MODULE__, [fMap, tMap, writer, hashtagEngine, mentionsEngine])                      
    end

    def handle_cast({:register, userId}, [fMap, tMap, writer, hashtagEngine, mentionsEngine]) do
        fMap = Map.put(fMap, userId, []) 
        tMap = Map.put(tMap, userId, [])
        {:noreply, [fMap, tMap, writer, hashtagEngine, mentionsEngine]}
    end 

    #addFollowers
    def handle_cast({:subscribe, userId, followerList}, [fMap, tMap, writer, hashtagEngine, mentionsEngine]) do 
        {id, fMap} = Map.get_and_update(fMap, userId, 
            fn fList -> 
                if fList == nil do 
                    {userId, followerList}
                else
                    {userId, followerList ++ fList}
                end
            end
            )
        #IO.puts "followersList" <> inspect(userId) <> inspect(fMap) <> inspect(self())
        {:noreply, [fMap, tMap, writer, hashtagEngine, mentionsEngine]}
    end

    def handle_call({:processTweet, userId, tweet}, _from, [fMap, tMap, writer, hashtagEngine, mentionsEngine]) do      
        {:ok, tweetId} = GenServer.call writer, {:writeTweet, tweet, userId}

        #update hashtag map if any
        hashtagList = String.split(tweet, ~r{\s})
        tagList = []
        tagList = Enum.reduce hashtagList, tagList, fn(tag, tagList) ->
                if String.starts_with? tag, "#" do 
                    tagList = [tag] ++ tagList
                end 
            tagList 
        end 
        if length(tagList) > 0 do 
            GenServer.cast hashtagEngine, {:addTags, tagList, tweetId}
        end 

        #update mentions map if any
        mentionsList = String.split(tweet, ~r{\s})
        mList = []
        mList = Enum.reduce mentionsList, mList, fn(mention, mList) -> 
                if String.starts_with? mention, "@" do 
                    m = String.replace(mention, ~r/[@]/, "")                   
                    mList = [String.to_integer(m)] ++ mList
                end 
            mList 
        end 
        IO.puts "mentionsList" <> inspect(mList)        
        if length(mList) > 0 do 
            GenServer.cast mentionsEngine, {:addMentions, mList, tweetId}
        end

        #update tMap mentioned users
        #tMap = updateTMap(mList, tMap, userId, tweetId)
        {:ok, fList} = Map.fetch(fMap, userId) 
        fList = fList -- mList
       
        #update followers - mentions
        tMap = Enum.reduce fList, tMap, fn(follower, tMap) -> 
            {id, tMap} = Map.get_and_update(tMap, follower, 
                 fn tList -> 
                    sTweet = {tweetId, :os.system_time(:seconds), false}
                    pushTweet(follower, sTweet)                                            
                    if tList == nil do 
                        {follower, [sTweet]}
                    else
                        {follower, tList ++ [sTweet]}
                    end 
                 end
                 )      
            tMap
        end

        # update mentions
        tMap = Enum.reduce mList, tMap, fn(follower, tMap) -> 
            {id, tMap} = Map.get_and_update(tMap, follower, 
                 fn tList -> 
                    sTweet = {tweetId, :os.system_time(:seconds), false}  
                    pushTweet(follower, sTweet)                                            
                    if tList == nil do 
                        {follower, [sTweet]}
                    else
                        {follower, tList ++ [sTweet]}
                    end 
                 end
                 )      
            tMap
        end

        {:reply, :ok, [fMap, tMap, writer, hashtagEngine, mentionsEngine]}        
    end

    def handle_call({:processreTweet, userId, tweetId}, _from, [fMap, tMap, writer, hashtagEngine, mentionsEngine]) do      
        {:ok, fList} = Map.fetch(fMap, userId) 
        tMap = Enum.reduce fList, tMap, fn(follower, tMap) -> 
            {id, tMap} = Map.get_and_update(tMap, follower, 
                 fn tList -> 
                    sTweet = {tweetId, :os.system_time(:seconds), true}
                    if tList == nil do 
                        {follower, [sTweet]}
                    else
                        {follower, tList ++ [sTweet]}
                    end 
                 end
                 )      
            tMap
        end
    end

    #getTweets
    def handle_call({:getTweets, userId}, _from, [fMap, tMap, writer, hashtagEngine, mentionsEngine]) do 
        {:ok, tList} = Map.fetch(tMap, userId)
        {:reply, tList, [fMap, tMap, writer, hashtagEngine, mentionsEngine]}
    end

    def pushTweet(tweet, user) do 
        if :global.whereis_name(user) != :undefined do
            GenServer.call :global.whereis_name(user), {:recieveTweet, tweet}
        end
    end 
end
    