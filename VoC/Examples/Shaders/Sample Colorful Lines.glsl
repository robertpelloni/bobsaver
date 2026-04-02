#version 420

// original https://www.shadertoy.com/view/tsXBD8

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TWOPI 6.28318530718
#define NUM_OCTAVES 3

vec3 g_a = vec3(0.66,0.56,0.68);
vec3 g_b = vec3(0.718,0.438,0.720);
vec3 g_c = vec3(0.520,0.8,0.520);
vec3 g_d = vec3(-0.430,-0.397,-0.083);

//iq's cosine gradient https://www.iquilezles.org/www/articles/palettes/palettes.htm
vec3 grad( in float t)
{
    return g_a + g_b*cos( 6.28318*(g_c*t+g_d) );
}

float random (in vec2 uv) {
    return fract(sin(dot(uv.xy,vec2(12.9898,78.233)))*43758.5453123);
}

// Based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float noise (in vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

//From book of shaders ch. 13 https://thebookofshaders.com/13/
float fbm ( in vec2 st) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100.0);
    // Rotate to reduce axial bias
    mat2 rot = mat2(cos(0.5), sin(0.5),
                    -sin(0.5), cos(0.50));
    for (int i = 0; i < NUM_OCTAVES; ++i) {
        v += a * noise(st);
        st = rot * st * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

void main(void) {
    
    float stime = date.w * 0.09;
    float ctime = time * 0.3273;
    float ttime = time * 0.0697;
    float ptime = time * 0.0987;
    
    float mx = max(resolution.x , resolution.y);
    
    vec2 uv = gl_FragCoord.xy / mx;
    vec2 st = uv * 3.2; 
    vec2 tuv = uv * 1.2;
    
    float n_x = 2.0 * fbm(st + vec2(7.29 , ttime)) - 1.0;
    float n_y = 2.0 * fbm(st + vec2(3.67 , ttime)) - 1.0;
    float n_z = 0.5 * fbm(st + vec2(0.0 , 0.0)) + 0.5;

    vec3 n = normalize(vec3(n_x , n_y , n_z));
    vec3 l = normalize(vec3(cos(ttime) , sin(ttime) , 1.0));

    float c = dot(l,n);

    vec2 cuv = fract(9.7 * vec2(n_x , n_y) * tuv + vec2(0.0 , ctime * 0.1));
    float cx = cuv.x;
    float cy = cuv.y;
    cx = step(0.5 * sin(cx * TWOPI) + 0.5 , 0.5);
    cy = step(0.5 * sin(cy * TWOPI) + 0.5 , 0.5);
  
    
    vec2 duv = fract(9.7 * vec2(n_x , n_y) * tuv + vec2(0.0 , ptime * 0.1));
    float dx = duv.x;
    float dy = duv.y;  
    dx = step(0.5 * sin(dx * TWOPI) + 0.5 , 0.5);
    dy = step(0.5 * sin(dy * TWOPI) + 0.5 , 0.5); 
    
    float total = cx+cy;
    bool isWhite = mod(total , 2.0) == 0.0;

    vec3 w = vec3(1.0);

    vec3 b = vec3(0.0);

    vec3 ch = isWhite ? w:b;

       ch -= vec3(floor(dx + dy * 0.975));

    vec3 o = grad(c * c * c + ttime * 0.5 + stime);
        
    //Uncomment for more chaotic shapes
    //ch -= vec3(floor(fract(c * 12.0) + 0.25));

    glFragColor = vec4(ch + o , 1.0);
}

