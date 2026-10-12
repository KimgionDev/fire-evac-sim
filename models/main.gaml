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

	// Khai báo số lượng tác tử ---
    int nb_firefighters <- 2; // 2 Lính dập lửa
    int nb_rescuers     <- 1; // 1 Lính cứu hộ/dẫn người

    init {
        // Khởi tạo layout văn phòng và gán cờ cho từng ô floor_cell
        do setup_map;
        do setup_fire_and_rescuers;
    }

    action setup_map {
        ask floor_cell {
            int gx <- self.grid_x;
            int gy <- self.grid_y;

            // 1. Bên ngoài tòa nhà (Outside area) - vành đai viền 3 ô
            if (gx < 3 or gx > 46 or gy < 3 or gy > 46) {
                is_outside <- true;
                is_floor   <- true;
                is_wall    <- false;
                color      <- rgb(235, 235, 235);
            }
            // 2. Tường bao ngoài tòa nhà (Perimeter walls)
            else if (gx = 3 or gx = 46 or gy = 3 or gy = 46) {
                // 2 cửa thoát hiểm ở 2 đầu hành lang chính (gy từ 16 đến 18)
                if ((gx = 3 or gx = 46) and (gy >= 16 and gy <= 18)) {
                    is_exit    <- true;
                    is_floor   <- true;
                    is_wall    <- false;
                    color      <- rgb(46, 204, 113); // Màu xanh lá cửa thoát hiểm
                } else {
                    is_wall    <- true;
                    is_floor   <- false;
                    color      <- rgb(60, 60, 60);  // Tường màu xám đậm
                }
            }
            // 3. Bên trong tòa nhà
            else {
                // --- A. 4 Phòng họp ở cạnh trên (gy từ 4 đến 14) ---
                if (gy >= 4 and gy <= 14) {
                    // Tường ngăn giữa 4 phòng họp
                    if (gx = 14 or gx = 25 or gx = 35) {
                        is_wall  <- true;
                        is_floor <- false;
                        color    <- rgb(80, 80, 80);
                    }
                    // Bàn họp trong các phòng (vật cản)
                    else if ((gy >= 7 and gy <= 10) and
                             ((gx >= 7 and gx <= 10) or
                              (gx >= 18 and gx <= 21) or
                              (gx >= 29 and gx <= 31) or
                              (gx >= 39 and gx <= 42))) {
                        is_wall  <- true;
                        is_floor <- false;
                        color    <- rgb(130, 110, 90); // Bàn gỗ
                    }
                    else {
                        is_room  <- true;
                        is_floor <- true;
                        color    <- rgb(230, 240, 255); // Sàn phòng họp
                    }
                }
                // --- B. Vách tường ngăn phòng họp với hành lang (gy = 15) ---
                else if (gy = 15) {
                    // Cửa ra vào của 4 phòng họp mở ra hành lang
                    if ((gx >= 8 and gx <= 9) or
                        (gx >= 19 and gx <= 20) or
                        (gx >= 29 and gx <= 30) or
                        (gx >= 40 and gx <= 41)) {
                        is_floor <- true;
                        is_wall  <- false;
                        color    <- rgb(245, 245, 245);
                    } else {
                        is_wall  <- true;
                        is_floor <- false;
                        color    <- rgb(80, 80, 80);
                    }
                }
                // --- C. Hành lang chính thông giữa 2 cửa thoát hiểm (gy từ 16 đến 18) ---
                else if (gy >= 16 and gy <= 18) {
                    is_floor <- true;
                    is_wall  <- false;
                    color    <- rgb(245, 245, 245);
                }
                // --- D. Khu làm việc chung ở giữa (gy từ 19 đến 33) ---
                else if (gy >= 19 and gy <= 33) {
                    // Các cụm bàn làm việc (bàn ghế là vật cản)
                    if (((gy >= 21 and gy <= 24) or (gy >= 27 and gy <= 30)) and
                        ((gx >= 7 and gx <= 12) or
                         (gx >= 17 and gx <= 22) or
                         (gx >= 27 and gx <= 32) or
                         (gx >= 37 and gx <= 42))) {
                        is_wall  <- true;
                        is_floor <- false;
                        color    <- rgb(120, 120, 120); // Bàn ghế làm việc
                    } else {
                        is_room  <- true;
                        is_floor <- true;
                        color    <- #white; // Lối đi khu làm việc
                    }
                }
                // --- E. Hành lang chuyển tiếp phía dưới (gy = 34) ---
                else if (gy = 34) {
                    is_floor <- true;
                    is_wall  <- false;
                    color    <- rgb(245, 245, 245);
                }
                // --- F. Vách ngăn vào Bếp và Kho (gy = 35) ---
                else if (gy = 35) {
                    // Cửa vào Bếp (gx: 12..13), sảnh giữa (gx: 24..25), cửa vào Kho (gx: 34..35)
                    if ((gx >= 12 and gx <= 13) or (gx >= 34 and gx <= 35) or (gx >= 24 and gx <= 25)) {
                        is_floor <- true;
                        is_wall  <- false;
                        color    <- rgb(245, 245, 245);
                    } else {
                        is_wall  <- true;
                        is_floor <- false;
                        color    <- rgb(80, 80, 80);
                    }
                }
                // --- G. Khu vực phía dưới (gy từ 36 đến 45) ---
                else if (gy >= 36 and gy <= 45) {
                    // Bếp / Pantry ở góc dưới trái (gx từ 4 đến 22) - Nơi phát hỏa
                    if (gx >= 4 and gx <= 22) {
                        // Kệ bếp / quầy pantry (vật cản)
                        if ((gx >= 5 and gx <= 6 and gy >= 38 and gy <= 43) or
                            (gy >= 43 and gy <= 44 and gx >= 5 and gx <= 18)) {
                            is_wall    <- true;
                            is_floor   <- false;
                            color      <- rgb(160, 120, 90);
                        } else {
                            is_room    <- true;
                            is_kitchen <- true;
                            is_floor   <- true;
                            color      <- rgb(255, 243, 224); // Màu ấm của bếp
                        }
                    }
                    // Tường ngăn cách giữa Bếp và Kho (gx = 23)
                    else if (gx = 23) {
                        is_wall  <- true;
                        is_floor <- false;
                        color    <- rgb(80, 80, 80);
                    }
                    // Hành lang sảnh nối phía dưới (gx: 24..25)
                    else if (gx >= 24 and gx <= 25) {
                        is_floor <- true;
                        is_wall  <- false;
                        color    <- rgb(245, 245, 245);
                    }
                    // Kho / Phòng nghỉ ở góc dưới phải (gx từ 26 đến 45)
                    else if (gx >= 26 and gx <= 45) {
                        // Kệ kho chứa đồ (vật cản)
                        if ((gy >= 38 and gy <= 42) and
                            ((gx >= 29 and gx <= 31) or (gx >= 37 and gx <= 39))) {
                            is_wall  <- true;
                            is_floor <- false;
                            color    <- rgb(140, 140, 140); // Kệ kho
                        } else {
                            is_room  <- true;
                            is_floor <- true;
                            color    <- rgb(240, 245, 235); // Màu khu kho/nghỉ
                        }
                    }
                }
            }
        }
    }

    // --- Hàm tạo Lửa và Lính cứu hộ ---
    action setup_fire_and_rescuers {
        // A. Tạo Ngọn lửa (Fire) tại khu vực Bếp và đánh dấu ô lưới
        list<floor_cell> kitchen_cells <- floor_cell where (each.is_kitchen and !each.is_wall);
        if (!empty(kitchen_cells)) {
            create Fire number: 2 {
                location <- one_of(kitchen_cells).location;
                ask floor_cell(location) {
                    is_fire        <- true;
                    is_fire_hazard <- true;
                }
            }
        } else {
            // Dự phòng nếu chưa tìm thấy ô kitchen
            create Fire number: 2 { 
                location <- {15.0, 38.0}; 
                ask floor_cell(location) {
                    is_fire        <- true;
                    is_fire_hazard <- true;
                }
            }
        }
        
        // B. Tạo Firefighter & Rescuer ở Bên ngoài tòa nhà
        list<floor_cell> outside_cells <- floor_cell where (each.is_outside);
        if (!empty(outside_cells)) {
            create Firefighter number: nb_firefighters {
                location <- one_of(outside_cells).location;
            }
            create Rescuer number: nb_rescuers {
                location <- one_of(outside_cells).location;
            }
        } else {
            // Dự phòng tọa độ ngoài tòa nhà
            create Firefighter number: nb_firefighters { location <- {5.0, 48.0}; }
            create Rescuer number: nb_rescuers { location <- {45.0, 48.0}; }
        }
        
        // In dòng kiểm tra ra Console
        write "========================================";
        write "DA TAO THANH CONG: " + length(Firefighter) + " Firefighter, " + length(Rescuer) + " Rescuer, " + length(Fire) + " Fire";
        write "========================================";
    }
}

// ============ GRID  ============
grid floor_cell width: grid_width height: grid_height {
    bool is_wall        <- false;  // Tường, bàn ghế, vật cản (không đi qua được)
    bool is_floor       <- true;   // Ô đi được (mặc định, = not is_wall)
    bool is_exit        <- false;  // Cửa thoát hiểm (chạm vào là thoát thành công)
    bool is_fire        <- false;  // Ô đang có lửa
    bool is_fire_hazard <- false;  // Ô lửa/khói gây hại
    bool is_room        <- false;  // Phòng họp, khu làm việc, bếp, kho
    bool is_kitchen     <- false;  // Bếp — nơi phát hỏa
    bool is_outside     <- false;  // Bên ngoài tòa nhà
    rgb  color          <- #white;
}

// ============ EVACUEE ============
// Do thành viên TV2 (AI Evacuee) phụ trách cài đặt

// ============ RESCUEWORKER (cha) ============
species RescueWorker skills: [moving] {
    float stamina <- 200.0;
    float speed <- 1.2;
    float vision <- 15.0;
    rgb color <- #blue;
    
    aspect default {
        draw circle(1.0) color: color;
    }
}


// ============ FIREFIGHTER (con) ============
species Firefighter parent: RescueWorker {
    float water_supply <- 100.0;
    
    init {
        color <- #yellow;
    }
    
    reflex wander_outside {
        do wander bounds: union((floor_cell where (each.is_outside)) collect (each.shape));
    }
    
    aspect default {
        draw rectangle(1.2, 1.2) color: color;
    }
}

// ============ RESCUER (con) ============
species Rescuer parent: RescueWorker {
    float calm_radius <- 4.0;
    
    init {
        color <- #cyan;
    }
    
    reflex wander_outside {
        do wander bounds: union((floor_cell where (each.is_outside)) collect (each.shape));
    }
    
    aspect default {
        draw triangle(1.3) color: color;
    }
}

// ============ FIRE ============
species Fire {
    float intensity <- 100.0;
    bool  is_active <- true;
    rgb   color     <- #red;
    
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
        }
    }
}
