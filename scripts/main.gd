extends Node2D

const ARENA_SIZE = Vector2(2600, 1900)
const FOOD_MAX = 190
const BODY_SPACING = 18.0
const SPEED = 210.0
const BOOST_SPEED = 330.0
const BOT_COUNT = 7
const COLORS = [Color("42f5b5"),Color("ff6b85"),Color("54b8ff"),Color("ffd45a"),Color("b68cff"),Color("ff9d55"),Color("7ff3ff"),Color("f37cff"),Color("c4f36a")]

var hud
var worms: Array = []
var foods: Array = []
var camera_pos = Vector2.ZERO
var player: Dictionary
var joystick = Vector2.ZERO
var boosting = false
var boost_energy = 100.0
var score = 0
var best = 0
var loading_time = 0.0
var game_mode = "bots"
var game_started = false
var loading_tips = ["¡Come para crecer!", "Evita chocar con otros gusanos.", "Acelerar consume energía.", "Las monedas aparecen en zonas seguras.", "¡La arena es tuya!"]
var food_timer = 0.0
var sound_players: Dictionary = {}
var bg_audio: AudioStreamPlayer
var game_time = 0.0
var net: WebSocketPeer
var online = false
var net_timer = 0.0
var room_code = ""
var server_url = "ws://127.0.0.1:8080"
var remote_worms: Dictionary = {}
var online_player_id = ""
var network_join_code = ""
var skin_index = 0
var network_state = ""

func _ready():
	randomize()
	_create_hud()
	_make_audio()
	_create_food()
	_show_menu()

func _create_hud():
	hud = Control.new()
	hud.set_script(load("res://scripts/hud.gd"))
	hud.name = "HUD"
	add_child(hud)
	hud.joystick_changed.connect(_on_joystick)
	hud.boost_changed.connect(_on_boost)
	hud.menu_pressed.connect(_on_menu_action)
	hud.online_pressed.connect(_on_online_pressed)
	hud.room_join_pressed.connect(_room_action)
	hud.customize_pressed.connect(_cycle_skin)

func _make_audio():
	for n in ["eat","boost","hit","click","start"]:
		var p=AudioStreamPlayer.new()
		p.volume_db=-8
		add_child(p)
		sound_players[n]=p
		var wav=load("res://assets/"+n+".wav")
		if wav: p.stream=wav
	bg_audio=AudioStreamPlayer.new()
	bg_audio.volume_db=-18
	add_child(bg_audio)
	bg_audio.stream=load("res://assets/ambient.wav")

func _play_sound(name:String):
	if sound_players.has(name):
		var p=sound_players[name]
		p.stop()
		p.play()

func _show_menu():
	game_started=false
	online=false
	if bg_audio: bg_audio.stop()
	hud.game_state="menu"
	hud.queue_redraw()

func _open_room_menu():
	hud.game_state="room"
	hud.room_code=""
	hud.queue_redraw()

func _cycle_skin():
	skin_index=(skin_index+1)%COLORS.size()
	hud.skin_label=["VERDE NEÓN","ROSA","AZUL","DORADO","VIOLETA","NARANJA","CYAN","MAGENTA","LIMA"][skin_index]
	_play_sound("click")
	hud.queue_redraw()

func _on_online_pressed():
	if hud.game_state=="dead":
		_show_menu()
	else:
		_open_room_menu()

func _room_action(action:String, code:String, url:String):
	# The room screen UI is wired; server URL/code entry is configurable from exported settings.
	# CREATE/JOIN connect to the companion server when configured.
	if url.strip_edges()!="" and not url.contains("TU_SERVIDOR"): server_url=url
	network_join_code=code
	if action=="CREATE":
		room_code=""
		_connect_online("CREATE")
	elif action=="JOIN":
		_connect_online("JOIN")

func _connect_online(action:String):
	if server_url.contains("TU_SERVIDOR") or server_url.strip_edges()=="":
		_hud_message("Escribe la URL de tu servidor WebSocket")
		return
	net=WebSocketPeer.new()
	var err=net.connect_to_url(server_url)
	if err!=OK:
		_hud_message("No se pudo conectar. Revisa el servidor.")
		return
	network_state=action
	game_mode="online"
	online=true
	_start_loading()

func _hud_message(msg:String):
	print(msg)

func _start_loading():
	game_started=false
	loading_time=0
	hud.game_state="loading"
	hud.loading_progress=0
	hud.loading_tip=loading_tips.pick_random()
	hud.queue_redraw()

func _start_game():
	game_started=true
	game_time=0
	score=0
	boost_energy=100
	worms.clear()
	player=_new_worm(hud.name_edit.text.strip_edges() if hud.name_edit.text.strip_edges()!="" else "GIAN",Vector2(ARENA_SIZE.x*0.5,ARENA_SIZE.y*0.5),COLORS[skin_index],true)
	worms.append(player)
	if not online:
		for i in range(BOT_COUNT):
			var pos=Vector2(randf_range(250,ARENA_SIZE.x-250),randf_range(250,ARENA_SIZE.y-250))
			worms.append(_new_worm(["PIXEL","LUNA","NOVA","RAYO","MANGO","KIRA","ZED"][i],pos,COLORS[(i+1)%COLORS.size()],false))
	camera_pos=player.head
	foods.clear()
	_create_food()
	hud.game_state="playing"
	if bg_audio and bg_audio.stream:
		if bg_audio.stream is AudioStreamWAV:
			bg_audio.stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
		bg_audio.play()
	_play_sound("start")
	hud.queue_redraw()

func _new_worm(n:String,pos:Vector2,color:Color,is_player:bool)->Dictionary:
	var trail:Array=[]
	for i in range(70): trail.append(pos-Vector2(i*BODY_SPACING,0))
	return {"name":n,"head":pos,"dir":Vector2.RIGHT,"trail":trail,"length":5,"color":color,"is_player":is_player,"alive":true,"score":0,"turn":Vector2.ZERO,"ai_timer":0.0,"target":Vector2(randf_range(0,ARENA_SIZE.x),randf_range(0,ARENA_SIZE.y)),"boost":false}

func _create_food():
	while foods.size()<FOOD_MAX:
		foods.append({"pos":Vector2(randf_range(35,ARENA_SIZE.x-35),randf_range(35,ARENA_SIZE.y-35)),"color":Color.from_hsv(randf(),0.75,1.0),"value":1 if randf()<0.93 else 3,"size":randf_range(4,7)})

func _on_joystick(v:Vector2):
	joystick=v

func _on_boost(active:bool):
	boosting=active
	if active: _play_sound("boost")

func _on_menu_action():
	if hud.game_state=="menu":
		game_mode="bots"
		_start_loading()
	elif hud.game_state=="dead":
		game_mode="bots"
		online=false
		_start_loading()
	elif hud.game_state=="room" or hud.game_state=="playing":
		_show_menu()

func _process(delta):
	if hud.game_state=="loading":
		loading_time+=delta
		hud.loading_progress=clamp(loading_time/1.7,0,1)
		hud.queue_redraw()
		if loading_time>=1.7: _start_game()
		return
	if hud.game_state!="playing": return
	game_time+=delta
	_update_worms(delta)
	_update_food(delta)
	camera_pos=camera_pos.lerp(player.head,1-exp(-delta*9.0))
	if online: _network_process(delta)
	_update_hud()
	queue_redraw()

func _update_worms(delta):
	for w in worms:
		if not w.alive: continue
		if online and not w.is_player: continue
		if w.is_player:
			if joystick.length()>0.12:
				w.dir=joystick.normalized()
			else:
				w.dir=w.dir
			w.boost=boosting and boost_energy>1
			if w.boost: boost_energy=max(0,boost_energy-33*delta)
			else: boost_energy=min(100,boost_energy+20*delta)
		else:
			w.ai_timer-=delta
			if w.ai_timer<=0:
				w.ai_timer=randf_range(0.25,0.75)
				var closest=Vector2.ZERO
				var best_d=INF
				for f in foods:
					var d=w.head.distance_squared_to(f.pos)
					if d<best_d: best_d=d;closest=f.pos
				w.target=closest
				# Steer away from arena boundaries and nearby bodies.
			var avoid=Vector2.ZERO
			var margin=200
			if w.head.x<margin: avoid.x+=1
			if w.head.x>ARENA_SIZE.x-margin: avoid.x-=1
			if w.head.y<margin: avoid.y+=1
			if w.head.y>ARENA_SIZE.y-margin: avoid.y-=1
			var desired=(w.target-w.head).normalized()+avoid*1.5
			w.dir=w.dir.lerp(desired.normalized(),0.65).normalized()
		var enemy_dist=player.head.distance_to(w.head)
		if enemy_dist<180 and randf()<0.02: w.dir=(w.head-player.head).normalized()
		w.boost=false
		var sp=SPEED*(1.05 if not w.is_player else 1.0)
		if w.boost: sp=BOOST_SPEED
		w.head+=w.dir*sp*delta
		w.trail.push_front(w.head)
		if w.trail.size()>int(w.length*BODY_SPACING/5)+80: w.trail.pop_back()
		# Boundary impact
		if w.head.x<20 or w.head.x>ARENA_SIZE.x-20 or w.head.y<20 or w.head.y>ARENA_SIZE.y-20:
			if w.is_player: _die()
			else: w.alive=false
			continue
		# Eat pellets
		for i in range(foods.size()-1,-1,-1):
			if w.head.distance_to(foods[i].pos)<22:
				var value=foods[i].value
				w.length+=value
				w.score+=value*10
				foods.remove_at(i)
				if w.is_player: score+=value*10;_play_sound("eat")
				break
		# Body collisions with other players, except initial spawn grace
		if game_time>2.5:
			for other in worms:
				if other==w or not other.alive: continue
				var body=other.trail
				for j in range(8,body.size(),4):
					if w.head.distance_to(body[j])<15:
					if w.is_player: _die()
					else: w.alive=false
					break
				if not w.alive: break

func _update_food(delta):
	food_timer+=delta
	if food_timer>0.6:
		food_timer=0
		_create_food()

func _die():
	if not player.alive:return
	player.alive=false
	hud.game_state="dead"
	best=max(best,score)
	_play_sound("hit")
	if bg_audio: bg_audio.stop()
	hud.queue_redraw()

func _update_hud():
	hud.score=score
	hud.best=best
	hud.player_length=player.length
	hud.players=[]
	for w in worms:
		if w.alive: hud.players.append({"name":w.name,"length":w.length})
	hud.minimap_points=[]
	for w in worms:
		if w.alive: hud.minimap_points.append(Vector2(w.head.x/ARENA_SIZE.x,w.head.y/ARENA_SIZE.y))
	hud.queue_redraw()

func _draw():
	if hud.game_state=="playing" or hud.game_state=="dead":
		var screen=get_viewport_rect().size
		draw_set_transform(screen*0.5-camera_pos)
		_draw_arena()
		for f in foods:
			draw_circle(f.pos,f.size+3,Color(f.color.r,f.color.g,f.color.b,0.12))
			draw_circle(f.pos,f.size,f.color)
		for w in worms:
			if w.alive: _draw_worm(w)
		_draw_world_border()
		draw_set_transform(Vector2.ZERO)

func _draw_arena():
	draw_rect(Rect2(Vector2.ZERO,ARENA_SIZE),Color("102337"),true)
	var grid=90
	for x in range(0,int(ARENA_SIZE.x),grid):
		draw_line(Vector2(x,0),Vector2(x,ARENA_SIZE.y),Color(0.14,0.24,0.33,0.32),1)
	for y in range(0,int(ARENA_SIZE.y),grid):
		draw_line(Vector2(0,y),Vector2(ARENA_SIZE.x,y),Color(0.14,0.24,0.33,0.32),1)
	# decorative landmarks, safe and lightweight
	for i in range(24):
		var p=Vector2((i*317)%int(ARENA_SIZE.x),(i*229)%int(ARENA_SIZE.y))
		draw_circle(p,22,Color(0.08,0.17,0.22,0.7))
		draw_circle(p,12,Color(0.13,0.24,0.3,0.6))

func _draw_world_border():
	draw_rect(Rect2(Vector2.ZERO,ARENA_SIZE),Color(0.28,0.93,0.72),false,6)

func _draw_worm(w):
	var trail=w.trail
	var step=max(1,int(BODY_SPACING/5))
	var count=min(int(w.length),int(trail.size()/step))
	for i in range(count-1,-1,-1):
		var idx=min(i*step,trail.size()-1)
		var pos=trail[idx]
		var radius=13.0*(1.0-min(i/count*0.3,0.25))
		var c=w.color
		var shade=0.78+0.22*(1.0-float(i)/max(1,count))
		draw_circle(pos+Vector2(2,3),radius+1,Color(0,0,0,0.22))
		draw_circle(pos,radius,Color(c.r*shade,c.g*shade,c.b*shade,c.a))
		if i%2==0:
			draw_circle(pos+Vector2(-2,-3),radius*0.35,Color(1,1,1,0.12))
	# head and eyes
	var head=w.head
	draw_circle(head,15,w.color)
	var side=w.dir.rotated(PI/2)*5
	var front=w.dir*5
	draw_circle(head+front+side,3.6,Color.WHITE)
	draw_circle(head+front-side,3.6,Color.WHITE)
	draw_circle(head+front+side+w.dir*1.5,1.8,Color("101923"))
	draw_circle(head+front-side+w.dir*1.5,1.8,Color("101923"))
	# names floating above head in world coordinates
	var font=ThemeDB.fallback_font
	var name_size=16
	var width=font.get_string_size(w.name,HORIZONTAL_ALIGNMENT_LEFT,-1,name_size).x
	draw_rect(Rect2(head+Vector2(-width/2-7,-38),Vector2(width+14,22)),Color(0.015,0.04,0.08,0.75),true,8)
	draw_string(font,head+Vector2(-width/2,-22),w.name,HORIZONTAL_ALIGNMENT_LEFT,-1,name_size,Color.WHITE)
	if w.is_player and w.boost:
		for k in range(3):
			draw_circle(head-w.dir*(24+k*13),5-k,Color(0.4,0.95,1,0.6-k*0.15))

func _network_process(delta):
	if net==null:return
	net.poll()
	var state=net.get_ready_state()
	if state==WebSocketPeer.STATE_OPEN:
		if network_state!="CONNECTED":
			var msg={"type":network_state.to_lower(),"name":hud.name_edit.text.strip_edges(),"room":network_join_code,"color":"#42f5b5"}
			net.send_text(JSON.stringify(msg))
			network_state="CONNECTED"
		net_timer+=delta
		if net_timer>0.05:
			net_timer=0
			net.send_text(JSON.stringify({"type":"input","dir":[joystick.x,joystick.y],"boost":boosting}))
		while net.get_available_packet_count()>0:
			var raw=net.get_packet().get_string_from_utf8()
			var data=JSON.parse_string(raw)
			if data is Dictionary:
				if data.has("room"): room_code=data.room;hud.room_code=room_code
				if data.has("id"): online_player_id=data.id
				if data.has("players"):
					remote_worms=data.players
					worms.clear()
					for rp in remote_worms:
						var rpos=Vector2(float(rp.get("x",0)),float(rp.get("y",0)))
						var rw=_new_worm(str(rp.get("name","Player")),rpos,Color.from_string(str(rp.get("color","#42f5b5")),Color.CYAN),str(rp.get("id",""))==online_player_id)
						rw.head=rpos;rw.length=int(rp.get("length",5));rw.score=int(rp.get("score",0));rw.dir=Vector2(float(rp.get("dx",1)),float(rp.get("dy",0)));rw.alive=bool(rp.get("alive",true))
						rw.trail=[]
						if rp.has("trail") and rp.trail.size()>0:
							for tp in rp.trail: rw.trail.append(Vector2(float(tp.x),float(tp.y)))
						else:
							for ti in range(90): rw.trail.append(rpos-rw.dir*ti*BODY_SPACING)
						worms.append(rw)
						if rw.is_player: player=rw;score=rw.score
						if rw.is_player and not rw.alive and hud.game_state=="playing": _die()
				if data.has("food"):
					foods=[]
					for f in data.food: foods.append({"pos":Vector2(f.x,f.y),"color":Color(0.35,1,0.7),"value":1,"size":5})
	elif state==WebSocketPeer.STATE_CLOSED:
		online=false
		_hud_message("Conexión online cerrada")

