#version 420

// original https://www.shadertoy.com/view/wltGzM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Plento

mat2 rot(float a) {
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

#define b vec3(2)

vec3 hash33(vec3 p3){
    p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy + p3.yxx)*p3.zyx);
}
float hash12(vec2 p){
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 R;

float trace(vec3 rd, vec3 ro){
     float t = 0., d = 0., g = 0.;   
    vec3 p = vec3(0);
    
    for(int i = 0; i < 38; i++){
        p = (ro+rd*t);
        p = mod(p, b)-.5*b;
        d = length(p) - .23; 
        
        if(abs(d) < .01 || t > 25.){
            break;
        }
        t += d * .9;
    }
    
    return t;
}
vec3 color(vec3 ro, vec3 rd, float t){
    vec3 g = mod(ro, b)-.5*b;
    vec3 objcol = hash33(floor(ro*.5 - .25 ))*.35 - .05;
    vec3 col = objcol + vec3(.7, .6, .6)*exp(-length(g.xy-vec2(.05, .1))*40.)*40.;
    col = mix(col, vec3(0), 1. - exp( -.005*t*t*t));
    col = 1. - exp( -col );
    
    return col;   
}

vec3 scene(vec2 uv, float dt){
    float time = (time+dt)*3.;
    
    vec3 rd = normalize(vec3(uv, 1.0 - dot(uv, uv) * -.8));
    vec3 ro = vec3(0., time*2.0, time*4.);
    rd.yz*=rot(-.25);
   
    float t = trace(rd, ro);
    ro += rd*t;
    
    return color(ro, rd, t);
}

vec3 blur(vec2 uv){  
    vec3 col = vec3(0);
    for(float i = 0.; i < 4.; i++){
        col += scene(uv, (i*.0175) + (hash12(uv*999.)*.015) );    
    }
    col /= 4.;
    return col;
}

void main(void) {
    R = resolution.xy;
    vec2 uv = vec2(gl_FragCoord.xy - 0.5*R.xy)/R.y;
   
    vec3 col = blur(uv);
    //vec3 col = scene(uv, 0.); // without motion blur
    
    glFragColor = vec4(sqrt(clamp(col, 0.0, 1.0)), 1.0);
}

