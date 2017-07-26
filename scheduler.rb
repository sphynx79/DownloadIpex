# frozen_string_literal: true

require 'rufus-scheduler'
require File.expand_path('lib/ipex.rb', __dir__)
require 'pretty_backtrace'
PrettyBacktrace.enable
# PrettyBacktrace.multi_line = true
require 'ap'

$VERBOSE_MODE = true

$logger = Logger.new(STDOUT)
$logger.level = Logger::DEBUG
$logger.formatter = proc do |severity, _datetime, _progname, msg|
  "#{severity}: #{msg}\n"
end

ENV['TZ'] = 'Europe/Rome'

class Email

  def self.send(err, action, controparte)
    $logger.debug "Prepara invio email"
    Mail.defaults do
      delivery_method(:smtp, {address: "relay.eni.pri",
                              port: 25,
                              openssl_verify_mode: "none"
                             }
                     )
    end

    Mail.deliver do
      from     'michele.boscolo@eni.com'
      to       'michele.boscolo@eni.com'
      # cc       'Area.Programmi.Power@eni.com'
      subject  "Scaricamento esiti Time: #{Time.now.strftime("%d-%m-%Y %H:%M:%S")} Controparte: #{controparte}"
      body     err
      add_file 'log/application.log'
    end
    sleep 2

    FileUtils.rm('log/application.log')
    $logger.warn "Email Inviata"

  end
end

class Handler
  attr_reader :mercato

  def initialize(mercato)
    @mercato = mercato
  end

  def call(job, time)
    $logger.debug("Avvio scaricamento per #{job.tags[0]}")
    sito               = nil
    mercato            = job.tags[0]
    data               = (%w[MGP MI1 MI2 MSD1].include?(mercato) ? Date.today + 1 : Date.today).strftime('%d/%m/%Y')
    prezzo_is_active   = true
    offerte_is_active  = true
    cumulati_is_active = true
    societa            = 'ENI'

    ipex = Ipex.new(sito, mercato, data, prezzo_is_active, offerte_is_active, cumulati_is_active, societa)

    scarica(ipex)

  end

  def scarica(sito)
    count   = 0
    @result = []
    while count <= 2
      $logger.debug("Tentativo: #{count}")
      @result[count] = sito.start_from_scheduler
      break if @result[count][0]
      count += 1
    end
    if count < 2
      $logger.debug('File scaricati con successo')
    else
      ap @result
      # $logger.debug('Non sono riuscito a scaricare gli esiti')
    end
    #p "* #{time} - Handler #{mercato.inspect} called for #{job.id}"

  end

end


mercati = %w[MGP MI1 MI2 MI3 MI4 MI4 MI6 MI7 MSD1 MSD2 MSD3 MSD4 MSD5 MSD6]

mercati.each do |m|
  instance_variable_set('@' + m.downcase, Handler.new(m))
end

scheduler = Rufus::Scheduler.new(frequency: '5s')

now    = Time.now + 3660
minute = '%02d' % now.min
hour   = '%02d' % now.hour
scheduler.cron("#{minute} #{hour} * * *", @mgp, timeout: '5m', tag: 'MGP')

scheduler.join
