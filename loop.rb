@minutes = 60*2
loop {
  mem_usage =  `ps aux | grep ruby #{$0} | awk '{sum +=$4}; END {print sum}'`
  p "script memory usage #{mem_usage}"
  p "Beginning run #{Time.now}"
  system('./update_stats.sh')
  p "Ending Running #{Time.now}. Sleeping #{@minutes} minutes"
  sleep 60*@minutes
  p "Done sleeping at #{Time.now}"
}
