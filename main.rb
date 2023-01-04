require 'http'
require 'dotenv'
Dotenv.load

class APIRequest
    def main()
        response = getRequest()
        dataStructure = parseJson(response)
        postRequest(dataStructure)
    end

    def getRequest()
        address = ENV['ADDRESS']
        host =  ENV['HOST']
        rapidKey = ENV['RAPID_API_KEY']
        #secretKey =  ENV['API_KEY']
        response = HTTP.headers("X-RapidAPI-Key"=>rapidKey, "X-RapidAPI-Host"=>host).get(address, :params =>{"health"=>"5"})
        puts response.code
        return response.parse
    end

    def parseJson(response)
        #actvities = []
        response.each do |key,value|
            puts " Key: #{key}, Value: #{value}"
        end
    end

    def postRequest()
        
        
    end
end

A = new APIRequest() 
A.main()