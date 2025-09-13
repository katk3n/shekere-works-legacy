fn hash2(p: vec2<f32>) -> f32 {
    let a = dot(p, vec2(127.1, 311.7));
    return fract(sin(a) * 43758.5453);
}

fn hash3(p: vec3<f32>) -> vec2<f32> {
    let a = dot(p, vec3(127.1, 311.7, 74.7));
    let b = dot(p, vec3(269.5, 183.3, 246.1));
    return fract(sin(vec2(a, b)) * 43758.5453);
}

fn orb(pos: vec2<f32>, center: vec2<f32>, radius: f32, intensity: f32) -> f32 {
    let dist = length(pos - center);
    let core = smoothstep(radius + 0.02, radius - 0.01, dist) * intensity;
    let glow = exp(-dist / (radius * 2.5)) * intensity * 0.5;
    return core + glow;
}

fn note_to_position(note: u32) -> vec2<f32> {
    let center = vec2(0.5, 0.5);
    
    // 中央ノート（50-54）は中央付近で小さくランダムに動かす
    if (note >= 50u && note <= 54u) {
        let time_slow = Time.duration * 0.2;
        let hash_input = vec3(f32(note), time_slow, 0.0);
        let random_offset = hash3(hash_input);
        let offset = (random_offset - vec2(0.5)) * 0.15; // 小さい範囲で動く
        return center + offset;
    }
    
    // その他のノートは画面全体でランダムに動く
    let time_slow = Time.duration * 0.3;
    let hash_input = vec3(f32(note), time_slow, 1.0);
    let random_pos = hash3(hash_input);
    
    // 画面端を避けて 0.15 から 0.85 の範囲でランダム位置を生成
    let margin = 0.15;
    let range = 1.0 - 2.0 * margin;
    let x = margin + random_pos.x * range;
    let y = margin + random_pos.y * range;
    
    return vec2(x, y);
}

fn screen_flash(pos: vec2<f32>, intensity: f32, color: vec3<f32>) -> vec4<f32> {
    let flash_color = color * intensity;
    return vec4(flash_color, intensity * 0.4);
}

fn hsv_to_rgb(h: f32, s: f32, v: f32) -> vec3<f32> {
    let c = v * s;
    let x = c * (1.0 - abs((h * 6.0) % 2.0 - 1.0));
    let m = v - c;
    
    var rgb = vec3<f32>(0.0);
    
    if (h < 1.0 / 6.0) {
        rgb = vec3(c, x, 0.0);
    } else if (h < 2.0 / 6.0) {
        rgb = vec3(x, c, 0.0);
    } else if (h < 3.0 / 6.0) {
        rgb = vec3(0.0, c, x);
    } else if (h < 4.0 / 6.0) {
        rgb = vec3(0.0, x, c);
    } else if (h < 5.0 / 6.0) {
        rgb = vec3(x, 0.0, c);
    } else {
        rgb = vec3(c, 0.0, x);
    }
    
    return rgb + vec3(m);
}

fn note_to_color(note: u32) -> vec3<f32> {
    let normalized_note = f32(note - 50u) / 20.0;
    let hue = normalized_note;
    let saturation = 0.8;
    let value = 0.9;
    return hsv_to_rgb(hue, saturation, value);
}


@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let uv = in.tex_coords;
    let t = Time.duration;
    
    let previous_frame = SamplePreviousPass(uv);

    var final_color = previous_frame;
    final_color -= vec4(0.01);

    if (final_color[3] < 0.001) {
        final_color = vec4(0.0);
    }

    let pulse = 1.0 + sin(t * 8.0) * 0.1;
    let orb_radius = 0.04;
    
    for (var note = 50u; note <= 72u; note++) {
        if (MidiNoteOn(note) > 0.0) {
            let orb_center = note_to_position(note);
            let intensity = pulse * 0.8;
            let orb_value = orb(uv, orb_center, orb_radius, intensity);
            
            if (orb_value > 0.01) {
                let base_color = note_to_color(note);
                let orb_color = base_color * orb_value;
                final_color += vec4(orb_color, orb_value);
            }
        }
    }
    
    if (MidiNoteOn(93u) > 0.0) {
        let flash_intensity = pulse * 0.3;
        let bright_blue_white = vec3(0.7, 0.85, 1.0);
        let flash_effect = screen_flash(uv, flash_intensity, bright_blue_white);
        final_color += flash_effect;
    }
    
    if (MidiNoteOn(95u) > 0.0) {
        let flash_intensity = pulse * 0.3;
        let bright_blue_white = vec3(0.7, 0.85, 1.0);
        let flash_effect = screen_flash(uv, flash_intensity, bright_blue_white);
        final_color += flash_effect;
    }
    
    return final_color;
}