# frozen_string_literal: true

require 'file-tail'

$log = ''
$mutex = Mutex.new

class SchedulerGui < Gtk::Window

  def initialize
    super
    set_border_width 15
    set_default_size 550, 300
    set_window_position :center

    init_ui
  end

  def init_ui
    grid = Gtk::Grid.new
    grid.set_column_spacing 5
    grid.set_row_spacing 5

    title = Gtk::Label.new "Scheduler Log:"

    align1 = Gtk::Alignment.new 0, 0, 0, 0
    align1.add title
    grid.attach align1, 0, 0, 1, 1

    # Creo il bottone per login Ipex
    ipex_btn = Gtk::ToggleButton.new :label => "Ipex"
    ipex_btn.set_size_request 70, 30

    # Creo il bottone per login PCE
    pce_btn = Gtk::ToggleButton.new :label => "Pce"
    pce_btn.set_size_request 70, 30

    # Creo il bottone start
    start_btn = Gtk::Button.new :label => "Start"
    start_btn.set_size_request 70, 30

    # Creo il frame per contiene la mia textview
    frame = Gtk::Frame.new
    frame.set_hexpand true
    frame.set_vexpand true
    # Inserisco il frame nella griglia
    grid.attach frame, 0, 1, 3, 3

    # Inserisco bottoni PCE e IPEX nella griglia
    vbox = Gtk::Box.new :vertical, 4
    vbox.add ipex_btn
    vbox.add pce_btn
    grid.attach vbox, 3, 1, 1, 1

    # Inserisco bottoni Start nella griglia
    grid.attach start_btn, 3, 4, 1, 1

    # Creo la mia textview, che contiene il mii log
    create_text_view(frame)

    add grid

    set_title "Scheduler"

    signal_connect "destroy" do
      Thread.list.each { |t| t.kill if t != Thread.main }
      Gtk.main_quit
    end

    ipex_btn.signal_connect("toggled") do |button|
      on_button_toggled(button)
    end

    pce_btn.signal_connect("toggled") do |button|
      on_button_toggled(button)
    end

    start_btn.signal_connect("clicked") do |button|
      on_button_start(button)
    end

    show_all
  end

  private

  def create_text_view(frame)
    swindow = Gtk::ScrolledWindow.new
    textview = Gtk::TextView.new
    swindow.add(textview)
    frame.add(swindow)
    timeout = setup_scroll(textview, swindow)
    textview.signal_connect("destroy") { GLib::Source.remove(timeout) }
  end

  def setup_scroll(textview, swindow)
    buffer = textview.buffer
    end_iter = buffer.end_iter
    buffer.create_mark("scroll", end_iter, true)
    last_vadjustment = 0.0
    count = 5
    return GLib::Timeout.add(1800) do # scroll to bottom
             # Get end iterator
             end_iter = buffer.end_iter
             # and insert some text at it, the iter will be revalidated
             # after insertion to point to the end of inserted text
             buffer.insert(end_iter, $log)
             $mutex.synchronize do
               $log = ''
             end
             if count == 5
               if swindow.vadjustment.value < last_vadjustment
                 GLib::Source::REMOVE
                 count = 0
               end
             end
             last_vadjustment = swindow.vadjustment.value

             # Move the iterator to the beginning of line, so we don't scroll
             # in horizontal direction
             end_iter.line_offset = 0
             # and place the mark at iter. the mark will stay there after we
             # insert some text at the end because it has left gravity.
             mark = buffer.get_mark("scroll")
             buffer.move_mark(mark, end_iter)
             # Scroll the mark onscreen.
             #
             unless count < 5
               textview.scroll_mark_onscreen(mark)
             else
               count+= 1
             end
             # Shift text back if we got enough to the right.
             GLib::Source::CONTINUE
           end
  end

  def on_button_toggled(button)
    label = button.label

    if button.active?
      state = "on"
    else
      state = "off"
    end

    if state == 'on'
      p "on"
      login_dialog(label)
    else
      disconnect_dialog(label)
    end
  end

  def login_dialog(label)
    if label == 'Ipex'
      p "ipex"
      ipex_dialog
    else
      p "pce"
    end
  end

  def ipex_dialog
    dialog = Gtk::Dialog.new(:title =>"Login Ipex",
                             :parent => self,
                             :flags => :modal,
                             :buttons => [[Gtk::Stock::OK, Gtk::ResponseType::OK],
                                          [Gtk::Stock::CANCEL, Gtk::ResponseType::CANCEL]])

    content_area = dialog.content_area
    hbox = initialize_ipex_dialog_interface
    content_area.pack_start(hbox)
    dialog.set_border_width 6
    # dialog.set_default_size(300, 300)

    response = dialog.run

    dialog.set_has_focus false
    if response == :ok
      p "ok"
    end

    dialog.destroy
  end

  def initialize_ipex_dialog_interface
    hbox = Gtk::Box.new(:horizontal, 8)
    entry = Gtk::Entry.new
    entry.margin_bottom = 5
    entry.placeholder_text = 'Password'
    # entry.set_can_focus false
    entry.set_can_focus false
    entry.signal_connect("enter_notify_event") do |entry|
      entry.set_can_focus true
    end
    # entry.set_placeholder_text "ciao"
    # binding.pry 
    # table, @dialog_entry1, @dialog_entry2 = initialize_grid_with_entries
    # hbox.pack_start(table, :expand => false, :fill => false, :padding => 0)
    hbox.pack_start(entry, :expand => true, :fill => true, :padding => 0)
    hbox.show_all
    hbox

  end

  def initialize_grid_with_entries
    table = Gtk::Grid.new
    table.row_spacing = 4
    table.column_spacing = 4

    label = Gtk::Label.new("_Entry 1", :use_underline => true)
    table.attach(label, 0, 0, 1, 1)

    entry1 = Gtk::Entry.new
    table.attach(entry1, 1, 0, 1, 1)
    label.set_mnemonic_widget(entry1)

    label = Gtk::Label.new("E_ntry 2", :use_underline => true)
    table.attach(label, 0, 1, 1, 1)

    entry2 = Gtk::Entry.new
    table.attach(entry2, 1, 1, 1, 1)
    label.set_mnemonic_widget(entry2)

    [table, entry1, entry2]
  end

  def disconnect_dialog(label)
  end

  def on_button_start(button)
    th = Thread.new do
      begin
        File.open("mio.log", "r") do |log|
          log.extend(File::Tail)
          log.interval = 2
          log.backward(20)
          log.tail {|line|
            $mutex.synchronize do
              $log += line
            end
          }
        end
      rescue Exception => e
        puts "EXCEPTION: #{e.inspect}"
        puts "MESSAGE: #{e.message}"
        ap e.backtrace
      end
    end
  end

end
