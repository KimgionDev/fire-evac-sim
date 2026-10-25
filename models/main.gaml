/**
 * Model: FireEvacuationSimulation
 * Description: Mô phỏng sơ tán khẩn cấp khi hỏa hoạn (Fire Evacuation Simulation)
 * Project: CT189 - Nhập môn Mô phỏng (Đại học Cần Thơ)
 */
model FireEvacuationSimulation

// ============ GLOBAL ============
global {
    // Kích thước bản đồ (50x50 ô)
    int grid_width  <- 50;
    int grid_height <- 50;

    // Số lượng tác tử
    int nb_evacuees      <- 40;
    int nb_firefighters  <- 2;
    int nb_rescuers      <- 1;
    int nb_initial_fires <- 2;

    // Chỉ số toàn cục cho chart
    int nb_escaped <- 0;
    int nb_dead    <- 0;
    int nb_panic   <- 0;

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
            location <- any_location_in(
                one_of(floor_cell where (each.is_room and not each.is_wall and not each.is_fire))
            );
        }
    }

    reflex update_panic_count {
        nb_panic <- length(Evacuee where (each.panic_level > 50.0 and not each.is_escaped));
    }

    // ===== TV1: Thiết lập bản đồ + exit_cells + room_graph =====
    action setup_map {
        ask floor_cell {
            int gx <- self.grid_x;
            int gy <- self.grid_y;

            // 1. Bên ngoài tòa nhà — vành đai 3 ô
            if (gx < 3 or gx > 46 or gy < 3 or gy > 46) {
                is_outside <- true;
                is_floor   <- true;
                is_wall    <- false;
                base_color <- rgb(235, 235, 235);
                color      <- base_color;
            }
            // 2. Tường bao ngoài & Cửa thoát hiểm
            else if (gx = 3 or gx = 46 or gy = 3 or gy = 46) {
                if ((gx = 3 or gx = 46) and (gy >= 16 and gy <= 18)) {
                    // Cửa thoát hiểm — 2 cửa ở 2 đầu hành lang, mỗi cửa rộng 3 ô
                    is_exit    <- true;
                    is_floor   <- true;
                    is_wall    <- false;
                    base_color <- rgb(46, 204, 113);
                    color      <- base_color;
                } else {
                    is_wall    <- true;
                    is_floor   <- false;
                    base_color <- rgb(60, 60, 60);
                    color      <- base_color;
                }
            }
            // 3. Bên trong tòa nhà
            else {
                // --- A. 4 Phòng họp cạnh trên (gy 4..14) ---
                if (gy >= 4 and gy <= 14) {
                    if (gx = 14 or gx = 25 or gx = 35) {
                        // Tường ngăn giữa 4 phòng
                        is_wall  <- true;
                        is_floor <- false;
                        base_color <- rgb(80, 80, 80);
                        color      <- base_color;
                    }
                    else if ((gy >= 7 and gy <= 10) and
                             ((gx >= 7 and gx <= 10) or
                              (gx >= 18 and gx <= 21) or
                              (gx >= 29 and gx <= 31) or
                              (gx >= 39 and gx <= 42))) {
                        // Bàn họp (vật cản)
                        is_wall  <- true;
                        is_floor <- false;
                        base_color <- rgb(130, 110, 90);
                        color      <- base_color;
                    }
                    else {
                        is_room  <- true;
                        is_floor <- true;
                        base_color <- rgb(230, 240, 255);
                        color      <- base_color;
                    }
                }
                // --- B. Vách ngăn phòng họp – hành lang (gy = 15) ---
                else if (gy = 15) {
                    if ((gx >= 8 and gx <= 9) or
                        (gx >= 19 and gx <= 20) or
                        (gx >= 29 and gx <= 30) or
                        (gx >= 40 and gx <= 41)) {
                        // Cửa phòng họp
                        is_floor   <- true;
                        is_wall    <- false;
                        base_color <- rgb(245, 245, 245);
                        color      <- base_color;
                    } else {
                        is_wall    <- true;
                        is_floor   <- false;
                        base_color <- rgb(80, 80, 80);
                        color      <- base_color;
                    }
                }
                // --- C. Hành lang chính (gy 16..18) — nối thẳng ra 2 cửa thoát ---
                else if (gy >= 16 and gy <= 18) {
                    is_floor   <- true;
                    is_wall    <- false;
                    base_color <- rgb(245, 245, 245);
                    color      <- base_color;
                }
                // --- D. Khu làm việc chung (gy 19..33) ---
                else if (gy >= 19 and gy <= 33) {
                    if (((gy >= 21 and gy <= 24) or (gy >= 27 and gy <= 30)) and
                        ((gx >= 7 and gx <= 12) or
                         (gx >= 17 and gx <= 22) or
                         (gx >= 27 and gx <= 32) or
                         (gx >= 37 and gx <= 42))) {
                        // Cụm bàn làm việc (vật cản)
                        is_wall  <- true;
                        is_floor <- false;
                        base_color <- rgb(120, 120, 120);
                        color      <- base_color;
                    } else {
                        is_room  <- true;
                        is_floor <- true;
                        base_color <- #white;
                        color      <- base_color;
                    }
                }
                // --- E. Hành lang chuyển tiếp (gy = 34) ---
                else if (gy = 34) {
                    is_floor   <- true;
                    is_wall    <- false;
                    base_color <- rgb(245, 245, 245);
                    color      <- base_color;
                }
                // --- F. Vách ngăn Bếp – Kho (gy = 35) ---
                else if (gy = 35) {
                    if ((gx >= 12 and gx <= 13) or (gx >= 34 and gx <= 35) or (gx >= 24 and gx <= 25)) {
                        is_floor   <- true;
                        is_wall    <- false;
                        base_color <- rgb(245, 245, 245);
                        color      <- base_color;
                    } else {
                        is_wall    <- true;
                        is_floor   <- false;
                        base_color <- rgb(80, 80, 80);
                        color      <- base_color;
                    }
                }
                // --- G. Khu vực phía dưới (gy 36..45) ---
                else if (gy >= 36 and gy <= 45) {
                    // Bếp / Pantry — góc dưới trái (gx 4..22)
                    if (gx >= 4 and gx <= 22) {
                        if ((gx >= 5 and gx <= 6 and gy >= 38 and gy <= 43) or
                            (gy >= 43 and gy <= 44 and gx >= 5 and gx <= 18)) {
                            // Kệ bếp (vật cản)
                            is_wall  <- true;
                            is_floor <- false;
                            base_color <- rgb(160, 120, 90);
                            color      <- base_color;
                        } else {
                            is_room    <- true;
                            is_kitchen <- true;
                            is_floor   <- true;
                            base_color <- rgb(255, 243, 224);
                            color      <- base_color;
                        }
                    }
                    // Tường ngăn Bếp – Kho (gx = 23)
                    else if (gx = 23) {
                        is_wall  <- true;
                        is_floor <- false;
                        base_color <- rgb(80, 80, 80);
                        color      <- base_color;
                    }
                    // Hành lang sảnh nối (gx 24..25)
                    else if (gx >= 24 and gx <= 25) {
                        is_floor   <- true;
                        is_wall    <- false;
                        base_color <- rgb(245, 245, 245);
                        color      <- base_color;
                    }
                    // Kho / Phòng nghỉ — góc dưới phải (gx 26..45)
                    else if (gx >= 26 and gx <= 45) {
                        if ((gy >= 38 and gy <= 42) and
                            ((gx >= 29 and gx <= 31) or (gx >= 37 and gx <= 39))) {
                            // Kệ kho (vật cản)
                            is_wall  <- true;
                            is_floor <- false;
                            base_color <- rgb(140, 140, 140);
                            color      <- base_color;
                        } else {
                            is_room  <- true;
                            is_floor <- true;
                            base_color <- rgb(240, 245, 235);
                            color      <- base_color;
                        }
                    }
                }
            }
        }

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
                    is_fire        <- true;
                    is_fire_hazard <- true;
                    color          <- rgb(231, 76, 60);
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
}

// ============ GRID  ============
grid floor_cell width: grid_width height: grid_height {
    bool is_wall        <- false;
    bool is_floor       <- true;
    bool is_exit        <- false;
    bool is_fire        <- false;
    bool is_fire_hazard <- false;
    bool is_room        <- false;
    bool is_kitchen     <- false;
    bool is_outside     <- false;
    rgb  base_color     <- #white; 
    rgb  color          <- #white;

    action update_color {
        if (is_fire) {
            color <- rgb(231, 76, 60); 
        } else if (is_fire_hazard) {
            color <- rgb(243, 156, 18); 
        } else if (is_exit) {
            color <- rgb(46, 204, 113); 
        } else {
            color <- base_color;
        }
    }
}

// ============ EVACUEE ============
// Do thành viên TV2 phụ trách cài đặt hành vi
species Evacuee skills: [moving] {
    float stamina     <- 100.0;
    float panic_level <- 0.0;
    float speed       <- rnd(0.4, 0.7);
    float vision      <- 12.0;
    bool  is_escaped  <- false;
    bool  is_guided   <- false;
    string current_action <- "EVACUATE";
    
    // 4 biến lưu điểm số tiện ích vừa tính được
    float u_evacuate <- 0.0;
    float u_flee     <- 0.0;
    float u_follow   <- 0.0;
    float u_flock    <- 0.0;

    action compute_utility {
	    u_evacuate <- 0.0;
	    u_flee     <- 0.0;
	    u_follow   <- 0.0;
	    u_flock    <- 0.0;
	    
	    floor_cell nearest_exit <- empty(exit_cells) ? nil : (exit_cells closest_to self);
	    Fire nearest_fire <- empty(Fire) ? nil : (Fire closest_to self);
	    Rescuer nearest_rescuer <- empty(Rescuer) ? nil : (Rescuer closest_to self);
	    
	    list<Evacuee> nearby_evacuees <- Evacuee at_distance 6.0 where (each != self and not each.is_escaped);
	    int nearby_count <- length(nearby_evacuees);
	    
	    if (is_guided) {
	        u_follow <- 100.0;
	        current_action <- "FOLLOW_LEADER";
	        return;
	    }

	    if (nearest_exit != nil) {
            u_evacuate <- u_evacuate + 40.0;
            if ((self distance_to nearest_exit) <= vision) { u_evacuate <- u_evacuate + 30.0; }
	        if (stamina < 30.0) { u_evacuate <- u_evacuate + 20.0; }
	    }
	    
	    if (nearest_fire != nil and (self distance_to nearest_fire) <= vision) {
	        float dist_fire <- self distance_to nearest_fire;
	        if (dist_fire <= 4.0) { u_flee <- u_flee + 70.0; }
	        else if (dist_fire <= 8.0) { u_flee <- u_flee + 40.0; }
	    }
	    
	    if (nearest_rescuer != nil and (self distance_to nearest_rescuer) <= 3.0) {
	        u_follow <- u_follow + 60.0;
	    }
	    
	    if (nearby_count >= 1) {
	        u_flock <- u_flock + 30.0;
	        if (nearby_count >= 3) { u_flock <- u_flock + 20.0; }
	    }
	    
	    float max_score <- max([u_flee, u_evacuate, u_follow, u_flock]);
	    
	    if (max_score <= 0.0) {
	        current_action <- "EVACUATE";
	    } else if (u_flee = max_score) {
	        current_action <- "FLEE_FIRE";
	    } else if (u_evacuate = max_score) {
	        current_action <- "EVACUATE";
	    } else if (u_follow = max_score) {
	        current_action <- "FOLLOW_LEADER";
	    } else {
	        current_action <- "FLOCK";
	    }
    }

    action flee_from (Fire target) {
        if (target != nil) {
            list<floor_cell> neighbor_floors <- floor_cell(location).neighbors where (each.is_floor and not each.is_wall and not each.is_fire);
            if (!empty(neighbor_floors)) {
                floor_cell best_cell <- neighbor_floors farthest_to target;
                if (best_cell != nil) {
                    do goto target: best_cell.location on: room_graph;
                } else {
                    do wander_random;
                }
            } else {
                do wander_random;
            }
        } else {
            do wander_random;
        }
    }

    action evacuate (floor_cell target_exit) {
        if (target_exit != nil) {
            do goto target: target_exit.location on: room_graph;
        } else {
            do wander_random;
        }
    }

    action follow_leader (Rescuer leader) {
        if (leader != nil) {
            do goto target: leader.location on: room_graph;
        } else {
            floor_cell target_exit <- empty(exit_cells) ? nil : (exit_cells closest_to self);
            do evacuate(target_exit);
        }
    }

    action flock {
        list<Evacuee> nearby <- Evacuee at_distance 6.0 where (each != self and not each.is_escaped);
        floor_cell nearest_exit <- empty(exit_cells) ? nil : (exit_cells closest_to self);
        
        if (!empty(nearby)) {
            point center_pos <- mean(nearby collect each.location);
            if (nearest_exit != nil) {
                point target_pos <- { (center_pos.x + nearest_exit.location.x) / 2.0, (center_pos.y + nearest_exit.location.y) / 2.0 };
                do goto target: target_pos on: room_graph;
            } else {
                do goto target: center_pos on: room_graph;
            }
        } else if (nearest_exit != nil) {
            do evacuate(nearest_exit);
        } else {
            do wander_random;
        }
    }

    action wander_random {
        list<floor_cell> neighbor_floors <- floor_cell(location).neighbors where (each.is_floor and not each.is_wall and not each.is_fire);
        if (!empty(neighbor_floors)) {
            floor_cell random_cell <- one_of(neighbor_floors);
            do goto target: random_cell.location on: room_graph;
        }
    }
    
    reflex main_decision {
	    stamina <- max(0.0, stamina - 0.05);
	    
	    Fire nearest_fire <- empty(Fire) ? nil : (Fire closest_to self);
	    if (nearest_fire != nil and (self distance_to nearest_fire) <= 5.0 and not is_guided) {
	        panic_level <- min(100.0, panic_level + 2.0);
	    }

        floor_cell current_cell <- floor_cell(location);
        floor_cell nearest_exit <- empty(exit_cells) ? nil : (exit_cells closest_to self);
        
	    if (current_cell.is_exit or (nearest_exit != nil and (self distance_to nearest_exit) <= 1.0)) {
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

        if (current_action = "FLEE_FIRE") {
            do flee_from(nearest_fire);
        } else if (current_action = "EVACUATE") {
            do evacuate(nearest_exit);
        } else if (current_action = "FOLLOW_LEADER") {
            Rescuer leader <- empty(Rescuer) ? nil : (Rescuer closest_to self);
            do follow_leader(leader);
        } else if (current_action = "FLOCK") {
            do flock;
        } else {
            do wander_random;
        }
    }
	    
    aspect default {
        rgb my_color <- #blue;
        
        if (panic_level > 50.0 and not is_guided) {
            my_color <- #red;
        } else if (is_guided or (panic_level <= 20.0 and current_action = "EVACUATE")) {
            my_color <- #green;
        } else if (current_action = "FLOCK") {
            my_color <- rgb(155, 89, 182);
        }
       
        draw circle(0.6) color: my_color border: #black;
        
        if (current_action != "IDLE") {
            draw current_action size: 1.2 color: #black at: location + {0, -1};
        }
    }
}

// ============ RESCUEWORKER ============
species RescueWorker skills: [moving] {
    float stamina <- 300.0;
    float speed   <- 0.8;
    float vision  <- 15.0;
    rgb color     <- #blue;

    reflex stamina_loss {
        stamina <- max(0.0, stamina - 0.05);
    }

    aspect default {
        draw circle(1.0) color: color border: #black;
    }
}

// ============ FIREFIGHTER ============
species Firefighter parent: RescueWorker {
    float water_supply <- 100.0;

    init {
        stamina <- 250.0;
        speed   <- 1.0;
        color   <- #yellow;
    }

    action compute_utility {}

    // Action dập lửa
    action extinguish (Fire target) {
        if (target != nil and water_supply > 0) {
            target.intensity <- target.intensity - 20.0;  // Giảm 20 theo INTERFACE
            water_supply     <- max(0.0, water_supply - 5.0);  // Giảm 5 theo INTERFACE
            
            // Nếu ngọn lửa bị dập tắt hoàn toàn
            if (target.intensity <= 0) {
                ask floor_cell(target.location) {
                    is_fire        <- false;
                    is_fire_hazard <- false;  // Xóa cờ nguy hiểm
                    do update_color;
                }
                ask target {
                    do die;
                }
            }
        }
    }

    reflex check_death {
        if (stamina <= 0.0) {
            write "[TỬ VONG] Lính dập lửa " + name + " đã hy sinh trong hỏa hoạn tại cycle " + cycle;
            do die;
        }
    }

    // Logic quyết định di chuyển & dập lửa
    reflex main_decision {
        Fire target_fire <- empty(Fire) ? nil : (Fire closest_to self);
        if (target_fire != nil) {
            if (self distance_to target_fire <= 1.8) {
                do extinguish(target_fire);
            } else {
                do goto target: target_fire.location on: room_graph;
            }
        } else {
            floor_cell safe_exit <- empty(exit_cells) ? nil : (exit_cells closest_to self);
            if (safe_exit != nil) {
                do goto target: safe_exit.location on: room_graph;
            }
        }
    }

    aspect default {
        draw rectangle(1.2, 1.2) color: color border: #black;
        draw "Firefighter" size: 1.0 color: #black at: location + {0, -1};
    }
}

// ============ RESCUER ============
species Rescuer parent: RescueWorker {
    float calm_radius <- 2.0;

    init {
        color <- #cyan;
    }

    action compute_utility {}

    reflex check_death {
        if (stamina <= 0.0) {
            write "[TỬ VONG] Lực lượng cứu hộ " + name + " đã hy sinh tại cycle " + cycle;
            do die;
        }
    }

    reflex main_decision {
        list<Evacuee> nearby_touching <- Evacuee at_distance calm_radius where (not each.is_escaped);
        ask nearby_touching {
            self.panic_level <- 0.0;
            self.is_guided   <- true;
        }

        list<Evacuee> my_guided_followers <- Evacuee at_distance 8.0 where (not each.is_escaped and each.is_guided);

        if (!empty(my_guided_followers)) {
            floor_cell safe_exit <- empty(exit_cells) ? nil : (exit_cells closest_to self);
            if (safe_exit != nil) {
                do goto target: safe_exit.location on: room_graph;
            }
        } else {
            list<Evacuee> unguided_evacuees <- Evacuee where (not each.is_escaped and not each.is_guided);
            if (!empty(unguided_evacuees)) {
                Evacuee target <- unguided_evacuees closest_to self;
                if (target != nil) {
                    do goto target: target.location on: room_graph;
                }
            } else {
                floor_cell safe_exit <- empty(exit_cells) ? nil : (exit_cells closest_to self);
                if (safe_exit != nil) {
                    do goto target: safe_exit.location on: room_graph;
                }
            }
        }
    }

    aspect default {
        draw triangle(1.3) color: color border: #black;
        draw "Rescuer" size: 1.0 color: #black at: location + {0, -1};
    }
}

// ============ FIRE ============
species Fire {
    float intensity <- 100.0;
    bool  is_active <- true;
    rgb   color     <- #red;

    // 1. Lan truyền lửa ngẫu nhiên
    reflex spread {
        if (is_active and flip(0.05)) {  // 5% mỗi cycle
            floor_cell current_cell <- floor_cell(location);
            if (current_cell != nil) {
                // Không lan vào tường, ô đã có lửa, và không lan ra ngoài sân
                list<floor_cell> neighbor_cells <- current_cell.neighbors where (not each.is_wall and not each.is_fire and not each.is_outside);
                if (!empty(neighbor_cells)) {
                    floor_cell target_cell <- one_of(neighbor_cells);
                    create Fire {
                        location  <- target_cell.location;
                        intensity <- 50.0;  // Lửa mới tạo có intensity = 50
                        ask target_cell {
                            is_fire        <- true;
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
            stamina <- max(0.0, stamina - 5.0);  // Sát thương 5.0
        }

        // Trừ stamina của cứu hộ (phải gộp Firefighter + Rescuer vì RescueWorker bị rỗng)
        list<RescueWorker> nearby_workers <- (Firefighter + Rescuer) at_distance 1.5;
        ask nearby_workers {
            stamina <- max(0.0, stamina - 3.0);  // Sát thương 3.0
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
            grid floor_cell border: #black;
            species Fire aspect: default;
            species Firefighter aspect: default;
            species Rescuer aspect: default;
            species Evacuee aspect: default;
        }

        display chart_display refresh: every(1#cycle) {
            chart "Thống kê tình trạng sơ tán (Tuần 3)" type: series {
                data "Số người thoát hiểm" value: nb_escaped color: #green;
                data "Số người tử vong" value: nb_dead color: #red;
                data "Số người hoảng loạn" value: nb_panic color: #orange;
            }
        }
    }
}