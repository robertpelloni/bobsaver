#version 420

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

vec3 theme_color = vec3(0.995,0.000,0.90);

vec3 draw_borders(vec2 st,vec3 color,vec3 target_color){
    float mix_value = max(
        smoothstep(0.745,0.75,st.y)-smoothstep(0.75,0.755,st.y),
        smoothstep(0.245,0.25,st.y)-smoothstep(0.25,0.255,st.y)
    );
    
    return mix(color,target_color,mix_value);
}

vec3 draw_hlines(vec2 st,vec3 color,vec3 target_color){
    float dist = 0.0;
    if(st.y >= 0.75){
        dist = st.y - 0.6;
    }else if(st.y <= 0.25){
        dist = 0.4 - st.y;
    }else{
        return color;
    }
    
    float mix_value = 1.0 - abs(sin(time*6.0 + 3.5/dist));
    
    if(mix_value < 0.9){
        mix_value = 0.0;
    }else if(mix_value < 0.95){
        mix_value = (mix_value - 0.9) * 20.0;
    }
    
    return mix(color,target_color,mix_value);
}

vec3 draw_vlines(vec2 st,vec3 color,vec3 target_color){
    if(st.y < 0.75 && st.y > 0.25)return color;
    
    float mix_value = 1.0 - abs(cos((0.5-st.x)/abs(0.5-st.y)/6.0 * 30.0 + sin(time/2.0)*5.0));
    
    if(mix_value < 0.9){
        mix_value = 0.0;
    }else if(mix_value < 0.95){
        mix_value = (mix_value - 0.9) * 20.0;
    }
    
    return mix(color,target_color,mix_value);
}

void main(void) {
    vec2 st = gl_FragCoord.xy/resolution.xy;

    vec3 color = vec3(0.0);
    color = draw_borders(st,color,theme_color);
    color = draw_hlines(st,color,theme_color);
    color = draw_vlines(st,color,theme_color);

    glFragColor = vec4(color,1.0);
}
