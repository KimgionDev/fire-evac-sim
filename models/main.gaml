/**
 * Model: FireEvacuationSimulation
 * Description: Mô phỏng sơ tán khẩn cấp khi hỏa hoạn (Fire Evacuation Simulation)
 * Project: CT189 - Nhập môn Mô phỏng (Đại học Cần Thơ)
 */
model FireEvacuationSimulation

// ============ GLOBAL ============
global {
// Kích thước bản đồ (50x50 ô)
	int grid_width <- 50;
	int grid_height <- 50;

	// Số lượng tác tử
	int nb_evacuees <- 40;
	int nb_firefighters <- 2;
	int nb_rescuers <- 1;
	int nb_initial_fires <- 2;

	// Chỉ số toàn cục cho chart
	int nb_escaped <- 0;
	int nb_dead <- 0;
	int nb_panic <- 0;

	// ===== TV1: Đồ thị di chuyển né tường & danh sách ô thoát hiểm =====
	graph room_graph;
	list<floor_cell> exit_cells;

	init {
	// 1. Dựng bản đồ văn phòng (tường, sàn, cửa thoát, bàn ghế, bếp, kho)
		do setup_map;

		// 2. Tạo lửa tại bếp và lực lượng cứu hộ bên ngoài
		do setup_fire_and_rescuers;

		// 3. Spawn Evacuee trong các phòng (không đè tường/lửa)
		create Evacuee number: nb_evacuees {
			location <- any_location_in(one_of(floor_cell where (each.is_room and not each.is_wall and not each.is_fire)));
		}

	}

	// ===== TV1: Thiết lập bản đồ + exit_cells + room_graph =====
	action setup_map {
		ask floor_cell {
			int gx <- self.grid_x;
			int gy <- self.grid_y;

			// 1. Bên ngoài tòa nhà — vành đai 3 ô
			if (gx < 3 or gx > 46 or gy < 3 or gy > 46) {
				is_outside <- true;
				is_floor <- true;
				is_wall <- false;
				base_color <- rgb(235, 235, 235);
				color <- base_color;
			}
			// 2. Tường bao ngoài & Cửa thoát hiểm
else if (gx = 3 or gx = 46 or gy = 3 or gy = 46) {
				if ((gx = 3 or gx = 46) and (gy >= 16 and gy <= 18)) {
				// Cửa thoát hiểm — 2 cửa ở 2 đầu hành lang, mỗi cửa rộng 3 ô
					is_exit <- true;
					is_floor <- true;
					is_wall <- false;
					base_color <- rgb(46, 204, 113);
					color <- base_color;
				} else {
					is_wall <- true;
					is_floor <- false;
					base_color <- rgb(60, 60, 60);
					color <- base_color;
				}

			}
			// 3. Bên trong tòa nhà
else {
			// --- A. 4 Phòng họp cạnh trên (gy 4..14) ---
				if (gy >= 4 and gy <= 14) {
					if (gx = 14 or gx = 25 or gx = 35) {
					// Tường ngăn giữa 4 phòng
						is_wall <- true;
						is_floor <- false;
						base_color <- rgb(80, 80, 80);
						color <- base_color;
					} else if ((gy >= 7 and gy <= 10) and ((gx >= 7 and gx <= 10) or (gx >= 18 and gx <= 21) or (gx >= 29 and gx <= 31) or (gx >= 39 and gx <= 42))) {
					// Bàn họp (vật cản)
						is_wall <- true;
						is_floor <- false;
						base_color <- rgb(130, 110, 90);
						color <- base_color;
					} else {
						is_room <- true;
						is_floor <- true;
						base_color <- rgb(230, 240, 255);
						color <- base_color;
					}

				}
				// --- B. Vách ngăn phòng họp – hành lang (gy = 15) ---
else if (gy = 15) {
					if ((gx >= 8 and gx <= 9) or (gx >= 19 and gx <= 20) or (gx >= 29 and gx <= 30) or (gx >= 40 and gx <= 41)) {
					// Cửa phòng họp
						is_floor <- true;
						is_wall <- false;
						base_color <- rgb(245, 245, 245);
						color <- base_color;
					} else {
						is_wall <- true;
						is_floor <- false;
						base_color <- rgb(80, 80, 80);
						color <- base_color;
					}

				}
				// --- C. Hành lang chính (gy 16..18) — nối thẳng ra 2 cửa thoát ---
else if (gy >= 16 and gy <= 18) {
					is_floor <- true;
					is_wall <- false;
					base_color <- rgb(245, 245, 245);
					color <- base_color;
				}
				// --- D. Khu làm việc chung (gy 19..33) ---
else if (gy >= 19 and gy <= 33) {
					if (((gy >= 21 and gy <= 24) or (gy >= 27 and gy <= 30)) and ((gx >= 7 and gx <= 12) or (gx >= 17 and gx <= 22) or (gx >= 27 and gx <= 32) or (gx >= 37 and gx <= 42))) {
					// Cụm bàn làm việc (vật cản)
						is_wall <- true;
						is_floor <- false;
						base_color <- rgb(120, 120, 120);
						color <- base_color;
					} else {
						is_room <- true;
						is_floor <- true;
						base_color <- #white;
						color <- base_color;
					}

				}
				// --- E. Hành lang chuyển tiếp (gy = 34) ---
else if (gy = 34) {
					is_floor <- true;
					is_wall <- false;
					base_color <- rgb(245, 245, 245);
					color <- base_color;
				}
				// --- F. Vách ngăn Bếp – Kho (gy = 35) ---
else if (gy = 35) {
					if ((gx >= 12 and gx <= 13) or (gx >= 34 and gx <= 35) or (gx >= 24 and gx <= 25)) {
						is_floor <- true;
						is_wall <- false;
						base_color <- rgb(245, 245, 245);
						color <- base_color;
					} else {
						is_wall <- true;
						is_floor <- false;
						base_color <- rgb(80, 80, 80);
						color <- base_color;
					}

				}
				// --- G. Khu vực phía dưới (gy 36..45) ---
else if (gy >= 36 and gy <= 45) {
				// Bếp / Pantry — góc dưới trái (gx 4..22)
					if (gx >= 4 and gx <= 22) {
						if ((gx >= 5 and gx <= 6 and gy >= 38 and gy <= 43) or (gy >= 43 and gy <= 44 and gx >= 5 and gx <= 18)) {
						// Kệ bếp (vật cản)
							is_wall <- true;
							is_floor <- false;
							base_color <- rgb(160, 120, 90);
							color <- base_color;
						} else {
							is_room <- true;
							is_kitchen <- true;
							is_floor <- true;
							base_color <- rgb(255, 243, 224);
							color <- base_color;
						}

					}
					// Tường ngăn Bếp – Kho (gx = 23)
else if (gx = 23) {
						is_wall <- true;
						is_floor <- false;
						base_color <- rgb(80, 80, 80);
						color <- base_color;
					}
					// Hành lang sảnh nối (gx 24..25)
else if (gx >= 24 and gx <= 25) {
						is_floor <- true;
						is_wall <- false;
						base_color <- rgb(245, 245, 245);
						color <- base_color;
					}
					// Kho / Phòng nghỉ — góc dưới phải (gx 26..45)
else if (gx >= 26 and gx <= 45) {
						if ((gy >= 38 and gy <= 42) and ((gx >= 29 and gx <= 31) or (gx >= 37 and gx <= 39))) {
						// Kệ kho (vật cản)
							is_wall <- true;
							is_floor <- false;
							base_color <- rgb(140, 140, 140);
							color <- base_color;
						} else {
							is_room <- true;
							is_floor <- true;
							base_color <- rgb(240, 245, 235);
							color <- base_color;
						}

					} } } }

					// ===== TV1: Cache danh sách ô thoát hiểm =====
		exit_cells <- floor_cell where (each.is_exit);

		// ===== TV1: Dựng đồ thị di chuyển trên các ô đi được (né tường tự động) =====
		// Khi tác tử dùng: do goto target: xxx on: room_graph;
		// → GAMA tự tìm đường A* trên đồ thị này, 100% không bước lên ô tường.
		list<floor_cell> walkable <- floor_cell where (each.is_floor);
		room_graph <- as_distance_graph(walkable, 1.5);

		// Log kiểm tra
		write "========================================";
		write "TV1: exit_cells = " + length(exit_cells) + " o";
		write "TV1: room_graph da duoc tao thanh cong";
		write "========================================";
	}

	// --- Tạo Lửa và Lính cứu hộ ---
	action setup_fire_and_rescuers {
	// A. Tạo lửa tại Bếp
		list<floor_cell> kitchen_cells <- floor_cell where (each.is_kitchen and not each.is_wall);
		if (!empty(kitchen_cells)) {
			create Fire number: nb_initial_fires {
				location <- one_of(kitchen_cells).location;
				ask floor_cell(location) {
					is_fire <- true;
					is_fire_hazard <- true;
					color <- rgb(231, 76, 60);
				}

			}

		}

		// B. Tạo Firefighter & Rescuer bên ngoài tòa nhà
		list<floor_cell> outside_cells <- floor_cell where (each.is_outside and not each.is_wall);
		if (!empty(outside_cells)) {
			create Firefighter number: nb_firefighters {
				location <- one_of(outside_cells).location;
			}

			create Rescuer number: nb_rescuers {
				location <- one_of(outside_cells).location;
			}

		}

		write "========================================";
		write "KHOI TAO: " + length(Firefighter) + " Firefighter, " + length(Rescuer) + " Rescuer, " + length(Fire) + " Fire";
		write "========================================";
	}

	// ===== Cập nhật chỉ số toàn cục mỗi cycle =====
	reflex update_metrics {
	// Cập nhật số người đang hoảng loạn (panic_level > 70) theo INTERFACE.md
		nb_panic <- Evacuee count (each.panic_level > 70.0);
	} }

	// ============ GRID  ============
grid floor_cell width: grid_width height: grid_height {
	bool is_wall <- false;
	bool is_floor <- true;
	bool is_exit <- false;
	bool is_fire <- false;
	bool is_fire_hazard <- false;
	bool is_room <- false;
	bool is_kitchen <- false;
	bool is_outside <- false;
	rgb base_color <- #white;
	rgb color <- #white;

	action update_color {
		if (is_fire) {
			color <- rgb(231, 76, 60);
		} else if (is_fire_hazard) {
			color <- rgb(243, 156, 18);
		} else if (is_exit) {
			color <- rgb(46, 204, 113);
		} else {
			color <- base_color;
		} } }

		// ============ EVACUEE ============
// Do thành viên TV2 phụ trách cài đặt hành vi
species Evacuee skills: [moving] {
	float stamina <- 100.0;
	float panic_level <- 0.0;
	float speed <- rnd(1.0, 1.5);
	float vision <- 10.0;
	bool is_escaped <- false;
	string current_action <- "IDLE";

	// 4 biến lưu điểm số tiện ích vừa tính được
	float u_evacuate <- 0.0;
	float u_flee <- 0.0;
	float u_follow <- 0.0;
	float u_flock <- 0.0;

	action compute_utility {
		u_evacuate <- 0.0;
		u_flee <- 0.0;
		u_follow <- 0.0;
		u_flock <- 0.0;
		floor_cell nearest_exit <- empty(exit_cells) ? nil : (exit_cells closest_to self);
		Fire nearest_fire <- empty(Fire) ? nil : (Fire closest_to self);
		list<RescueWorker> responders <- (Firefighter as list) + (Rescuer as list);
		RescueWorker nearest_worker <- empty(responders) ? nil : (responders closest_to self);
		int nearby_evacuees_count <- length(Evacuee at_distance 5.0);

		// 1. Điểm EVACUATE (Thoát hiểm)
		// Chỉ kích hoạt khi phát hiện lối thoát trong tầm nhìn (< vision)
		if (nearest_exit != nil and (self distance_to nearest_exit) < vision) {
			float dist_exit <- self distance_to nearest_exit;
			u_evacuate <- u_evacuate + 60.0; // Thấy lối thoát trong tầm nhìn
			if (dist_exit <= 2.0) {
				u_evacuate <- u_evacuate + 40.0; // Ở rất gần lối thoát
			}

			if (stamina < 20.0) {
				u_evacuate <- u_evacuate + 40.0; // Ưu tiên khẩn cấp khi kiệt sức
			}

		}

		// 2. Điểm FLEE_FIRE (Chạy né khói lửa)
		// Chỉ kích hoạt khi có lửa trong tầm nhìn (<= vision)
		if (nearest_fire != nil and (self distance_to nearest_fire) <= vision) {
			float dist_fire <- self distance_to nearest_fire;
			if (dist_fire <= 5.0) {
				u_flee <- u_flee + 50.0;
			}

			if (dist_fire <= 2.0) {
				u_flee <- u_flee + 50.0;
			} // Nguy cấp
			if (stamina < 40.0) {
				u_flee <- u_flee + 30.0;
			} // Thể lực thấp khi có lửa gần
		}

		// 3. Điểm FOLLOW_LEADER (Đi theo cứu hộ)
		// ĐIỀU KIỆN TIÊN QUYẾT: Chỉ kích hoạt khi có RescueWorker trong bán kính 8 ô!
		if (nearest_worker != nil and (self distance_to nearest_worker) <= 8.0) {
			u_follow <- u_follow + 50.0;

			// Nếu bản thân chưa thấy lối thoát trong tầm nhìn -> càng muốn bám theo cứu hộ (+30)
			if (nearest_exit = nil or (self distance_to nearest_exit) >= vision) {
				u_follow <- u_follow + 30.0;
			}

			// Nếu hoảng loạn mất phương hướng -> cần người dẫn đường (+30)
			if (panic_level > 70.0) {
				u_follow <- u_follow + 30.0;
			}

		}

		// 4. Điểm FLOCK (Gộp nhóm đông người)
		if (nearby_evacuees_count >= 3) {
			u_flock <- u_flock + 40.0;
		}

		if (nearby_evacuees_count >= 1 and panic_level > 50.0) {
			u_flock <- u_flock + 20.0;
		}

		// BƯỚC D: So sánh và Tie-break (FLEE > EVACUATE > FOLLOW > FLOCK)
		float max_score <- max([u_flee, u_evacuate, u_follow, u_flock]);
		if (max_score <= 0.0) {
			current_action <- "IDLE";
		} else if (u_flee = max_score) {
			current_action <- "FLEE_FIRE";
		} else if (u_evacuate = max_score) {
			current_action <- "EVACUATE";
		} else if (u_follow = max_score) {
			current_action <- "FOLLOW_LEADER";
		} else {
			current_action <- "FLOCK";
		} }

	action flee_from (Fire target) {
	}

	action evacuate (floor_cell target_exit) {
	}

	action follow_leader (RescueWorker leader) {
	}

	action flock {
	}

	reflex main_decision {
		stamina <- max(0.0, stamina - 0.1);
		panic_level <- min(100.0, max(0.0, panic_level + 0.5));
		if (floor_cell(location).is_exit) {
			is_escaped <- true;
			nb_escaped <- nb_escaped + 1;
			write "[THOÁT HIỂM] " + name + " đã thoát an toàn tại cycle " + cycle;
			do die;
		}

		if (stamina <= 0.0 and not is_escaped) {
			nb_dead <- nb_dead + 1;
			write "[TỬ VONG] " + name + " đã tử vong vì kiệt sức tại cycle " + cycle;
			do die;
		}

		do compute_utility;
	}

	aspect default {
		rgb my_color <- #blue;
		if (current_action = "FLEE_FIRE") {
			my_color <- #red;
		} else if (current_action = "EVACUATE") {
			my_color <- #green;
		} else if (current_action = "FOLLOW_LEADER") {
			my_color <- #yellow;
		} else if (current_action = "FLOCK") {
			my_color <- rgb(155, 89, 182); // Màu tím
		}

		draw circle(0.6) color: my_color border: #black;
		if (current_action != "IDLE") {
			draw current_action size: 1.2 color: #black at: location + {0, -1};
		} } }

		// ============ RESCUEWORKER ============
species RescueWorker skills: [moving] {
	float stamina <- 200.0;
	float speed <- 1.2;
	float vision <- 15.0;
	rgb color <- #blue;

	reflex stamina_loss {
		stamina <- max(0.0, stamina - 0.05);
	}

	reflex check_death {
		if (stamina <= 0.0) {
			nb_dead <- nb_dead + 1;
			write "[HY SINH] " + name + " đã hy sinh khi đang làm nhiệm vụ tại cycle " + cycle;
			do die;
		}

	}

	aspect default {
		draw circle(1.0) color: color border: #black;
	}

}

// ============ FIREFIGHTER ============
species Firefighter parent: RescueWorker {
	float water_supply <- 100.0;

	init {
		color <- #yellow;
	}

	action compute_utility {
	}

	// Action dập lửa
	action extinguish (Fire target) {
		if (target != nil and water_supply > 0) {
			target.intensity <- target.intensity - 20.0; // Giảm 20 theo INTERFACE
			water_supply <- max(0.0, water_supply - 5.0); // Giảm 5 theo INTERFACE

			// Nếu ngọn lửa bị dập tắt hoàn toàn
			if (target.intensity <= 0) {
				ask floor_cell(target.location) {
					is_fire <- false;
					is_fire_hazard <- false; // Xóa cờ nguy hiểm
					do update_color;
				}

				ask target {
					do die;
				}

			}

		}

	}

	// Logic quyết định di chuyển & dập lửa
	reflex main_decision {
		Fire target_fire <- Fire closest_to self;
		if (target_fire != nil) {
			if (self distance_to target_fire <= 1.5) {
				do extinguish(target_fire);
			} else {
				do goto target: target_fire.location on: room_graph;
			}

		}

	}

	aspect default {
		draw rectangle(1.2, 1.2) color: color border: #black;
	}

}

// ============ RESCUER ============
species Rescuer parent: RescueWorker {
	float calm_radius <- 4.0;

	init {
		color <- #cyan;
	}

	action compute_utility {
	}

	action guide (Evacuee target) {
	}

	reflex main_decision {
	// TV3 viết logic tuần tra/dẫn đường tại đây
	}

	// Khi di chuyển, dùng: do goto target: xxx on: room_graph;
	aspect default {
		draw triangle(1.3) color: color border: #black;
	}

}

// ============ FIRE ============
species Fire {
	float intensity <- 100.0;
	bool is_active <- true;
	rgb color <- #red;

	// 1. Lan truyền lửa ngẫu nhiên
	reflex spread {
		if (is_active and flip(0.05)) { // 5% mỗi cycle
			floor_cell current_cell <- floor_cell(location);
			if (current_cell != nil) {
			// Không lan vào tường, ô đã có lửa, và không lan ra ngoài sân
				list<floor_cell> neighbor_cells <- current_cell.neighbors where (not each.is_wall and not each.is_fire and not each.is_outside);
				if (!empty(neighbor_cells)) {
					floor_cell target_cell <- one_of(neighbor_cells);
					create Fire {
						location <- target_cell.location;
						intensity <- 50.0; // Lửa mới tạo có intensity = 50
						ask target_cell {
							is_fire <- true;
							is_fire_hazard <- true;
							do update_color;
						}

					}

				}

			}

		}

	}

	// 2. Gây sát thương cho tác tử ở gần
	reflex damage {
	// Trừ stamina của Evacuee (bán kính <= 1.5 ô)
		list<Evacuee> nearby_evacuees <- Evacuee at_distance 1.5;
		ask nearby_evacuees {
			stamina <- max(0.0, stamina - 5.0); // Sát thương 5.0
		}

		// Trừ stamina của cứu hộ (phải gộp Firefighter + Rescuer vì RescueWorker bị rỗng)
		list<RescueWorker> nearby_workers <- (Firefighter + Rescuer) at_distance 1.5;
		ask nearby_workers {
			stamina <- max(0.0, stamina - 3.0); // Sát thương 3.0
		}

	}

	aspect default {
		draw circle(0.8) color: color;
	}

}

// ============ EXPERIMENT ============
experiment FireEvacuation type: gui {
	output {
		display map {
			grid floor_cell;
			species Fire aspect: default;
			species Firefighter aspect: default;
			species Rescuer aspect: default;
			species Evacuee aspect: default;
		}

		display chart_view type: 2d refresh: every(1 #cycle) {
			chart "Thống kê sơ tán thời gian thực" type: series size: {1.0, 0.5} position: {0.0, 0.0} {
				data "Thoát thành công" value: nb_escaped color: #green;
				data "Tử vong" value: nb_dead color: #red;
				data "Đang hoảng loạn" value: (Evacuee count (each.panic_level > 70.0)) color: #orange;
			}

			chart "Số đám lửa còn lại" type: series size: {1.0, 0.5} position: {0.0, 0.5} {
				data "Đám lửa" value: length(Fire) color: #darkred;
			}

		}

	}

}
 