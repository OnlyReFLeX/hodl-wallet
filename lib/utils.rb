# frozen_string_literal: true

module Utils
  # Конвертация Bitcoin в сатоши
  def to_satoshi(amount)
    (amount * 100_000_000).to_i
  end

  # Конвертация сатоши в Bitcoin
  def to_btc(satoshis)
    satoshis / 100_000_000.0
  end

  # Форматирование Bitcoin суммы
  def format_btc(amount, precision = 8)
    format("%.#{precision}f", amount)
  end
end
