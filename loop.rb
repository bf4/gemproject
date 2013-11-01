@minutes = 60*2
loop { p "Beginning run #{Time.now}"; system('./update_stats.sh'); p "Ending Running #{Time.now}. Sleeping #{@minutes} minutes"; sleep 60*@minutes; p "Done sleeping at #{Time.now}" }
