/**
 * File: rescue_and_fire.gaml
 * Tác giả: Lâm (TV3)
 * Mô tả: Định nghĩa các loài Cứu hộ (RescueWorker, Firefighter, Rescuer) và Ngọn lửa (Fire)
 */

model FireEvacuationSimulation

/* 1. Tác tử Ngọn lửa (Fire) */
species Fire {
    float intensity <- 100.0;
    rgb color <- #red;
    
    aspect default {
        draw circle(0.8) color: color;
    }
}

/* 2. Species Cha: RescueWorker */
species RescueWorker skills: [moving] {
    float stamina <- 200.0;
    float speed <- 1.2;
    float vision <- 15.0;
    rgb color <- #blue;
    
    aspect default {
        draw circle(1.0) color: color;
    }
}

/* 3. Species Con 1: Firefighter (Lính dập lửa) */
species Firefighter parent: RescueWorker {
    float water_supply <- 100.0;
    
    init {
        color <- #yellow;
    }
    
    // Di chuyển thử nghiệm Tuần 1
    reflex wander_outside {
        do wander;
//        do wander bounds: floor_cell where (each.is_outside);
    }
    
    aspect default {
        draw rectangle(1.2, 1.2) color: color;
    }
}

/* 4. Species Con 2: Rescuer (Lính cứu hộ / Dẫn người) */
species Rescuer parent: RescueWorker {
    int guidance_capacity <- 5;
    
    init {
        color <- #cyan;
    }
    
    // Di chuyển thử nghiệm Tuần 1
    reflex wander_outside {
        do wander;
//	do wander bounds: floor_cell where (each.is_outside);
    }
    
    aspect default {
        draw triangle(1.3) color: color;
    }
}