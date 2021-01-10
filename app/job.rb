# frozen_string_literal: true

require_relative 'config'
require_relative 'services/currency'
require_relative 'services/jobber'
require_relative 'services/websocket/client'

socket = WebSocket::Client.init(JOB_SOCKET_URL)

#
# describe jobs
#
Jobber.every 10.seconds do
  socket.send(Currency.value)
end

Jobber.every 20.seconds do
  p 'some other job'
end

Jobber.run_all!
