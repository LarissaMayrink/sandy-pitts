set_item_stats({ type: GEARTYPES.WEAPON, damage: 10 });

gear = new GearItem(noone, -95);

attacks = new AttackList({
	stats: { end_lag: 50, reset_time: 51, light_start: q_ek_inst_1, heavy_start: q_ek_charge },
	list: [
		new Attack({ type: ACTIONTYPE.INSTANT,
					 action: q_ek_inst_1,
					 link_light: q_ek_inst_2,
					 link_heavy: q_ek_charge,
					 attack_frame: 1,
					 reset_frame: 6,
					 damage_multi: 1 }),
		new Attack({ type: ACTIONTYPE.INSTANT,
					 action: q_ek_inst_2,
					 link_light: q_ek_inst_1,
					 link_heavy: q_ek_charge,
					 attack_frame: 1,
					 reset_frame: 6,
					 damage_multi: 1 }),
		new Attack({ type: ACTIONTYPE.CHARGE,
					 action: q_ek_charge,
					 link_light: noone,
					 link_heavy: noone,
					 attack_frame: 1,
					 reset_frame: 7,
					 charge_min: 1,
					 charge_end: 7,
					 damage_multi: 0.2 })
	]
});