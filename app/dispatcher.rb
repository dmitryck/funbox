require 'active_support/time'
require_relative 'config'
require_relative 'services/currency'
require_relative 'services/jobber'

class Dispatcher
  def self.default_data!
    lock_time! nil
    currency_force! nil
    currency_last! Currency.value
  end

  def self.clients_send(clients, value)
    clients.each { |client| client.send(value) }
  end

  def self.socket_proc(data, clients, socket_type)
    send("#{socket_type}_socket_proc", data, clients)
  end

  def self.job_socket_proc(data, clients)
    currency_last!(data)
    clients_send(clients, data) unless lock_time?
  end

  def self.admin_socket_proc(data, clients)
    currency, time = /^(.+?)@(.+)$/.match(data).to_a.slice(1, 2)
    time = time.to_time

    currency_admin!(currency)

    if lock_time?(time)
      lock_time!(time)
      currency_force!(currency)
      after_lock_callback(time, clients)
      
      clients_send(clients, currency)
    end
  end

  def self.after_lock_callback(time, clients)
    Jobber.at! time, em: false do
      clients_send(clients, currency_last)
    end
  end

  def self.currency
    currency_resolve(currency_last)
  end

  def self.currency_resolve(currency)
    lock_time? ? currency_force : currency
  end

  def self.currency_force!(value)
    File.write("#{DATA_DIR}/currency_force", value)
  end

  def self.currency_force
    File.read("#{DATA_DIR}/currency_force")
  end

  def self.currency_last!(value)
    File.write("#{DATA_DIR}/currency_last", value)
  end

  def self.currency_last
    File.read("#{DATA_DIR}/currency_last")
  end

  def self.currency_admin!(value)
    File.write("#{DATA_DIR}/admin/currency", value)
  end

  def self.currency_admin
    File.read("#{DATA_DIR}/admin/currency")
  rescue
    currency_admin! nil
    ''
  end

  def self.lock_time?(time = nil)
    (time || lock_time)&.>= Time.now
  end

  def self.lock_time!(time)
    File.write("#{DATA_DIR}/lock_time", time)
  end

  def self.lock_time
    File.read("#{DATA_DIR}/lock_time").to_time
  end
end
