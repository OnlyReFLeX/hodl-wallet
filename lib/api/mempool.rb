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
      response = self.class.post(
        '/tx',
        body: tx_hex,
        headers: { 'Content-Type' => 'text/plain' }
      )

      if response.success?
        { 'txid' => response.body }
      else
        { 'error' => response.body }
      end
    end

    def fees
      response = self.class.get('/v1/fees/recommended')

      response.parsed_response
    end
  end
end
