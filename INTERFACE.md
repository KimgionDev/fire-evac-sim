
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
    float stamina     <- 100.0;   // clamp >= 0
    float panic_level <- 0.0;     // clamp 0..100
    float speed       <- 1.0;     // 1.0 .. 1.5
    float vision      <- 10.0;
    bool  is_escaped  <- false;
}

species RescueWorker skills: [moving] {
    float stamina <- 200.0;
    float speed   <- 1.2;
    float vision  <- 15.0;
}

species Firefighter parent: RescueWorker {
    float water_supply <- 100.0;  // clamp >= 0
}

species Rescuer parent: RescueWorker {
    float calm_radius <- 4.0;
}

species Fire {
    float intensity <- 100.0;  // clamp >= 0
    bool  is_active <- true;
}
```

**Quy ước bắt buộc:**
- `panic_level` luôn `clamp(panic_level, 0, 100)`.
- `stamina` không âm, `<= 0` thì chết.
- `water_supply` không âm, `<= 0` thì không được EXTINGUISH.
- `is_escaped = true` ⇒ không tính là thương vong.

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

**Lưu ý:**
- Evacuee KHÔNG spawn đè ô lửa.
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
if (is_active and flip(0.05)) {
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

### 8.4. Firefighter dập lửa

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