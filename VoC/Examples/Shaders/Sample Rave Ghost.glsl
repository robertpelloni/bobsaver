#version 420

// original https://www.shadertoy.com/view/tdtGWr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TWO_PI 6.28
#define PI 3.1415926535

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float N21(vec2 p){
    return fract(sin(p.x*884.32+p.y*49993.)*239.);
}

float smoothNoise(vec2 uv){
    
    vec2 lv = fract(uv);
    vec2 id = floor(uv);
    
    lv = lv*lv*(3.-2.*lv);
    float bl = N21(id);
    float br = N21(id+vec2(1, 0));
    
    float b = mix(bl, br, lv.x);
    
    float tl = N21(id+vec2(0, 1));
    float tr = N21(id+vec2(1,1));
    float t = mix(tl, tr, lv.x);
    
    return mix(b, t, lv.y);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    vec3 col = vec3(0.);
    float height = 0.2;
    vec2 p = uv;
    
    float rate = 3.5;
    p.x += sin(uv.y*6.+time*rate)*0.025;
    if(p.y < -0.2) // Tail wiggle
        p.x += sin(uv.y*65.+time*rate)*0.25*(p.y+0.2);
    
    float pix = 1.5/resolution.y;
    p.y += 0.1;
    //Body
    col += smoothstep(0.2+pix, 0.2-pix, abs(p.x));
   
    col -= smoothstep(0.3-pix, 0.3+pix, abs(p.y-0.0));
    col = clamp(col, 0., 1.0);
    col += smoothstep(0.201+pix, 0.201-pix, length(vec2(p.x, p.y-0.29)));
    
    
    
    
    //Triangle
    vec2 gt = p;
    
    float a = 0.9;
    gt *= mat2(cos(a), -sin(a), sin(a), cos(a));
    col -= smoothstep(0.1+pix, 0.1-pix, abs(gt.y+0.3));
    col = clamp(col, 0., 1.);
    
    
    a = -0.9;
    gt *= mat2(cos(a), -sin(a), sin(a), cos(a));
    gt.x *= -1.;
    a = 0.9;
    gt *= mat2(cos(a), -sin(a), sin(a), cos(a));
    col -= smoothstep(0.1+pix, 0.1-pix, abs(gt.y+0.3));
    
    //Random number based upon time
    float t = mod(time, 200.);
    float h = smoothNoise(vec2(t));
    h += smoothNoise(vec2(t*2.))*0.5;
    h += smoothNoise(vec2(t*4.))*0.25;
    
    //Eyes
    float size = sin(time*rate)*0.02+0.05;
    
    col *= vec3( smoothstep(size-pix, size+pix, length(vec2(abs(p.x - 0.1), p.y-0.3))));
    col *= vec3( smoothstep(size-pix, size+pix, length(vec2(abs(p.x + 0.1), p.y-0.3))));
    col = clamp(col, 0., 1.0);
    
    //Arms
    vec2 av = p;
    
    av.y -= sin(abs(av.x*30.)-2.*time)*0.025;
    float thickness = 0.05*(1.0-abs(av.x*1.5));
    col += smoothstep( thickness+pix, thickness-pix, abs(av.y-0.13) );
    col = clamp(col, 0., 1.);
    
    
    
    
    vec3 rave = hsv2rgb(vec3(h, 0.7,1.0));
    col *= rave;
    
    col = clamp(col, 0., 1.);
    
    col += smoothstep(0.0, 1.0, abs(p.y-0.1))*rave;

    // Output to screen
    glFragColor = vec4(col,1.0);
}
