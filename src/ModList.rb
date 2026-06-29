require "wx/core"

require "pathname"

exe_path = Pathname.new(ENV["OCRAN_EXECUTABLE"]) if ENV["OCRAN_EXECUTABLE"]
$game_dir = exe_path ? exe_path.dirname : Pathname.new(__dir__)
$game_exe = $game_dir.entries.find { |f| f.extname == ".exe" && f.basename != exe_path.basename } if exe_path # makes this windows only
$bepinex_enabled = ($game_dir / "winhttp.dll").exist?

def toggle_file(filename, prev_enabled = true)
  filepath = $game_dir / filename.to_s.gsub("_disabled", "")
  disabled_filepath = filepath.sub_ext("_disabled#{filepath.extname}")

  src, dest = if filepath.exist? && prev_enabled
      [filepath, disabled_filepath]
    elsif disabled_filepath.exist?
      [disabled_filepath, filepath]
    else
      return
    end
  src.rename(dest)
end

$mod_name_to_dlls = {}
$mod_state = []

plugin_folder = $game_dir / "BepInEx" / "plugins"
plugin_folder.each_child do |mod_folder|
  name = mod_folder.basename.to_s
  dlls = mod_folder.each_child.filter_map { |f| f.relative_path_from($game_dir) if f.extname == ".dll" }
  $mod_name_to_dlls[name] = dlls

  enabled = !dlls.first.basename(".dll").to_s.end_with?("_disabled")
  $mod_state.append(enabled)
end if plugin_folder.exist?

unless ($game_dir / "winhttp.dll").exist? then toggle_file("winhttp.dll") end

Wx::App.run do
  icon_path = Pathname.new(__dir__).dirname / "assets" / "icon.ico"

  # Pathname.new(__dir__).dirname.find { |f| p f }

  frame = Wx::Frame.new(nil, title: "Koki Mod Manager")
  frame.set_background_colour(Wx::WHITE)
  frame.set_icon(Wx::Icon.new(icon_path.to_s))
  frame.set_focus

  checklist = Wx::CheckListBox.new(frame, style: Wx::Border::BORDER_NONE, choices: $mod_name_to_dlls.keys)
  checklist.font = checklist.font.scale(1.25)
  $mod_state.each_with_index { |val, i| checklist.check(i, val) }
  evt_checklistbox(checklist) do |event|
    check_idx = event.get_int
    check_val = checklist.is_checked(check_idx)
    $mod_state[check_idx] = check_val

    $mod_name_to_dlls[event.get_string].each { |f| toggle_file(f, !check_val) }
  end

  launch_game = Wx::Button.new(frame, label: "Start Game")

  if exe_path
    exe_path = ".\\#{$game_exe.basename}"
    evt_button(launch_game) { Process.detach(spawn([exe_path, exe_path])) }
  end

  main_layout = Wx::VBoxSizer.new
  main_layout.add(checklist, Wx::SizerFlags.new.expand.proportion(1).double_border)
  main_layout.add(launch_game, Wx::SizerFlags.new.expand.border)

  frame.set_sizer(main_layout)
  frame.evt_close do
    toggle_file("winhttp.dll")
    frame.destroy
  end
  frame.show
end
