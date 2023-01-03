require 'http'
require 'dotenv'
Dotenv.load

def main()
    
end

def getRequest()
    address = ENV['ADDRESS']
    secretKey =  ENV['API_KEY']
    response = HTTP.get(address, :params =>{ :api_key => secretKey})
    puts response.parse
end