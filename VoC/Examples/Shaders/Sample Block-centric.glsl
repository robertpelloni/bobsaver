#version 420

// original https://www.shadertoy.com/view/Ws3BR2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Cole Peterson
#define R resolution.xy
#define m vec2(R.x/R.y*(mouse*resolution.xy.x/R.x-.5),mouse*resolution.xy.y/R.y-.5)
#define ss(a, b, t) smoothstep(a, b, t)

float point(vec2 p, float r){
     return ss(0.003, 0.0, length(p) - r);   
}
mat2 rot(float a) {
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

vec3 drawTriangle(vec3 col, vec2 uv, vec2 A, vec2 B, vec2 C){
    col = mix(col, vec3(1., 0., 0.), point(A.xy-uv, 0.006));
    col = mix(col, vec3(1., 0., 0.), point(B.xy-uv, 0.006));
    col = mix(col, vec3(1., 0., 0.), point(C.xy-uv, 0.006));
    return col;
}

float hash13(vec3 p3){
    p3  = fract(p3 * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

void main(void) {
    vec2 uv = vec2(gl_FragCoord.xy - 0.5*R.xy)/R.y;
    uv*= 1.0;
    
    vec3 col = vec3(1);
    float scl = 0.25 + (.5+.3*sin(time*.5))*.3;
    
    //vec2 A = m;
    vec2 A = vec2(0., -.17)*scl;
    vec2 B = vec2(-0.1, -0.25)*scl;
    vec2 C = vec2(0.1, -0.25)*scl;
    
    //if(mouse*resolution.xy.z > 0.0) A = m;
    
    vec3 M = vec3(uv.x, uv.y, 1.);
    
    vec3 A3 = vec3(A, 1.);
    vec3 B3 = vec3(A, 1.);
    vec3 C3 = vec3(A, 1.);
    
    mat3 mat = mat3(vec3(A, 1.), vec3(B, 1.), vec3(C, 1.));
    
    vec3 bc = inverse(mat) * M;
    
    
    bc.yz *= rot(time*.2);
    bc.y -= time*4.;
    
    //bc.y += cos(bc.z*3.6 + time*8.)*0.03;
    //bc.z += sin(bc.y*3.6 + time*8.)*0.03;
    
       vec3 id = floor(bc);
    
    float sY = floor(mod(id.y, 2.))*2. - 1.;
    
   
    id = floor(bc);
    vec3 rbc = fract(bc-.5)-.5;
   
    vec2 dim = vec2(3);
    
       col = vec3(0.03);    
    
    vec2 ridBIG = floor(mod(id.zy, (2.*dim.x - 1.)*14.));
    
    if(ridBIG.x < 5. || ridBIG.y < 0.)
        dim = vec2(3);
    else
        dim = vec2(2);
    
    
    vec2 rid = mod(id.zy, 2.*dim.x - 1.);
    
    if(rid.x == 3.) rid.x = 0.;
    if(rid.y == 3.) rid.y = 0.;
    
    
    float chng = floor(mod((rid.x + dim.x-1.) / (dim.x + dim.x-1.), 2.));
    
    vec2 p = vec2(0., 0.);
    
    float block = min(step(dim.x, abs(rid.y-p.x)) + 
                      step(dim.y, abs(rid.x-p.y)), 1.);
    
    
    bc.z += time * cos(id.y);
    bc.y += time * cos(id.z);
    vec3 rbc2 = fract(bc)-.5;
    
    float t = id.y*0.14 + id.z*0.14;
    vec3 c = .5+.2*cos(vec3(2.2, 3.3, 1.3) * t);
    col = mix(c, col, block);
    
    
    vec2 ra = vec2(1.-step(.5, chng), step(.5, chng));
    float re = rbc2.z*ra.x + rbc2.y*ra.y;
    float road = abs(dot(ra, abs(rbc.yz)-.5));
    float stripe = (ss(.04,.0, road-.01));
    stripe *= ss(.04, .0, abs(re)-.2);
      
    col = mix(col, vec3(1., 1., 1.), stripe*block);
    
    
    
    col *= ss(0.8, .0, length(vec2(uv.x, uv.y*1.8))-.5);
    
    //col += (1.-step(0.026, abs(rbc.y) - 0.01))*.4 *(.5+.5*cos(time));
    //col += (1.-step(0.026, abs(rbc.z) - 0.01))*.4*(.5+.5*cos(time));
    
    vec3 rbc3 = fract((bc - vec3(0., time, time))*0.2)-.5;
    
    
    //if(mouse*resolution.xy.z > 0.0) col = drawTriangle(col, uv, A, B, C);
    
    
    glFragColor = vec4(col, 1.0);
}

