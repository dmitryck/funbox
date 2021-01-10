# frozen_string_literal: true

require 'iodine'

class WebSocket
  class Client
    class Handler
      REBOOT_AT_SECONDS = 250
      @@url = nil

      def on_open(connection)
        connection.subscribe :updates
      end

      def on_close(connection)
        Iodine.run_after(REBOOT_AT_SECONDS) { self.class.connect(@@url) }
      end

      def self.connect(url)
        Iodine.connect(url: @@url = url, handler: new) 
      end
    end

    def self.init(url)
      Iodine.threads = 1
      Iodine.defer { Handler.connect(url) if Iodine.master? }
      Thread.new { Iodine.start }
      new
    end

    def send(data)
      Iodine.publish(:updates, "#{data}")
    end
  end
end
