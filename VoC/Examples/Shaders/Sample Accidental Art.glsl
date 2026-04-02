#version 420

// original https://www.shadertoy.com/view/3dt3Dr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
#define TWO_PI 6.28318530718

float sdfLine(float pt, float pos, float blur){
    
    return smoothstep(pos - blur, pos, pt) - smoothstep(pos, pos+blur, pt);

}

void main(void)
{
    float a = max(resolution.x, resolution.y);
    vec2 uv = ((2.0 * gl_FragCoord.xy) - resolution.xy)/a;
    
    //colors
    vec3 bg = vec3(0.0);
    
    float x = uv.x;
    float y = uv.y;
    
    vec3 col = bg;
   
    
    //horizontals
    float phase = sin(atan(y,x));
    y = y + 0.3 * sin(x + time - phase);
    
    col = vec3(sdfLine(y, 0.0, 0.05));
    
    col = mix(col, vec3(1.0, 0.0, 0.0), vec3(sdfLine(y, 0.1, 0.05)));
    
    col = mix(col, vec3(0.0, 1.0, 0.0), vec3(sdfLine(y, -0.1, 0.05)));
    
    col = mix(col, vec3(0.0, 0.0, 1.0), vec3(sdfLine(y, 0.2, 0.05)));
    
    col = mix(col, vec3(1.0, 1.0, 0.0), vec3(sdfLine(y, -0.2, 0.05)));
    
    
    //verticals
    phase = sin(atan(x,y));
    y = uv.y;
    x = x + 0.3 * sin(y + time - phase);
    
    col = mix(col, vec3(1.0), vec3(sdfLine(x, 0.0, 0.05)));
    
    col = mix(col, vec3(1.0, 0.0, 0.0), vec3(sdfLine(x, 0.1, 0.05)));
    
    col = mix(col, vec3(0.0, 1.0, 0.0), vec3(sdfLine(x, -0.1, 0.05)));
    
    col = mix(col, vec3(0.0, 0.0, 1.0), vec3(sdfLine(x, 0.2, 0.05)));
    
    col = mix(col, vec3(1.0, 1.0, 0.0), vec3(sdfLine(x, -0.2, 0.05)));
    
    

    // Output to screen
    glFragColor = vec4(col,1.0);
}
