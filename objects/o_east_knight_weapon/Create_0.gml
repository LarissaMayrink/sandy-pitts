owner = noone;

attacks = new AttackList({
	stats: { end_lag: 0, reset_time: 0 },
	list: [
		new Attack({ act: q_ek_light_1,	
					 link_light: q_ek_light_2,
					 link_heavy: q_ek_heavy,
					 cancel_threshold: 5,
					 rotation_lock_threshold: 5,
					 rotation_unlock_threshold: 18,
					 charge_time: 0	}),
		new Attack({ act: q_ek_light_2,
					 link_light: q_ek_light_1,
					 link_heavy: q_ek_heavy,
					 cancel_threshold: 5,
					 rotation_lock_threshold: 5,
					 rotation_unlock_threshold: 18,
					 charge_time: 0	}),
		new Attack({ act: q_ek_heavy,
					 link_light: noone,
					 link_heavy: noone,
					 cancel_threshold: 0,
					 rotation_lock_threshold: 5,
					 rotation_unlock_threshold: 18,
					 charge_time: 15 }) //# seq is unfinished
	]
});

show_debug_message(attacks);