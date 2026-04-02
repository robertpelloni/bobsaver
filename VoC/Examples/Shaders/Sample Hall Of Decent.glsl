#version 420

// original https://www.shadertoy.com/view/wttcRN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Cole Peterson

#define R resolution.xy
#define ss(a, b, t) smoothstep(a, b, t)

mat2 rot(float a) {
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}
float hash11(float p){
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

float opsub( float d1, float d2 ) { return max(-d1,d2); }

float rBox( vec3 p, vec3 b, float r ){
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

vec3 ref(vec3 rp, vec3 q){
    return -vec3(abs(rp.x), abs(rp.y), abs(rp.z)) + q*step(vec3(0), q);
}

float map(vec3 rp){
    float d = 999.;
    
    float tm = (time-3.)*2.;
    
    rp.z += tm-3.;
    
    vec3 p = rp;
    vec3 b = vec3(4.0, 4., 9.0);
   
    p = mod(rp, b)-b*.5;
    p = -abs(p);
    
    
    float sp = 0.8;
    
    float t2 = tm*.1;
    
    for(float i = 0.; i < 4.; i++){
        p.yz *= rot(i*0.01);
        p.xy *= rot(i*0.4 + rp.z*.07);
        p.xz *= rot(i*7.);
        
        float h = 1.3*max(hash11(i*232.4+34.3)*2.2, 1.7);
        d = min(rBox(ref(p, vec3(0.3, 0.9, 0.9)), vec3(h, .2, .2), .08), d);
    }
    
    d = opsub(length(rp.xy)-1.9 + cos(rp.z)*.4, d);
    
    return d;
}

vec3 normal( in vec3 pos ){
    vec2 e = vec2(0.002, -0.002);
    return normalize(
        e.xyy * map(pos + e.xyy) + 
        e.yyx * map(pos + e.yyx) + 
        e.yxy * map(pos + e.yxy) + 
        e.xxx * map(pos + e.xxx));
}

vec2 march(vec3 rd, vec3 ro){
     float t = 0., d = 0., c=0., md = 999., acc = 0.0;   
    float g = 0.;
    
    for(int i = 0; i < 64; i++){
    
        d = map(ro + rd*t);
        
        if(abs(d) < .0015 || t > 50.) break;
        
        t += d * .75;
        c++;
    }
    
    return vec2(t, c);
}

vec3 color(vec3 p, vec3 rd, vec3 n, float t, float ns){
    vec3 lp = vec3(-4., -3.0, 0.);
    
    vec3 ld = normalize(lp-p);
       
    float ldist = length(lp - p);
    float fal = 20. / (ldist*ldist);
    
    float spec = pow(max(dot(normalize(reflect(ld, n)), rd), 0.), 18.);
    float dif = max(dot(n, ld), .01);
    
    vec3 col = .75+.75*cos(abs(n) + time + 2.*t*vec3(.2, .6, .6));
    col *= dif * fal;
    col *= max(abs(cos(abs(n.x*6.))), .7);
    col += vec3(0.6, 0.8, 0.99) * spec * 0.8;
    
    float ao = ss(40., 10., ns);
    col *= ao;
    
    col = mix(vec3(.0), col, exp(-t*t*t*0.0001));
    
    return col;   
}

void main(void) {
    vec2 uv = vec2(gl_FragCoord.xy - 0.5*R.xy)/R.y;
    
    uv = abs(uv);
    
    vec3 rd = normalize(vec3(uv, 1.0 - dot(uv, uv) * -.5));
    vec3 ro = vec3(0., 0.0, 0.);
    rd.xy*=rot(-time*.2);
    vec2 t = march(rd, ro);
    
    vec3 n = normal(ro + rd*t.x);
    vec3 col = color(ro + rd*t.x, rd, n, t.x, t.y);
    
    
    col = 1.-exp(-col);
    col *= ss(0.99, 0.45, abs(uv.x));
    
    glFragColor = vec4(sqrt(clamp(col, .0, 1.)), 1.);
    
}

