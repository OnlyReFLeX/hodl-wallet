require 'bitcoin'
require_relative 'config'
require_relative 'lib/api/mempool'
require_relative 'lib/wallet'
require_relative 'lib/transaction'
require_relative 'lib/interface'

Interface.new.load
