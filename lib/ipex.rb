# frozen_string_literal: true

require File.join(File.dirname(__FILE__), 'sito.rb')
# require 'pretty_backtrace'
# PrettyBacktrace.enable

$risposta = ''

class Ipex < Sito
  # Inizializzo la mia classe
  # return ==> Istance IPEX Class
  def initialize(sito, mercato, data, prezzo_is_active, offerte_is_active, cumulati_is_active, societa)
    @sito                   = sito
    @mercato                = mercato
    @societa                = societa
    @anno                   = data[6..9]
    @mese                   = data[3..4]
    @giorno                 = data[0..1]
    @check                  = {}
    @check['prezzo']        = prezzo_is_active
    @check['offerte']       = offerte_is_active
    @check['cumulati']      = cumulati_is_active
    @path_prezzi            = "F:\\PROGRAMMAZIONE #{@anno}\\ITALIA\\Report\\Giornaliero\\Prezzi\\"
    @path_esitate           = "F:\\PROGRAMMAZIONE #{@anno}\\ITALIA\\Report\\SOA Italia\\Esitate\\"
    @path_esitate_gl        = "F:\\PROGRAMMAZIONE #{@anno}\\ITALIA\\Report\\SOA Italia\\Esitate_GL\\"
    @path_validate          = "F:\\PROGRAMMAZIONE #{@anno}\\ITALIA\\Report\\SOA Italia\\Validate\\"
    @path_validate_gl       = "F:\\PROGRAMMAZIONE #{@anno}\\ITALIA\\Report\\SOA Italia\\Validate_GL\\"
    @path_cumulati          = "F:\\PROGRAMMAZIONE #{@anno}\\ITALIA\\Report\\Giornaliero\\Programmi Cumulati\\"
    @path_elenco_offerte    = "F:\\PROGRAMMAZIONE #{@anno}\\ITALIA\\Report\\Giornaliero\\Elenco offerte\\"
    @path_elenco_offerte_gl = "F:\\PROGRAMMAZIONE #{@anno}\\ITALIA\\Report\\Giornaliero\\Elenco offerte_GL\\"
    @path_report_flussi     = "F:\\PROGRAMMAZIONE #{@anno}\\ITALIA\\Report\\Giornaliero\\Report Flussi\\"

    create_getters
  end

  def start_from_gui(button, parent)
    $result_ipex = {status: true, contesto: '', backtrace: [], message: ''}
    begin
      avvia_ipex

      case controlla_se_mercato_chiuso
      when  'mercato non chiuso'  then messaggio(parent, 'Informazione', "Attenzione mercato #{@mercato} non ancora chiuso! \n\n      Non e' possibile scaricare l'esito"); button.sensitive = true; return
      when  'validate'            then messaggio(parent, 'Informazione', "Attenzione mercato #{@mercato} non ancora chiuso! \n\n      Verrano scaricate le Validate"); scarica_validate
      when  'esitate'             then scarica_esiti
      end
    rescue Exception => e
      $result_ipex[:status]     = false
      $result_ipex[:contesto]   = 'Globale'
      $result_ipex[:backtrace]  = e.backtrace
      $result_ipex[:message]    = e.message
    end

    if $result_ipex[:status]
      messaggio(parent, 'Esito Download', 'File da mercato IPEX scaricati correttamente')
    else
      messaggio(parent, $result_ipex[:contesto], $result_ipex[:message])
    end
    sleep 5
    button.sensitive = true
    @browser.close
  end

  def start_from_scheduler

    $result_ipex = [true, '', '']
    begin
       avvia_ipex
    
       case controlla_se_mercato_chiuso
       when  'mercato non chiuso'  then $result_ipex[0..2] = false, '', 'mercato non chiuso'
       when  'validate'            then $result_ipex[0..2] = false, '', 'mercato non chiuso sono presenti le validate'
       when  'esitate'             then scarica_esiti
       end
    rescue Exception => e
       $result_ipex[0..2] = false, '', "#{e.backtrace[0].split(":").last} #{e.message}"
    end
    
    @browser.close
    return $result_ipex
  end

  private

  # Avvio il browser ed accedo ad IPEX
  def avvia_ipex
    @browser = start_browser

    @browser.goto("https://#{@sito}.ipex.it")

    if ENV['USERNAME'] == ''
      login
    end

    @browser.window.maximize
  end

  # Seleziono il mercato
  def seleziona_mercato
    try(3){@browser.select_list(:id, 'BoxDataMarket1_dllMarket').select("#{@mercato}")}
    @browser.select_list(:id, 'BoxDataMarket1_dllMarket').fire_event 'onchange'
  end

  # Controllo se il mercato è chiuso
  def controlla_se_mercato_chiuso
    if ['MGP', 'MI1', 'MI2', 'MSD1'].include? @mercato
      @browser.text_field(:id, 'BoxDataMarket1_CalendarioMaster_txtBox').set "#{@giorno}/#{@mese}/#{@anno}"
    else
      data = DateTime.new(@anno.to_i, @mese.to_i, @giorno.to_i) + 1
      @browser.text_field(:id, 'BoxDataMarket1_CalendarioMaster_txtBox').set "#{data.strftime('%d/%m/%Y')}"
    end
    # Click su Mercati nel menu di sinistra per refreshare la pagina
    # Altrimenti la tabellina sopra dove ci sono i semafori non si aggiornava
    @browser.link(:text, 'Mercati').click
    i = 0
    while i < 3 && @browser.img(:id, "GridOrImageBar_ImageMarketResult_#{mercato}").title != 'Disponibili'
      i += 1
      sleep 1
    end

    if @browser.img(:id, "GridOrImageBar_ImageMarketResult_#{mercato}").title == 'Disponibili'
      return 'esitate'
    elsif !(['MGP', 'MI1', 'MI2', 'MI3', 'MI4', 'MI5', 'MI6', 'MI7', 'MSD1'].include? @mercato)
      return 'mercato non chiuso'
    else
      @check = Hash.new
      @check['offerte'] = true
      return 'validate'
    end
  end

  # Scarico da Ipex l'esito richiesto dall'utente, tipo prezzi o cumulati oppure tutto.
  # controlla i checkbox selezionati dall'utente e per ogni checkbox avvia il relativo metodo
  # in caso uno dei metodi esce con errore prima di uscire setta $result_ipex[0..2] = false, Contesto, e.message ed esce dalla funzione scarica_esiti
  def scarica_esiti
    unless (@mercato == 'MGP') || (@mercato == 'MI1') || (@mercato == 'MI2') || (@mercato == 'MSD1')
      @browser.text_field(:id, 'BoxDataMarket1_CalendarioMaster_txtBox').set "#{@giorno}/#{@mese}/#{@anno}"
    end
    @browser.link(:text, 'Mercati').click
    seleziona_mercato

    check.each do |key, value|
      if value
        case key
        when 'prezzo'          then break if scarica_prezzi   == false
        when 'offerte'         then break if scarica_esitate  == false
        when 'cumulati'        then break if scarica_cumulati == false
        end
      end
    end
  end

  # Scarico i prezzi
  def scarica_prezzi
    begin
      apri_pagina('Risultati Mercato')

      # Click sul bottone Definitivi
      try(3){@browser.link(:text, 'Risultati Zone-Prezzo').click}

      set_export_file_type_excel

      # Click per esportare in excel
      try(3){@browser.button(:id, 'MainContent_GenericToolbarFindZone_Toolbar_cmdExport').click}

      save_file("#{@path_prezzi}Prezzi#{mercato}_#{@giorno}_#{@mese}_#{@anno[2..3]}.xls")

      if mercato == 'MGP'
        # Clicco sul tab report flussi
        @browser.element(:xpath, '//*[@id="MainContent_Menu_Results"]/ul/li[5]/a').click

        set_export_file_type_excel

        # Click per esportare in excel
        try(3){@browser.button(:id, 'MainContent_GenericToolbarFlowResult_Toolbar_cmdExport').click}

        # Salvo il file report flussi
        save_file("#{@path_report_flussi}FlussiMGP_#{@giorno}_#{@mese}_#{@anno[2..3]}.xls")
      end
    rescue Exception => e
      $result_ipex[:status]     = false
      $result_ipex[:contesto]   = 'Prezzi'
      $result_ipex[:backtrace]  = e.backtrace
      $result_ipex[:message]    = e.message
      return false
    end
    return true
  end

  # Scarica le esitate
  def scarica_esitate
    begin
      operatore = setta_operatore
      apri_pagina('Elenco Offerte')

      set_export_file_type_excel

      operatore.each do |oper|
        # Seleziono l'operatore
        @browser.select_list(:id, 'bidoffer_operator').select("#{oper}")

        try(3){@browser.button(:id, 'MainContent_GenericToolbar_Toolbar_cmdExport').click}

        path           = set_path(oper)
        name_file_oper = (check_operatore(oper)).capitalize

        if mercato == 'MGP'
          save_file("#{path}Esitate_#{name_file_oper}_#{@giorno}#{@mese}#{@anno}.xls")
        elsif mercato == 'MI1' || mercato == 'MI2' || mercato == 'MI3' || mercato == 'MI4' || mercato == 'MI5' || mercato == 'MI6' || mercato == 'MI7'
          save_file("#{path}Esitate_#{name_file_oper}_#{@giorno}#{@mese}#{@anno}_#{mercato}.xls")
        else
          save_file("#{path}Esitate_#{name_file_oper}_#{@giorno}#{@mese}#{@anno}_#{mercato}_#{oper[-7..-1]}.xls")
        end
      end
    rescue Exception => e
      $result_ipex[:status]     = false
      $result_ipex[:contesto]   = 'Esitate'
      $result_ipex[:backtrace]  = e.backtrace
      $result_ipex[:message]    = e.message
      return false
    end
    return true
  end

  # Scarica le validate
  def scarica_validate
    begin
      unless (@mercato == 'MGP') || (@mercato == 'MI1') || (@mercato == 'MI2') || (@mercato == 'MSD1')
        @browser.text_field(:id, 'BoxDataMarket1_CalendarioMaster_txtBox').set "#{@giorno}/#{@mese}/#{@anno}"
      end

      operatore = setta_operatore

      apri_pagina('Elenco Offerte')

      seleziona_mercato

      set_export_file_type_excel

      operatore.each do |oper|
        @browser.select_list(:id, 'bidoffer_operator').select("#{oper}")
        # Se il mercato è MSD attivo il checkbox Predefinito
        # e sulla selectlist Stato seleziono solo Valido
        if mercato == 'MSD1' && oper == 'ENI SPA-OEESDAN'
          @browser.checkbox(:id, 'MainContent__offerFindParameters_cbPredefinito').set
          try(3){@browser.spans(:class, 'ui-dropdownchecklist-text')[2].click}
          sleep 1
          try(3){@browser.div(:id, 'ddcl-MainContent__offerFindParameters_lstState-ddw').label(:text, 'ALL').click}
          sleep 1
          try(3){@browser.div(:id, 'ddcl-MainContent__offerFindParameters_lstState-ddw').label(:text, 'Valido').click}
        end

        try(3){@browser.button(:id, 'MainContent_GenericToolbar_Toolbar_cmdExport').click}

        path           = set_path(oper)
        name_file_oper = (check_operatore(oper)).capitalize

        if mercato == 'MGP'
          save_file("#{path}Validate_#{name_file_oper}_#{@giorno}#{@mese}#{@anno}.xls")
        elsif mercato == 'MI1' || mercato == 'MI2' || mercato == 'MI3' || mercato == 'MI4' || mercato == 'MI5' || mercato == 'MI6' || mercato == 'MI7'
          save_file("#{path}Validate_#{name_file_oper}_#{@giorno}#{@mese}#{@anno}_#{mercato}.xls")
        else
          save_file("#{path}Validate_#{name_file_oper}_#{@giorno}#{@mese}#{@anno}_#{mercato}_#{oper[-7..-1]}.xls")
        end
      end
    rescue Exception => e
      $result_ipex[:status]     = false
      $result_ipex[:contesto]   = 'Validate'
      $result_ipex[:backtrace]  = e.backtrace
      $result_ipex[:message]    = e.message
      return false
    end
    return true
  end

  # Scarico i cumulati
  def scarica_cumulati
    begin
      operatore = setta_operatore

      apri_pagina('Programmi Orari')

      set_export_file_type_excel

      operatore.each do |oper|
        @browser.select_list(:id, 'MainContent_HourProgramFindParameter1_AjaxOperatorUnitsDropDownList_ddlMaster').select("#{oper}")

        # Se sono su MGP e l'operatore è "ENI SPA - OEESDAN" scarico l'elenco offerte
        if (oper == 'ENI SPA-OEESDAN' || oper == 'ENI GAS E LUCE SPA-121562') && mercato == 'MGP'
          scarica_elenco_offerte(oper)
        end

        # Setto il checkbox Cumulative
        try(3){@browser.checkbox(:id, 'chkCumulative').set}

        # Click per esportare in excel
        try(3){@browser.button(:id, 'MainContent_GenericToolbar_Toolbar_cmdExport').click}

        # Salvo il cumulato
        if mercato == 'MGP'
          save_file("#{@path_cumulati}#{cartella_cumulati(oper)}\\cumulato_#{@giorno}_#{@mese}_#{@anno[2..3]}_MGP.xls")
        elsif mercato == 'MI1' || mercato == 'MI2' || mercato == 'MI3' || mercato == 'MI4' || mercato == 'MI5' || mercato == 'MI6' || mercato == 'MI7'
          save_file("#{@path_cumulati}#{cartella_cumulati(oper)}\\cumulato#{mercato}_#{@giorno}_#{@mese}_#{@anno[2..3]}.xls")
        else
          save_file("#{@path_cumulati}Cumulati MSD\\Cumulato Orario\\cumulato_#{@giorno}_#{@mese}_#{@anno[2..3]}_orario#{nome_oper(oper)}#{nome_mercato}.xls")
        end
      end
    rescue Exception => e
      $result_ipex[:status]     = false
      $result_ipex[:contesto]   = 'Cumulati'
      $result_ipex[:backtrace]  = e.backtrace
      $result_ipex[:message]    = e.message
      return false
    end
    return true
  end

  # Scarica l'elenco offerte
  def scarica_elenco_offerte(oper)
    @browser.checkbox(:id, 'chkCumulative').clear
    # Clicco su cerca
    @browser.button(:id, 'MainContent_GenericToolbar_Toolbar_cmdSearch').click

    set_export_file_type_excel

    # Click per esportare in excel
    try(3){@browser.button(:id, 'MainContent_GenericToolbar_Toolbar_cmdExport').click}

    # Salvo l'elenco offerte
    path = oper == 'ENI SPA-OEESDAN' ? @path_elenco_offerte : @path_elenco_offerte_gl
    save_file("#{path}elencoofferte_#{@giorno}_#{@mese}_#{@anno[2..3]}.xls")
  end

  # Setto il menu sul tipo di file e seleziono excel 2003
  def set_export_file_type_excel
    unless menu_is_excel_2003
      try(3){@browser.button(:title, 'Select an action').click}
      try(3){@browser.link(:id, 'ui-id-4').click}
    end
  end

  def menu_is_excel_2003
    try(3){!(@browser.element(:css, "#Toolbar_divExport>input").value.match "Excel 2003").nil?}
  end

  def apri_pagina(text)
    # Se il menu mercati non è aperto ci clicca
    1.upto(2) {|i|
      unless @browser.link(:text, text).present?
        try(3){@browser.link(:text, 'Mercati').click}
      end
      sleep 2
    }

    # Clicca su elenco offerte
    try(3){@browser.link(:text, text).click}
    sleep 1
  end

  def create_getters
    instance_variables.each do |v|
      define_singleton_method(v.to_s.tr('@','')) do
        instance_variable_get(v)
      end
    end
  end

  def login
    pid  = Process.spawn("login.exe")
    Process.wait pid
  end

  def nome_mercato
    case mercato
    when "MSD1"      then ""
    when "MSD2"      then "_MSD2"
    when "MSD3"      then "_MSD3"
    when "MSD4"      then "_MSD4"
    when "MSD5"      then "_MSD5"
    when "MSD6"      then "_MSD6"
    end
  end

  def nome_oper(oper)
    case oper
    when "ENI SPA-OEESDAN"              then "_ENI"
    when "ENIPOWER MANTOVA SPA-OEEMSNP" then "_MN"
    when "ENIPOWER S.P.A.-OEESNPW"      then ""
    when "S.E.F. SRL-OESEFSS"           then "_SEF"
    end
  end

  def cartella_cumulati(oper)
    case oper
    when "ENI GAS E LUCE SPA-121562"    then "GL"
    when "ENI SPA-OEESDAN"              then "Eni"
    when "ENIPOWER MANTOVA SPA-OEEMSNP" then "Mantova"
    when "ENIPOWER S.P.A.-OEESNPW"      then "Enipower"
    when "S.E.F. SRL-OESEFSS"           then "Sef"
    end
  end

  def setta_operatore
    mercati       = ['MGP', 'MI1', 'MI2', 'MI3', 'MI4', 'MI5', 'MI6', 'MI7']
    oper_eni      = ['ENI SPA-OEESDAN'] 
    oper_gl       = ['ENI GAS E LUCE SPA-121562']
    all_oper_eni  = ['ENI SPA-OEESDAN', 'ENIPOWER MANTOVA SPA-OEEMSNP', 'ENIPOWER S.P.A.-OEESNPW', 'S.E.F. SRL-OESEFSS']
    all_oper      = ['ENI SPA-OEESDAN', 'ENIPOWER MANTOVA SPA-OEEMSNP', 'ENIPOWER S.P.A.-OEESNPW', 'S.E.F. SRL-OESEFSS', 'ENI GAS E LUCE SPA-121562']
    call          = caller(1,1)[0].split(" ").last

    if @societa == 'GL'
      return oper_gl
    end

    if @societa == 'ENI'
      if call.match 'cumulati'
        return all_oper_eni
      end
      if mercati.include? @mercato
        return oper_eni
      else
        return all_oper_eni
      end
    end

    if @societa == 'ALL'
      if call.match 'cumulati'
        if mercati.include? @mercato
         return all_oper
        else
          return all_oper_eni 
        end
      end
      if mercati.include? @mercato
        return oper_eni+oper_gl
      else
        return all_oper_eni
      end
    end
  end

  def check_operatore(oper)
    (['ENI SPA-OEESDAN', 'ENIPOWER MANTOVA SPA-OEEMSNP', 'ENIPOWER S.P.A.-OEESNPW', 'S.E.F. SRL-OESEFSS'].include? oper) ? 'ENI' : 'GL'
  end

  def set_path(oper)
    call_method = caller(1,1)[0].split(" ").last
    if /esitate/ =~ call_method
      (check_operatore(oper) == 'ENI') ? @path_esitate : @path_esitate_gl
    else
      (check_operatore(oper) == 'ENI') ? @path_validate : @path_validate_gl
    end
  end

end
