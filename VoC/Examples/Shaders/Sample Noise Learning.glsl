#version 420

// original https://www.shadertoy.com/view/fs3cRn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash(vec2 p){
    return fract(sin(p.x * 3331.0+6337.6)*cos(p.x*p.y)+cos(p.y * 9946.1+3333.0));
}

float remap(float t){
    return -2.0*t*t*t + 3.0*t;
    //return sin(t);
}

float noise(vec2 p){
    vec2 base = floor(p);
    vec2 t = fract(p);
    t.x = remap(t.x);
    t.y = remap(t.y);
    
    //v0  v1
    //v2  v3
    vec2 cood0 = base;
    vec2 cood1 = base + vec2(1.0,0.0);
    vec2 cood2 = base + vec2(0.0,1.0);
    vec2 cood3 = base + vec2(1.0,1.0);
    
    float val0 = hash(cood0);
    float val1 = hash(cood1);
    float val2 = hash(cood2);
    float val3 = hash(cood3);
    
    float top = mix(val0,val1,t.x);
    float bot = mix(val2,val3,t.x);
    
    return mix(top,bot,t.y);
}

float fbm(vec2 p){
    float n = noise(p*4.0);
    n += noise(p*8.0)*0.5;
    n += noise(p*16.0)*0.25;
    n += noise(p*32.0)*0.125;
    n += noise(p*64.0)*0.0625;
    return n;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    // strench the canvas
    uv.y /= resolution.x / resolution.y;

    // Time varying pixel color
   float tim = time * 0.1;
    
    float a = fbm( uv + fbm( uv)+tim );
    a = sqrt(a);

    vec3 col = vec3(a*0.0/255.0,a*210.0/255.0,a*240.0/255.0);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
