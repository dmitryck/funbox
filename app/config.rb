require 'dotenv/load'

APP_PORT = ENV['APP_PORT']&.to_i || 3000
VERSION = File.read File.expand_path('../.version', __dir__)

CLIENT_SOCKET_PATH='/client/data'
ADMIN_SOCKET_PATH='/admin/data'
JOB_SOCKET_PATH='/job/data'

CLIENT_SOCKET_URL="ws://localhost:#{APP_PORT}#{CLIENT_SOCKET_PATH}"
ADMIN_SOCKET_URL="ws://localhost:#{APP_PORT}#{ADMIN_SOCKET_PATH}"
JOB_SOCKET_URL="ws://localhost:#{APP_PORT}#{JOB_SOCKET_PATH}"

DATA_DIR = File.expand_path('data', __dir__)

DATETIME_SEPARATOR = '@'
