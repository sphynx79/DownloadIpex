module GuiUtility
  def set_calendar
    set_toggle_button_signal(@calendar_win_data, @toggle_button_data)
    set_calendar_signal(@calendar_data, @calendar_win_data, @entry_data, @toggle_button_data)

    @calendar_win_data.signal_connect("focus-out-event") do |popup, event|
      @calendar_win_data.hide
      @toggle_button_data.active = false
      false
    end
  end

  def setup_calendar calendar
    cal_window = Gtk::Window.new(:toplevel)
    cal_window.set_keep_above(true)
    cal_window.set_decorated(false)
    cal_window.set_resizable(false)
    cal_window.skip_taskbar_hint = true
    cal_window.skip_pager_hint = true
    # cal_window.set_type_hint(Gdk::Window::TYPE_HINT_DOCK)
    cal_window.events = [:focus_change_mask]
    cal_window.stick()
    cal_vbox = Gtk::Box.new(:vertical, 10)
    cal_window.add(cal_vbox)
    cal_vbox.pack_start(calendar, :expand => true, :fill => false, :padding => 0)
    return cal_window
  end

  def format_date(datetime)
    date_format = '%d/%m/%Y'
    datetime.strftime( date_format = '%d/%m/%Y')
  end

  def apply_screen_coord_correction(x, y, widget, relative_widget)
    corrected_y = y
    corrected_x = x
    rect = widget.allocation()

    screen_w = Gdk::Screen.width
    screen_h = Gdk::Screen.height

    delta_x = screen_w - (x + rect.width)
    delta_y = screen_h - (y + rect.height)
    if delta_x < 0
      corrected_x += delta_x
    end
    if corrected_x < 0
      corrected_x = 0
    end
    if delta_y < 0
      corrected_y = y - rect.height - relative_widget.allocation().height
    end
    if corrected_y < 0
      corrected_y = 0
    else
      # p corrected_x
      # p corrected_y
      return corrected_x, corrected_y
    end
  end

  def set_calendar_signal(calendar, calendar_win, entry, button)
    calendar.signal_connect("day-selected-double-click") do |widget,event|
      date_arr = calendar.date
      year = date_arr[0]
      month = date_arr[1]# + 1 # gtk : months 0-indexed, Time.gm : 1-index
      day = date_arr[2]

      if calendar
        time = Time.gm(year, month, day)
        entry.text = format_date(time)
      end
      calendar_win.hide
      button.active = false
    end
    calendar.signal_connect("day-selected") do |widget,event|
    end
    calendar.signal_connect("prev-month") do |widget,event|
      calendar.select_day(0)
    end
  end

  def set_toggle_button_signal calendar_win,button
    button.signal_connect("toggled") do
      if button.active?
        rect = button.allocation
        main_window = button.toplevel
        _j, win_x, win_y = main_window.window.origin
        cal_x = win_x + rect.x
        cal_y = win_y + rect.y + rect.height
        x, y = self.apply_screen_coord_correction(cal_x, cal_y, calendar_win, button)
        calendar_win.move(x, y)
        calendar_win.show_all()
        #@toggle_button.set_label("Hide Calendar")
      else
        calendar_win.hide
        #@toggle_button.set_label("Show Calendar")
      end
    end
  end

end
