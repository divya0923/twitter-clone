defmodule WriterEngine do
    use GenServer

    def start_link(tweetCount) do
        GenServer.start_link(__MODULE__, [tweetCount])
    end

    def init([tweetCount]) do
        {:ok, [tweetCount, :ets.new(:tweetsTable, [:named_table, :protected]), 0]}
    end

    # insert in tweetsTable[tweetId, tweet, userId]
    def handle_call({:writeTweet, tweet, userId}, _from, [tweetCount, :tweetsTable, lastRecord]) do 
        tweetCount = tweetCount + 1; 
        insertOk = :ets.insert_new(:tweetsTable, {tweetCount, tweet, userId})        
        if insertOk do     
            {:reply, {:ok, tweetCount}, [tweetCount, :tweetsTable, lastRecord]} 
        else
            {:reply, :error, [tweetCount, :tweetsTable, lastRecord]}
        end
    end 

    def handle_call({:findTweet, tweetId}, _from, [tweetCount, :tweetsTable, lastRecord]) do
        case :ets.lookup(:tweetsTable, :tweetId) do
          [{^tweetId, tweet}] -> {:ok, tweet}
          [] -> {:error}
        end
        {:reply, :ok, [tweetCount, :tweetsTable, lastRecord]}
    end
end     