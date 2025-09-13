// Tutorial by "The Art of Code"
// Shader Coding: Making a starfield
// Part 1: https://www.youtube.com/watch?v=rvDo9LvfoVE
// Part 2: https://www.youtube.com/watch?v=dhuigO4A7RY

const PI = 3.1415;
const NUM_LAYERS = 6.0;

fn Rot(a: f32) -> mat2x2<f32> {
    let s = sin(a);
    let c = cos(a);
    return mat2x2<f32>(c, -s, s, c);
}

fn Star(uv_in: vec2<f32>, flare: f32) -> f32 {
    var uv = uv_in;
    let d = length(uv);
    var m = 0.05 / d;

    var rays = max(0.0, 1.0 - abs(uv.x * uv.y * 1000.0));
    m += rays * flare;

    uv = uv * Rot(PI/4.0);
    rays = max(0.0, 1.0 - abs(uv.x * uv.y * 1000.0));
    m += rays * 0.3 * flare;

    m *= smoothstep(1.0, 0.2, d);

    return m;
}

fn Hash21(p: vec2<f32>) -> f32 {
    var p2 = fract(p * vec2(123.34, 456.21));
    p2 += dot(p2, p2 + 45.32);
    return fract(p2.x * p2.y);
}

fn StarLayer(uv_in: vec2<f32>) -> vec3<f32> {
    var uv = uv_in;
    var col = vec3(0.0);
    let gv = fract(uv) - 0.5;
    let id = floor(uv);

    for (var y = -1; y <= 1; y++) {
        for (var x = -1; x <=1; x++) {
            let offs = vec2(f32(x), f32(y));

            let n = Hash21(id + offs);  // random value between 0.0 and 1.0
            let size = fract(n * 345.32);
            var star = Star(gv - offs - vec2(n, fract(n * 34.0)) + 0.5, smoothstep(0.9, 1.0, size) * 0.6);

            var color = sin(vec3(0.2, 0.3, 0.9) * fract(n * 2345.2) * 123.2) * 0.5 + 0.5;
            color = color * vec3(1.0, 0.4, 1.0 + size);

            star *= sin(Time.duration * 3.0 + n * 2 * PI) * 0.5 + 1.0;
            col += star * size * color;
        }
    }

    return col;
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    var uv = NormalizedCoords(in.position.xy);
    //let M = MouseCoords();
    let M = NormalizedCoords(vec2(sin(Time.duration * 2.0) * 0.5 + 0.5, cos(Time.duration * 1.7) * 0.5 + 0.5));
    let t = Time.duration * 0.02;

    uv += M;
    uv *= Rot(t);
    var col = vec3(0.0);

    for (var i = 0.0; i < 1.0; i += 1.0 / NUM_LAYERS) {
        let depth = fract(i + t);
        let scale = mix(20.0, 0.5, depth);
        let fade = depth * smoothstep(1.0, 0.9, depth);
        col += StarLayer(uv * scale + i * 453.2 - M) * fade;
    }

    return vec4(ToLinearRgb(col), 1.0);
}