# frozen_string_literal: true

module Utils
  SATOSHIS_PER_BTC = '100_000_000'.to_d

  # Конвертация Bitcoin в сатоши
  def to_satoshi(amount)
    (amount.to_d * SATOSHIS_PER_BTC).to_i
  end

  # Конвертация сатоши в Bitcoin
  def to_btc(satoshis)
    satoshis.to_d / SATOSHIS_PER_BTC
  end

  # Форматирование Bitcoin суммы
  def format_btc(amount)
    amount.to_d.to_s("F")
  end
end
