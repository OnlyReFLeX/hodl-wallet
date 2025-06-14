require 'httparty'

module Api
  class Mempool
    include HTTParty

    base_uri 'https://mempool.space/signet/api'

    def initialize(address)
      @address = address
    end

    def utxo
      self.class.get("/address/#{@address}/utxo")
    end

    def broadcast(tx_hex)
      self.class.post(
        '/tx',
        body: tx_hex
      )
    end

    def fees
      self.class.get('/v1/fees/recommended')
    end
  end
end
