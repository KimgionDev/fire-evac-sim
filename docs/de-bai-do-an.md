**TRƯỜNG ĐẠI HỌC CẦN THƠ**  
**TRƯỜNG CÔNG NGHỆ THÔNG TIN & TRUYỀN THÔNG**  
**MÔN HỌC: NHẬP MÔN MÔ PHỎNG (CT189)**

## **ĐỀ TÀI**

## **MÔ PHỎNG SƠ TÁN KHẨN CẤP KHI HỎA HOẠN**

### **(FIRE EVACUATION SIMULATION IN GAMA PLATFORM)**

**THÔNG TIN ĐỒ ÁN MÔ PHỎNG (CT189)**

* **Thời gian thực hiện:** 05 tuần  
* **Môi trường phát triển:** GAMA Platform (Ngôn ngữ GAML – Agent-Based Modeling)  
* **Cơ chế ra quyết định:** Hệ thống Điểm Tiện ích Ma trận (Utility Matrix System)  
* **Yêu cầu cốt lõi:** Mô phỏng hành vi nổi trội (Emergent Behavior), tương tác đa tác tử, trực quan hóa biểu đồ thời gian thực.

## **CHƯƠNG 1: TỔNG QUAN ĐỀ TÀI & MỤC TIÊU MÔ PHỎNG**

### **1.1 Bối cảnh & Tính cấp thiết**

Trong các sự cố hỏa hoạn tại văn phòng, trường học, tòa nhà, việc tản thoát đám đông diễn ra vô cùng phức tạp do tâm lý hoảng loạn, tầm nhìn hạn chế bởi khói độc, và nguy cơ tắc nghẽn tại lối thoát hiểm. Việc ứng dụng Mô phỏng Đa tác tử (ABM) trên GAMA giúp nghiên cứu, dự đoán hành vi di chuyển của con người, từ đó đề xuất phương án kiến trúc hoặc hướng dẫn cứu hộ tối ưu.

### **1.2 Bối cảnh cụ thể**

**Mô phỏng 1 tầng văn phòng, nhìn từ trên xuống (top-down), kích thước 50x50 ô.**

* **4 phòng họp** ở cạnh trên.  
* **Khu làm việc chung** ở giữa (nhiều bàn ghế là vật cản).  
* **Bếp/Pantry** ở góc dưới trái — **nơi phát hỏa ngay từ đầu**.  
* **Kho/Nghỉ** ở góc dưới phải.  
* **2 cửa thoát hiểm** ở 2 đầu hành lang (trái và phải).

**Quy tắc khởi tạo:**

* **Evacuee (40 người)** sinh **bên trong các phòng** (phòng họp, khu làm việc, bếp, kho).  
* **Firefighter (2) và Rescuer (1)** sinh **bên ngoài tòa nhà**, di chuyển vào trong.  
* **Lửa** bùng phát **ngay khi bắt đầu mô phỏng** tại bếp, lan dần ra.

### **1.3 Môi trường Mô phỏng (Environment Grid Map)**

| Loại ô | Mô tả |
| :---- | :---- |
| **is\_floor** | Ô sàn di chuyển tự do |
| **is\_wall** | Tường, bàn ghế, vật cản — không đi qua được |
| **is\_exit** | Cửa thoát hiểm — chạm vào là thoát thành công |
| **is\_fire\_hazard** | Ô lửa/khói — gây mất stamina, giảm tầm nhìn |

### **1.4 Khai báo Các Đối tượng Tác tử (Agents)**

| Loại Tác tử | Thuộc tính Cốt lõi | Chức năng & Hành vi Chính | Vị trí spawn |
| :---- | :---- | :---- | :---- |
| **Evacuee** (Người tản thoát) | • stamina: float (100.0) • panic\_level: float (0–100) • speed: float (1.0–1.5) • vision: float (10.0) • is\_escaped: bool | Tìm lối thoát, né khói lửa, đi theo cứu hộ, gộp nhóm khi hoảng loạn | **Bên trong các phòng** |
| **RescueWorker** (species cha) | • stamina: float (200.0) • speed: float (1.2) • vision: float (15.0) | Species trừu tượng chứa thuộc tính và hành vi chung | Không tạo trực tiếp |
| **Firefighter** (con của RescueWorker) | • water\_supply: float (100.0) | **Chỉ dập lửa** — di chuyển đến ổ lửa và dập tắt | **Bên ngoài tòa nhà** |
| **Rescuer** (con của RescueWorker) | • calm\_radius: float (4.0) | **Chỉ dẫn đường** — đến gần Evacuee, dẫn họ về cửa thoát, trấn an hoảng loạn | **Bên ngoài tòa nhà** |
| **Fire** (Lửa) | • intensity: float (0–100) • is\_active: bool | Lan truyền sang ô kề, gây sát thương khi tiếp xúc | **Tại bếp, ngay từ đầu** |

**Số lượng tác tử mặc định:**

* Evacuee: **40** (sinh trong phòng)  
* Firefighter: **2** (sinh ngoài tòa nhà)  
* Rescuer: **1** (sinh ngoài tòa nhà)  
* Fire: **1–3 ổ lửa ban đầu** tại bếp, lan dần.

## **CHƯƠNG 2: THIẾT KẾ MA TRẬN ĐIỂM TIỆN ÍCH (UTILITY MATRIX)**

**CÔNG THỨC TÍNH ĐIỂM UTILITY TỔNG THỂ**  
**Utility\_Tổng \= (Tổng điểm Yếu tố Đánh giá) \+ (Điểm Ưu tiên Trạng thái Khẩn cấp) – (Điểm Hình phạt Vi phạm)**

* **Điểm yếu tố:** khoảng cách, tầm nhìn, môi trường xung quanh.  
* **Điểm ưu tiên:** cộng thưởng khi rơi vào trạng thái nguy cấp.  
* **Điểm hình phạt:** trừ nặng để ngăn hành động phi lý.

### **2.1 Ma trận Utility cho Tác tử Evacuee**

**Lưu ý:** Vì lửa bùng phát ngay từ đầu, Evacuee **không có WANDER**. Mọi hành động đều hướng đến sinh tồn.

| Hành động | Yếu tố đánh giá | Điều kiện kích hoạt (GAML) | Điểm |
| :---- | :---- | :---- | :---- |
| **EVACUATE** (Thoát hiểm) | Có lối thoát trong tầm nhìn | closest\_to(exit) \< vision | 60 |
|  | Ở rất gần lối thoát (≤ 2\) | dist(exit) \<= 2 | 40 |
| **TỔNG TỐI ĐA** |  |  | **100** |
| **FLEE\_FIRE** (Né khói lửa) | Lửa/khói ở gần trong bán kính 5 | closest\_to(fire) \<= 5 | 50 |
|  | Thể lực thấp (\< 40\) | stamina \< 40 | 30 |
|  | Đâm đầu trực tiếp vào lửa (≤ 2\) | closest\_to(fire) \<= 2 | 50 (ưu tiên) |
| **TỔNG TỐI ĐA** |  |  | **130** |
| **FOLLOW\_LEADER** (Đi theo Cứu hộ) | Có RescueWorker trong bán kính 8 | closest\_to(RescueWorker) \<= 8 | 50 |
|  | Chưa phát hiện lối thoát | closest\_to(exit) \== nil | 30 |
|  | Mất phương hướng | panic\_level \> 70 | 30 (ưu tiên) |
| **TỔNG TỐI ĐA** |  |  | **110** |
| **FLOCK** (Gộp nhóm) | Có ≥ 3 người dân xung quanh | count(Evacuee, 5\) \>= 3 | 40 |
|  | Hoảng loạn cao (\> 50\) | panic\_level \> 50 | 20 |
| **TỔNG TỐI ĐA** |  |  | **60** |

* **Quy tắc di chuyển & an toàn:**
  - **FOLLOW_LEADER:** Bám theo `RescueWorker` gần nhất. Khi cách xa Leader ($> 2.0$ ô), bám theo Leader; khi đã đến sát bên ($\le 2.0$ ô), cùng di chuyển hướng về cửa thoát hiểm an toàn trên `room_graph`. (Lưu ý: FLEE_FIRE có điểm tối đa 130 cao hơn FOLLOW_LEADER 110, nên khi gần lửa dân sẽ tự né ra, không đâm vào lửa).
  - **FLOCK (Dòng người & Nghẽn bottleneck):** Tụ lại theo trọng tâm nhóm và dồn về phía hành lang hướng ra cửa thoát. Khi chen lấn đông đúc trong bán kính hẹp ($< 1.0$ ô), tốc độ di chuyển bị suy giảm tỷ lệ nghịch với số người xung quanh (`speed * max(0.5, 1.0 - crowd_count * 0.1)`).

### **2.2 Ma trận Utility cho Tác tử Firefighter**

**Lưu ý:** Firefighter chỉ dập lửa, không dẫn đường. Có MOVE\_TO\_FIRE để di chuyển đến lửa khi ở xa.

| Hành động | Yếu tố đánh giá | Điều kiện kích hoạt (GAML) | Điểm |
| :---- | :---- | :---- | :---- |
| **EXTINGUISH** (Dập lửa) | Ô lửa nằm ngay cạnh (≤ 1.5, không bị tường cản) | dist(fire) \<= 1.5 and not_blocked_by_wall | 70 |
|  | Lửa cường độ cao (\> 50\) | fire.intensity \> 50 | 30 |
|  | Lửa đang chặn lối thoát | fire blocks exit \== true | 40 |
| **TỔNG TỐI ĐA** |  |  | **140** |
| **MOVE\_TO\_FIRE** (Tiến đến lửa) | Có lửa trong tầm nhìn nhưng chưa đến gần | closest\_to(fire) \<= vision and dist(fire) \> 1.5 | 50 |
|  | Lửa cường độ cao | fire.intensity \> 50 | 20 |
| **TỔNG TỐI ĐA** |  |  | **70** |
| **WANDER** (Tuần tra / Rút lui) | Không có lửa trong tầm nhìn HOẶC hết nước | closest\_to(fire) \== nil or water\_supply \<= 0 | 30 |
| **TỔNG TỐI ĐA** |  |  | **30** |

* **Quy tắc di chuyển & an toàn:**
  - **EXTINGUISH:** Khoảng cách $\le 1.5$ ô và phải cùng phòng / nối trực tiếp trên `room_graph` (không dập lửa xuyên tường).
  - **MOVE_TO_FIRE:** Di chuyển tới ô an toàn kề cạnh ngọn lửa (`neighbor where (not each.is_fire and not each.is_wall)`), không dẫm vào ô lửa.
  - **WANDER khi hết nước:** Rút lui ra ngoài sân (`is_outside`), tuyệt đối không đứng dừng lại ở ô cửa thoát hiểm (`is_exit`) cản trở người dân.
  - **Cơ chế tiếp nước ngoài sân (Refill):** Khi đã ra đến ngoài sân (`is_outside`), tạm dừng trừ `stamina`; sau khi ở ngoài sân đủ **20 cycle** tiếp nước từ xe cứu hỏa ngoài tòa nhà, `water_supply` được hồi phục đầy 100.0 để tiếp tục quay lại dập lửa.

### **2.3 Ma trận Utility cho Tác tử Rescuer**

**Lưu ý:** Rescuer chỉ dẫn đường, không dập lửa.

| Hành động | Yếu tố đánh giá | Điều kiện kích hoạt (GAML) | Điểm |
| :---- | :---- | :---- | :---- |
| **GUIDE** (Dẫn đường) | Có Evacuee chưa thoát trong bán kính 4 | closest\_to(Evacuee) \<= 4 | 60 |
|  | Evacuee chưa phát hiện lối thoát | target.closest\_to(exit) \== nil | 30 |
|  | Evacuee có panic\_level \> 50 | target.panic\_level \> 50 | 30 |
| **TỔNG TỐI ĐA** |  |  | **120** |
| **WANDER** (Tuần tra) | Không có Evacuee trong bán kính | closest\_to(Evacuee) \== nil | 30 |
| **TỔNG TỐI ĐA** |  |  | **30** |

### **2.4 Ma trận Hình phạt (Penalties)**

| Loại điểm | Tác tử / Hành động | Điều kiện vi phạm | Điểm hiệu chỉnh |
| :---- | :---- | :---- | :---- |
| Hình phạt | Bất kỳ di chuyển nào | Bước vào ô tường (is\_wall) | **–100** (Vô hiệu hóa) |
| Hình phạt | Di chuyển Evacuee | Đích đến là ô lửa/khói (is\_fire\_hazard) | **–80** (Chỉ đi nếu đường khác bị chặn) |
| Hình phạt | EVACUATE | Không phát hiện lối thoát | **–50** (Vô hiệu hóa) |

### **2.5 Điểm Ưu tiên Trạng thái**

| Ưu tiên | Tác tử → Hành động | Điều kiện | Điểm cộng |
| :---- | :---- | :---- | :---- |
| Priority | Evacuee → FLEE\_FIRE | Đâm đầu trực tiếp vào lửa (dist(fire) \<= 2\) | **\+50** |
| Priority | Evacuee → EVACUATE | Thể lực nguy kịch (stamina \< 20\) | **\+40** |
| Priority | Evacuee → FOLLOW\_LEADER | Mất phương hướng (panic\_level \> 70\) | **\+30** |
| Priority | Firefighter → EXTINGUISH | Lửa đang chặn cửa thoát | **\+50** |
| Priority | Rescuer → GUIDE | Evacuee có panic\_level \> 80 | **\+40** |

### **2.6 Quy tắc Phân giải Hòa điểm (Tie-Breaking Rules)**

* **Evacuee:** 🥇 FLEE\_FIRE \> 🥈 EVACUATE \> 🥉 FOLLOW\_LEADER \> 🏅 FLOCK  
* **Firefighter:** 🥇 EXTINGUISH \> 🥈 MOVE\_TO\_FIRE \> 🎗️ WANDER  
  *(Lưu ý: EXTINGUISH ưu tiên cao nhất, WANDER ưu tiên thấp nhất. Khi code không được để `max_score = u_wander` lên trước).*
* **Rescuer:** 🥇 GUIDE \> 🎗️ WANDER

## **CHƯƠNG 3: KẾ HOẠCH & PHÂN CÔNG CÔNG VIỆC 5 TUẦN**

| Tuần | Mốc nghiệm thu | TV1 (Map & Render) | TV2 (AI Evacuee) | TV3 (AI RescueWorker & Fire) |
| :---- | :---- | :---- | :---- | :---- |
| **Tuần 1** | Học GAMA & Dựng Map thô | • Học cú pháp GAML cơ bản. • Tạo main.gaml và grid cell (is\_wall, is\_floor, is\_exit). • Vẽ layout văn phòng: 4 phòng họp, khu làm việc, bếp, kho, 2 cửa thoát. | • Khai báo species Evacuee. • Tạo thuộc tính: stamina, panic\_level, speed, vision, is\_escaped. • Spawn Evacuee **trong các phòng**. | • Khai báo species cha RescueWorker. • Khai báo Firefighter parent: RescueWorker, Rescuer parent: RescueWorker. • Khai báo species Fire, spawn tại bếp. • Spawn Firefighter/Rescuer **ngoài tòa nhà**. |
| **Tuần 2** | Chuyển động & Lan truyền | • Rải vị trí lối thoát hiểm. • Xử lý né tường cho các tác tử. • Vẽ màu grid theo trạng thái (sàn, tường, lửa). | • Cài đặt logic tính utility cho Evacuee. • Test giảm stamina theo thời gian. • Test logic chết khi stamina \<= 0\. | • Cài đặt lan truyền lửa ngẫu nhiên. • Cài đặt Firefighter MOVE\_TO\_FIRE \+ EXTINGUISH. • Cài đặt Fire gây sát thương. |
| **Tuần 3** | Tương tác Lõi P1 | • Vẽ Chart theo dõi số người thoát, số thương vong, số người hoảng loạn. | • Cài đặt logic FLEE\_FIRE (né lửa) và EVACUATE (tìm cửa thoát). • Cài đặt logic thoát thành công khi chạm exit. • Áp dụng hình phạt và ưu tiên. | • Cài đặt Rescuer GUIDE (dẫn Evacuee về exit). • Cài đặt logic trấn an panic\_level. |
| **Tuần 4** | Tương tác Lõi P2 | • Tối ưu hiển thị, màu sắc theo mức hoảng loạn. • Hiển thị đường đi hoặc hướng di chuyển. | • Cài đặt logic FOLLOW\_LEADER (bám theo cứu hộ, khi sát bên thì cùng hướng về exit). 
• Cài đặt logic FLOCK (gộp nhóm dồn về hành lang, giảm tốc độ khi chen lấn đông người). 
• Cân bằng chỉ số spawn trong phòng (phân bổ số lượng theo diện tích phòng và gán panic\_level ban đầu theo khoảng cách tới bếp). | • Cân bằng số lượng Firefighter (2) và Rescuer (1). 
• Cài đặt logic Firefighter hết nước: rút lui ra ngoài sân `is_outside` (không đứng chắn `is_exit`), cơ chế nạp lại nước đầy 100.0 sau 20 cycle ngoài sân và tạm dừng trừ stamina.
• Cân bằng tốc độ lan lửa (điều chỉnh xác suất lan khoảng 2.2% / cycle). |
| **Tuần 5** | Hoàn thiện & Slide | • Kiểm thử 50–100 tác tử. • Chụp ảnh mô phỏng & biểu đồ. • Ghép Slide tổng hợp phần môi trường. | • Lập bảng Utility hoàn chỉnh cho Evacuee. • Tinh chỉnh điểm phạt và ưu tiên. • Ghép Slide phần Evacuee. | • Lập bảng Utility hoàn chỉnh cho Firefighter & Rescuer. • Cân bằng chỉ số sinh tồn. • Tổng duyệt code & Slide phần cứu hộ \+ lửa. |

## **CHƯƠNG 4: HƯỚNG DẪN KHUNG CODE CẤU TRÚC GAML MẪU**

model FireEvacuationSimulation

global {  
    int grid\_width \<- 50;  
    int grid\_height \<- 50;  
    int nb\_evacuees \<- 40;  
    int nb\_firefighters \<- 2;  
    int nb\_rescuers \<- 1;  
      
    init {  
        // Evacuee spawn TRONG các phòng  
        create Evacuee number: nb\_evacuees {  
            location \<- any\_location\_in(one\_of(floor\_cell where (each.is\_room)));  
        }  
          
        // Firefighter & Rescuer spawn NGOÀI tòa nhà  
        create Firefighter number: nb\_firefighters {  
            location \<- any\_location\_in(one\_of(floor\_cell where (each.is\_outside)));  
        }  
        create Rescuer number: nb\_rescuers {  
            location \<- any\_location\_in(one\_of(floor\_cell where (each.is\_outside)));  
        }  
          
        // Lửa bùng phát ngay tại bếp  
        create Fire number: 2 {  
            location \<- any\_location\_in(one\_of(floor\_cell where (each.is\_kitchen)));  
        }  
    }  
}

grid floor\_cell width: grid\_width height: grid\_height {  
    bool is\_wall \<- false;  
    bool is\_exit \<- false;  
    bool is\_fire \<- false;  
    bool is\_room \<- false;     // phòng họp, khu làm việc, bếp, kho  
    bool is\_outside \<- false;  // bên ngoài tòa nhà  
    bool is\_kitchen \<- false;  // bếp \- nơi phát hỏa  
    rgb color \<- \#white;  
}

// \============ TÁC TỬ NGƯỜI DÂN \============  
species Evacuee skills: \[moving\] {  
    float stamina \<- 100.0;  
    float panic\_level \<- 0.0;  
    float speed \<- 1.0;  
    float vision \<- 10.0;  
    bool is\_escaped \<- false;  
      
    action compute\_utility {  
        float u\_evacuate \<- 0.0;  
        float u\_flee \<- 0.0;  
        float u\_follow \<- 0.0;  
        float u\_flock \<- 0.0;  
          
        floor\_cell target\_exit \<- floor\_cell closest\_to self where (each.is\_exit);  
        Fire nearest\_fire \<- Fire closest\_to self;  
        RescueWorker leader \<- RescueWorker closest\_to self;  
          
        // EVACUATE  
        if (target\_exit \!= nil and (self distance\_to target\_exit) \< vision) {  
            u\_evacuate \<- u\_evacuate \+ 60.0;  
        }  
        if (target\_exit \!= nil and (self distance\_to target\_exit) \<= 2\) {  
            u\_evacuate \<- u\_evacuate \+ 40.0;  
        }  
        if (stamina \< 20\) {  
            u\_evacuate \<- u\_evacuate \+ 40.0;  // Ưu tiên khẩn cấp  
        }  
          
        // FLEE\_FIRE  
        if (nearest\_fire \!= nil and (self distance\_to nearest\_fire) \<= 5\) {  
            u\_flee \<- u\_flee \+ 50.0;  
        }  
        if (stamina \< 40\) {  
            u\_flee \<- u\_flee \+ 30.0;  
        }  
        if (nearest\_fire \!= nil and (self distance\_to nearest\_fire) \<= 2\) {  
            u\_flee \<- u\_flee \+ 50.0;  // Ưu tiên khẩn cấp  
        }  
          
        // FOLLOW\_LEADER  
        if (leader \!= nil and (self distance\_to leader) \<= 8\) {  
            u\_follow \<- u\_follow \+ 50.0;  
        }  
        if (target\_exit \== nil) {  
            u\_follow \<- u\_follow \+ 30.0;  
        }  
        if (panic\_level \> 70\) {  
            u\_follow \<- u\_follow \+ 30.0;  
        }  
          
        // FLOCK  
        if (count(Evacuee at\_distance 5\) \>= 3\) {  
            u\_flock \<- u\_flock \+ 40.0;  
        }  
        if (panic\_level \> 50\) {  
            u\_flock \<- u\_flock \+ 20.0;  
        }  
          
        // Chọn hành động có điểm cao nhất (Tie-break theo thứ tự FLEE \> EVACUATE \> FOLLOW \> FLOCK)  
        if (u\_flee \>= u\_evacuate and u\_flee \>= u\_follow and u\_flee \>= u\_flock) {  
            if (nearest\_fire \!= nil) { do flee\_from target: nearest\_fire; }  
        } else if (u\_evacuate \>= u\_follow and u\_evacuate \>= u\_flock) {  
            if (target\_exit \!= nil) { do goto target: target\_exit; }  
        } else if (u\_follow \>= u\_flock) {  
            if (leader \!= nil) { do goto target: leader; }  
        } else {  
            do wander;  
        }  
    }  
      
    action flee\_from (Fire target) {  
        // Di chuyển ngược hướng lửa  
        point flee\_point \<- self.location \+ (self.location \- target.location);  
        do goto target: flee\_point;  
    }  
      
    reflex main\_decision {  
        stamina \<- stamina \- 0.1;  
        panic\_level \<- panic\_level \+ 0.5;  
          
        if (stamina \<= 0\) { do die; }  
          
        // Kiểm tra thoát  
        if (floor\_cell(location).is\_exit) {  
            is\_escaped \<- true;  
            do die;  
        }  
          
        do compute\_utility;  
    }  
      
    aspect default {  
        draw circle(1.5) color: (panic\_level \> 70 ? \#red : (panic\_level \> 40 ? \#orange : \#blue)) border: \#black;  
    }  
}

// \============ TÁC TỬ CỨU HỘ (SPECIES CHA) \============  
species RescueWorker skills: \[moving\] {  
    float stamina \<- 200.0;  
    float speed \<- 1.2;  
    float vision \<- 15.0;  
      
    reflex stamina\_loss {  
        stamina \<- stamina \- 0.05;  
    }  
}

// \============ LÍNH CỨU HỎA (CON) \============  
species Firefighter parent: RescueWorker {  
    float water\_supply \<- 100.0;  
      
    action compute\_utility {  
        float u\_extinguish \<- 0.0;  
        float u\_move \<- 0.0;  
        float u\_wander \<- 0.0;  
          
        Fire nearest\_fire \<- Fire closest\_to self;  
        if (nearest\_fire \!= nil) {  
            float d \<- self distance\_to nearest\_fire;  
              
            // EXTINGUISH: khi ở gần  
            if (d \<= 1.5) {  
                u\_extinguish \<- u\_extinguish \+ 70.0;  
                if (nearest\_fire.intensity \> 50\) { u\_extinguish \<- u\_extinguish \+ 30.0; }  
            }  
              
            // MOVE\_TO\_FIRE: khi ở xa  
            if (d \> 1.5 and d \< vision) {  
                u\_move \<- u\_move \+ 50.0;  
                if (nearest\_fire.intensity \> 50\) { u\_move \<- u\_move \+ 20.0; }  
            }  
        } else {  
            u\_wander \<- u\_wander \+ 30.0;  
        }  
          
        // Tie-break chuẩn: EXTINGUISH > MOVE_TO_FIRE > WANDER
        if (u\_extinguish \>= u\_move and u\_extinguish \>= u\_wander and u\_extinguish \> 0 and water\_supply \> 0) {  
            do extinguish target: nearest\_fire;  
        } else if (u\_move \>= u\_wander and nearest\_fire \!= nil and water\_supply \> 0) {  
            // Tiếp cận ô an toàn kề cạnh đám lửa, không bước vào tâm ô lửa
            list<floor_cell> safe_neighbors \<- floor_cell(nearest\_fire.location).neighbors where (not each.is_fire and not each.is_wall);
            if (\!empty(safe_neighbors)) {
                do goto target: one\_of(safe_neighbors).location on: room\_graph;
            } else {
                do goto target: nearest\_fire.location on: room\_graph;
            }
        } else {  
            // Khi hết nước: rút lui ra ngoài sân (is_outside), không chặn cửa thoát hiểm
            if (water\_supply \<= 0) {
                floor_cell safe_outside \<- empty(floor_cell where (each.is_outside)) ? nil : (floor_cell where (each.is_outside) closest_to self);
                if (safe_outside \!= nil) { do goto target: safe_outside.location on: room\_graph; }
            } else {
                do wander;  
            }
        }  
    }  
      
    action extinguish (Fire target) {  
        water\_supply \<- water\_supply \- 5.0;  
        target.intensity \<- target.intensity \- 20.0;  
        if (target.intensity \<= 0\) {  
            do target.die;  
        }  
    }  
      
    reflex main\_decision {  
        do compute\_utility;  
    }  
      
    aspect default {  
        draw circle(2) color: \#red border: \#black;  
    }  
}

// \============ NHÂN VIÊN CỨU NẠN (CON) \============  
species Rescuer parent: RescueWorker {  
    float calm\_radius \<- 4.0;  
      
    action compute\_utility {  
        float u\_guide \<- 0.0;  
        float u\_wander \<- 0.0;  
          
        Evacuee nearest\_evacuee \<- Evacuee closest\_to self;  
        if (nearest\_evacuee \!= nil and (self distance\_to nearest\_evacuee) \<= calm\_radius) {  
            u\_guide \<- u\_guide \+ 60.0;  
            if (nearest\_evacuee.panic\_level \> 50\) { u\_guide \<- u\_guide \+ 30.0; }  
            if (nearest\_evacuee.panic\_level \> 80\) { u\_guide \<- u\_guide \+ 40.0; }  
        } else {  
            u\_wander \<- u\_wander \+ 30.0;  
        }  
          
        if (u\_guide \> 0 and nearest\_evacuee \!= nil) {  
            do guide target: nearest\_evacuee;  
        } else {  
            do wander;  
        }  
    }  
      
    action guide (Evacuee target) {  
        // Di chuyển đến gần evacuee, sau đó dẫn về exit  
        floor\_cell target\_exit \<- floor\_cell closest\_to self where (each.is\_exit);  
        if (target\_exit \!= nil) {  
            do goto target: target\_exit;  
        }  
        target.panic\_level \<- max(0.0, target.panic\_level \- 10.0);  
    }  
      
    reflex main\_decision {  
        do compute\_utility;  
    }  
      
    aspect default {  
        draw circle(2) color: \#orange border: \#black;  
    }  
}

// \============ TÁC TỬ LỬA \============  
species Fire {  
    float intensity \<- 100.0;  
    bool is\_active \<- true;  
      
    reflex spread {  
        if (is\_active and flip(0.05)) {  
            floor\_cell neighbor \<- one\_of(self.neighbors) where (not each.is\_fire);  
            if (neighbor \!= nil) {  
                create Fire at: neighbor.location {  
                    intensity \<- 50.0;  
                }  
            }  
        }  
    }  
      
    reflex damage {  
        ask Evacuee at\_distance 1 {  
            stamina \<- stamina \- 5.0;  
        }  
        ask RescueWorker at\_distance 1 {  
            stamina \<- stamina \- 3.0;  
        }  
    }  
      
    aspect default {  
        draw square(1) color: (intensity \> 50 ? \#red : \#orange);  
    }  
}

experiment FireEvacuation type: gui {  
    output {  
        display map {  
            grid floor\_cell lines: \#black;  
            species Fire aspect: default;  
            species Evacuee aspect: default;  
            species Firefighter aspect: default;  
            species Rescuer aspect: default;  
        }  
        display chart {  
            chart "Số người thoát & thương vong" type: series {  
                data "Thoát thành công" value: Evacuee count (each.is\_escaped);  
                data "Thương vong" value: Evacuee count (each.stamina \<= 0 and not each.is\_escaped);  
            }  
            chart "Số lửa còn lại" type: series {  
                data "Fire" value: length(Fire);  
            }  
        }  
    }  
}  
