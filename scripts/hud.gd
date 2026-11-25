extends Control
signal joystick_changed(vector: Vector2)
signal boost_changed(active: bool)
signal menu_pressed
signal online_pressed
signal customize_pressed
signal room_join_pressed(action: String, code: String, server: String)

var game_state = "menu"
var score = 0
var best = 0
var player_length = 4
var players: Array = []
var minimap_points: Array = []
var room_code = ""
var loading_progress = 0.0
var loading_tip = ""
var joystick_center = Vector2(115, 0)
var joystick_pos = Vector2.ZERO
var joystick_active = false
var boost_active = false
var joystick_touch_id = -1
var boost_touch_id = -1
var boost_rect = Rect2()
var map_rect = Rect2()
var online_code = ""
var code_edit: LineEdit
var server_edit: LineEdit
var name_edit: LineEdit
var server_url = "ws://127.0.0.1:8080"
var font: Font
var ui_scale = 1.0
var skin_label = "VERDE NEÓN"

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	font = ThemeDB.fallback_font
	code_edit = LineEdit.new()
	code_edit.placeholder_text = "Código de sala (para unirse)"
	code_edit.max_length = 8
	code_edit.visible = false
	code_edit.add_theme_font_size_override("font_size", 18)
	add_child(code_edit)
	name_edit = LineEdit.new()
	name_edit.text = "GIAN"
	name_edit.placeholder_text = "Tu nombre"
	name_edit.max_length = 14
	name_edit.add_theme_font_size_override("font_size", 18)
	add_child(name_edit)
	server_edit = LineEdit.new()
	server_edit.text = "ws://127.0.0.1:8080"
	server_edit.placeholder_text = "ws://servidor:8080"
	server_edit.visible = false
	server_edit.add_theme_font_size_override("font_size", 14)
	add_child(server_edit)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _draw():
	var s = get_viewport_rect().size
	ui_scale = clamp(s.x / 1280.0, 0.72, 1.25)
	code_edit.visible = game_state == "room"
	server_edit.visible = game_state == "room"
	name_edit.visible = game_state == "room" or game_state == "menu"
	if game_state == "menu":
		_draw_menu(s)
	elif game_state == "loading":
		_draw_loading(s)
	elif game_state == "playing":
		_draw_game_ui(s)
	elif game_state == "dead":
		_draw_game_ui(s)
		_draw_dead(s)
	elif game_state == "room":
		_draw_room(s)

func _draw_menu(s):
	_draw_panel(Rect2(s.x*0.23,s.y*0.11,s.x*0.54,s.y*0.78),Color(0.035,0.07,0.12,0.94),30)
	_draw_text("GUSANO",Vector2(s.x*0.5,s.y*0.25),64*ui_scale,Color(0.35,1,0.73),true)
	_draw_text("BATTLE",Vector2(s.x*0.5,s.y*0.32),34*ui_scale,Color(0.45,0.73,1),true)
	_draw_text("CRECE · SOBREVIVE · DOMINA LA ARENA",Vector2(s.x*0.5,s.y*0.38),16*ui_scale,Color(0.73,0.84,0.95),true)
	name_edit.position=Vector2(s.x*0.4,s.y*0.405)
	name_edit.size=Vector2(s.x*0.2,s.y*0.05)
	_draw_button(Rect2(s.x*0.35,s.y*0.46,s.x*0.3,s.y*0.09),"JUGAR · BOTS",Color(0.08,0.72,0.47))
	_draw_button(Rect2(s.x*0.35,s.y*0.57,s.x*0.3,s.y*0.09),"JUGAR ONLINE",Color(0.12,0.42,0.86))
	_draw_button(Rect2(s.x*0.35,s.y*0.68,s.x*0.3,s.y*0.09),"SKIN: "+skin_label,Color(0.35,0.27,0.65))
	_draw_text("v1.0 · JUEGO OFFLINE + MULTIJUGADOR",Vector2(s.x*0.5,s.y*0.86),13*ui_scale,Color(0.5,0.63,0.75),true)

func _draw_loading(s):
	_draw_text("GUSANO BATTLE",Vector2(s.x*0.5,s.y*0.43),44*ui_scale,Color(0.38,1,0.72),true)
	_draw_text("Preparando arena...",Vector2(s.x*0.5,s.y*0.53),18*ui_scale,Color.WHITE,true)
	var r=Rect2(s.x*0.28,s.y*0.59,s.x*0.44,14*ui_scale)
	draw_rect(r,Color(0.12,0.19,0.28),true,10)
	draw_rect(Rect2(r.position,r.size*Vector2(loading_progress,1)),Color(0.25,0.94,0.64),true,10)
	_draw_text(loading_tip,Vector2(s.x*0.5,s.y*0.72),14*ui_scale,Color(0.66,0.77,0.89),true)

func _draw_game_ui(s):
	# top HUD
	_draw_panel(Rect2(18*ui_scale,16*ui_scale,220*ui_scale,72*ui_scale),Color(0.035,0.07,0.12,0.75),16)
	_draw_text("PUNTOS",Vector2(34*ui_scale,42*ui_scale),13*ui_scale,Color(0.6,0.76,0.88))
	_draw_text(str(score),Vector2(34*ui_scale,72*ui_scale),30*ui_scale,Color(0.36,1,0.72))
	_draw_text("LARGO  "+str(player_length),Vector2(150*ui_scale,65*ui_scale),16*ui_scale,Color.WHITE)
	_draw_panel(Rect2(s.x*0.5-100*ui_scale,16*ui_scale,200*ui_scale,42*ui_scale),Color(0.035,0.07,0.12,0.72),14)
	_draw_text("GUSANO BATTLE",Vector2(s.x*0.5,43*ui_scale),17*ui_scale,Color(0.76,0.94,1),true)
	_draw_panel(Rect2(s.x-160*ui_scale,16*ui_scale,142*ui_scale,92*ui_scale),Color(0.035,0.07,0.12,0.78),14)
	_draw_text("TOP 5",Vector2(s.x-144*ui_scale,40*ui_scale),13*ui_scale,Color(0.4,1,0.74))
	var sorted=players.duplicate()
	sorted.sort_custom(func(a,b): return a.get("length",0)>b.get("length",0))
	for i in range(min(5,sorted.size())):
		_draw_text(str(i+1)+". "+str(sorted[i].get("name","Gusano")),Vector2(s.x-144*ui_scale,(61+i*15)*ui_scale),11*ui_scale,Color(0.84,0.91,1))
	# minimap left-bottom, deliberately compact
	map_rect=Rect2(14*ui_scale,s.y-102*ui_scale,106*ui_scale,82*ui_scale)
	draw_rect(map_rect,Color(0.025,0.07,0.11,0.86),true,12)
	draw_rect(map_rect,Color(0.25,0.85,0.68,0.5),false,2)
	for p in minimap_points:
		var q=map_rect.position+Vector2(p.x*map_rect.size.x,p.y*map_rect.size.y)
		draw_circle(q,2.3*ui_scale,Color(0.5,0.9,1))
	_draw_text("MAPA",Vector2(map_rect.position.x+8*ui_scale,map_rect.position.y+15*ui_scale),10*ui_scale,Color(0.56,0.8,0.91))
	# joystick visual
	var jc=Vector2(172*ui_scale,s.y-108*ui_scale)
	draw_circle(jc,58*ui_scale,Color(0.07,0.13,0.2,0.42))
	draw_circle(jc,58*ui_scale,Color(0.4,0.85,1,0.22),false,2*ui_scale)
	draw_circle(jc+joystick_pos*38*ui_scale,22*ui_scale,Color(0.22,0.8,0.97,0.68))
	# boost button
	boost_rect=Rect2(s.x-132*ui_scale,s.y-130*ui_scale,100*ui_scale,100*ui_scale)
	draw_circle(boost_rect.get_center(),50*ui_scale,Color(0.95,0.44,0.12,0.42 if boost_active else 0.27))
	draw_circle(boost_rect.get_center(),50*ui_scale,Color(1,0.7,0.3,0.7),false,3*ui_scale)
	_draw_text("⚡",boost_rect.get_center()+Vector2(0,-4*ui_scale),34*ui_scale,Color(1,0.82,0.4),true)
	_draw_text("ACELERAR",boost_rect.get_center()+Vector2(0,28*ui_scale),11*ui_scale,Color.WHITE,true)
	_draw_button(Rect2(s.x-84*ui_scale,12*ui_scale,68*ui_scale,34*ui_scale),"PAUSA",Color(0.3,0.35,0.43))

func _draw_dead(s):
	_draw_panel(Rect2(s.x*0.32,s.y*0.25,s.x*0.36,s.y*0.5),Color(0.03,0.07,0.12,0.94),24)
	_draw_text("¡TE ELIMINARON!",Vector2(s.x*0.5,s.y*0.36),30*ui_scale,Color(1,0.45,0.42),true)
	_draw_text("Puntuación: "+str(score),Vector2(s.x*0.5,s.y*0.45),22*ui_scale,Color.WHITE,true)
	_draw_button(Rect2(s.x*0.38,s.y*0.53,s.x*0.24,s.y*0.08),"REINTENTAR",Color(0.08,0.72,0.47))
	_draw_button(Rect2(s.x*0.38,s.y*0.64,s.x*0.24,s.y*0.08),"MENÚ",Color(0.25,0.38,0.55))

func _draw_room(s):
	_draw_panel(Rect2(s.x*0.28,s.y*0.15,s.x*0.44,s.y*0.70),Color(0.035,0.07,0.12,0.95),24)
	_draw_text("MULTIJUGADOR",Vector2(s.x*0.5,s.y*0.29),32*ui_scale,Color(0.38,0.92,1),true)
	_draw_text("Código de sala",Vector2(s.x*0.5,s.y*0.38),17*ui_scale,Color.WHITE,true)
	_draw_panel(Rect2(s.x*0.38,s.y*0.41,s.x*0.24,s.y*0.08),Color(0.1,0.15,0.22),12)
	_draw_text(room_code if room_code!="" else "CREAR / UNIR",Vector2(s.x*0.5,s.y*0.46),22*ui_scale,Color(0.4,1,0.72),true)
	_draw_button(Rect2(s.x*0.36,s.y*0.56,s.x*0.28,s.y*0.075),"CREAR SALA",Color(0.08,0.72,0.47))
	_draw_button(Rect2(s.x*0.36,s.y*0.655,s.x*0.28,s.y*0.075),"UNIRSE (CÓDIGO)",Color(0.12,0.42,0.86))
	_draw_button(Rect2(s.x*0.36,s.y*0.75,s.x*0.28,s.y*0.06),"VOLVER",Color(0.32,0.38,0.48))
	name_edit.position=Vector2(s.x*0.4,s.y*0.32)
	name_edit.size=Vector2(s.x*0.2,s.y*0.05)
	code_edit.position=Vector2(s.x*0.38,s.y*0.50)
	code_edit.size=Vector2(s.x*0.24,s.y*0.05)
	server_edit.position=Vector2(s.x*0.32,s.y*0.82)
	server_edit.size=Vector2(s.x*0.36,s.y*0.05)

func _draw_button(r: Rect2, text: String, color: Color):
	draw_rect(r,color,true,12)
	draw_rect(r,Color(1,1,1,0.16),false,1.0)
	_draw_text(text,r.get_center()+Vector2(0,5),17*ui_scale,Color.WHITE,true)

func _draw_panel(r: Rect2,color: Color,rad:float):
	draw_rect(r,color,true)
	draw_rect(r,Color(0.45,0.75,0.95,0.11),false,1.0)

func _draw_text(t:String,pos:Vector2,size:float,color:Color,center:bool=false):
	var f=font
	var w=f.get_string_size(t,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	draw_string(f,pos-Vector2(w*0.5 if center else 0,0),t,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func _input(event):
	if game_state == "playing":
		if event is InputEventScreenTouch and event.pressed and Rect2(get_viewport_rect().size.x-84*ui_scale,12*ui_scale,68*ui_scale,34*ui_scale).has_point(event.position):
			menu_pressed.emit()
			return
		if event is InputEventMouseButton and event.pressed and Rect2(get_viewport_rect().size.x-84*ui_scale,12*ui_scale,68*ui_scale,34*ui_scale).has_point(event.position):
			menu_pressed.emit()
			return
	if game_state != "playing":
		if event is InputEventScreenTouch and event.pressed:
			_handle_menu_touch(event.position)
		elif event is InputEventMouseButton and event.pressed:
			_handle_menu_touch(event.position)
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if boost_rect.has_point(event.position):
				boost_active=true
				boost_touch_id=event.index
				boost_changed.emit(true)
			else:
				joystick_active=true
				joystick_touch_id=event.index
				joystick_center=Vector2(172*ui_scale,get_viewport_rect().size.y-108*ui_scale)
				var delta=event.position-joystick_center
				joystick_pos=delta.limit_length(45*ui_scale)/(45*ui_scale)
				joystick_changed.emit(joystick_pos)
		else:
			if event.index==joystick_touch_id:
				joystick_active=false
				joystick_pos=Vector2.ZERO
				joystick_changed.emit(Vector2.ZERO)
				joystick_touch_id=-1
			if event.index==boost_touch_id:
				boost_active=false
				boost_changed.emit(false)
				boost_touch_id=-1
			queue_redraw()
	elif event is InputEventScreenDrag:
		if event.index==boost_touch_id:
			return
		if event.index==joystick_touch_id:
			var delta=event.position-joystick_center
			joystick_pos=delta.limit_length(45*ui_scale)/(45*ui_scale)
			joystick_changed.emit(joystick_pos)
			queue_redraw()
	elif event is InputEventMouseButton:
		if event.pressed:
			if boost_rect.has_point(event.position):
				boost_active=true
				boost_changed.emit(true)
			else:
				joystick_active=true
				joystick_center=event.position
		else:
			joystick_active=false
			joystick_pos=Vector2.ZERO
			boost_active=false
			boost_changed.emit(false)
			joystick_changed.emit(Vector2.ZERO)
	elif event is InputEventMouseMotion and joystick_active:
		joystick_pos=(event.position-joystick_center).limit_length(45*ui_scale)/(45*ui_scale)
		joystick_changed.emit(joystick_pos)
		queue_redraw()

func _handle_menu_touch(p:Vector2):
	var s=get_viewport_rect().size
	if game_state=="menu":
		if Rect2(s.x*0.35,s.y*0.46,s.x*0.3,s.y*0.09).has_point(p): menu_pressed.emit()
		elif Rect2(s.x*0.35,s.y*0.57,s.x*0.3,s.y*0.09).has_point(p): online_pressed.emit()
		elif Rect2(s.x*0.35,s.y*0.68,s.x*0.3,s.y*0.09).has_point(p): customize_pressed.emit()
	elif game_state=="room":
		if Rect2(s.x*0.36,s.y*0.56,s.x*0.28,s.y*0.075).has_point(p): room_join_pressed.emit("CREATE","",server_edit.text.strip_edges())
		elif Rect2(s.x*0.36,s.y*0.655,s.x*0.28,s.y*0.075).has_point(p): room_join_pressed.emit("JOIN",code_edit.text.strip_edges().to_upper(),server_edit.text.strip_edges())
		elif Rect2(s.x*0.36,s.y*0.75,s.x*0.28,s.y*0.06).has_point(p): menu_pressed.emit()
	elif game_state=="dead":
		if Rect2(s.x*0.38,s.y*0.53,s.x*0.24,s.y*0.08).has_point(p): menu_pressed.emit()
		elif Rect2(s.x*0.38,s.y*0.64,s.x*0.24,s.y*0.08).has_point(p): online_pressed.emit()
