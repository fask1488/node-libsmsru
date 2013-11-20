'use strict'

# library
sms = require './lib/libsmsru'

# API ID from sms.ru. INSERT YOUR!
api_id = '00000000-0000-0000-0000-000000000000'

# authorization data
# You can use api_id like in the following code or simply login password like:
# sms.auth 'login', 'password'
#
sms.auth api_id

# send SMS
# '79150000000'          - destination number
# 'Пример SMS-сообщения' - text of SMS message
# 'xinit.ru'             - sender. Should be created on sms.ru.
#
sms.send '79150000000', 'Пример SMS-сообщения', { from: 'xinit.ru'}, (err, answer) ->
    # when error is null then SMS has been successfully send. Otherwise some
    # error occured and you can get `err.code` and `err.message`
    console.log 'Error:', err

    # If err is null then answer has the following format:
    # {
    #     status: 100, //100 means success. Other statuses you can see on sms.ru
    #     smsId : [],  //array of sent SMS ID-s. You need it only if you want to
    #                  //look their status later, but it's completely optional'
    #     balance: '100.75' //balance of your account, RUB
    # }
    console.log 'Answer:', answer

    # check status every second until SMS delivered
    if not err?
        int = setInterval(
            ->
                # get SMS status.
                # answer.smsId[0] - is ID of sent SMS message
                # ans is object {
                #     status : '103', //status code from sms.ru. If 103 then
                #                     //SMS successfully delivered. If 102 then
                #                     //message is delivering. If not 1xx then
                #                     //error occured and err will not be null
                #     message: '' //human readable message from sms.ru
                # }
                # err will be null only if SMS either delivering or delivered.
                # If for some reason SMS can't be delivered at all then err will
                # not be null and you can read `err.code` and `err.message`
                sms.status answer.smsId[0], (err, ans) ->
                    console.log err, ans

                    # delivered
                    if ans.status is '103'
                        clearInterval int
                        console.log 'Delivered'

            , 1000
        )
