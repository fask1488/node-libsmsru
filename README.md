Simple sms.ru API library. All you basicly need is here - sending SMS and
checking delivering status of sent messages.

Usage is as simple as it can be.
Require library (in this example it located in ./lib/, but you can install it
to your node_modules directory):

    sms = require './lib/libsmsru'

You need to authorise with your API ID:

    sms.auth '00000000-0000-0000-0000-000000000000'

or with your login and password:

    sms.auth 'login', 'pa$$w0rd'

Then just send SMS with text 'Пример SMS-сообщения' to number 79150000000 from
sender xinit.ru:

    sms.send '79150000000', 'Пример SMS-сообщения', { from: 'xinit.ru'}, onSend

Note that in options object { from: 'xinit.ru'} you can use all parameters
from sms.ru you want. Or you can just skip it and send SMS this way:

    sms.send '79150000000', 'Пример SMS-сообщения', onSend

This time SMS will be sent from default sender.

onSend is Callback function with two parameters: (err, answer). If err is null
then you are lucky - your SMS has been successfully sent. If err is not null
then SMS will not be delivered because of error occured while sending. You
can view err.code (number error code) and err.message (human readable russian
message). If err is null then answer is object like this:

{
    raw    : '100\n200007-300007\nbalance=199.03',
    smsId  : [ '200007-300007' ],
    status : '100',
    balance: '199.03'
}

`raw` is just raw answer from sms.ru server. You probably don't need it until
you perfectly know what you are doing (you do not need it even then).
`smsId` is array of SMS identifiers. You need it if you want to check sent SMS
status.
`status` is message sending status code. Nomally it should be always '100'.
`balance` is you account balance in russian RUB.

When you successfully sent SMS, you probably want to know whether it came to
receipient or not. You can do it simply calling one function:

    sms.status '200007-300007', onStatus

'200007-300007' is SMS identifier from onSend()'s answer.smsId array. Note
that sms.status() can work only with one ID string, not with arrays.

onStatus is callback function (err, answer). If SMS can't be delivered at all
(for any reason) then err will contain two fields: `code` (number code of
error) and `message` (human readable error description in russian). If SMS
delivered or in progress then err is null and answer is key-value object with
the following parameters:

{
    raw    : '102',
    status : '102',
    message: 'Сообщение отправлено (в пути)'
}

`raw` is raw answer from sms.ru which you don't need until debugging purposes.
`status` is code which shows SMS delivering status. Normally you need statuses
'102' (means that SMS delivering is in progress) and '103' (means that SMS
successfully delivered).
`message` is human readable message in russian.

That's all! You can also try well commented example `usecase.coffee`
(`usecase.js` if you want raw JavaScript).


If you want this library always stay actual you can:
- donate via PayPal (more info: http://xinit.ru/)
- use sms.ru from this access point: http://xinit.sms.ru/ (it makes no
  differences for you but allow me to get a little money)
- send SMS messages with this library (here is my agent code which makes no
  differences for you but allow me to get a little money)
- comment, share, spread this library
- send issues, pull requests


@license Feel free to use or modify this lib as long as my @author tag remains
@version 0.0.1
@author Alexander Zubakov <developer@xinit.ru>
