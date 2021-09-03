/// @func	CombatClass();
function CombatClass(_side) constructor {
	var _owner = other;
	
	_this = {};
	
	with(_this) {
		owner = _owner;
		side = _side;
		attacks = [];
		gear = { cur_helm: noone, cur_bod: noone, cur_weapon: noone, cur_shield: noone };
		items = [];
		seq = {
			_attack: noone,
			_layer: noone,
			_cur: noone
		}
		attacking = false;
		attack_index = 0;
		stats = noone;
		list = noone;
	}
	
	if(!_this.owner.has_combat_stats) {
		show_debug_message("you haven't set your stats up. consider using the set_combat_stats function to initialize all of the stats this object will use.");
	}
	
	#region /// timer system
	timer = new TimerSystem();
	#endregion
	
	#region // functions for changing base stats after creation
	/// @func	hp_set(_hp);
	/// @param	{int}	_hp		the hp value to add or subtract.
	hp_set = function(_hp) {
		_this.owner.cur_hp = clamp(_this.owner.cur_hp + _hp, 0, _this.owner.max_hp);
	}
	
	/// @func	hp_set_max(_max_hp);
	/// @param	{int}	_max_hp		the max_hp value to set
	hp_set_max = function(_max_hp) {
		_this.owner.max_hp = _max_hp;
	}
	
	/// @func	damage_set(_damage);
	/// @param	{int}	_damage		the damage value to set
	damage_set = function(_damage) {
		_this.owner.dam = _damage;
	}
	
	/// @func	look_dir_lock();
	look_dir_lock = function() {
		_this.owner.look_dir_locked = true;
	}
	
	///	@func	look_dir_unlock();
	look_dir_unlock = function() {
		_this.owner.look_dir_locked = false;
	}
	#endregion
	
	#region // gear changing functions #UNFINISHED
	/// @func	set_gear(_type, _id);
	///	@param	{string}	_type	gear type input.
	/// @param	{id}		_id		gear id input.
	set_gear = function(_type, _id) {
		with(_this) {
			switch(_type) {
				case "helm":
				gear.cur_helm = _id;
				break;
				
				case "bod":
				gear.cur_bod = _id;
				break;
				
				case "weapon":
				if(gear.cur_weapon != noone) {
					with(gear.cur_weapon)instance_destroy(); // #TEST probably remove later with weapon swapping.
				}
				var _weapon = instance_create_layer(owner.x, owner.y, _entity_layer, _id);
				_weapon.owner = owner.id;
				gear.cur_weapon = _weapon;
				stats = _weapon.attacks.stats;
				list = _weapon.attacks.list;
				break;
				
				case "shield":
				gear.cur_shield = _id;
				break;
			}
		}
	}
	
	/// @func	get_gear(_type);
	/// @param	{string}	_type	gear type input.
	get_gear = function(_type) {
		with(_this) {
			switch(_type) {
				case "helm":
				return gear.cur_helm;
				
				case "bod":
				return gear.cur_bod;
				
				case "weapon":
				return gear.cur_weapon;
				
				case "shield":
				return gear.cur_shield;
			}
		}
	}
	
	///	@func	swap_gear(_id);
	/// @param	{id}	_id	gear id input.
	swap_gear = function(_id) {
		
	}
	#endregion
	
	#region // attacking functions
	/// @func	start(_seq);
	/// @param	{sequence}	_seq	the input sequence
	start = function(_seq) {
		with(_this) {
			attacking = true;
			seq._attack = _seq;
			seq._layer = layer_create(owner.depth);
			seq._cur = layer_sequence_create(seq._layer, owner.x, owner.y, seq._attack);
			
			other.timer.set(1, "set attack", function() {
				layer_sequence_angle(seq._cur, owner.look_dir);
				layer_sequence_speedscale(seq._cur, 0.9 + owner.act_spd * 0.1);
				layer_sequence_xscale(seq._cur, 0.9 + owner.size * 0.1);
				layer_sequence_yscale(seq._cur, 0.9 + owner.size * 0.1);
				
				var _box = instance_create_layer(-1000, -1000, seq._layer, o_hitbox);
				_box.damage = owner.damage;
				_box.side = side;
				_box.image_angle = owner.look_dir;
				sequence_instance_override_object(layer_sequence_get_instance(seq._cur), o_hitbox, _box);
			});
		}
	}
	
	/// @func	check();
	check = function() {
		with(_this) {
			other.timer.check();
			
			if(seq._cur == noone)return;
			
			layer_sequence_angle(seq._cur, owner.look_dir);
			layer_sequence_x(seq._cur, owner.x);
			layer_sequence_y(seq._cur, owner.y);
			layer_depth(seq._layer, owner.depth - 10);
			
			if(layer_sequence_get_headpos(seq._cur) == list[attack_index].rotation_lock_threshold) {
				other.look_dir_lock();
			}
			
			if(layer_sequence_get_headpos(seq._cur) == list[attack_index].rotation_unlock_threshold) {
				other.look_dir_unlock();
			}
			
			if(layer_sequence_is_finished(seq._cur)) {
				layer_sequence_pause(seq._cur);
				if(!other.timer.exists("end_lag") && !other.timer.exists("reset_time")) {
					other.timer.set(stats.end_lag, "end_lag", function() {
						
						other.timer.set(stats.reset_time, "reset_time", function() {
							layer_sequence_destroy(seq._cur);
							layer_destroy(seq._layer);
							
							seq._attack = noone;
							seq._layer = noone;
							seq._cur = noone;
							attack_index = 0;
							attacking = false;
						});
					});
				}
			}
		}
	}
	
	/// @func	attack(_input);
	/// @param	{enum}	_input	takes in a verb enum for light or heavy.
	attack = function(_input) {
		if(timer.exists("reset_time")) {
			timer.cancel("reset_time");
			with(_this) {
				layer_sequence_destroy(seq._cur);
				layer_destroy(seq._layer);
				
				seq._attack = noone;
				seq._layer = noone;
				seq._cur = noone;
				
				var _att = other.get_gear("weapon").attacks;
				if(_input == Verb.lattack && _att.list[attack_index].link_light != noone) {
					attack_index = _att.list[attack_index].link_light;
					other.start(_att.list[attack_index].act);
				} else if(_input == Verb.hattack && _att.list[attack_index].link_heavy != noone) {
					attack_index = _att.list[attack_index].link_heavy;
					other.start(_att.list[attack_index].act);
				}
			}
		}
		if(!is_attacking() && !timer.exists("end_lag")) {
			with(_this) {
				var _att = other.get_gear("weapon").attacks;
				if(_input == Verb.lattack && _att.list[attack_index].link_light != noone) {
					attack_index = _att.list[attack_index].link_light;
					other.start(_att.list[attack_index].act);
				} else if(_input == Verb.hattack && _att.list[attack_index].link_heavy != noone) {
					attack_index = _att.list[attack_index].link_heavy;
					other.start(_att.list[attack_index].act);
				}
			}
		}
	}
	#endregion
	
	#region // i-frame functions #UNFINISHED
	
	#endregion
	
	#region // state change listener functions
	/// @func	is_attacking();
	is_attacking = function() {
		return _this.attacking;
	}
	
	/// @func	look_dir_is_locked();
	look_dir_is_locked = function() {
		return _this.owner.look_dir_locked;
	}
	#endregion
	
	#region // functions for controlling look direction and angle
	/// @func look();
	look = function() {
		with(_this.owner) {
			if(!other.look_dir_is_locked()) {
				if(input_player_source_get(player_num) == INPUT_SOURCE.KEYBOARD_AND_MOUSE)look_dir = point_direction(x, y, mouse_x, mouse_y);
				else if(input_player_source_get(player_num) == INPUT_SOURCE.GAMEPAD)look_dir = input_direction(Verb.aim_left, Verb.aim_right, Verb.aim_up, Verb.aim_down, player_num);
			}
			
			if(look_dir == undefined)look_dir = look_dir_saved;
			look_dir_saved = look_dir;
			
			if(look_dir > 90 && look_dir <= 270)mv_sign = -1;
			else mv_sign = 1;
		}
	}
	#endregion
}

#region // combat handler functions
/// @func	set_combat_stats(_hp, _dam, _act_spd, _size);
/// @param	{int}	_hp			hitpoints
/// @param	{int}	_dam		attack damage
/// @param	{int}	_act_spd	action speed
/// @param	{int}	_size		player size
function set_combat_stats(_hp, _dam, _act_spd, _size) {
	with(other) {
		has_combat_stats = true;
		cur_hp = _hp;
		max_hp = _hp;
		damage = _dam;
		act_spd = _act_spd;
		size = _size;
		mv_sign = 1;
		look_dir = 0;
		look_dir_saved = 0;
		look_dir_locked = false;
	}
}

/// @func	AttackList(_struct);
/// @param	{struct}	_struct		the input struct.
function AttackList(_struct) constructor {
	#region // instantate variables
	stats = _struct.stats;
	
	if(!variable_struct_exists(stats, "end_lag"))stats.end_lag = 0;
	if(!variable_struct_exists(stats, "reset_time"))stats.reset_time = 0;
	
	if(!variable_struct_exists(stats, "light_start"))stats.light_start = noone;
	if(!variable_struct_exists(stats, "heavy_start"))stats.heavy_start = noone;
	#endregion
	
	#region // create list with an extra object at array 0 that contains an empty attack with only link variables.
	list = [];
	
	array_push(list, new Attack({ act: noone,	
								  link_light: stats.light_start,
								  link_heavy: stats.heavy_start,
								  attack_frame: 0,
								  reset_frame: 0,
								  damage_multi: 0 }));
	
	var _i = 0;
	repeat(array_length(_struct.list)) {
		array_push(list, _struct.list[_i]);
		_i++;
	}
	#endregion
	
	#region // loop through the list, converting link sequences to the index of that sequence in the array.
	var _i = 0;
	repeat(array_length(list)) {
		if(list[_i].link_light != noone) {					//	make sure that link_light isn't noone.
			var _l = 0;
			repeat(array_length(list)) {
				if(list[_l].act == list[_i].link_light) {	//	check to see if the current index contains the sequence in the link_light reference.
					list[_i].link_light = _l;				//	set link_light to equal the index of the attack sequence that matches.
					break;
				}
				_l++;
			}
		}
		
		if(list[_i].link_heavy != noone) {					//	make sure that link_heavy isn't noone.
			var _h = 0;
			repeat(array_length(list)) {
				if(list[_h].act == list[_i].link_heavy) {	//	check to see if the current index contains the sequence in the link_heavy reference.
					list[_i].link_heavy = _h;				//	set link_heavy to equal the index of the attack sequence that matches.
					break;
				}
				_h++;
			}
		}
		_i++;
	}
	#endregion
}

/// @func	Attack(_struct);
/// @param	{struct}	_struct		the input struct.
function Attack(_struct) constructor {
	#region // check and set input type.
	if(!variable_struct_exists(_struct, "type")) {
		show_debug_message("variable type does not exist or is misnamed. setting type to INSTANT.");
		type = ACTIONTYPE.INSTANT;
	} else {
		switch(_struct.type) {
			case ACTIONTYPE.INSTANT:
			type = ACTIONTYPE.INSTANT;
			break;
			
			case ACTIONTYPE.HELD:
			type = ACTIONTYPE.HELD;
			break;
			
			case ACTIONTYPE.CHARGE:
			type = ACTIONTYPE.CHARGE;
			break;
			
			default:
			show_debug_message("type must use the ACTIONTYPE enum. setting to INSTANT.");
			type = ACTIONTYPE.INSTANT;
			break;
		}
	}
	#endregion
	
	#region // check that act exists and is a sequence and set it.
	if(!variable_struct_exists(_struct, "act")) {
		act = noone;
	} else if(_struct.act == noone) {
		act = _struct.act;
	} else if(!sequence_exists(_struct.act)) {
		show_debug_message("act must be a sequence or 'noone.' setting to 'noone.'");
		act = noone;
	} else {
		act = _struct.act;
	}
	#endregion
	
	#region // check that link_light exists and is a sequence and set it.
	if(!variable_struct_exists(_struct, "link_light")) {
		link_light = noone;
	} else if(_struct.link_light == noone) {
		link_light = _struct.link_light;
	} else if(!sequence_exists(_struct.link_light)) {
		show_debug_message("link_light must be a valid sequence or 'noone.' setting to 'noone.'");
		link_light = noone;
	} else {
		link_light = _struct.link_light;
	}
	#endregion
	
	#region // check that link_heavy exists and is a sequence and set it.
	if(!variable_struct_exists(_struct, "link_heavy")) {
		link_heavy = noone;
	} else if(_struct.link_heavy == noone) {
		link_heavy = _struct.link_heavy;
	} else if(!sequence_exists(_struct.link_heavy)) {
		show_debug_message("link_heavy must be a valid sequence or 'noone.' setting to 'noone.'");
		link_heavy = noone;
	} else {
		link_heavy = _struct.link_heavy;
	}
	#endregion
	
	#region// check that attack_frame exists and is a real positive integer and set it.
	if(!variable_struct_exists(_struct, "attack_frame")) {
		attack_frame = 0;
	} else if(!is_real(_struct.attack_frame)) {
		show_debug_message("attack_frame must be real. setting to 0.");
		attack_frame = 0;
	} else if(frac(_struct.attack_frame) != 0) {
		show_debug_message("attack_frame must be an integer. rounding down.");
		attack_frame = int64(_struct.attack_frame);
	} else if(_struct.attack_frame < 0) {
		show_debug_message("rotation_lock_threshold must be positive. setting to 0.");
		attack_frame = 0;
	} else {
		attack_frame = _struct.attack_frame;
	}
	#endregion
	
	#region // check that reset_frame exists and is a real positive integer and set it.
	if(!variable_struct_exists(_struct, "reset_frame")) {
		reset_frame = 0;
	} else if(!is_real(_struct.reset_frame)) {
		show_debug_message("reset_frame must be real. setting to 0.");
		reset_frame = 0;
	} else if(frac(_struct.reset_frame) != 0) {
		show_debug_message("reset_frame must be an integer. rounding down.");
		reset_frame = int64(_struct.reset_frame);
	} else if(_struct.reset_frame < 0) {
		show_debug_message("reset_frame must be positive. setting to 0.");
		reset_frame = 0;
	} else {
		reset_frame = _struct.reset_frame;
	}
	#endregion
	
	#region // check that damage_multi exists and is a real positive integer and set it.
	if(!variable_struct_exists(_struct, "damage_multi")) {
		damage_multi = 0;
	} else if(!is_real(_struct.damage_multi)) {
		show_debug_message("damage_multi must be real. setting to 1.");
		damage_multi = 1;
	} else if(_struct.damage_multi < 0) {
		show_debug_message("damage_multi must be positive. setting to 1.");
		damage_multi = 1;
	} else {
		damage_multi = _struct.damage_multi;
	}
	#endregion
	
	#region // check that attack_type = CHARGE, that charge_end_frame exists, and that it is a real positive integer, then set it.
	if(_struct.type = ACTIONTYPE.CHARGE) {
		if(!variable_struct_exists(_struct, "charge_time")) {
			charge_end_frame = 0;
		} else if(!is_real(_struct.charge_end_frame)) {
			show_debug_message("charge_time must be real. setting to 0.");
			charge_end_frame = 0;
		} else if(frac(_struct.charge_end_frame) != 0) {
			show_debug_message("charge_time must be an integer. rounding down.");
			cancel_treshold = int64(_struct.charge_end_frame);
		} else if(_struct.charge_end_frame < 0) {
			show_debug_message("charge_end_frame must be positive. setting to 0.");
			charge_end_frame = 0;
		} else {
			charge_end_frame = _struct.charge_end_frame;
		}
	}
	#endregion
	
	#region // check that attack_type = CHARGE, that charge_min exists, and that it is a real positive integer, then set it.
	if(_struct.type = ACTIONTYPE.CHARGE) {
		if(!variable_struct_exists(_struct, "charge_min")) {
			charge_min = 0;
		} else if(!is_real(_struct.charge_min)) {
			show_debug_message("charge_min must be real. setting to 0.");
			charge_min = 0;
		} else if(frac(_struct.charge_min) != 0) {
			show_debug_message("charge_min must be an integer. rounding down.");
			cancel_treshold = int64(_struct.charge_min);
		} else if(_struct.charge_min < 0) {
			show_debug_message("charge_min must be positive. setting to 0.");
			charge_min = 0;
		} else {
			charge_min = _struct.charge_min;
		}
	}
	#endregion
	
	#region // check that attack_type = HELD, that hold_frame exists, and that it is a real positive integer, then set it.
	if(_struct.type = ACTIONTYPE.CHARGE) {
		if(!variable_struct_exists(_struct, "hold_frame")) {
			hold_frame = 0;
		} else if(!is_real(_struct.hold_frame)) {
			show_debug_message("hold_frame must be real. setting to 0.");
			hold_frame = 0;
		} else if(frac(_struct.hold_frame) != 0) {
			show_debug_message("hold_frame must be an integer. rounding down.");
			cancel_treshold = int64(_struct.hold_frame);
		} else if(_struct.hold_frame < 0) {
			show_debug_message("hold_frame must be positive. setting to 0.");
			hold_frame = 0;
		} else {
			hold_frame = _struct.hold_frame;
		}
	}
	#endregion
}

/// @func	Skill(_struct);
/// @param	{struct}	_struct		the input struct.
function Skill(_struct) constructor {
	#region // check and set input type.
	if(!variable_struct_exists(_struct, "type")) {
		show_debug_message("variable type does not exist or is misnamed. setting type to INSTANT.");
		type = ACTIONTYPE.INSTANT;
	} else {
		switch(_struct.type) {
			case ACTIONTYPE.INSTANT:
			type = ACTIONTYPE.INSTANT;
			break;
			
			case ACTIONTYPE.HELD:
			type = ACTIONTYPE.HELD;
			break;
			
			case ACTIONTYPE.CHARGE:
			type = ACTIONTYPE.CHARGE;
			break;
			
			default:
			show_debug_message("type must use the ACTIONTYPE enum. setting to INSTANT.");
			type = ACTIONTYPE.INSTANT;
			break;
		}
	}
	#endregion
	
	
}
#endregion

#region // attack/skill type enum
enum ACTIONTYPE {
  INSTANT,
  HELD,
  CHARGE
}
#endregion