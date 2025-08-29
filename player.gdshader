shader_type canvas_item;

// === Source Colors to Detect ===

// Body & neck (default player sprite colors)
uniform vec3 body = vec3(0.149, 0.149, 0.647);
uniform vec3 neck = vec3(0.647, 0.149, 0.149);
uniform vec3 outline: source_color;
uniform vec3 shadow: source_color;

// Visor shades (original green pixels)
uniform vec3 visor_lower : source_color; // RGB(38, 101, 38) ≈ vec3(0.149, 0.396, 0.149)
uniform vec3 visor_upper : source_color; // RGB(39, 164, 39) ≈ vec3(0.153, 0.643, 0.153)

// === Tolerances ===
uniform float tolerance_outline = 0.015;
uniform float tolerance_body = 0.02;
uniform float tolerance_neck = 0.01;
uniform float tolerance_shadow = 0.002; // tweakable
uniform float tolerance_visor_lower = 0.002; // tweakable
uniform float tolerance_visor_upper = 0.002; // tweakable

// === Replacement Colors ===
uniform vec4 player_color : source_color = vec4(0.0, 0.5, 1.0, 1.0);
uniform vec4 visor_lower_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 visor_upper_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    vec3 color = tex_color.rgb;
    float dist_outline = dot(color - outline, color - outline);
    float dist_body = dot(color - body, color - body);
    float dist_neck = dot(color - neck, color - neck);
    float dist_visor_lower = dot(color - visor_lower, color - visor_lower);
    float dist_visor_upper = dot(color - visor_upper, color - visor_upper);
    float dist_shadow = dot(color - shadow, color - shadow);

    if (dist_body < tolerance_body) {
        tex_color.rgb = player_color.rgb;
    } else if (dist_neck < tolerance_neck) {
        tex_color.rgb = player_color.rgb * 0.65;
    } else if (dist_outline < tolerance_outline) {
        tex_color.rgb = player_color.rgb * 0.175;
    } else if (dist_visor_lower < tolerance_visor_lower) {
        tex_color.rgb = visor_lower_color.rgb;
    } else if (dist_visor_upper < tolerance_visor_upper) {
        tex_color.rgb = visor_upper_color.rgb;
    } else if (dist_shadow < tolerance_shadow) {
        tex_color.rgba = vec4(0.0,0.0,0.0,0.0);
    }


    COLOR = tex_color;
}