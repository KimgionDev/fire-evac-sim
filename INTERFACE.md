
---
```markdown
# INTERFACE.md — Fire Evacuation Simulation (GAMA)
> Mọi người code theo file này.

---

## 0. Thông tin chung

- **Tên model:** `FireEvacuationSimulation`
- **Ngôn ngữ:** GAML (GAMA Platform)
- **File chính:** `main.gaml` (1 file duy nhất, chia comment rõ ràng)
- **Tên experiment:** `FireEvacuation`
- **Quy ước đặt tên:** `snake_case` cho biến/thuộc tính, `PascalCase` cho species
- **Bản đồ:** 50 x 50 ô, top-down

---

## 1. Cấu trúc `global`

```gaml
global {
    // Kích thước bản đồ
    int grid_width  <- 50;
    int grid_height <- 50;

    // Số lượng tác tử
    int nb_evacuees        <- 40;
    int nb_firefighters    <- 2;
    int nb_rescuers        <- 1;
    int nb_initial_fires   <- 2;

    // Chỉ số toàn cục cho chart
    int nb_escaped <- 0;   // số người thoát thành công
    int nb_dead    <- 0;   // số thương vong
    int nb_panic   <- 0;   // số người đang hoảng loạn (panic_level > 70)

    init {
        // Evacuee spawn TRONG các phòng (không đè lửa, không đè tường)
        create Evacuee number: nb_evacuees {
            location <- any_location_in(
                one_of(floor_cell where (each.is_room
                                         and not each.is_wall
                                         and not each.is_fire))
            );
        }

        // Firefighter spawn NGOÀI tòa nhà
        create Firefighter number: nb_firefighters {
            location <- any_location_in(
                one_of(floor_cell where (each.is_outside
                                         and not each.is_wall))
            );
        }

        // Rescuer spawn NGOÀI tòa nhà
        create Rescuer number: nb_rescuers {
            location <- any_location_in(
                one_of(floor_cell where (each.is_outside
                                         and not each.is_wall))
            );
        }

        // Lửa bùng phát NGAY tại bếp
        create Fire number: nb_initial_fires {
            location <- any_location_in(
                one_of(floor_cell where (each.is_kitchen
                                         and not each.is_wall))
            );
        }
    }
}
```

---

## 2. Cờ trên `floor_cell`

```gaml
grid floor_cell width: grid_width height: grid_height {
    bool is_wall        <- false;  // tường, bàn ghế, vật cản
    bool is_floor       <- true;   // ô đi được (mặc định, = not is_wall)
    bool is_exit        <- false;  // cửa thoát hiểm
    bool is_fire        <- false;  // ô đang có lửa
    bool is_fire_hazard <- false;  // ô lửa/khói gây hại
    bool is_room        <- false;  // phòng họp, khu làm việc, bếp, kho
    bool is_kitchen     <- false;  // bếp — nơi phát hỏa
    bool is_outside     <- false;  // bên ngoài tòa nhà
    rgb  color          <- #white;
}
```

**Quy ước tập con:**

| Quan hệ | Ý nghĩa |
|---|---|
| `is_exit ⊂ is_floor` | Cửa thoát hiểm là ô đi được |
| `is_room ⊂ is_floor` | Phòng là ô đi được |
| `is_kitchen ⊂ is_room` | Bếp nằm trong khu phòng |
| `is_outside ⊂ is_floor` | Bên ngoài là ô đi được |
| `is_fire ⊂ is_fire_hazard` | Ban đầu 2 cờ này bằng nhau, sau có thể thêm khói |
| `is_wall ⇒ not is_floor` | Tường thì không đi được |

---

## 3. Species & thuộc tính

### 3.1. Danh sách species

| Species | Parent | Spawn trực tiếp? |
|---|---|---|
| `Evacuee` | — | ✅ Có |
| `RescueWorker` | — | ❌ Không (species cha trừu tượng) |
| `Firefighter` | `RescueWorker` | ✅ Có |
| `Rescuer` | `RescueWorker` | ✅ Có |
| `Fire` | — | ✅ Có |

### 3.2. Thuộc tính

```gaml
species Evacuee skills: [moving] {
    float stamina         <- 100.0;   // clamp >= 0
    float panic_level     <- 0.0;     // clamp 0..100
    float speed           <- 1.0;     // 1.0 .. 1.5
    float vision          <- 10.0;
    bool  is_escaped      <- false;
    string current_action <- "IDLE";  // FLEE_FIRE, EVACUATE, FOLLOW_LEADER, FLOCK
    float u_evacuate      <- 0.0;
    float u_flee          <- 0.0;
    float u_follow        <- 0.0;
    float u_flock         <- 0.0;
}

species RescueWorker skills: [moving] {
    float stamina <- 200.0;
    float speed   <- 1.2;
    float vision  <- 15.0;
}

species Firefighter parent: RescueWorker {
    float water_supply    <- 100.0;   // clamp >= 0
    string current_action <- "WANDER"; // EXTINGUISH, MOVE_TO_FIRE, WANDER
    float u_extinguish    <- 0.0;
    float u_move_fire     <- 0.0;
    float u_wander        <- 0.0;
    int refill_timer      <- 0;       // Đếm số cycle tiếp nước ngoài sân
}

species Rescuer parent: RescueWorker {
    float calm_radius     <- 4.0;
    string current_action <- "WANDER"; // GUIDE, WANDER
    float u_guide         <- 0.0;
    float u_wander        <- 0.0;
}

species Fire {
    float intensity <- 100.0;  // clamp >= 0
    bool  is_active <- true;
}
```

**Quy ước bắt buộc:**
- `panic_level` luôn `clamp(panic_level, 0, 100)`.
- `stamina` không âm, `<= 0` thì chết.
- `water_supply` không âm, `<= 0` thì không được EXTINGUISH:
  - Khi `water_supply <= 0`, Firefighter chuyển trạng thái `WANDER` với mục tiêu **rút lui ra ngoài sân (`is_outside`)**, **TUYỆT ĐỐI KHÔNG** dừng lại đứng chắn ở ô cửa thoát hiểm (`is_exit`) để tránh chặn đường `Evacuee`.
  - **Cơ chế tiếp nước ngoài sân (Refill Water):**
    + Khi Firefighter đã ra đến ô ngoài sân (`is_outside`), tạm dừng trừ `stamina` (an toàn, không hít khói).
    + Sau khi ở ngoài sân đủ **20 cycle** tiếp nước từ xe cứu hỏa ngoài tòa nhà (`refill_timer >= 20`), `water_supply` được hồi phục đầy `100.0` và `refill_timer <- 0` để tiếp tục tiến vào tòa nhà dập lửa.
- `is_escaped = true` ⇒ không tính là thương vong.

### 3.3. Quy định hiển thị (`aspect default`)

Để đồng bộ hiển thị và trực quan hóa trạng thái AI thời gian thực trên giao diện mô phỏng:
- Mọi tác tử người (`Evacuee`, `Firefighter`, `Rescuer`) cần hiển thị nhãn hành động hiện tại trên đầu:
  ```gaml
  if (current_action != "IDLE") {
      draw current_action size: 1.2 color: #black at: location + {0, -1};
  }
  ```
- Màu sắc cơ bản theo quy ước:
  - `Evacuee`: Đổi màu linh hoạt theo trạng thái (FLEE: đỏ, EVACUATE: xanh lá, FOLLOW: vàng, FLOCK: tím).
  - `Firefighter`: `#yellow`, hình chữ nhật `rectangle(1.2, 1.2)`.
  - `Rescuer`: `#cyan`, hình tam giác `triangle(1.3)`.
  - `Fire`: Hình tròn/vuông chuyển từ đỏ sang cam theo intensity.

---

## 4. Action & reflex signatures

### 4.1. Evacuee

```gaml
action compute_utility
action flee_from(Fire target)
action evacuate(floor_cell target_exit)
action follow_leader(RescueWorker leader)
action flock
reflex main_decision
```

### 4.2. Firefighter

```gaml
action compute_utility
action extinguish(Fire target)
reflex main_decision
```

### 4.3. Rescuer

```gaml
action compute_utility
action guide(Evacuee target)
reflex main_decision
```

### 4.4. Fire

```gaml
reflex spread
reflex damage
```

### 4.5. RescueWorker

```gaml
reflex stamina_loss
```

---

## 5. Tên action Utility & Tie-break

> **Lưu ý:** `INTERFACE.md` quy định chuẩn tên action, thứ tự tie-break và biến dùng chung. Chi tiết công thức tính điểm và bảng ma trận utility của từng tác tử xem tại file **`docs/de-bai-do-an.md` (Chương 2)**.

### 5.1. Tên action logic

| Tác tử | Action |
|---|---|
| Evacuee | `FLEE_FIRE`, `EVACUATE`, `FOLLOW_LEADER`, `FLOCK` |
| Firefighter | `EXTINGUISH`, `MOVE_TO_FIRE`, `WANDER` |
| Rescuer | `GUIDE`, `WANDER` |

### 5.2. Thứ tự ưu tiên khi hòa điểm

- **Evacuee:** `FLEE_FIRE > EVACUATE > FOLLOW_LEADER > FLOCK`
- **Firefighter:** `EXTINGUISH > MOVE_TO_FIRE > WANDER`
- **Rescuer:** `GUIDE > WANDER`

---

## 6. Quy tắc spawn (chốt cứng)

| Tác tử | Số lượng | Điều kiện ô spawn |
|---|---|---|
| Evacuee | 40 | `is_room = true AND is_wall = false AND is_fire = false` |
| Firefighter | 2 | `is_outside = true AND is_wall = false` |
| Rescuer | 1 | `is_outside = true AND is_wall = false` |
| Fire | 2 | `is_kitchen = true AND is_wall = false` |

**Lưu ý & Cân bằng phân bổ:**
- Evacuee KHÔNG spawn đè ô lửa.
- **Phân bổ số lượng Evacuee theo diện tích phòng:**
  - Khu làm việc chung (giữa tầng): ~20 người (khu vực đông đúc nhất).
  - 4 Phòng họp (cạnh trên): ~12 người (~3 người mỗi phòng).
  - Bếp/Pantry và Kho (cạnh dưới): ~8 người (bếp ~3 người, kho ~5 người).
- **Mức `panic_level` ban đầu:** Gán tỷ lệ với khoảng cách tới bếp phát hỏa (người ở bếp xuất phát `panic = 40.0 - 50.0`, khu làm việc `panic = 10.0 - 20.0`, phòng họp xa lửa `panic = 0.0 - 5.0`).
- Firefighter/Rescuer spawn ngoài tòa nhà, di chuyển vào trong.
- Fire bùng phát ngay từ bước 0 tại bếp.

---

## 7. Chỉ số toàn cục & Chart

### 7.1. Biến toàn cục

```gaml
int nb_escaped <- 0;   // thoát thành công
int nb_dead    <- 0;   // thương vong
int nb_panic   <- 0;   // đang hoảng loạn (panic_level > 70)
```

### 7.2. Cách cập nhật

```gaml
// Thoát thành công
if (floor_cell(location).is_exit) {
    is_escaped <- true;
    nb_escaped <- nb_escaped + 1;
    do die;
}

// Tử vong
if (stamina <= 0 and not is_escaped) {
    nb_dead <- nb_dead + 1;
    do die;
}

// Hoảng loạn (tính mỗi step, không cộng dồn)
nb_panic <- Evacuee count (each.panic_level > 70);
```

### 7.3. Chart

| Chart | Data | Value |
|---|---|---|
| "Thoát thành công" | Thoát | `nb_escaped` |
| "Thương vong" | Chết | `nb_dead` |
| "Hoảng loạn" | Panic | `nb_panic` |
| "Số lửa còn lại" | Fire | `length(Fire)` |

---

## 8. Quy tắc tương tác cốt lõi

### 8.1. Suy giảm theo thời gian

| Tác tử | Thay đổi mỗi step |
|---|---|
| Evacuee | `stamina -= 0.1` |
| Evacuee | `panic_level += 0.5` |
| RescueWorker | `stamina -= 0.05` |

### 8.2. Lửa gây sát thương

```gaml
ask Evacuee at_distance 1        { stamina -= 5.0; }
ask RescueWorker at_distance 1   { stamina -= 3.0; }
```

### 8.3. Lửa lan

```gaml
if (is_active and flip(0.022)) { // 2.2% mỗi cycle
    floor_cell neighbor <- one_of(
        floor_cell(self.location).neighbors
        where (not each.is_wall and not each.is_fire)
    );
    if (neighbor != nil) {
        create Fire at: neighbor.location { intensity <- 50.0; }
        neighbor.is_fire        <- true;
        neighbor.is_fire_hazard <- true;
    }
}
```

### 8.4. Firefighter dập lửa & tiếp cận an toàn

- **Quy tắc dập lửa không xuyên tường:**
  - Điều kiện dập lửa hợp lệ là khoảng cách $\le 1.5$ ô **VÀ** ô lửa phải là ô lân cận đi được (nằm cùng phòng / kết nối trực tiếp trên `room_graph`), không bị tường `is_wall` ngăn cách ở giữa.
- **Quy tắc tiếp cận đám lửa an toàn:**
  - Khi thực hiện `MOVE_TO_FIRE`, đích đến của `goto` phải là **ô sàn an toàn nằm kề cạnh ngọn lửa** (`neighbor where (not each.is_fire and not each.is_wall)`), không `goto` thẳng vào tâm ô đang cháy để tránh dính sát thương lửa không cần thiết.

```gaml
action extinguish(Fire target) {
    water_supply      <- water_supply - 5.0;
    target.intensity  <- target.intensity - 20.0;
    if (target.intensity <= 0) {
        floor_cell(target.location).is_fire        <- false;
        floor_cell(target.location).is_fire_hazard <- false;
        do target.die;
    }
}
```

### 8.5. Rescuer trấn an

```gaml
target.panic_level <- max(0.0, target.panic_level - 10.0);
```

### 8.6. Thoát & chết

- **Thoát:** `floor_cell(location).is_exit == true` ⇒ `is_escaped = true`, `nb_escaped += 1`, `do die`.
- **Chết:** `stamina <= 0 AND not is_escaped` ⇒ `nb_dead += 1`, `do die`.

### 8.7. Evacuee: Bám theo cứu hộ & Gộp nhóm đám đông

- **Đi theo Cứu hộ (`follow_leader`):**
  - Người dân bám theo `RescueWorker` gần nhất trong tầm nhận biết.
  - Khi cách xa Leader ($> 2.0$ ô): `do goto target: leader.location on: room_graph;`
  - Khi đã đến sát Leader ($\le 2.0$ ô): cùng di chuyển theo hướng về lối thoát hiểm gần nhất (`floor_cell target_exit <- exit_cells closest_to self; do goto target: target_exit on: room_graph;`).
  - *Lưu ý an toàn:* Khi lại gần ngọn lửa, điểm `FLEE_FIRE` (tối đa 130) ưu tiên cao hơn `FOLLOW_LEADER` (tối đa 110) nên người dân sẽ tự động né lửa dạt ra an toàn.

- **Gộp nhóm & Nghẽn dòng người (`flock`):**
  - Khi hoảng loạn cao (`panic_level > 50`) và có $\ge 3$ người dân xung quanh, người dân có tâm lý bầy đàn dồn lại thành cụm.
  - Hướng di chuyển: Tính trọng tâm cụm người xung quanh (`point center <- mean(nearby_evacuees collect each.location);`) và di chuyển dồn về phía hành lang / lối thoát hiểm chung trên `room_graph`.
  - **Cơ chế nghẽn dòng người (Crowd Congestion / Bottleneck):**
    - Khi chen lấn đông đúc trong bán kính hẹp ($< 1.0$ ô), tốc độ di chuyển bị suy giảm tỷ lệ nghịch với số lượng người xung quanh:
      ```gaml
      int crowd_count <- length(Evacuee at_distance 1.0);
      float speed_factor <- max(0.5, 1.0 - (crowd_count * 0.1)); // Giảm tối đa 50% tốc độ khi chen chúc
      do goto target: target_point speed: speed * speed_factor on: room_graph;
      ```

---

## 9. Quy ước code & Git

### Chia comment trong `main.gaml`

```gaml
// ============ GLOBAL ============
// ============ GRID  ============
// ============ EVACUEE ============
// ============ RESCUEWORKER (cha) ============
// ============ FIREFIGHTER (con) ============
// ============ RESCUER (con) ============
// ============ FIRE ============
// ============ EXPERIMENT ============
```