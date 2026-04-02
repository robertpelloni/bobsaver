#version 420

// original https://www.shadertoy.com/view/ttcGWs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Plento
vec2 R;
const float pi = 3.14159;

mat2 rot(float a) {
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

#define s time*3.8

// The stairs sdf
float map(vec3 rp){
    //float k = floor(rp.x*.75)*.25;
    rp.yz += s;
    return min(rp.y - floor(rp.z), 1.- (rp.z - floor(rp.y)));
}

vec3 normal( in vec3 pos ){ // Can def get rid of this
    vec2 e = vec2(0.002, -0.002);
    return normalize(
        e.xyy * map(pos + e.xyy) + 
        e.yyx * map(pos + e.yyx) + 
        e.yxy * map(pos + e.yxy) + 
        e.xxx * map(pos + e.xxx));
}

float march(vec3 rd, vec3 ro){
     float t = 0., d = 0.;   
    
    for(int i = 0; i < 44; i++){
        d = map(ro + rd*t);        
        
        if(abs(d) < .005 || t > 64.){
            break;
        }
        
        t += d * .75;
    }
    
    return t;
}

// Color the stairs and also fake the staircase width
vec3 render(vec3 ro, vec3 rd, vec3 n, vec2 u, float t){
    vec3 lp = ro + vec3(0., .012, -.7);
    vec3 ld = lp-ro;
   
    float dif = max(dot(n, ld), .0);
    vec3 col = vec3(0);
    
    //float k = floor(ro.x*0.75)*.25;
    ro.yz+=s;
    
    
    //ro.x += cos(ro.z*.2)*4.;
    ro.x*=.5;
    
    float c = smoothstep(0.1, 0.15, sin(ro.x*4.));
    vec3 cc = .4 + .34*cos(2.*pi*(vec3(0.7, 4.8, 0.5)*floor(ro.z)));
    
    col = mix(vec3(.0), cc, c)*dif;
    col = mix(vec3(0), col,  smoothstep(9.9, 10.1, 30./abs(ro.x-4.33)));
    
    return col;   
}

void main(void) {
    vec2 u = gl_FragCoord.xy;

    R = resolution.xy;
    vec2 uv = vec2(u.xy - 0.5*R.xy)/R.y;
    vec2 m = mouse*resolution.xy.xy / R.xy-.5; 
    m.x *= R.x/R.y;
    
    float st = s+m.x*40.;
    
    vec3 rd = normalize(vec3(uv, 1.0));
    //vec3 ro = vec3(0.5,st+6.6 , -6. + st);
    vec3 ro = vec3(0.5,6.6 , -6.);
    
    rd.yz*=rot(.4);
    rd.xz*=rot(-.75);
    
    float t = march(rd, ro);
    
    ro += rd*t;
    
    vec3 n = normal(ro);
    vec3 col = render(ro, rd, n, u, t);
    
    col*=smoothstep(.52, .2, uv.y);
    glFragColor = vec4(sqrt(clamp(col, .0, 1.)), 1.);
    
}

