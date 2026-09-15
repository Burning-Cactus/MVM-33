shader_type spatial;
render_mode cull_disabled, unshaded;

uniform vec4 water_color : source_color = vec4(0.0, 0.45, 0.75, 0.85);
uniform vec4 foam_color : source_color = vec4(0.95, 0.95, 1.0, 1.0);

// Use a seamless noise texture
uniform sampler2D flow_noise : hint_default_white, repeat_enable;

//@export_group("Speed & Scale")
uniform float flow_speed = 1.5;
uniform vec2 uv_scale = vec2(1.0, 0.3); // Stretches texture vertically

//@export_group("Foam Settings")
uniform float foam_cutoff : hint_range(0.0, 1.0) = 0.55;
uniform float foam_smoothness : hint_range(0.0, 0.2) = 0.05;

void fragment() {
    // 1. Scale UVs to stretch the noise into vertical water streaks
    vec2 scaled_uv = UV * uv_scale;
    
    // 2. Pan the UV coordinates downwards over time
    vec2 moving_uv = vec2(scaled_uv.x, scaled_uv.y - (TIME * flow_speed));
    
    // 3. Sample the noise texture
    float noise = texture(flow_noise, moving_uv).r;
    
    // 4. Create foam masks based on noise values
    float foam_mask = smoothstep(foam_cutoff, foam_cutoff + foam_smoothness, noise);
    
    // 5. Fade out transparency smoothly at the very top and bottom edges
    float edge_fade = smoothstep(0.0, 0.1, UV.y) * smoothstep(1.0, 0.9, UV.y);
    
    // 6. Combine colors
    vec3 final_color = mix(water_color.rgb, foam_color.rgb, foam_mask);
    
    ALBEDO = final_color;
    ALPHA = mix(water_color.a, foam_color.a, foam_mask) ;
    
    // Water surface properties
    ROUGHNESS = 0.1;
    SPECULAR = 0.6;
}