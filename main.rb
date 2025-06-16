require 'bitcoin'
require 'httparty'
require 'bigdecimal/util'
require_relative 'config'
require_relative 'lib/utils'
require_relative 'lib/api/mempool'
require_relative 'lib/wallet'
require_relative 'lib/transaction'
require_relative 'lib/interface'

FileUtils.mkdir_p(Wallet::FOLDER)
Interface.new.load
