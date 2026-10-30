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
		if (target != nil) {
			// Tính điểm đối xứng ngược hướng với ngọn lửa
			point flee_point <- self.location + (self.location - target.location);
			if ((self.location distance_to target.location) = 0.0) {
				floor_cell current_cell <- floor_cell(location);
				if (current_cell != nil) {
					list<floor_cell> escape_cells <- current_cell.neighbors where (each.is_floor and not each.is_wall and not each.is_fire and (each.location distance_to target.location) > 0.0);
					if (!empty(escape_cells)) {
						flee_point <- one_of(escape_cells).location;
					}
				}
			}
			
			// Tháo chạy ngược hướng ngọn lửa nhưng vẫn né tường
			do goto target: flee_point on: room_graph;
	}
}
	action evacuate (floor_cell target_exit) {
		if(target_exit != nil){
			// Di chuyển theo đồ thị né tường về phía cửa thoát hiểm
			do goto target: target_exit on: room_graph;
		}
	}

	action follow_leader (RescueWorker leader) {
	}

	action flock {
	}

	reflex main_decision {
		//giam the luc va tang nhe panic theo thoi gian
		stamina <- max(0.0, stamina - 0.1);
		panic_level <- min(100.0, max(0.0, panic_level + 0.5));
		
		
		//Kiem tra tu vong do kiet suc
		if (stamina <= 0.0 and not is_escaped) {
			nb_dead <- nb_dead + 1;
			write "[TỬ VONG] " + name + " đã tử vong vì kiệt sức tại cycle " + cycle;
			do die;
		}

		do compute_utility;
		
		//thuc hien hanh dong di chuyen
		if (current_action = "FLEE_FIRE") {
			Fire nearest_fire <- empty(Fire) ? nil : (Fire closest_to self);
			if (nearest_fire != nil) {
				do flee_from(nearest_fire);
			}
		} else if (current_action = "EVACUATE") {
			floor_cell nearest_exit <- empty(exit_cells) ? nil : (exit_cells closest_to self);
			if (nearest_exit != nil) {
				do evacuate(nearest_exit);
			}
		}
		
		// Kiểm tra an toàn khi vừa chạm ô cửa thoát hiểm (Exit)
		floor_cell my_cell <- floor_cell(location);
		if (my_cell != nil and my_cell.is_exit) {
			is_escaped <- true;
			nb_escaped <- nb_escaped + 1;
			write "[THOÁT HIỂM] " + name + " đã thoát an toàn tại cycle " + cycle;
			do die;
		}
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
	float water_supply    <- 100.0;
	string current_action <- "WANDER";

	float u_extinguish <- 0.0;
	float u_move_fire  <- 0.0;
	float u_wander     <- 0.0;

	// Biến đếm cycle tiếp nước ngoài sân
	int refill_timer <- 0;

	init {
		color <- #yellow;
	}

	// Ghi đè stamina_loss: Tạm dừng trừ stamina khi đã ra ngoài sân (is_outside)
	reflex stamina_loss {
		floor_cell my_cell <- floor_cell(location);
		if (my_cell != nil and not my_cell.is_outside) {
			stamina <- max(0.0, stamina - 0.05);
		}
	}

	// Cập nhật action compute_utility chuẩn ma trận và Tie-break (Mục 2.2 & 2.6 de-bai-do-an.md)
	action compute_utility {
		u_extinguish <- 0.0;
		u_move_fire  <- 0.0;
		u_wander     <- 0.0;

		Fire nearest_fire <- empty(Fire) ? nil : (Fire closest_to self);
		floor_cell nearest_exit <- empty(exit_cells) ? nil : (exit_cells closest_to self);

		// 1. Khi hết nước hoặc đã dập sạch toàn bộ lửa -> WANDER (rút lui nạp nước hoặc tuần tra)
		if (water_supply <= 0.0 or nearest_fire = nil) {
			u_wander <- 30.0;
		} else {
			float dist_fire <- self distance_to nearest_fire;

			// EXTINGUISH: Khi ở ngay cạnh lửa (<= 1.5 ô) và còn nước -> Ưu tiên dập ngay
			if (dist_fire <= 1.5) {
				u_extinguish <- u_extinguish + 70.0;
				
				if (nearest_fire.intensity > 50.0) {
					u_extinguish <- u_extinguish + 30.0;
				}
				
				if (nearest_exit != nil and (nearest_fire distance_to nearest_exit) <= 3.0) {
					u_extinguish <- u_extinguish + 40.0;
				}
			}
			// MOVE_TO_FIRE: Khi còn nước và chưa tới gần (dist > 1.5 ô) -> Di chuyển thẳng tới ngọn lửa
			else {
				u_move_fire <- u_move_fire + 50.0;
				
				if (nearest_fire.intensity > 50.0) {
					u_move_fire <- u_move_fire + 20.0;
				}
			}
		}

		// 3. Phân giải hòa điểm chuẩn Tie-break: EXTINGUISH > MOVE_TO_FIRE > WANDER
		float max_score <- max([u_extinguish, u_move_fire, u_wander]);

		if (max_score <= 0.0) {
			current_action <- "WANDER";
		} else if (u_extinguish = max_score and water_supply > 0.0) {
			current_action <- "EXTINGUISH";
		} else if (u_move_fire = max_score and water_supply > 0.0) {
			current_action <- "MOVE_TO_FIRE";
		} else {
			current_action <- "WANDER";
		}
	}

	// Action dập lửa
	action extinguish (Fire target) {
		if (target != nil and water_supply > 0) {
			target.intensity <- target.intensity - 20.0;
			water_supply     <- max(0.0, water_supply - 5.0);

			if (target.intensity <= 0) {
				ask floor_cell(target.location) {
					is_fire        <- false;
					is_fire_hazard <- false;
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
		do compute_utility;

		Fire target_fire <- empty(Fire) ? nil : (Fire closest_to self);

		if (current_action = "EXTINGUISH") {
			if (target_fire != nil and (self distance_to target_fire <= 1.5)) {
				do extinguish(target_fire);
			}
		} else if (current_action = "MOVE_TO_FIRE") {
			if (target_fire != nil) {
				// Di chuyển trên room_graph tiếp cận ngọn lửa gần nhất
				do goto target: target_fire.location on: room_graph;
			}
		} else if (current_action = "WANDER") {
			floor_cell my_cell <- floor_cell(location);

			// A. TRƯỜNG HỢP HẾT NƯỚC (water_supply <= 0)
			if (water_supply <= 0.0) {
				// Khi đã ra tới ngoài sân (is_outside)
				if (my_cell != nil and my_cell.is_outside) {
					refill_timer <- refill_timer + 1;
					
					// Đủ 20 cycle tiếp nước -> hồi phục 100% bình nước và quay lại làm nhiệm vụ
					if (refill_timer >= 20) {
						water_supply <- 100.0;
						refill_timer <- 0;
					}
				} 
				// Khi chưa ra tới sân -> di chuyển ra ô ngoài sân NGAY CẠNH CỬA THOÁT HIỂM gần nhất
				else {
					floor_cell nearest_exit <- empty(exit_cells) ? nil : (exit_cells closest_to self);
					list<floor_cell> outside_cells <- floor_cell where (each.is_outside and not each.is_wall);
					floor_cell safe_outside <- nil;
					if (nearest_exit != nil) {
						safe_outside <- outside_cells closest_to nearest_exit;
					} else {
						safe_outside <- empty(outside_cells) ? nil : (outside_cells closest_to self);
					}
					
					if (safe_outside != nil) {
						do goto target: safe_outside.location on: room_graph;
					}
				}
			} 
			// B. TRƯỜNG HỢP CÒN NƯỚC NHƯNG ĐÃ DẬP SẠCH LỬA
			else {
				list<floor_cell> wander_cells <- floor_cell where (each.is_floor and not each.is_wall and not each.is_fire);
				if (!empty(wander_cells)) {
					do goto target: one_of(wander_cells).location on: room_graph;
				}
			}
		}
	}

	aspect default {
		draw rectangle(1.2, 1.2) color: color border: #black;
		// Trực quan hóa nhãn hành động trên đầu tác tử theo Mục 3.3 INTERFACE.md
		if (current_action != "IDLE") {
			draw current_action size: 1.2 color: #black at: location + {0, -1};
		}
	}
}

// ============ RESCUER ============
species Rescuer parent: RescueWorker {
	float calm_radius <- 4.0;
	string current_action <- "IDLE";
	init {
		color <- #cyan;
	}

	// Ghi đè stamina_loss: Tạm dừng trừ stamina khi đã ra ngoài sân (is_outside)
	reflex stamina_loss {
		floor_cell my_cell <- floor_cell(location);
		if (my_cell != nil and not my_cell.is_outside) {
			stamina <- max(0.0, stamina - 0.05);
		}
	}

	action compute_utility {
		list<Evacuee> target_evacuees <- Evacuee where (not each.is_escaped);
			if (!empty(target_evacuees)) {
				current_action <- "GUIDE";
			} else {
				current_action <- "WANDER";
		}
	}

	action guide (Evacuee target) {
		if (target != nil) {
			// 1. Kiểm tra xem đã có Evacuee nào ở sát bên trong bán kính calm_radius chưa
			list<Evacuee> nearby_evacuees <- Evacuee at_distance calm_radius where (not each.is_escaped);

			if (!empty(nearby_evacuees)) {
				// Trấn an những người đang ở gần (panic_level - 10.0, kẹp không âm theo Mục 8.5 & Ảnh 1, 2)
				ask nearby_evacuees {
					self.panic_level <- max(0.0, self.panic_level - 10.0);
				}
				// Khi đã có người đi cùng -> dẫn họ di chuyển về phía lối thoát hiểm gần nhất
				floor_cell safe_exit <- empty(exit_cells) ? nil : (exit_cells closest_to self);
				if (safe_exit != nil) {
					do goto target: safe_exit.location on: room_graph;
				}
			} else {
				// Nếu chưa có Evacuee ở sát bên -> tiếp tục đi sâu vào trong để tìm và tiếp cận Evacuee
				do goto target: target.location on: room_graph;
			}
		}
	}

	reflex main_decision {
		do compute_utility;

		if (current_action = "GUIDE") {
			list<Evacuee> unguided_evacuees <- Evacuee where (not each.is_escaped);
			if (!empty(unguided_evacuees)) {
				// Chọn người dân chưa thoát gần nhất để đi tìm
				Evacuee target <- unguided_evacuees closest_to self;
				do guide(target);
			}
		} else {
			// Khi không còn ai cần cứu -> rút lui ra ngoài sân an toàn, không đứng chắn cửa exit
			floor_cell nearest_exit <- empty(exit_cells) ? nil : (exit_cells closest_to self);
			list<floor_cell> outside_cells <- floor_cell where (each.is_outside and not each.is_wall);
			floor_cell safe_outside <- (nearest_exit != nil) ? (outside_cells closest_to nearest_exit) : (outside_cells closest_to self);
			if (safe_outside != nil) {
				do goto target: safe_outside.location on: room_graph;
			}
		}
	}

	// Khi di chuyển, dùng: do goto target: xxx on: room_graph;
	aspect default {
		draw triangle(1.3) color: color border: #black;
		// Trực quan hóa nhãn hành động trên đầu tác tử theo Mục 3.3 INTERFACE.md
		if (current_action != "IDLE") {
			draw current_action size: 1.2 color: #black at: location + {0, -1};
		}
	}

}

// ============ FIRE ============
species Fire {
	float intensity <- 100.0;
	bool is_active <- true;
	rgb color <- #red;

	// 1. Lan truyền lửa ngẫu nhiên
	reflex spread {
		if (is_active and flip(0.02)) { // 5% mỗi cycle --> 2%
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

