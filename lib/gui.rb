require_relative 'gui_utility.rb'

ICON =  File.join(File.dirname(__FILE__), '/icon/Calendar.png')

class Gui < Gtk::Window
  include GuiUtility

  def initialize
    super
    set_title "Scaricamento Esiti"
    init_ui
    set_default_size 140, 200
    set_border_width 10
    set_keep_above(true)
    set_resizable(false)
    set_window_position :center
    signal_connect "destroy" do
      Thread.list.each { |t| t.kill if t != Thread.main }
      Gtk.main_quit
    end
    show_all
  end

  def init_ui
    make_menu

    # StackSwitcher
    stack = Gtk::Stack.new
    stack.set_transition_type(:slide_left_right)
    sw = Gtk::StackSwitcher.new
    sw.halign="center"
    sw.set_stack(stack)
    sw.margin_top = 10

    # Stack Ipex
    ipex = stack_ipex
    stack.add_named(ipex, "IPEX")
    stack.child_set_property(ipex, "title", "IPEX")

    # Stack PCE
    pce = stack_pce
    stack.add_named(pce, "PCE")
    stack.child_set_property(pce, "title", "PCE")

    # Frame selezione data data
    frame_data             = Gtk::Frame.new()
    frame_data.shadow_type = :in
    frame_data.margin_top  = 10
    @entry_data            = Gtk::Entry.new
    @calendar_data         = Gtk::Calendar.new
    @toggle_button_data    = Gtk::ToggleButton.new()
    @image_calendar        = Gtk::Image.new(:file => ICON)
    @calendar_win_data     = setup_calendar @calendar_data
    @toggle_button_data.set_margin_left(10)
    @toggle_button_data.set_size_request 32, 26
    @toggle_button_data.set_image @image_calendar
    @entry_data.width_chars = 15
    set_calendar
    hbox_data = Gtk::Box.new(:horizontal, 10)
    hbox_data.add(@entry_data)
    hbox_data.add(@toggle_button_data)
    hbox_data.margin = 10

    # ComboBox selezione società
    @comboSocieta  = Gtk::ComboBoxText.new()
    @comboSocieta.append_text("ALL")
    @comboSocieta.append_text("ENI")
    @comboSocieta.append_text("GL")
    @comboSocieta.active = 0
    @comboSocieta.set_margin_left(10)
    hbox_data.add(@comboSocieta)


    frame_data.add(hbox_data)

    # Bottone avvio
    @button_avvio  = Gtk::Button.new(:label => "Avvio")
    @button_avvio.margin_top = 10

    # Grilgia principale
    grid = Gtk::Grid.new
    grid.set_column_spacing 5
    grid.attach frame_data, 0, 0, 3, 1
    grid.attach sw, 0, 1, 3, 1
    grid.attach stack, 0, 3, 3, 1
    grid.attach @button_avvio, 0, 4, 3, 1

    add grid

    # Signal
    @button_avvio.signal_connect("clicked"){
      # Disabilito il bottone start
      @button_avvio.sensitive = false

      if  stack.visible_child_name == "IPEX"
        require File.join(File.dirname(__FILE__), 'ipex.rb')
        sito               = (@radiobuttonsito1.group.select { |v| v.active?  == true })[0].label == "Ipex" ? nil :  (@radiobuttonsito1.group.select { |v| v.active? == true })[0].label
        mercato            = @comboMercato.active_iter[0]
        data               = @entry_data.text
        prezzo_is_active   = @checkBoxPrezzo.active?
        offerte_is_active  = @checkBoxOfferte.active?
        cumulati_is_active = @checkBoxCumulati.active?
        societa            = @comboSocieta.active_iter[0]
        ipex = Ipex.new(sito, mercato, data, prezzo_is_active, offerte_is_active, cumulati_is_active, societa)
        t = Thread.new do
          ipex.start_from_gui(@button_avvio, self)
        end
        t.abort_on_exception = true
      else
        require File.join(File.dirname(__FILE__), 'pce.rb')
        data                 = @entry_data.text
        pos_net              = @checkBoxPosNet.active?
        prog_fisica          = @checkBoxProgrFisica.active? 
        liq_giornaliera      = @checkBoxLiqGiornaliera.active?
        elenc_offerte        = @checkBoxElOfferte.active?
        societa              = @comboSocieta.active_iter[0]
        pce = Pce.new(data, pos_net, prog_fisica, liq_giornaliera, elenc_offerte, societa)
        t = Thread.new do
          pce.start(@button_avvio, self)
        end
        t.abort_on_exception = true

      end
    }
  end

  def stack_ipex
    # ComboBox selezione mercato
    @comboMercato  = Gtk::ComboBoxText.new()
    ["MGP", "MI1", "MI2", "MI3", "MI4", "MI5", "MI6", "MI7", "MSD1", "MSD2", "MSD3", "MSD4", "MSD5", "MSD6"].each do |e|
      @comboMercato.append_text(e)
    end
    @comboMercato.active = 0
    @comboMercato.valign = "center"
    @comboMercato.halign = "start"
    @comboMercato.margin_left = 10
    @comboMercato.set_size_request 104, -1

    # Checkbox per cosa deve scaricare
    @checkBoxuncheck    = Gtk::CheckButton.new("All")
    @checkBoxPrezzo     = Gtk::CheckButton.new("Prezzo")
    @checkBoxOfferte    = Gtk::CheckButton.new("Offerte")
    @checkBoxCumulati   = Gtk::CheckButton.new("Cumulati")
    @checkBoxuncheck.set_active  1
    @checkBoxPrezzo.set_active   1
    @checkBoxOfferte.set_active  1
    @checkBoxCumulati.set_active 1
    hbox_checbox = Gtk::Box.new(:vertical, 8)
    hbox_checbox.homogeneous = true
    hbox_checbox.margin_top  = 12
    hbox_checbox.add(@checkBoxuncheck)
    hbox_checbox.add(@checkBoxPrezzo)
    hbox_checbox.add(@checkBoxOfferte)
    hbox_checbox.add(@checkBoxCumulati)

    # Separator sopra scelta sito ipex
    separator = Gtk::Separator.new(:horizontal)
    separator.set_margin_top(10)
    separator.set_margin_left(10)
    separator.set_margin_right(10)

    # RadioButton per scelta sito ipex
    @radiobuttonsito1   = Gtk::RadioButton.new(:label => "Ipex")
    @radiobuttonsito2   = Gtk::RadioButton.new(:member => @radiobuttonsito1, :label => "Ipex2")
    @radiobuttonsito3   = Gtk::RadioButton.new(:member => @radiobuttonsito1, :label => "Ipex3")
    @radiobuttonsito4   = Gtk::RadioButton.new(:member => @radiobuttonsito1, :label => "Ipex4")
    # Hbox contiene i miei RadioButton
    hbox_radio = Gtk::Box.new(:horizontal, 10)
    hbox_radio.margin_top = 15
    hbox_radio.border_width = 10
    hbox_radio.add(@radiobuttonsito1)
    hbox_radio.add(@radiobuttonsito2)
    hbox_radio.add(@radiobuttonsito3)
    hbox_radio.add(@radiobuttonsito4)

    # Griglia principale IPEX
    table_ipex = Gtk::Grid.new
    table_ipex.attach(@comboMercato, 0, 0, 1, 1)
    table_ipex.attach(hbox_checbox, 1, 0, 1, 4)
    table_ipex.attach(separator, 0, 5, 2, 1)
    table_ipex.attach(hbox_radio, 0, 6, 2, 1)

    # Frame che contiene lo stack ipex
    frame_ipex = Gtk::Frame.new()
    frame_ipex.shadow_type = :in
    frame_ipex.add(table_ipex)

    # Signal
    @checkBoxuncheck.signal_connect('toggled') do |w|
      if w.active?
        [ @checkBoxPrezzo, @checkBoxOfferte, @checkBoxCumulati].each do |y|
          y.set_active true
        end
      else
        [@checkBoxPrezzo, @checkBoxOfferte, @checkBoxCumulati].each do |y|
          y.set_active false
        end
      end
    end

    return frame_ipex
  end

  def stack_pce
    # CheckBox per cosa deve scaricare da PCE
    @checkBoxuncheckPce     = Gtk::CheckButton.new("All")
    @checkBoxPosNet         = Gtk::CheckButton.new("Posizioni Nette")
    @checkBoxProgrFisica    = Gtk::CheckButton.new("Programmazioni Fisica")
    @checkBoxLiqGiornaliera = Gtk::CheckButton.new("Liquidazione giornaliera")
    @checkBoxElOfferte      = Gtk::CheckButton.new("Elenco Offerte")
    # Attivo tutti i checkbox PCE
    @checkBoxuncheckPce.set_active     1
    @checkBoxPosNet.set_active         1
    @checkBoxProgrFisica.set_active    1
    @checkBoxLiqGiornaliera.set_active 1
    @checkBoxElOfferte.set_active      1

    # Vbox contiene i miei checkbox PCE
    hbox_checbox = Gtk::Box.new(:vertical, 8)
    hbox_checbox.homogeneous = true
    hbox_checbox.margin_top  = 12
    hbox_checbox.add(@checkBoxuncheckPce)
    hbox_checbox.add(@checkBoxPosNet)
    hbox_checbox.add(@checkBoxProgrFisica)
    hbox_checbox.add(@checkBoxLiqGiornaliera)
    hbox_checbox.add(@checkBoxElOfferte)
    hbox_checbox.margin_left   = 10
    hbox_checbox.margin_bottom = 20

    # Frame che contiene lo stack PCE
    frame_pce = Gtk::Frame.new
    frame_pce.shadow_type = :in
    frame_pce.add(hbox_checbox)

    # Signal
    @checkBoxuncheckPce.signal_connect('toggled') do |w|
      if w.active?
        [@checkBoxPosNet, @checkBoxProgrFisica, @checkBoxLiqGiornaliera, @checkBoxElOfferte].each do |y|
          y.set_active true
        end
      else
        [@checkBoxPosNet, @checkBoxProgrFisica, @checkBoxLiqGiornaliera, @checkBoxElOfferte].each do |y|
          y.set_active false
        end
      end
    end

    return frame_pce
  end

  def make_menu
    # set config theme
    cfg_path = "#{ENV['HOME']}\\.gtkconfig"
    if File.exists?(cfg_path)
      config_theme = IO.read(cfg_path).split('=')[1].strip
    else
      config_theme = 'Default'
      IO.write(cfg_path,  "gtk_theme_name = Default")
    end
    t = Gtk::Settings.default
    if /\(dark\)/  =~  config_theme
      t.set_gtk_application_prefer_dark_theme(true)
    else
      t.set_gtk_application_prefer_dark_theme(false)
    end
    unless /Defaul/  =~  config_theme
      t.gtk_theme_name = config_theme.sub(/\(dark\)/,"")
    end

    # set header
    header = Gtk::HeaderBar.new
    button = Gtk::Button.new()
    icon   = Gio::ThemedIcon.new("open-menu-symbolic")
    image  = Gtk::Image.new(:icon => icon, :size => :button)
    header.set_show_close_button(true)
    header.set_has_subtitle(false)
    button.add(image)
    header.pack_start(button)
    set_titlebar(header)

    themes = %w{Default
                Default(dark)
                Ashes
                Ashes(dark)
                OSX-Arc-Shadow
                OSX-Arc-White
                Zukitwo
                Zukitwo(dark)
    }
    # set popover
    pop_box = Gtk::Box.new(:vertical, 0)
    rdo_btn = Gtk::RadioButton.new(:label => "Default")
    themes.each{|t|
      b = Gtk::RadioButton.new(:member => rdo_btn, :label => t)
      if t == config_theme
        b.set_active(true)
      end
      pop_box.pack_start(b, :expand => false, :fill => false, :padding => 0)
    }
    pop = Gtk::Popover.new(button)
    pop.set_size_request(200, -1)
    pop.vexpand = true
    pop.border_width = 6
    sw = Gtk::ScrolledWindow.new
    sw.set_shadow_type(:in)
    sw.set_policy(:never, :automatic)
    sw.add(pop_box)
    pop.add(sw)

    button.signal_connect("clicked"){
      if pop.visible?
        popover.hide()
      else
        pop.show_all()
      end
    }


    rdo_btn.group.each{|b|
      b.signal_connect("toggled"){|x|
        label = x.label
        if x.active?
          t = Gtk::Settings.default
          if /\(dark\)/  =~  label
            t.set_gtk_application_prefer_dark_theme(true)
          else
            t.set_gtk_application_prefer_dark_theme(false)
          end
          unless /Defaul/  =~  label
            t.gtk_theme_name = label.sub(/\(dark\)/,"")
          end
          reshow_with_initial_size
          IO.write(cfg_path,  "gtk_theme_name = #{label}")
          if /Defaul/  =~  label
            pid = Process.spawn("rubyw main.rbw")
            Process.wait pid
            system("taskkill.exe /f /pid #{Process.pid}")
          end

        end
      }
    }

  end
end

