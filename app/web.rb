require 'active_support/time'
require 'sinatra'
require 'sinatra-websocket'
require_relative 'config'
require_relative 'dispatcher'

#
# helpers
#
def socket_proc(socket_type)
  case socket_type
  when :client
    proc do |socket|
      socket.onopen { settings.clients << socket }
      socket.onclose { settings.clients.delete(socket) }
    end
  when :admin, :job
    proc do |socket|
      socket.onmessage do |data|
        EM.next_tick {
          Dispatcher.socket_proc(data, settings.clients, socket_type)
        }
      end
    end
  end
end

def locals(page)
  case page
  when :client
    {
      currency: Dispatcher.currency,
      socket_url: CLIENT_SOCKET_URL,
      version: VERSION
    }
  when :admin
    {
      currency: (v = Dispatcher.currency_admin).empty? ? Dispatcher.currency : v,
      time: Time.now.strftime("%Y.%m.%d %T"),
      sep: DATETIME_SEPARATOR,
      socket_url: ADMIN_SOCKET_URL,
      version: VERSION
    }
  end
end

#
# data at boot
#
Dispatcher.default_data!

#
# app
#
set port: APP_PORT
set clients: []

get '/' do
  erb :client, locals: locals(:client)
end

get '/admin' do
  erb :admin, locals: locals(:admin)
end

get CLIENT_SOCKET_PATH do
  request.websocket(&(socket_proc :client))
end

get ADMIN_SOCKET_PATH do
  request.websocket(&(socket_proc :admin))
end

get JOB_SOCKET_PATH do
  request.websocket(&(socket_proc :job))
end
