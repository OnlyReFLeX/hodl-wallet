# frozen_string_literal: true

class Wallet
  FOLDER = './wallets'

  attr_reader :key, :mempool

  def initialize(file = nil)
    @key = load_or_create_key(file)
    @mempool = Api::Mempool.new(address)
  end

  def address
    @key.to_addr
  end

  def balance
    @mempool.utxo.sum { |t| t['value'] } / 100_000_000.0
  end

  def transfer(to_addr, amount)
    Transaction.new(self, to_addr, amount).transfer!
  end

  private

  def load_or_create_key(file)
    if file && File.exist?("#{FOLDER}/#{file}")
      key = Bitcoin::Key.from_wif(File.read("#{FOLDER}/#{file}").strip)
    else
      key = Bitcoin::Key.generate
      File.write("#{FOLDER}/#{key.to_addr}", key.to_wif)
    end

    key
  end
end
