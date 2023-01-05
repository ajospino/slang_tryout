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

    def parseJson(r)
        result = {"user_sessions":{}}
        activities = {"activities":[  
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
        response = activities[:activities]
        sessions = result[:user_sessions]
        previousUser = " "
        previousTime = 0
        count = -1
        response.each do |a|
            regisUser = a[:user_id]
            activityId = a[:id]
            activityStart = a[:first_seen_at]
            activityEnd = a[:answered_at]
            unless sessions.has_key? regisUser.to_sym
                sessions.store(regisUser.to_sym , [
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
                        currentDuration = sessions[regisUser.to_sym][count][:duration_seconds] + timeDifference
                        sessions[regisUser.to_sym][count].store(:ended_at, activityEnd)
                        sessions[regisUser.to_sym][count].store(:duration_seconds, currentDuration) 
                        sessions[regisUser.to_sym][count][:activity_ids].push(activityId)
                        previousTime = activityEnd
                    elsif timeDifference>300 && regisUser.eql?(previousUser)
                        sessions[regisUser.to_sym].push(
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
                        if !(previousUser.eql?(regisUser)) && !(sessions.has_key?(regisUser))
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
            puts sessions
        end 
        puts result
    end

    def dateCalculator(date1, date2)
        time1 = Time.parse(date1)
        time2 = Time.parse(date2)
        result = (time1 - time2).abs
        return result
    end


    def postRequest(user_sessions)
        response = HTTP.headers("X-RapidAPI-Key"=>@@rapidKey, "X-RapidAPI-Host"=>@@host).post(@@address, :params =>{"user_sessions"=>user_sessions})
        puts response.code
    end
end

a = APIRequest.new() 
a.main()