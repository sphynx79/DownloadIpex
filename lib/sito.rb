# frozen_string_literal: true

class Sito

  def start_browser
    prefs = {
      prompt_for_download: true
    }
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--disable-gpu')
    options.add_argument('--disable-internal-flash')
    options.add_argument('--disable-bundled-ppapi-flash')
    options.add_argument('--disable-flash-sandbox')
    options.add_argument('--no-sandbox')
    options.add_argument('--fast-start')
    options.add_argument('--disable-translate')
    options.add_argument('--disable-infobars')
    options.add_preference(:download, prefs)

    browser = Watir::Browser.new :chrome, options: options
    browser.driver.manage.timeouts.implicit_wait = 15
    browser.driver.manage.timeouts.page_load = 20
    Watir.default_timeout = 15
    return browser
  end

  def try(n)
    begin
      tries ||= n
      # p "tries ##{n}"
      yield
    rescue => e
      sleep 1
      unless (tries -= 1).zero?
        retry
      else
        raise e
      end
    end
  end

  def save_file(filepath)
    if $PROGRAM_NAME == "scheduler"
      $risposta = "OK"
    end

    if File.exist?(filepath) && $risposta == ""
      messagio_sovrascrivere_file
      while $risposta == ""
        sleep 0.2
      end
    end

    if $risposta == "OK"
      FileUtils.rm_f(filepath)
    elsif $risposta == "cancel"
      @browser.close
      raise "Non sovrascrivo i file"
      # exit!
    end
    sleep 2

    pid  = Process.spawn("save_as.exe \"#{filepath}\"")
    Process.wait pid

    ext = filepath.sub("xls","crdownload")
    i = 0
    while i < 20
      break unless File.exist?(ext)
      sleep 0.5
      i += 1
    end
  end

  def messagio_sovrascrivere_file
    GLib::Idle.add do
      dialog = Gtk::Dialog.new(:title => "Sovrascrivere File!")
      dialog.set_default_size(300, 140)
      dialog.set_window_position :center
      dialog.set_keep_above(true)
      label = Gtk::Label.new("File già presenti si vuole sovrascivere?")
      label.set_margin_top(36)
      dialog.child.add(label)

      dialog.add_button("SI", Gtk::ResponseType::OK)
      dialog.add_button("NO", Gtk::ResponseType::CANCEL)
      dialog.set_default_response(Gtk::ResponseType::CANCEL)

      dialog.signal_connect("response") do |widget, response|
        case response
        when Gtk::ResponseType::OK     then $risposta = "OK"
        when Gtk::ResponseType::CANCEL then $risposta = "cancel"
        when Gtk::ResponseType::CLOSE  then dialog.destroy
        end
      end
      dialog.show_all
      dialog.run
      dialog.destroy
      false
    end
  end

  def messaggio(parent, tipo, msg)
    GLib::Idle.add do
      msg = msg.gsub("<","").gsub(">","")
      dialog = Gtk::MessageDialog.new(:title => "#{tipo}", :parent => parent, :flags => :modal, :buttons_type => :ok, :message => "<big><b>#{msg}</b></big>")
      dialog.set_use_markup(true)
      dialog.set_window_position :center
      dialog.set_keep_above(true)

      if msg.match("correttamente")
        dialog.message_type= :info
        image  = Gtk::Image.new(:icon_name => "emblem-ok", :size => :dialog)
      else
        dialog.message_type= :warning
        image  = Gtk::Image.new(:icon_name => "dialog-warning", :size => :dialog)
      end
      dialog.set_image(image)

      dialog.show_all
      dialog.run
      dialog.destroy
      false
    end
  end

end
