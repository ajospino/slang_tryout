require 'time'
require 'http'
require 'dotenv'
Dotenv.load

class APIRequest
    @@address = ENV['ADDRESS']
    @@secretKey =  ENV['API_KEY']
    def main()
        response = getRequest()
        parseJson(response)
        dataStructure = parseJson(response)
        #postRequest(dataStructure)
    end

    def getRequest()
        response = HTTP.auth(@@secretKey).get(@@address)
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
                                        "id": 251953,
                                        "user_id": "3pyg3scx",
                                        "answered_at": "2021-09-10T19:22:40.799-04:00",
                                        "first_seen_at": "2021-09-10T19:22:23.799-04:00"
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
        response.sort_by!{|value| value[:first_seen_at]}
        sessions = result[:user_sessions]
        previousUser = " "
        previousTime = 0
        count = -1
        i = 1
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
                puts "Usuario nuevo, primer caso."
                puts sessions
                if !(previousUser.eql?(regisUser)) && !(previousUser.eql?(" "))
                    if sessions[previousUser.to_sym][0][:duration_seconds] == 0 && sessions[previousUser.to_sym][0][:ended_at] == 0
                        currentDuration = dateCalculator(activityStart,activityEnd)
                        sessions[previousUser.to_sym][count].store(:ended_at, activityEnd)
                        sessions[previousUser.to_sym][count].store(:duration_seconds, currentDuration)
                        count=-1
                        puts "Usuario antiguo y distinto, cerrado por no tener más actividades Primer caso"
                    end
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
                end 
                previousTime = activityEnd
                previousUser = regisUser
                count+=1
            else
                if previousTime != 0
                    timeDifference = dateCalculator(previousTime, activityStart)
                    puts timeDifference
                    if timeDifference<=300 && regisUser.eql?(previousUser)
                        puts sessions[regisUser.to_sym], count
                        currentDuration = sessions[regisUser.to_sym][count][:duration_seconds] + timeDifference
                        sessions[regisUser.to_sym][count].store(:ended_at, activityEnd)
                        sessions[regisUser.to_sym][count].store(:duration_seconds, currentDuration) 
                        sessions[regisUser.to_sym][count][:activity_ids].push(activityId)
                        previousTime = activityEnd
                        puts "Mismo usuario, misma sesión"
                    elsif timeDifference>300 && regisUser.eql?(previousUser)
                        if i == response.length
                            currentDuration = dateCalculator(activityStart,activityEnd)
                            sessions[regisUser.to_sym].push(
                                                            {
                                                            "ended_at": activityEnd,
                                                            "started_at": activityStart,
                                                            "activity_ids": [activityId] ,
                                                            "duration_seconds": currentDuration
                                                            }
                                                            )
                            puts "Sesión distina mismo usuario y ultima actividad de la lista"
                            previousTime = activityEnd
                            count+=1
                        else
                            sessions[regisUser.to_sym].push(
                                                            {
                                                            "ended_at": 0,
                                                            "started_at": activityStart,
                                                            "activity_ids": [activityId] ,
                                                            "duration_seconds": 0 
                                                            }
                                                            )
                            puts "Sesión distina mismo usuario y una actividad X"
                            previousTime = activityEnd
                            count+=1
                        end
                    else
                        if !(previousUser.eql?(regisUser)) && !(sessions.has_key?(regisUser.to_sym))
                            sessions.store(regisUser.to_sym , [
                                                        {
                                                        "ended_at": 0,
                                                        "started_at": activityStart,
                                                        "activity_ids": [activityId] ,
                                                        "duration_seconds": 0 
                                                        }
                                                    ]
                                        )
                            puts "Sesión distina, usuario nuevo y distinto"
                            previousTime = activityEnd
                            previousUser = regisUser
                            count=-1  
                        end  
                    end
                end
                if !(previousUser.eql?(regisUser))
                    if sessions[previousUser.to_sym][count][:duration_seconds] == 0 && sessions[previousUser.to_sym][count][:ended_at] == 0
                        currentDuration = dateCalculator(activityStart,activityEnd)
                        sessions[previousUser.to_sym][count].store(:ended_at, activityEnd)
                        sessions[previousUser.to_sym][count].store(:duration_seconds, currentDuration)
                        puts "Usuario antiguo y distinto, cerrado por no tener más actividades."
                    end
                    sessions.store(regisUser.to_sym , [
                                                {
                                                "ended_at": 0,
                                                "started_at": activityStart,
                                                "activity_ids": [activityId] ,
                                                "duration_seconds": 0 
                                                }
                                                ]
                                    )
                    puts "Usuario nuevo completamente"
                    previousTime = activityEnd
                    previousUser = regisUser
                    count=-1   
                end 
            end
            i +=1
        end 
        puts result
        return result
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