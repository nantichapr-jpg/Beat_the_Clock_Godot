extends Control

enum Language { EN, TH }

const CARD_IMAGE_NAMES: Array[String] = [
    "Unicorn", "Rocket", "Dog", "Ball", "Pizza", "Controller"
]

const IMAGE_PATHS := {
    "Unicorn": "res://assets/unicorn2.png",
    "Rocket": "res://assets/Rocket2.png",
    "Dog": "res://assets/Dog2.png",
    "Ball": "res://assets/Ball2.png",
    "Pizza": "res://assets/Pizza2.png",
    "Controller": "res://assets/Controller2.png",
}

const TEXTS := {
    Language.EN: {
        "game_title": "Beat the Clock!",
        "how_to_play_title": "HOW TO PLAY:",
        "how_to_play_desc": "• Flip two cards at a time to find matching pairs.\n• Find all 6 matching pairs before time runs out!\n• Choose timed mode or Infinite mode for casual practice.",
        "select_mode": "Select Mode to Start:",
        "mode_30s": "30 Seconds Mode",
        "mode_60s": "1 Minute Mode",
        "mode_inf": "Infinite Time Mode",
        "gameplay_title": "Match the Pairs!",
        "time_left": "Time Left: %ds",
        "time_infinite": "Time: Infinite",
        "matches": "Matches: %d/%d",
        "main_menu": "Main Menu",
        "time_up_title": "Time is Up!",
        "time_up_msg": "Out of time! Want to try again?",
        "win_title": "YOU WON!",
        "win_msg": "Congratulations! You matched all pairs!",
        "play_again": "Play Again",
        "cancel": "Cancel",
        "lang_btn": "ภาษาไทย (TH)",
        "card_hint": "?"
    },
    Language.TH: {
        "game_title": "Beat the Clock!",
        "how_to_play_title": "วิธีการเล่น:",
        "how_to_play_desc": "• เปิดการ์ดครั้งละ 2 ใบเพื่อหาคู่ภาพที่เหมือนกัน\n• จับคู่ภาพทั้ง 6 คู่ให้ครบก่อนหมดเวลา!\n• เลือกโหมดจับเวลา หรือโหมดไม่จำกัดเวลาเพื่อฝึกเล่นแบบสบาย ๆ",
        "select_mode": "เลือกโหมดเพื่อเริ่มเล่น:",
        "mode_30s": "โหมด 30 วินาที",
        "mode_60s": "โหมด 1 นาที",
        "mode_inf": "โหมดไม่จำกัดเวลา",
        "gameplay_title": "จับคู่ภาพที่เหมือนกัน!",
        "time_left": "เวลาที่เหลือ: %d วินาที",
        "time_infinite": "เวลา: ไม่จำกัด",
        "matches": "จับคู่ได้: %d/%d",
        "main_menu": "เมนูหลัก",
        "time_up_title": "หมดเวลา!",
        "time_up_msg": "หมดเวลาแล้ว! ต้องการลองใหม่อีกครั้งไหม?",
        "win_title": "คุณชนะแล้ว!",
        "win_msg": "ยินดีด้วย! คุณจับคู่ภาพได้ครบทั้งหมดแล้ว!",
        "play_again": "เล่นอีกครั้ง",
        "cancel": "ยกเลิก",
        "lang_btn": "English (EN)",
        "card_hint": "?"
    }
}

var current_lang: Language = Language.EN
var deck: Array[String] = []
var card_buttons: Array[Button] = []
var card_icons: Array[TextureRect] = []
var flipped_indices: Array[int] = []

var matched_pairs := 0
var game_time := 30.0
var time_left := 30.0
var is_infinite := false
var is_playing := false
var is_checking_match := false

var menu_container: VBoxContainer
var game_container: VBoxContainer
var timer_label: Label
var score_label: Label
var grid_container: GridContainer
var game_timer: Timer

var title_label_ref: Label
var how_to_play_label_ref: Label
var select_mode_label_ref: Label
var btn_30s_ref: Button
var btn_60s_ref: Button
var btn_inf_ref: Button
var lang_btn_ref: Button
var game_title_ref: Label
var menu_btn_ref: Button


func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _build_ui()
    show_start_menu()


func get_txt(key: String) -> String:
    return TEXTS[current_lang].get(key, "")


func make_style(bg: Color, border: Color, border_width: int = 2, radius: int = 14) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = bg
    style.border_color = border
    style.set_border_width_all(border_width)
    style.set_corner_radius_all(radius)
    return style


func _apply_font(control: Control, size: int) -> void:
    var font := load("res://fonts/NotoSansThai-Regular.ttf") as Font
    if font:
        control.add_theme_font_override("font", font)
    control.add_theme_font_size_override("font_size", size)


func _build_ui() -> void:
    # Background
    var bg := ColorRect.new()
    bg.color = Color("#181825")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(bg)

    # Main menu
    menu_container = VBoxContainer.new()
    menu_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu_container.alignment = BoxContainer.ALIGNMENT_CENTER
    menu_container.add_theme_constant_override("separation", 12)
    menu_container.add_theme_constant_override("margin_left", 24)
    menu_container.add_theme_constant_override("margin_right", 24)
    add_child(menu_container)

    lang_btn_ref = Button.new()
    lang_btn_ref.text = get_txt("lang_btn")
    lang_btn_ref.custom_minimum_size = Vector2(220, 44)
    lang_btn_ref.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    _apply_font(lang_btn_ref, 17)
    lang_btn_ref.add_theme_stylebox_override("normal", make_style(Color("#2a2a3c"), Color("#bd93f9"), 2, 12))
    lang_btn_ref.pressed.connect(_toggle_language)
    menu_container.add_child(lang_btn_ref)

    var logo_rect := TextureRect.new()
    logo_rect.custom_minimum_size = Vector2(150, 150)
    logo_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    logo_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    logo_rect.texture = load("res://assets/logo.png") as Texture2D
    logo_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    menu_container.add_child(logo_rect)

    title_label_ref = Label.new()
    title_label_ref.text = get_txt("game_title")
    title_label_ref.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _apply_font(title_label_ref, 36)
    title_label_ref.add_theme_color_override("font_color", Color("#ffffff"))
    menu_container.add_child(title_label_ref)

    var how_to_play_box := PanelContainer.new()
    how_to_play_box.custom_minimum_size = Vector2(520, 0)
    how_to_play_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    how_to_play_box.add_theme_stylebox_override(
        "panel",
        make_style(Color("#2a2a3c"), Color("#bd93f9"), 2, 14)
    )

    how_to_play_label_ref = Label.new()
    how_to_play_label_ref.text = get_txt("how_to_play_title") + "\n" + get_txt("how_to_play_desc")
    how_to_play_label_ref.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    how_to_play_label_ref.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    how_to_play_label_ref.custom_minimum_size = Vector2(480, 120)
    _apply_font(how_to_play_label_ref, 16)
    how_to_play_label_ref.add_theme_color_override("font_color", Color("#f8f8f2"))
    how_to_play_box.add_child(how_to_play_label_ref)
    menu_container.add_child(how_to_play_box)

    select_mode_label_ref = Label.new()
    select_mode_label_ref.text = get_txt("select_mode")
    select_mode_label_ref.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _apply_font(select_mode_label_ref, 19)
    select_mode_label_ref.add_theme_color_override("font_color", Color("#bd93f9"))
    menu_container.add_child(select_mode_label_ref)

    btn_30s_ref = _make_mode_button(get_txt("mode_30s"))
    btn_30s_ref.pressed.connect(func(): start_game(30.0, false))
    menu_container.add_child(btn_30s_ref)

    btn_60s_ref = _make_mode_button(get_txt("mode_60s"))
    btn_60s_ref.pressed.connect(func(): start_game(60.0, false))
    menu_container.add_child(btn_60s_ref)

    btn_inf_ref = _make_mode_button(get_txt("mode_inf"))
    btn_inf_ref.pressed.connect(func(): start_game(0.0, true))
    menu_container.add_child(btn_inf_ref)

    # Gameplay
    game_container = VBoxContainer.new()
    game_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    game_container.alignment = BoxContainer.ALIGNMENT_CENTER
    game_container.add_theme_constant_override("separation", 16)
    game_container.visible = false
    add_child(game_container)

    game_title_ref = Label.new()
    game_title_ref.text = get_txt("gameplay_title")
    game_title_ref.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _apply_font(game_title_ref, 32)
    game_title_ref.add_theme_color_override("font_color", Color("#ffffff"))
    game_container.add_child(game_title_ref)

    var stats_hbox := HBoxContainer.new()
    stats_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
    stats_hbox.add_theme_constant_override("separation", 35)
    game_container.add_child(stats_hbox)

    timer_label = Label.new()
    _apply_font(timer_label, 19)
    timer_label.add_theme_color_override("font_color", Color("#ff5555"))
    stats_hbox.add_child(timer_label)

    score_label = Label.new()
    _apply_font(score_label, 19)
    score_label.add_theme_color_override("font_color", Color("#50fa7b"))
    stats_hbox.add_child(score_label)

    grid_container = GridContainer.new()
    grid_container.columns = 3
    grid_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    grid_container.add_theme_constant_override("h_separation", 12)
    grid_container.add_theme_constant_override("v_separation", 12)
    game_container.add_child(grid_container)

    menu_btn_ref = Button.new()
    menu_btn_ref.text = get_txt("main_menu")
    menu_btn_ref.custom_minimum_size = Vector2(210, 46)
    menu_btn_ref.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    _apply_font(menu_btn_ref, 17)
    menu_btn_ref.pressed.connect(show_start_menu)
    game_container.add_child(menu_btn_ref)

    game_timer = Timer.new()
    game_timer.wait_time = 1.0
    game_timer.one_shot = false
    game_timer.timeout.connect(_on_timer_tick)
    add_child(game_timer)


func _make_mode_button(button_text: String) -> Button:
    var button := Button.new()
    button.text = button_text
    button.custom_minimum_size = Vector2(300, 50)
    button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    _apply_font(button, 18)
    button.add_theme_stylebox_override("normal", make_style(Color("#bd93f9"), Color("#e5d4ff"), 2, 12))
    button.add_theme_color_override("font_color", Color("#ffffff"))
    return button


func _toggle_language() -> void:
    if current_lang == Language.EN:
        current_lang = Language.TH
    else:
        current_lang = Language.EN
    _update_ui_language()


func _update_ui_language() -> void:
    lang_btn_ref.text = get_txt("lang_btn")
    title_label_ref.text = get_txt("game_title")
    how_to_play_label_ref.text = get_txt("how_to_play_title") + "\n" + get_txt("how_to_play_desc")
    select_mode_label_ref.text = get_txt("select_mode")
    btn_30s_ref.text = get_txt("mode_30s")
    btn_60s_ref.text = get_txt("mode_60s")
    btn_inf_ref.text = get_txt("mode_inf")
    game_title_ref.text = get_txt("gameplay_title")
    menu_btn_ref.text = get_txt("main_menu")
    update_ui_labels()


func show_start_menu() -> void:
    game_timer.stop()
    is_playing = false
    is_checking_match = false
    flipped_indices.clear()
    menu_container.visible = true
    game_container.visible = false


func start_game(selected_time: float, infinite_mode: bool) -> void:
    game_timer.stop()
    is_infinite = infinite_mode
    game_time = selected_time
    time_left = game_time
    matched_pairs = 0
    flipped_indices.clear()
    card_buttons.clear()
    card_icons.clear()
    is_playing = true
    is_checking_match = false

    menu_container.visible = false
    game_container.visible = true

    deck = CARD_IMAGE_NAMES.duplicate()
    deck.append_array(CARD_IMAGE_NAMES)
    deck.shuffle()

    for child in grid_container.get_children():
        child.queue_free()

    await get_tree().process_frame

    for i in range(deck.size()):
        var card_btn := Button.new()
        card_btn.custom_minimum_size = Vector2(150, 150)
        card_btn.text = get_txt("card_hint")
        card_btn.focus_mode = Control.FOCUS_NONE
        _apply_font(card_btn, 42)
        card_btn.add_theme_stylebox_override(
            "normal",
            make_style(Color("#282a36"), Color("#bd93f9"), 4, 14)
        )
        card_btn.add_theme_stylebox_override(
            "hover",
            make_style(Color("#34364a"), Color("#d6b8ff"), 4, 14)
        )
        card_btn.add_theme_stylebox_override(
            "pressed",
            make_style(Color("#282a36"), Color("#50fa7b"), 4, 14)
        )
        card_btn.pressed.connect(_on_card_pressed.bind(i))

        var icon_rect := TextureRect.new()
        icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        icon_rect.offset_left = 8
        icon_rect.offset_top = 8
        icon_rect.offset_right = -8
        icon_rect.offset_bottom = -8
        icon_rect.visible = false
        icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

        card_btn.add_child(icon_rect)
        grid_container.add_child(card_btn)
        card_buttons.append(card_btn)
        card_icons.append(icon_rect)

    update_ui_labels()

    if not is_infinite:
        game_timer.start()


func update_ui_labels() -> void:
    if not is_instance_valid(timer_label):
        return
    if is_infinite:
        timer_label.text = get_txt("time_infinite")
    else:
        timer_label.text = get_txt("time_left") % int(max(time_left, 0.0))
    score_label.text = get_txt("matches") % [matched_pairs, CARD_IMAGE_NAMES.size()]


func _on_timer_tick() -> void:
    if not is_playing or is_infinite:
        return

    time_left -= 1.0
    update_ui_labels()

    if time_left <= 0.0:
        game_timer.stop()
        is_playing = false
        show_end_dialog(get_txt("time_up_title"), get_txt("time_up_msg"), false)


func _on_card_pressed(index: int) -> void:
    if not is_playing or is_checking_match:
        return
    if index in flipped_indices:
        return
    if card_buttons[index].disabled:
        return

    var style_face := make_style(Color("#0d0d27"), Color("#50fa7b"), 4, 14)
    card_buttons[index].add_theme_stylebox_override("normal", style_face)
    card_buttons[index].text = ""

    var tex := load(IMAGE_PATHS[deck[index]]) as Texture2D
    if tex:
        card_icons[index].texture = tex
        card_icons[index].visible = true

    flipped_indices.append(index)

    if flipped_indices.size() == 2:
        is_checking_match = true
        _check_match()


func _check_match() -> void:
    var idx1: int = flipped_indices[0]
    var idx2: int = flipped_indices[1]

    if deck[idx1] == deck[idx2]:
        card_buttons[idx1].disabled = true
        card_buttons[idx2].disabled = true
        matched_pairs += 1
        update_ui_labels()
        flipped_indices.clear()
        is_checking_match = false

        if matched_pairs == CARD_IMAGE_NAMES.size():
            game_timer.stop()
            is_playing = false
            show_end_dialog(get_txt("win_title"), get_txt("win_msg"), true)
    else:
        await get_tree().create_timer(0.7).timeout

        if not is_inside_tree():
            return

        if is_playing and card_buttons.size() > max(idx1, idx2):
            for idx in [idx1, idx2]:
                card_buttons[idx].add_theme_stylebox_override(
                    "normal",
                    make_style(Color("#282a36"), Color("#bd93f9"), 4, 14)
                )
                card_buttons[idx].text = get_txt("card_hint")
                card_icons[idx].visible = false

        flipped_indices.clear()
        is_checking_match = false


func show_end_dialog(dialog_title: String, dialog_text: String, won: bool) -> void:
    var dialog := AcceptDialog.new()
    dialog.title = dialog_title
    dialog.dialog_text = dialog_text
    dialog.ok_button_text = get_txt("play_again")
    dialog.add_cancel_button(get_txt("cancel"))
    dialog.confirmed.connect(func():
        dialog.queue_free()
        start_game(game_time, is_infinite)
    )
    dialog.canceled.connect(func():
        dialog.queue_free()
        show_start_menu()
    )
    add_child(dialog)
    dialog.popup_centered()
