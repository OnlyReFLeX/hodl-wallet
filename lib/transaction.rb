# frozen_string_literal: true

class Transaction
  include Utils

  attr_reader :wallet, :to_addr, :amount

  def initialize(wallet, to_addr, amount)
    @wallet = wallet
    @to_addr = to_addr
    @amount = amount
  end

  # Выполняет транзакцию, отправляя указанную сумму на адрес получателя
  def transfer!
    # Сначала создаем черновик транзакции для расчета размера
    draft_tx_hex = prepare_draft_transaction(to_addr, amount)

    # Рассчитываем размер и комиссию
    tx_size_vbytes = draft_tx_hex.to_payload.bytesize
    fee = calculate_fee(tx_size_vbytes).to_d
    total_amount = amount + fee

    # Проверяем, достаточно ли средств на счете
    validate_balance(total_amount)

    # Создаем финальную транзакцию с учетом комиссии
    tx_hex = prepare_transaction(to_addr, total_amount, fee).to_hex

    response = wallet.mempool.broadcast(tx_hex)

    raise "Ошибка при отправке транзакции: #{response.body}" unless response.success?

    {
      txid: response.body,
      amount: amount,
      fee: fee,
      total_amount: total_amount,
      from_address: wallet.address,
      to_address: to_addr,
      check_link: "https://mempool.space/signet/tx/#{response.body}"
    }
  end

  private

  # Проверяет, достаточно ли средств на счете для выполнения транзакции
  def validate_balance(total_amount)
    current_balance = wallet.balance

    return unless current_balance < total_amount

    fee = total_amount - amount
    raise <<~HEREDOC
      Недостаточно средств на счете.
      Требуется: #{format_btc(total_amount)} sBTC
      Сумма: #{format_btc(amount)} sBTC + комиссия: #{format_btc(fee)} sBTC
      Доступно: #{format_btc(current_balance)} sBTC
    HEREDOC
  end

  # Создает черновик транзакции для расчета размера
  def prepare_draft_transaction(to_addr, amount)
    prepare_transaction_internal(to_addr, amount, 0) # временная комиссия для расчета
  end

  # Создает транзакцию с учетом комиссии
  def prepare_transaction(to_addr, amount, fee)
    prepare_transaction_internal(to_addr, amount, fee)
  end

  # Получает текущую комиссию из mempool
  def fee_rate
    @fee_rate ||= wallet.mempool.fees['fastestFee'].to_d
  end

  def prepare_transaction_internal(to_addr, send_amount, fee)
    total_amount = send_amount.to_d + fee.to_d

    # Получаем UTXO
    utxos = wallet.mempool.utxo
    selected_utxos = select_utxos(utxos, total_amount)

    # Создаем новую транзакцию
    tx = Bitcoin::Tx.new
    tx.version = 2

    # Добавляем входы
    selected_utxos.each do |utxo|
      out_point = Bitcoin::OutPoint.from_txid(utxo['txid'], utxo['vout'])
      tx.in << Bitcoin::TxIn.new(out_point: out_point)
    end

    # Добавляем выход для получателя
    tx.out << Bitcoin::TxOut.new(
      value: to_satoshi(send_amount),
      script_pubkey: Bitcoin::Script.parse_from_addr(to_addr)
    )

    # Добавляем выход для сдачи (если есть)
    total_input = selected_utxos.sum { |utxo| utxo['value'].to_d }.to_d
    change_amount = to_btc(total_input) - total_amount

    if change_amount.positive?
      tx.out << Bitcoin::TxOut.new(
        value: to_satoshi(change_amount),
        script_pubkey: Bitcoin::Script.parse_from_addr(wallet.address)
      )
    end

    # Подписываем транзакцию
    tx.inputs.each_with_index do |input, index|
      # Определяем script_pubkey для данного UTXO
      script_pubkey = Bitcoin::Script.parse_from_addr(wallet.address)

      # Вычисляем сигнатуру для входа
      sig_hash = tx.sighash_for_input(
        index,
        script_pubkey,
        hash_type: Bitcoin::SIGHASH_TYPE[:all]
      )

      # Создаем ECDSA подпись
      signature = wallet.key.sign(sig_hash, algo: :ecdsa)
      signature += [Bitcoin::SIGHASH_TYPE[:all]].pack('C')

      # Устанавливаем script_sig
      input.script_sig = Bitcoin::Script.new << signature << wallet.key.pubkey.htb
    end

    tx
  end

  # Рассчитывает комиссию на основе размера транзакции в байтах
  def calculate_fee(tx_size_vbytes)
    to_btc(tx_size_vbytes * fee_rate)
  end

  # Берет UTXO, которые достаточно для отправки указанной суммы
  def select_utxos(utxos, required_amount)
    required_satoshis = to_satoshi(required_amount)

    # Сортируем UTXO по значению (от большего к меньшему)
    sorted_utxos = utxos.sort_by { |utxo| -utxo['value'] }

    selected = []
    total = 0
    sorted_utxos.each do |utxo|
      selected << utxo
      total += utxo['value']
      break if total >= required_satoshis
    end

    selected
  end
end
