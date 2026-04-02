#version 420

// original https://www.shadertoy.com/view/lt2BWd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define M_PI 3.14159265

// LogPolar transform
vec2 c2p(vec2 coord) {
    float th = atan(coord.y, coord.x);
    float r = log(sqrt(coord.x*coord.x+coord.y*coord.y)); 
    
    return vec2(th, r);
}

// Colorize. See:
// http://www.iquilezles.org/www/articles/palettes/palettes.htm
vec4 colorize(float t, vec3 a, vec3 b, vec3 c, vec3 d) {
    vec3 col = 2.5 * a * b * (cos(0.4*M_PI*(c*t+d))); 
    return vec4(col, 1.0);
}

float v(vec2 coord, float k, float s, float rot) {
    float cx = cos(rot);
    float sy = sin(rot);
    
    return 0.0 + 0.5 * cos((cx * coord.x + sy * coord.y) * k + s);
}

void main(void)
{
       float t = -6.12 * time;
    
    vec2 xy = gl_FragCoord.xy - (0.5 * resolution.xy);
    xy.x *= resolution.x / resolution.y;
    // vec2 uv = xy / (0.5 * resolution.xy);
    vec2 uv = c2p(xy);
    
    float vt = 0.0;
  
    float k = 4.0;
    
    for(int i = 0; i < int(k); i++) {
        float s = float(i) * M_PI / k;
        float w = v(uv, 75.0, t, s);
        
        vt += w / 0.5;
    }
    
    
    vec4 col = colorize(vt, vec3(0.5, 0.5, 0.5),
                            vec3(0.5, 0.5, 0.5),
                            vec3(1.0, 1.0, 1.0),
                            vec3(0.00, 0.33, 0.67));
    /*
    vec4 col = colorize(vt, vec3(0.5, 0.5, 0.5),
                            vec3(0.5, 0.5, 0.5),
                            vec3(1.0, 1.0, 0.5),
                            vec3(0.80, 0.90, 0.30));
    */
    
    // Mask center (a bit)
    float m =  3.0*(distance((gl_FragCoord.xy / resolution.xy), vec2(0.5, 0.5)));
    //col = vec4( m, m, m, 1.0);
    col = clamp(m, 0.0, 1.0) * col;
    
    // Output to screen
    glFragColor = col;
}
