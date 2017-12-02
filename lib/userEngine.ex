defmodule UserEngine do 
    use GenServer
    
    # userList - list containing all userIds
    #fMap - hashmap {userId, [followers]}
    #tMap - hashMap {userId, [tweetIds]}
    def start_link(userList, fMap, tMap) do
        {:ok, writer} = WriterEngine.start_link(0)
        :global.register_name(:writerEngine, writer)
        :global.sync()
        
        hashtagEngine = :global.whereis_name(:hashtagEngine)
        mentionsEngine = :global.whereis_name(:mentionsEngine) 
        actors = spawn_actors(1, 10, [])  
        GenServer.start_link(__MODULE__, [userList, fMap, tMap, writer, hashtagEngine, mentionsEngine, actors])              
    end

    #registerUser
    def handle_call({:register, userId}, _from, [userList, fMap, tMap, writer, hashtagEngine, mentionsEngine, actors]) do
        userList = [userId | userList]
        fMap = Map.put(fMap, userId, []) 
        tMap = Map.put(tMap, userId, [])
        {:reply, :done, [userList, fMap, tMap, writer, hashtagEngine, mentionsEngine, actors]}
    end 

    #addFollowers
    def handle_cast({:subscribe, userId, followerList}, [userList, fMap, tMap, writer, hashtagEngine, mentionsEngine, actors]) do 
        Enum.each actors, fn actor -> 
            GenServer.cast actor, {:subscribe, userId, followerList} 
        end 
        {:noreply, [userList, fMap, tMap, writer, hashtagEngine, mentionsEngine, actors]}
    end

    #postTweet 
    def handle_cast({:postTweet, userId, tweet}, [userList, fMap, tMap, writer, hashtagEngine, mentionsEngine, actors]) do 
        actor = Enum.random actors
        GenServer.call actor, {:processTweet, userId, tweet}    
        {:noreply, :ok, [userList, fMap, tMap, writer, hashtagEngine, mentionsEngine, actors]}
    end

    #postTweet 
    def handle_call({:postTweet, userId, tweet}, _from, [userList, fMap, tMap, writer, hashtagEngine, mentionsEngine, actors]) do 
        actor = Enum.random actors
        GenServer.call actor, {:processTweet, userId, tweet}    
        {:reply, :ok, [userList, fMap, tMap, writer, hashtagEngine, mentionsEngine, actors]}
    end

    #postTweet 
    def handle_call({:reTweet, userId, tweetId}, _from, [userList, fMap, tMap, writer, hashtagEngine, mentionsEngine, actors]) do 
        actor = Enum.random actors
        GenServer.call actor, {:processreTweet, userId, tweetId}    
        {:reply, :ok, [userList, fMap, tMap, writer, hashtagEngine, mentionsEngine, actors]}
    end

    #testMethod
    def handle_call({:test, userId}, _from, [userList, fMap, tMap, writer, hashtagEngine, mentionsEngine, actors]) do 
        {:ok, tList} = Map.fetch(tMap, userId)
        IO.puts "tweets for user" <> inspect(userId) <> " " <> inspect(tList)
        {:reply, :ok, [userList, fMap, tMap, writer, hashtagEngine, mentionsEngine, actors]}
    end

    def spawn_actors(numActors, maxActors, actorList) do 
        if numActors == maxActors do
            actorList
        else
            {:ok, pidActor} = UserActor.start_link(%{}, %{})
            :global.register_name("actor" <> Integer.to_string(numActors), pidActor)            
            actorList = [pidActor | actorList]
            spawn_actors(numActors + 1, maxActors, actorList)
        end
    end
end 

    