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
    float speed       <- rnd(1.0, 1.5);
    float vision      <- 10.0;
    bool  is_escaped  <- false;

    // TODO (TV2): action compute_utility
    // TODO (TV2): action flee_from, evacuate, follow_leader, flock
    // TODO (TV2): reflex main_decision
    // Khi di chuyển, dùng: do goto target: xxx on: room_graph;

    aspect default {
        draw circle(0.5) color: #blue border: #black;
    }
}

// ============ RESCUEWORKER (cha) ============
species RescueWorker skills: [moving] {
    float stamina <- 200.0;
    float speed   <- 1.2;
    float vision  <- 15.0;
    rgb color     <- #blue;

    // TODO (TV3): reflex stamina_loss

    aspect default {
        draw circle(1.0) color: color border: #black;
    }
}

// ============ FIREFIGHTER (con) ============
species Firefighter parent: RescueWorker {
    float water_supply <- 100.0;

    init {
        color <- #yellow;
    }

    // TODO (TV3): action compute_utility, action extinguish
    // TODO (TV3): reflex main_decision
    // Khi di chuyển, dùng: do goto target: xxx on: room_graph;

    aspect default {
        draw rectangle(1.2, 1.2) color: color border: #black;
    }
}

// ============ RESCUER (con) ============
species Rescuer parent: RescueWorker {
    float calm_radius <- 4.0;

    init {
        color <- #cyan;
    }

    // TODO (TV3): action compute_utility, action guide
    // TODO (TV3): reflex main_decision
    // Khi di chuyển, dùng: do goto target: xxx on: room_graph;

    aspect default {
        draw triangle(1.3) color: color border: #black;
    }
}

// ============ FIRE ============
species Fire {
    float intensity <- 100.0;
    bool  is_active <- true;
    rgb   color     <- #red;

    // TODO (TV4): reflex spread
    // TODO (TV4): reflex damage

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
    }
}
