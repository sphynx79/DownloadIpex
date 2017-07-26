# frozen_string_literal: true

require File.join(File.dirname(__FILE__), 'sito.rb')

$risposta = ""

class Pce < Sito

  def initialize(data, pos_nette, pro_fisica, liq_giornaliera, el_offerte, societa)
    @anno                                  = data[6..9]
    @mese                                  = data[3..4]
    @giorno                                = data[0..1]
    @societa                               = societa
    @check_pce                             = Hash.new
    @check_pce["posizioni_nette"]          = pos_nette
    @check_pce["prog_fisica"]              = pro_fisica
    @check_pce["liquidazione_giornaliera"] = liq_giornaliera
    @check_pce["elenco_offerte"]           = el_offerte
    @pathposizioninette                    = "G:\\MEOR\\PROGRAMMAZIONE #{@anno}\\ITALIA\\Programmazione Giornaliera\\Conversione PN\\\Input\\"
    @pathprogfisicavalidate                = "F:\\PROGRAMMAZIONE #{@anno}\\ITALIA\\Report\\Giornaliero\\Programmazione Fisica PCE\\#{@mese} #{mese(@mese)} #{@anno}\\Validati\\"
    @pathprogfisicaesitate                 = "F:\\PROGRAMMAZIONE #{@anno}\\ITALIA\\Report\\Giornaliero\\Programmazione Fisica PCE\\#{@mese} #{mese(@mese)} #{@anno}\\Esitati\\"
    @pathliquidazionegiornaliera           = "F:\\PROGRAMMAZIONE #{@anno}\\ITALIA\\Report\\Giornaliero\\Liquidazione PCE\\#{@mese} #{mese(@mese)} #{@anno}\\"
    @pathelencoofferte                     = "F:\\PROGRAMMAZIONE #{@anno}\\ITALIA\\Report\\Giornaliero\\Elenco Offerte PCE\\#{@mese} #{mese(@mese)} #{@anno}\\"
    @conto_energia_eni                     = ["CE-IMM-OEESDAN", "CE-PRE-OEESDAN"]
    @utente_dispaciamento_eni_imm          = ["ENI S.P.A. (OEESDAN)", "ZZ - ENIPOWER MANTOVA SPA (OEEMSNP)", "ZZ - ENIPOWER S.P.A. (OEESNPW)", "ZZZZ - OESEFSS (OESEFSS)"]
    @utente_dispaciamento_eni_pre          = ["ENI S.P.A. (OEESDAN)"]
    @conto_energia_gl                      = ["CE-PRE-121562"]
    @utente_dispaciamento_gl_pre           = ["ENI GAS E LUCE SPA (121562)"]
  end

  def start(button, parent)
    @parent     = parent
    @button     = button
    $result_pce =  {status: true, contesto: '', backtrace: [], message: ''}

    begin
      avvia_pce
      setta_operatore
      scarica_esiti
    rescue Exception => e
      $result_pce[:status]     = false
      $result_pce[:contesto]   = 'Globale'
      $result_pce[:backtrace]  = e.backtrace
      $result_pce[:message]    = e.message
    end

    if  $result_pce[:status]
      messaggio(@parent, 'Esito Download', 'PCE scaricata correttamente')
      sleep 1
    else
      messaggio(@parent, $result_pce[:contesto], $result_pce[:message])
    end

    sleep 5
    @browser.close
    @button.sensitive = true
  end

  def avvia_pce
    @browser = start_browser
  
    @browser.goto("https://pce.ipex.it")
    @browser.window.maximize
    @browser.text_field(:name, "UserName").set("mboscolo863")
    @browser.text_field(:name, "Password").set("200899aa")
    @browser.button(:value, "Log-in").click
  end

  def scarica_esiti
    @check_pce.each{|key, value|
      if value
        case key
        when "posizioni_nette"            then break if posizione_nette()          == false
        when "prog_fisica"                then break if prog_fisica()              == false
        when "liquidazione_giornaliera"   then break if liquidazione_giornaliera() == false
        when "elenco_offerte"             then break if elenco_offerte()           == false
        end
      end
    }
  end

  def posizione_nette()
    data = (Time.now).strftime("%Y%m%d")

    begin
      @browser.link(:id, "menu_Transazioni Comm.").click

      try(3){@browser.button(:id => "Toolbar_cmdExport_Extension").click}
      try(3){@browser.element(:css => "#Toolbar_Extensions > li:nth-child(1) > a").click}

      @operatori.each do |oper|
        try(3){@browser.select_list(:css , ".ms-choice").option(:text => oper).select}

        conto =  oper == "ENI S.P.A. (OEESDAN)" ? @conto_energia_eni : @conto_energia_gl

        conto.each do |conto|
          try(3){@browser.select_list(:id, "lstOperator").option(:text => "#{conto}").select}
          utente_disp = case conto
                        when "CE-IMM-OEESDAN" then @utente_dispaciamento_eni_imm
                        when "CE-PRE-OEESDAN" then @utente_dispaciamento_eni_pre
                        when "CE-PRE-121562"  then @utente_dispaciamento_gl_pre
                        else "non trovato"
                        end

          utente_disp.each do |utente|
            try(3){@browser.select_list(:id, "lstOperatorDispatcher").option(:text => "#{utente}").select}
            if utente == "ENI S.P.A. (OEESDAN)"
              try(3){@browser.text_field(:id, "date").set("#{@giorno}/#{@mese}/#{@anno}")}
            end

            try(3){@browser.button(:id, "Toolbar_cmdExport").click}
            sleep 1
            if conto == "CE-PRE-OEESDAN"
              save_file("#{@pathposizioninette}PN_#{data}.ENI-PRELIEVO_PosNetta.xls")
            elsif conto == "CE-PRE-121562"
              save_file("#{@pathposizioninette}PN_#{data}.GL-PRELIEVO_PosNetta.xls")
            else
              case utente
              when "ENI S.P.A. (OEESDAN)"                then save_file("#{@pathposizioninette}PN_#{data}.ENI_PosNetta.xls")
              when "ZZ - ENIPOWER MANTOVA SPA (OEEMSNP)" then save_file("#{@pathposizioninette}PN_#{data}.MANTOVA_PosNetta.xls")
              when "ZZ - ENIPOWER S.P.A. (OEESNPW)"      then save_file("#{@pathposizioninette}PN_#{data}.EPOWER_PosNetta.xls")
              when "ZZZZ - OESEFSS (OESEFSS)"            then save_file("#{@pathposizioninette}PN_#{data}.SEF_PosNetta.xls")
              end
            end
          end
        end
      end
    rescue Exception => e
      $result_pce[:status]     = false
      $result_pce[:contesto]   = 'Posizioni nette'
      $result_pce[:backtrace]  = e.backtrace
      $result_pce[:message]    = e.message
      return false
    end
    return true
  end

  def prog_fisica()
    begin
      try(3){@browser.link(:id, "menu_Program. fisica").click}
      try(3){@browser.link(:id, "submenu_Program. fisica").click}

      try(3){@browser.text_field(:id, "date").set("#{@giorno}/#{@mese}/#{@anno}")}
      @browser.refresh

      try(3){@browser.button(:id => "Toolbar_cmdExport_Extension").click}
      try(3){@browser.element(:css => "#Toolbar_Extensions > li:nth-child(1) > a").click}

      sleep 1

      path = ''
      if @browser.element(:xpath => "//*[@id=\"main\"]/div/div/div[2]/div/div[4]/img").attribute_value("src").match("green")
        path = @pathprogfisicaesitate
      else
        path = @pathprogfisicavalidate
        messaggio(@parent, "Informazione", "Attenzione mercato non ancora chiuso! \n\n      Verrano scaricate le Validate")
      end

      @operatori.each do |oper|
        try(3){@browser.select_list(:css , ".ms-choice").option(:text => oper).select}

        conto =  oper == "ENI S.P.A. (OEESDAN)" ? @conto_energia_eni : @conto_energia_gl

        conto.each do |conto|
          try(3){@browser.select_list(:id, "lstOperator").option(:text => "#{conto}").select}

          utente_disp = case conto
                        when "CE-IMM-OEESDAN" then @utente_dispaciamento_eni_imm
                        when "CE-PRE-OEESDAN" then @utente_dispaciamento_eni_pre
                        when "CE-PRE-121562"  then @utente_dispaciamento_gl_pre
                        else "non trovato"
                        end

          utente_disp.each do |utente|
            try(3){@browser.select_list(:id, "lstOperatorDispatcher").option(:text => utente).select}

            try(3){@browser.button(:id, "Toolbar_cmdExport").click}
            sleep 1
            if conto == "CE-PRE-OEESDAN"
              save_file("#{path}ProgrFisica_ENIPRELIEVO_#{@anno[-2..-1]}#{@mese}#{@giorno}.xls")
            elsif conto == "CE-PRE-121562"
              save_file("#{path}ProgrFisica_GLPRELIEVO_#{@anno[-2..-1]}#{@mese}#{@giorno}.xls")
            else
              case utente
              when "ENI S.P.A. (OEESDAN)"                then save_file("#{path}ProgrFisica_ENIIMMISSIONE_#{@anno[-2..-1]}#{@mese}#{@giorno}.xls")
              when "ZZ - ENIPOWER MANTOVA SPA (OEEMSNP)" then save_file("#{path}ProgrFisica_ENIPOWER MANTOVA_#{@anno[-2..-1]}#{@mese}#{@giorno}.xls")
              when "ZZ - ENIPOWER S.P.A. (OEESNPW)"      then save_file("#{path}ProgrFisica_ENIPOWER_#{@anno[-2..-1]}#{@mese}#{@giorno}.xls")
              when "ZZZZ - OESEFSS (OESEFSS)"            then save_file("#{path}ProgrFisica_SEF_#{@anno[-2..-1]}#{@mese}#{@giorno}.xls")
              end
            end
          end
        end
      end
    rescue Exception => e
      $result_pce[:status]     = false
      $result_pce[:contesto]   = 'Programmazione Fisica'
      $result_pce[:backtrace]  = e.backtrace
      $result_pce[:message]    = e.message
      return false
    end
    return true
  end

  def liquidazione_giornaliera()
    begin
      unless @check_pce["prog_fisica"]
        try(3){@browser.link(:id, "menu_Program. fisica").click}
      end

      try(3){@browser.link(:id, "submenu_Liquid. Giornaliera").click}

      try(3){@browser.text_field(:id, "date").set("#{@giorno}/#{@mese}/#{@anno}")}
      @browser.refresh
      sleep 3

      try(3){@browser.button(:id => "Toolbar_cmdExport_Extension").click}
      sleep 1
      try(3){@browser.element(:css => "#Toolbar_Extensions > li:nth-child(1) > a").click}


      @operatori.each do |oper|
        try(3){@browser.select_list(:css , ".ms-choice").option(:text => oper).select}
        try(3){@browser.button(:id, "Toolbar_cmdExport").click}

        oper = oper == "ENI S.P.A. (OEESDAN)" ? "ENI" : "GL"
        sleep 1
        save_file("#{@pathliquidazionegiornaliera}LiquidazioneGiornaliera_#{oper}_#{@anno[-2..-1]}#{@mese}#{@giorno}.xls")
      end
    rescue Exception => e
      $result_pce[:status]     = false
      $result_pce[:contesto]   = 'Liquidazione Giornaliera'
      $result_pce[:backtrace]  = e.backtrace
      $result_pce[:message]    = e.message
      return false
    end
    return true
  end

  def elenco_offerte()
    begin
      unless @check_pce["prog_fisica"]
        try(3){@browser.link(:id, "menu_Program. fisica").click}
      end

      try(3){@browser.link(:id, "submenu_Offerte").click}
      sleep 2

      try(3){@browser.button(:id => "Toolbar_cmdExport_Extension").click}
      sleep 1
      try(3){@browser.element(:css => "#Toolbar_Extensions > li:nth-child(1) > a").click}

      try(3){@browser.text_field(:xpath, '//*[@id="main"]/div/div[1]/div/div[2]/div/input').set("#{@giorno}/#{@mese}/#{@anno}")}
      try(3){@browser.text_field(:xpath, '//*[@id="main"]/div/div[1]/div/div[4]/div/input').set("#{@giorno}/#{@mese}/#{@anno}")}

      @browser.button(:id, "Toolbar_cmdExport").click

      sleep 1
      save_file("#{@pathelencoofferte}ElencoOfferte_#{@anno[-2..-1]}#{@mese}#{@giorno}.xls")
    rescue Exception => e
      $result_pce[:status]     = false
      $result_pce[:contesto]   = 'Elenco Offerte'
      $result_pce[:backtrace]  = e.backtrace
      $result_pce[:message]    = e.message
      return false
    end
    return true
  end

  def setta_operatore
   @operatori = case @societa
    when 'ALL' then ['ENI S.P.A. (OEESDAN)', 'ENI GAS E LUCE SPA (121562)']
    when 'ENI' then ['ENI S.P.A. (OEESDAN)']
    when 'GL'  then ['ENI GAS E LUCE SPA (121562)']
    end
  end

  def mese(numeromese)
  mese=case "#{numeromese}"
       when "01" then "Gennaio"
       when "02" then "Febbraio"
       when "03" then "Marzo"
       when "04" then "Aprile"
       when "05" then "Maggio"
       when "06" then "Giugno"
       when "07" then "Luglio"
       when "08" then "Agosto"
       when "09" then "Settembre"
       when "10" then "Ottobre"
       when "11" then "Novembre"
       when "12" then "Dicembre"
       else "Unknown"
       end
  mese
 end

end

