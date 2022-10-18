# Requires a Moralis API key.
# Writes out lists of owners of each token of each contract listed in the `CONTRACTS` array.
# Doesn't work on OpenSea contracts.

require 'net/http'
require 'uri'
require 'json'

MORALIS_API_KEY = 'HOkTTk4jVwpApTTma8y6IuyJRYq9o68DXeIT1ZLct4X0GXegQKHHBmmXutOZ37LT'

# These are the contracts to you want to download.
# Note that this WILL NOT work for OpenSea contracts, only contracts that are custom to the given project.
# 'Name' is used for your sanity and for generating the CSVs.

CONTRACTS = [
  {name: 'Turf', address: '0x55d89273143DE3dE00822c9271DbCBD9B44B44C6'}
]

# Given a contract address an a page (based on Morali's pagination logic), return a batch of holder info.
def fetchHolders(contractAddress, page, cursor = nil)
  url = "https://deep-index.moralis.io/api/v2/nft/#{contractAddress}/owners?chain=eth&format=decimal"
  owners = []

  if cursor
    url = url + '&cursor=' + cursor
  end

  uri = URI.parse(url)

  request = Net::HTTP::Get.new(uri)
  request['X-API-Key'] = MORALIS_API_KEY
  req_options = {
    use_ssl: uri.scheme == "https",
  }
  response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
    http.request(request)
  end

  data = JSON.parse(response.body)
  return {cursor: data['cursor'], total: data['total'], owners: data['result'].map{|r| r['owner_of']}}
end

cursor = nil
CONTRACTS.each do |c|
  puts c[:name]
  page = 0
  owners = []
  keepGoing = true
  while true do
    results = fetchHolders(c[:address], page, cursor)
    cursor = results[:cursor]
    owners.concat(results[:owners])
    if results[:total] <= owners.length
      break
    end
    puts "Got #{owners.length} of #{results[:total]} ..."
    page = page + 1
    sleep(1) # Be polite
  end
  File.write("#{c[:name].downcase.gsub(' ', '-')}.csv", owners.join("\n"))
end