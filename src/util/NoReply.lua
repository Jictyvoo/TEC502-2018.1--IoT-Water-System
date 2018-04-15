--[[
Autor:João Victor Oliveira Couto

Componente Curricular: Concorrência e Conectividade

Concluido em: 14/04/2018

Declaro que este código foi elaborado por mim de forma individual e não contém nenhum
trecho de código de outro colega ou de outro autor, tais como provindos de livros e
apostilas, e páginas ou documentos eletrônicos da Internet. Qualquer trecho de código
de outra autoria que não a minha está destacado com uma citação para o autor e a fonte
do código, e estou ciente que estes trechos não serão considerados para fins de avaliação.
--]]
local socket = require 'socket'
local smtp = require 'socket.smtp'
local ssl = require 'ssl'
local https = require 'ssl.https'
local ltn12 = require 'ltn12'
local NoReply = {}

function NoReply:new(from, to, server)

    local self = {
        from;
        to;
        server;

        constructor = function(this, from, to, server)
            this.from = from or {}
            this.to = to or {}
            this.server = server or {}
        end
    }

    self.constructor(self, from, to, server)

    -- Michal Kottman, 2011, public domain
    local sslCreate = function ()
        local sock = socket.tcp()
        return setmetatable({
            connect = function(_, host, port)
                local r, e = sock:connect(host, port)
                if not r then return r, e end
                sock = ssl.wrap(sock, {mode = 'client', protocol = 'tlsv1'})
                return sock:dohandshake()
            end
            }, {
            __index = function(t, n)
                return function(_, ...)
                    return sock[n](sock, ...)
                end
            end
        })
    end

    local setFrom = function(title, address, charset, encode)
        self.from.title = title or self.from.title
        self.from.address = address or self.from.address
        self.from.charset = charset or self.from.charset
        self.from.encode = encode or self.from.encode
    end

    local setTo = function(title, address, charset, encode)
        self.to.title = title or self.to.title
        self.to.address = address or self.to.address
        self.to.charset = charset or self.to.charset
        self.to.encode = encode or self.to.encode
    end

    local setServer = function(address, port, user, password, ssl, create)
        self.server.address = address or self.server.address
        self.server.port = port or self.server.port
        self.server.user = user or self.server.user
        self.server.password = password or self.server.password
        self.server.ssl = ssl
        self.server.create = create
    end

    --[[local sendMail = function(subject, mailBody, file)
        sendmail(self.from, self.to, self.server, {subject, mailBody, file})
    end--]]

    local sendMessage = function (subject, body)
        local msg = {
            headers = {
                to = self.to.address,
                subject = subject
            },
            body = body
        }

        local ok, err = smtp.send {
            from = self.from.address,
            rcpt = self.to.address,
            source = smtp.message(msg),
            user = self.server.user,
            password = self.server.password,
            server = self.server.address,
            port = self.server.port,
            create = sslCreate
        }
        if not ok then
            print("Mail send failed", err) -- better error handling required
        end
    end

    return {
        setFrom = setFrom;
        setTo = setTo;
        setServer = setServer;
        --[[sendMail = sendMail;--]]
        sendMessage = sendMessage
    }

end

return NoReply
