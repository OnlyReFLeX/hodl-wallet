# frozen_string_literal: true

class Interface
  MENU_OPTIONS = {
    '1' => :show_address,
    '2' => :show_balance,
    '3' => :create_transaction,
    'h' => :help,
    '0' => :bye, 'exit' => :bye
  }.freeze

  def load
    @wallet = select_wallet

    help
    menu
  end

  private

  def menu
    loop do
      print 'Выберите пункт: '
      choice = gets.chomp
      if MENU_OPTIONS[choice]
        send MENU_OPTIONS[choice]
      else
        puts 'Неправильная команда, используйте help для помощи'
      end
    end
  end

  def select_wallet
    title
    puts 'Выберите существующий кошелек или создайте новый'
    puts '1. Создать новый кошелек'
    wallets.each.with_index(2) do |wallet, i|
      puts "#{i}. #{wallet}"
    end

    ask_wallet_choice
  rescue RuntimeError => e
    puts e.message
    retry
  end

  def ask_wallet_choice
    choice = gets.chomp
    case choice
    when '1'
      Wallet.new
    when '0'
      bye
    else
      wallet_address = wallets[choice.to_i - 2]
      raise 'Выбран неправильный пункт, пожалуйста, попробуйте ещё раз' if wallet_address.nil?

      Wallet.new(wallet_address)
    end
  end

  def title
    puts '* Система управления Bitcoin кошельком *'
  end

  def help
    title
    puts '1. Показать адрес'
    puts '2. Показать баланс'
    puts '3. Отправить средства'
    puts '0. Выйти'
    puts 'h. Помощь'
  end

  def show_address
    puts "Адрес кошелька: #{@wallet.address}"
  end

  def show_balance
    puts "Ваш баланс: #{format('%.5f', @wallet.balance)} sBTC"
  end

  def create_transaction
    print 'Введите адрес получателя: '
    to_address = gets.strip

    print 'Введите сумму sBTC: '
    amount = gets.to_f

    raise 'Сумма должна быть больше 0' if amount <= 0

    result = @wallet.transfer(to_address, amount)
    transaction_info(result)
  rescue StandardError => e
    puts e.message
  end

  def bye
    puts 'Прощай, дорогой друг.'
    exit
  end

  def wallets
    @wallets ||= Dir.children('./wallets')
  end

  def transaction_info(result)
    puts <<~HEREDOC
      Транзакция успешно отправлена!
      ID транзакции: #{result[:txid]}
      Отправлено: #{format('%.8f', result[:amount])} sBTC
      Комиссия: #{format('%.8f', result[:fee])} sBTC
      Итоговая сумма: #{format('%.8f', result[:total_amount])} sBTC
      Адрес получателя: #{result[:to_address]}
      Адрес отправителя: #{result[:address]}
      Проверьте статус транзакции на https://mempool.space/signet/tx/#{result[:txid]}
    HEREDOC
  end
end
