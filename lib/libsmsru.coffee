# Simple sms.ru API library. All you basicly need is here - sending SMS and
# checking delivering status of sent messages.
#
# Usage is as simple as it can be.
# Require library (in this example it located in ./lib/, but you can install it
# to your node_modules directory):
#
#     sms = require './lib/libsmsru'
#
# You need to authorise with your API ID:
#
#     sms.auth '00000000-0000-0000-0000-000000000000'
#
# or with your login and password:
#
#     sms.auth 'login', 'pa$$w0rd'
#
# Then just send SMS with text 'Пример SMS-сообщения' to number 79150000000 from
# sender xinit.ru:
#
#     sms.send '79150000000', 'Пример SMS-сообщения', { from: 'xinit.ru'}, onSend
#
# Note that in options object { from: 'xinit.ru'} you can use all parameters
# from sms.ru you want. Or you can just skip it and send SMS this way:
#
#     sms.send '79150000000', 'Пример SMS-сообщения', onSend
#
# This time SMS will be sent from default sender.
#
# onSend is Callback function with two parameters: (err, answer). If err is null
# then you are lucky - your SMS has been successfully sent. If err is not null
# then SMS will not be delivered because of error occured while sending. You
# can view err.code (number error code) and err.message (human readable russian
# message). If err is null then answer is object like this:
#
# {
#     raw    : '100\n200007-300007\nbalance=199.03',
#     smsId  : [ '200007-300007' ],
#     status : '100',
#     balance: '199.03'
# }
#
# `raw` is just raw answer from sms.ru server. You probably don't need it until
# you perfectly know what you are doing (you do not need it even then).
# `smsId` is array of SMS identifiers. You need it if you want to check sent SMS
# status.
# `status` is message sending status code. Nomally it should be always '100'.
# `balance` is you account balance in russian RUB.
#
# When you successfully sent SMS, you probably want to know whether it came to
# receipient or not. You can do it simply calling one function:
#
#     sms.status '200007-300007', onStatus
#
# '200007-300007' is SMS identifier from onSend()'s answer.smsId array. Note
# that sms.status() can work only with one ID string, not with arrays.
#
# onStatus is callback function (err, answer). If SMS can't be delivered at all
# (for any reason) then err will contain two fields: `code` (number code of
# error) and `message` (human readable error description in russian). If SMS
# delivered or in progress then err is null and answer is key-value object with
# the following parameters:
#
# {
#     raw    : '102',
#     status : '102',
#     message: 'Сообщение отправлено (в пути)'
# }
#
# `raw` is raw answer from sms.ru which you don't need until debugging purposes.
# `status` is code which shows SMS delivering status. Normally you need statuses
# '102' (means that SMS delivering is in progress) and '103' (means that SMS
# successfully delivered).
# `message` is human readable message in russian.
#
# That's all! You can also try well commented example `usecase.coffee`
# (`usecase.js` if you want raw JavaScript).
#
#
# If you want this library always stay actual you can:
# - donate via PayPal (more info: http://xinit.ru/)
# - use sms.ru from this access point: http://xinit.sms.ru/ (it makes no
#   differences for you but allow me to get a little money)
# - send SMS messages with this library (here is my agent code which makes no
#   differences for you but allow me to get a little money)
# - comment, share, spread this library
# - send issues, pull requests
#
#
# @license Feel free to use or modify this lib as long as my @author tag remains
# @version 0.0.1
# @author Alexander Zubakov <developer@xinit.ru>
#

'use strict'

http        = require 'http'
querystring = require 'querystring'


errorCodesSend =
    '1'  : 'Неизвестная ошибка'
    '100': 'Сообщение принято к отправке'
    '200': 'Неправильный api_id'
    '201': 'Не хватает средств на лицевом счету'
    '202': 'Неправильно указан получатель'
    '203': 'Нет текста сообщения'
    '204': 'Имя отправителя не согласовано с администрацией'
    '205': 'Сообщение слишком длинное (превышает 8 СМС)'
    '206': 'Будет превышен или уже превышен дневной лимит на отправку сообщений'
    '207': 'На этот номер (или один из номеров) нельзя отправлять сообщения, либо указано более 100 номеров в списке получателей'
    '208': 'Параметр time указан неправильно'
    '209': 'Вы добавили этот номер (или один из номеров) в стоп-лист'
    '210': 'Используется GET, где необходимо использовать POST'
    '211': 'Метод не найден'
    '212': 'Текст сообщения необходимо передать в кодировке UTF-8 (вы передали в другой кодировке)'
    '220': 'Сервис временно недоступен, попробуйте чуть позже.'
    '230': 'Сообщение не принято к отправке, так как на один номер в день нельзя отправлять более 250 сообщений'
    '300': 'Неправильный token (возможно истек срок действия, либо ваш IP изменился)'
    '301': 'Неправильный пароль, либо пользователь не найден'
    '302': 'Пользователь авторизован, но аккаунт не подтвержден (пользователь не ввел код, присланный в регистрационной смс)'


errorCodesStatus =
    '1'  : 'Неизвестная ошибка'
    '-1' : 'Сообщение не найдено'
    '100': 'Сообщение находится в нашей очереди'
    '101': 'Сообщение передается оператору'
    '102': 'Сообщение отправлено (в пути)'
    '103': 'Сообщение доставлено'
    '104': 'Не может быть доставлено: время жизни истекло'
    '105': 'Не может быть доставлено: удалено оператором'
    '106': 'Не может быть доставлено: сбой в телефоне'
    '107': 'Не может быть доставлено: неизвестная причина'
    '108': 'Не может быть доставлено: отклонено'
    '200': 'Неправильный api_id'
    '210': 'Используется GET, где необходимо использовать POST'
    '211': 'Метод не найден'
    '220': 'Сервис временно недоступен, попробуйте чуть позже.'
    '300': 'Неправильный token (возможно истек срок действия, либо ваш IP изменился)'
    '301': 'Неправильный пароль, либо пользователь не найден'
    '302': 'Пользователь авторизован, но аккаунт не подтвержден (пользователь не ввел код, присланный в регистрационной смс)'


authInfo =
    api_id: null
    login : null
    pass  : null


# Authorisation data. Can be by login and password or by API ID.
#
# @param string login Login or API ID.
# @param [string, null] pass If exists then first parameter interprets as ligin
#                            name and this - as password. If there is no pass
#                            then first parameter will be used as API ID.
#
auth = (login, pass = null) ->
    if pass?
        authInfo.login = login
        authInfo.pass  = pass
    else
        authInfo.api_id = login


# Send SMS.
#
# @param [string, array] number If string then it is full version of number to
#                               send SMS to. If array given then it is array of
#                               full numbers to send SMS to.
# @param string text UTF-8 encoded text to send.
# @param object options Key-value object with additional parameters to use in
#                       request.
# @param callback onSend Function (err, answer) to invoke when SMS has been
#                        sent. answer is an key-value object.
#                        If err is null then answer is key-value object: {
#                            status: 100, # 100 means success. Other status codes you can see on sms.ru
#                            smsId : [],  # array of sent SMS ID-s. You need it only if you want to
#                                         # look their status later, but it's completely optional
#                            balance: '100.75' # balance of your account, RUB
#                        }
#                        If err is not null you can fetch err.code and
#                        err.message where err.code is numeric answer code from
#                        sms.ru and err.message is human readable message to
#                        describe error in russian.
#
send = (number, text, options, onSend = null) ->
    if not onSend?
        onSend = options
        options = {}

    # handle multiple numbers
    if Array.isArray(number) then number = number.join(',')

    # required params
    options.partner_id = 19743
    if authInfo.api_id?
        options.api_id = authInfo.api_id
    else
        options.login    = authInfo.login
        options.password = authInfo.pass

    options.to   = number
    options.text = text

    # query string
    query = querystring.stringify options

    # HTTP request params
    params =
        hostname: 'sms.ru'
        path    : "/sms/send"
        method  : 'POST'
        headers:
            'Content-Type'  : 'application/x-www-form-urlencoded'
            'Content-Length': query.length

    # send request
    http.request(params, (res) ->
        #prepare answer
        res.setEncoding 'utf8'
        answer =
            raw: ''

        # read answer body
        res.on 'data', (chunk) ->
            answer.raw += chunk

        # format answer and finish
        res.on 'end', ->
            answer.smsId  = answer.raw.split '\n'
            answer.status = answer.smsId.shift()

            # OK
            if answer.status is '100'
                answer.balance = answer.smsId.pop().replace('balance=', '')
                onSend null, answer

            # error
            else
                answer.smsId = []

                err =
                    httpStatus: res.statusCode
                    code      : answer.status or '1'
                    message   : errorCodesSend[answer.status or '1']

                onSend err, answer

        # some network error
        res.on 'error', (err) ->
            onSend err, null
    )
    .end query


# Send SMS.
#
# @param string id ID of SMS to get status. You can get SMS id from p1.smsId key
#                  in onSend(p1, p2) callbacj from send() function.
# @param callback onStatus Function (err, answer) to invoke when status got.
#                          answer is an key-value object.
#                          If err is null then answer is key-value object: {
#                              status : '103', # status code from sms.ru. If 103 then
#                                              # SMS successfully delivered. If 102 then
#                                              # message is delivering. If not 1xx then
#                                              # error occured and err will not be null
#                              message: '' # human readable message from sms.ru
#                          }
#                          If err is not null you can fetch err.code and
#                          err.message where err.code is numeric answer code from
#                          sms.ru and err.message is human readable message to
#                          describe error in russian.
#
status = (id, onStatus) ->
    # required params
    if authInfo.api_id?
        options =
            api_id: authInfo.api_id
    else
        options =
            login   : authInfo.login
            password: authInfo.pass

    options.id = id

    # query string
    query = querystring.stringify options

    # HTTP request params
    params =
        hostname: 'sms.ru'
        path    : "/sms/status"
        method  : 'POST'
        headers:
            'Content-Type'  : 'application/x-www-form-urlencoded'
            'Content-Length': query.length

    # send request
    http.request(params, (res) ->
        #prepare answer
        res.setEncoding 'utf8'
        answer =
            raw: ''

        # read answer body
        res.on 'data', (chunk) ->
            answer.raw += chunk

        # format answer and finish
        res.on 'end', ->
            answer.status  = answer.raw.trim()
            answer.message = errorCodesStatus[answer.status or '1']

            # OK
            if '100' < answer.status < '108'
                onStatus null, answer

            # error
            else
                err =
                    httpStatus: res.statusCode
                    code      : answer.status or '1'
                    message   : errorCodesStatus[answer.status or '1']

                onStatus err, answer

        # some network error
        res.on 'error', (err) ->
            onStatus err, null
    )
    .end query


exports.auth   = auth
exports.send   = send
exports.status = status
