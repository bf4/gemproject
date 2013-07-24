file = File.read('./license_results.rtf'); nil
Result = Struct.new(:state, :link, :number, :msg) do
  def message
    msg[/License.*gemspec/]
  end
end
results = file.scan(/^.*(open|closed)\s*$[^"$]+"(http[^"]+)[^$]+?$[^#]+?(#\d+?)([^$]+?)$/).map do |result|
  Result.new(*result)
end.sort_by {|result| result.link }
File.open('./license_results.csv', 'w+') do |file|
  file.write("link,state\n")
  results.each do |result|
    file.write([result.link,result.state].join(',') + "\n")
  end
end
