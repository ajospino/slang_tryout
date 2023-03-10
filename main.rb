require 'time'
require 'http'
require 'dotenv'
Dotenv.load

class APIRequest
    @@address = ENV['ADDRESS']
    @@secretKey =  ENV['API_KEY']
    @@postAddress = ENV['ADDRESS_POST']
    def main()
        response = getRequest()
        dataStructure = parseJson(response)
        postRequest(dataStructure)
    end

    def getRequest()
        response = HTTP.auth(@@secretKey).get(@@address)
        puts response.code
        return response.parse
    end

    def parseJson(response)
        result = {"user_sessions":{}}
        response = response["activities"]
        response.sort_by!{|value| value["first_seen_at"]}
        sessions = result[:user_sessions]
        previousUser = " "
        previousTime = 0
        count = 0
        i = 1
        response.each do |a|
            regisUser = a["user_id"]
            activityId = a["id"]
            activityStart = a["first_seen_at"]
            activityEnd = a["answered_at"]
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
                if !(previousUser.eql?(regisUser)) && !(previousUser.eql?(" "))
                    if sessions[previousUser][0][:duration_seconds] == 0 && sessions[previousUser][0][:ended_at] == 0
                        currentDuration = dateCalculator(activityStart,activityEnd)
                        sessions[previousUser][count].store(:ended_at, activityEnd)
                        sessions[previousUser][count].store(:duration_seconds, currentDuration)
                        count=0
                    end
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
                end 
                previousTime = activityEnd
                previousUser = regisUser
                count = 0
            else
                if previousTime != 0
                    timeDifference = dateCalculator(previousTime, activityStart)
                    if timeDifference<=300 && regisUser.eql?(previousUser)
                        currentDuration = sessions[regisUser][count][:duration_seconds] + timeDifference
                        sessions[regisUser][count].store(:ended_at, activityEnd)
                        sessions[regisUser][count].store(:duration_seconds, currentDuration) 
                        sessions[regisUser][count][:activity_ids].push(activityId)
                        previousTime = activityEnd
                    elsif timeDifference>300 && regisUser.eql?(previousUser)
                        if i == response.length
                            currentDuration = dateCalculator(activityStart,activityEnd)
                            sessions[regisUser].push(
                                                            {
                                                            "ended_at": activityEnd,
                                                            "started_at": activityStart,
                                                            "activity_ids": [activityId] ,
                                                            "duration_seconds": currentDuration
                                                            }
                                                            )
                            previousTime = activityEnd
                            count+=1
                        else
                            sessions[regisUser].push(
                                                            {
                                                            "ended_at": 0,
                                                            "started_at": activityStart,
                                                            "activity_ids": [activityId] ,
                                                            "duration_seconds": 0 
                                                            }
                                                            )
                            previousTime = activityEnd
                            count+=1
                        end
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
                            count = 0  
                        end  
                    end
                end
                if !(previousUser.eql?(regisUser))
                    if sessions[previousUser][count][:duration_seconds] == 0 && sessions[previousUser][count][:ended_at] == 0
                        currentDuration = dateCalculator(activityStart,activityEnd)
                        sessions[previousUser][count].store(:ended_at, activityEnd)
                        sessions[previousUser][count].store(:duration_seconds, currentDuration)
                    end
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
            i +=1
        end 
        return result
    end

    def dateCalculator(date1, date2)
        time1 = Time.parse(date1)
        time2 = Time.parse(date2)
        result = (time1 - time2).abs
        return result
    end


    def postRequest(user_sessions)
        response = HTTP.auth(@@secretKey).post(@@postAddress, :json => user_sessions)
        puts response.code
    end
end

a = APIRequest.new() 
a.main()