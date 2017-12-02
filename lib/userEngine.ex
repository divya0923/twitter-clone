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
        GenServer.start_link(__MODULE__, [userList, fMap, tMap, writer, hashtagEngine, mentionsEngine, actors, 0])              
    end

    #registerUser
    def handle_call({:register, userId}, _from, [userList, fMap, tMap, writer, hashtagEngine, mentionsEngine, actors, lastRecord]) do
        userList = [userId | userList]
        fMap = Map.put(fMap, userId, []) 
        tMap = Map.put(tMap, userId, [])
        Enum.each actors, fn actor -> 
            GenServer.cast actor, {:register, userId} 
        end 
        {:reply, :done, [userList, fMap, tMap, writer, hashtagEngine, mentionsEngine, actors, lastRecord]}
    end 

    #addFollowers
    def handle_cast({:subscribe, userId, followerList}, [userList, fMap, tMap, writer, hashtagEngine, mentionsEngine, actors, lastRecord]) do 
        Enum.each actors, fn actor -> 
            GenServer.cast actor, {:subscribe, userId, followerList} 
        end 
        {:noreply, [userList, fMap, tMap, writer, hashtagEngine, mentionsEngine, actors, lastRecord]}
    end

    #postTweet 
    def handle_cast({:postTweet, userId, tweet}, [userList, fMap, tMap, writer, hashtagEngine, mentionsEngine, actors, lastRecord]) do 
        actor = Enum.random actors
        GenServer.cast actor, {:processTweet, userId, tweet}    
        {:noreply, [userList, fMap, tMap, writer, hashtagEngine, mentionsEngine, actors, (lastRecord+1)]}
    end

    #reTweet
    def handle_cast({:reTweet, userId, tweetId}, [userList, fMap, tMap, writer, hashtagEngine, mentionsEngine, actors, lastRecord]) do 
        actor = Enum.random actors
        GenServer.cast actor, {:processreTweet, userId, tweetId}    
        {:noreply, [userList, fMap, tMap, writer, hashtagEngine, mentionsEngine, actors, (lastRecord+1)]}
    end

    #testMethod
    def handle_call({:test, userId}, _from, [userList, fMap, tMap, writer, hashtagEngine, mentionsEngine, actors, lastRecord]) do 
        {:ok, tList} = Map.fetch(tMap, userId)
        IO.puts "tweets for user" <> inspect(userId) <> " " <> inspect(tList)
        {:reply, :ok, [userList, fMap, tMap, writer, hashtagEngine, mentionsEngine, actors, lastRecord]}
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

    def handle_call(:getStat, _from, [userList, fMap, tMap, writer, hashtagEngine, mentionsEngine, actors, lastRecord]) do
        {:reply, lastRecord, [userList, fMap, tMap, writer, hashtagEngine, mentionsEngine, actors, 0]} 
    end
    def handle_info(msg, [userList, fMap, tMap, writer, hashtagEngine, mentionsEngine, actors, lastRecord]) do 
        {:ok, file} = File.open("data.log", [:append])   
        IO.binwrite(file, " Log: " <> Integer.to_string(lastRecord))   
        Process.send_after self(), :record, 10000    
        {:noreply, [userList, fMap, tMap, writer, hashtagEngine, mentionsEngine, actors, 0]} 
    end
end 

    