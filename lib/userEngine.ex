defmodule UserEngine do 
    use GenServer
    
    # userList - list containing all userIds
    #fMap - hashmap {userId, [followers]}
    #tMap - hashMap {userId, [tweetIds]}
    def start_link(userList, fMap, tMap) do
        {:ok, writer} = WriterEngine.start_link(0)
        {:ok, hashtagEngine} = HashtagEngine.start_link(%{})
        {:ok, mentionsEngine} = MentionsEngine.start_link(%{})        
        IO.inspect writer 
        GenServer.start_link(__MODULE__, [userList, fMap, tMap, writer, hashtagEngine, mentionsEngine])              
    end
      
    #registerUser
    def handle_cast({:register, userId}, [userList, fMap, tMap, writer, hashtagEngine, mentionsEngine]) do
        IO.inspect "register"
        userList = [userId | userList]
        fMap = Map.put(fMap, userId, [])
        tMap = Map.put(tMap, userId, [])
        {:noreply, [userList, fMap, tMap, writer, hashtagEngine, mentionsEngine]}
    end 

    #addFollowers
    def handle_cast({:subscribe, userId, followerList}, [userList, fMap, tMap, writer, hashtagEngine, mentionsEngine]) do 
        IO.inspect "subscribe"
        {id, fMap} = Map.get_and_update(fMap, userId, 
            fn fList -> 
                {userId, followerList ++ fList}
            end
            )
        {:ok, iList} = Map.fetch(fMap, userId)
        IO.puts "followersList" <> inspect(userId) <> inspect(iList)
        {:noreply, [userList, fMap, tMap, writer, hashtagEngine, mentionsEngine]}
    end

    #postTweet 
    def handle_call({:postTweet, userId, tweet}, _from, [userList, fMap, tMap, writer, hashtagEngine, mentionsEngine]) do 
        IO.inspect "postTweet"
        {:ok, tweetId} = GenServer.call writer, {:writeTweet, tweet, userId}
        IO.puts "tweetId of the recently inserted tweet " <> inspect(tweetId)

        #update tMap of followers
        {:ok, fList} = Map.fetch(fMap, userId)
        tMap = Enum.reduce fList, tMap, fn(follower, tMap) -> 
            IO.puts "follower " <> inspect(follower) 
            {id, tMap} = Map.get_and_update(tMap, follower, 
                 fn tList -> 
                     {follower, tList ++ [tweetId]}
                 end
                 )       
            tMap
        end

        #update hashtag map if any
        IO.puts "hashtags"
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
        IO.puts "mentions"
        mentionsList = String.split(tweet, ~r{\s})
        mList = []
        mList = Enum.reduce mentionsList, mList, fn(mention, mList) ->
            if String.starts_with? mention, "@" do 
                mList = [mention] ++ mList
            end 
            mList 
        end 
        if length(mList) > 0 do 
            GenServer.cast mentionsEngine, {:addMentions, mList, tweetId}
        end 

        {:reply, :ok, [userList, fMap, tMap, writer, hashtagEngine, mentionsEngine]}
    end

    #testMethod
    def handle_call({:test, userId}, _from, [userList, fMap, tMap, writer, hashtagEngine, mentionsEngine]) do 
        {:ok, tList} = Map.fetch(tMap, userId)
        IO.puts "tweets for user" <> inspect(userId) <> " " <> inspect(tList)
        {:reply, :ok, [userList, fMap, tMap, writer, hashtagEngine, mentionsEngine]}
    end
end 

    