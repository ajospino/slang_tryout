require 'time'
require 'http'
require 'dotenv'
Dotenv.load

class APIRequest
    @@address = ENV['ADDRESS']
    @@host =  ENV['HOST']
    @@rapidKey = ENV['RAPID_API_KEY']
    @@secretKey =  ENV['API_KEY']
    def main()
        response = getRequest()
        parseJson(response)
        #dataStructure = parseJson(response)
        #postRequest(dataStructure)
    end

    def getRequest()
        response = HTTP.headers("X-RapidAPI-Key"=>@@rapidKey, "X-RapidAPI-Host"=>@@host).get(@@address)
        puts response.code
        return response.parse
    end

    def parseJson(response)
        result = {"user_sessions":{}}
        actvities = {"actvities":[  
                                    {
                                        "id": 198891,
                                        "user_id": "emr5zqid",
                                        "answered_at": "2021-09-13T02:38:34.117-04:00",
                                        "first_seen_at": "2021-09-13T02:38:16.117-04:00"
                                    },
                                    {
                                        "id": 43990,
                                        "user_id": "emr5zqid",
                                        "answered_at": "2021-09-13T02:42:07.117-04:00",
                                        "first_seen_at": "2021-09-13T02:41:51.117-04:00"
                                    },
                                    {
                                        "id": 37191,
                                        "user_id": "emr5zqid",
                                        "answered_at": "2021-09-14T00:31:36.117-04:00",
                                        "first_seen_at": "2021-09-14T00:31:25.117-04:00"
                                    }
                                ]
                    }
        sessions = result["user_sessions"]
        previousUser = " "
        previousTime = 0
        count = -1
        actvities.each do |a| 
            regisUser = a.value(:user_id)
            activityId = a.value(:id)
            activityStart = a.value(:first_seen_at)
            activityEnd = a.value(:answered_at)

            unless sessions.has_key? regisUser
                sessions.store(regisUser , [
                                        {
                                        "ended_at": 0,
                                        "started_at": activityStart,
                                        "activity_ids": [activityId] ,
                                        "duration_seconds": 0 
                                        }
                                        ]
                                )
                previousTime = activityEnd
                previousUser = regisUser
                count+=1
            else
                if previousTime != 0
                    timeDifference = dateCalculator(previousTime, activityStart)
                    if timeDifference<=300 && regisUser.eql?(previousUser)
                        currentDuration = sessions.value(regisUser)[count].value("duration_seconds") + timeDifference
                        sessions.value(regisUser)[count].store("ended_at", activityEnd)
                        sessions.value(regisUser)[count].store("duration_seconds", currentDuration) 
                        sessions.value(regisUser)[count].value("activity_ids").push(activityId)
                        previousTime = activityEnd
                    elsif timeDifference>300 && regisUser.eql?(previousUser)
                        sessions.value(regisUser).push(
                                                        {
                                                        "ended_at": 0,
                                                        "started_at": activityStart,
                                                        "activity_ids": [activityId] ,
                                                        "duration_seconds": 0 
                                                        }
                                                      )
                        previousTime = activityEnd
                        count+=1
                    else
                        if !(previousUser.eql?(regisUser)) && sessions.has_key?(regisUser)
                            sessions.store(regisUser , [
                                                        {
                                                        "ended_at": 0,
                                                        "started_at": activityStart,
                                                        "activity_ids": [activityId] ,
                                                        "duration_seconds": 0 
                                                        }
                                                       ]
                                          )
                            previousTime = activityEnd
                            previousUser = regisUser
                            count=0  
                        end  
                    end
                end
                if !(previousUser.eql?(regisUser))
                    sessions.store(regisUser , [
                                                {
                                                "ended_at": 0,
                                                "started_at": activityStart,
                                                "activity_ids": [activityId] ,
                                                "duration_seconds": 0 
                                                }
                                                ]
                                    )
                    previousTime = activityEnd
                    previousUser = regisUser
                    count=0   
                end 
            end
        end

    end

    def dateCalculator(date1, date2)
        time1 = Time.parse(date1)
        time2 = Time.parse(date2)
        result = time1 - time2
        return result
    end


    def postRequest(user_sessions)
        response = HTTP.headers("X-RapidAPI-Key"=>@@rapidKey, "X-RapidAPI-Host"=>@@host).post(@@address, :params =>{"user_sessions"=>user_sessions})
        puts response.code
    end
end

a = APIRequest.new() 
a.main()