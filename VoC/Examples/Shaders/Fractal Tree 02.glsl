#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sdBox( vec3 p, vec3 b ) {
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float sdCapsule(vec3 p, vec3 a, vec3 b, float r) {
    vec3 pa = p - a;
    vec3 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - h * ba) - r;
}

float sdCappedCylinder( vec3 p, vec2 h ) {
    vec2 d = abs(vec2(length(p.xz),p.y)) - h;
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

vec3 tri(in vec3 x){return abs(fract(x)-.5);}
float surfFunc(in vec3 p){
    return dot(tri(p*0.5 + tri(p*0.25).yzx), vec3(0.666));
}

float smin(float a, float b, float k) {
    float h = clamp((b - a)/k *0.5 + 0.5, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float hash(vec2 p) {
    return fract(sin(p.x * 15.57 + p.y * 37.89) * 43758.26);
}

float map(vec3 p) {

    vec3 q = p-vec3(0,-0.5,0.);
    float d = 1e9;
    for(float i = 0.; i <= 1.; i += 1./5.){
        //+pk
        d = min(d, sdCappedCylinder(q, vec2(0.1, 0.4)));
        q.y -= 0.4;
        q *= 1.25;
        float th = 0.8*-sign(q.x);
        q.xy *= mat2(cos(th), sin(th), -sin(th), cos(th));
        th = (i+mouse.y)*7.;
        q.xz *= mat2(cos(th), sin(th), -sin(th), cos(th));
    }
    d = min(d, sdBox(p - vec3(0.0, 0.0, -1.0), vec3(1.0, 1.0, 0.01)));
    d = min(d, sdBox(p - vec3(0.0, -1.0, 0.0), vec3(1.0, 0.01, 1.0)));
    d = min(d, sdBox(p - vec3(1.0, 0.0, 0.0), vec3(0.01, 1.0, 1.0)));
    return d;
}

vec3 calcNormal(vec3 p) {
    vec2 e = vec2(-1.0, 1.0) * 0.001;
    return normalize(
        e.xyy * map(p + e.xyy) +
        e.yxy * map(p + e.yxy) +
        e.yyx * map(p + e.yyx) +
        e.xxx * map(p + e.xxx)
    );
}

float calcAO(in vec3 ro, in vec3 rd) {
    float t = 0.0;
    float h = 0.0;
    float occ = 0.0;
    for(int i = 0; i < 5; i++) {
        t = 0.01 + 0.12*float(i)/4.0;
        h = map(ro + rd * t);
        occ += (t-h)*(4.0-float(i));
    }
    return clamp(1.0 - 2.0*occ, 0.0, 1.0);
}

float softshadow(in vec3 ro, in vec3 rd, in float tmin, in float tmax) {
    float t = tmin;
    float h = 0.0;
    float sh = 1.0;
    for(int i = 0; i < 20; i++) {
        if(t > tmax) continue;
        h = map(ro + rd * t);
        sh = min(sh, h/t*50.0);
        t += h * 0.5;
    }
    return clamp(sh, 0.0, 1.0);
}

float shadow( in vec3 ro, in vec3 rd, float mint, float maxt ) {
    float t = mint;
    for( int i = 0; i < 20; i++) {
        if(t > maxt) continue;
        float h = map(ro + rd*t);
        if( h<0.001 ) {
                return 0.0;
        }
        t += h;
    }
    return 1.0;
}

float trace(in vec3 ro, in vec3 rd){
    float FAR = 50.0;
    float t = 0.0, h;
    for(int i = 0; i < 72; i++){
    h = map(ro+rd*t);
    if(abs(h)<0.002*(t*.125 + 1.) || t>FAR) break;       
        t += step(h, 1.)*h*.2 + h*.35;
    }
    
    return min(t, FAR);
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5*resolution.xy) / resolution.y;
    
    vec3 ro = vec3(-6.0, 3.0, 6.0) + vec3(mouse.x * 2.0 - 1.0, 0.0, 0.0) * 3.0;
    vec3 ta = vec3(0.0, 0.0, 0.0);
    
    vec3 cw = normalize(ta - ro);
    vec3 cup = vec3(0.0, 1.0, 0.0);
    vec3 cu = normalize(cross(cw, cup));
    vec3 cv = normalize(cross(cu, cw));
    
    float pi = 3.141592;
    float fovy = pi / 4.0;
    float f = tan(fovy * 0.5);
    vec3 rd = normalize(cu * uv.x + cv * uv.y + (1.0/f) * cw);
    
      //-----

    float e = 0.001;
    float h = 2.0 * e;
    float t = trace(ro, rd);
    
    float ff = clamp((t - 1.0) / 30.0, 0.0, 1.0);
    ff = exp(-3. * ff);
    vec3 sky = vec3(0., .9, 2.8);
    vec3 col = sky;
    
    vec3 lig_pos0 = vec3(0.0, 1.0, 0.0) * 10.0;
    vec3 lig_pos1 = vec3(-1.0, 0.0, 0.0) * 10.0;
    vec3 lig_pos2 = vec3(0.0, 0.0, 1.0) * 10.0;
    
    float dur = 10.0;
    float tt = mod(time, dur) / dur;
    
    vec3 lig_pos = mix(lig_pos0, lig_pos1, smoothstep(0.0, 0.333, tt));
    lig_pos = mix(lig_pos, lig_pos2, smoothstep(0.333, 0.666, tt));
    lig_pos = mix(lig_pos, lig_pos0, smoothstep(0.666, 1.0, tt));
    if(t < 50.0) {
        vec3 pos = ro + rd * t;
        vec3 nor = calcNormal(pos);
        vec3 lig = normalize(lig_pos);
        float dif = clamp(dot(nor, lig), 0.0, 1.0);
        vec3 ref = reflect(rd, nor);
        float spe = pow(clamp(dot(ref, lig), 0.0, 1.0), 64.0);
        float sh = shadow(pos, lig, 0.01, 10.0);
        float fre = 1.0 - dot(nor, -rd);
        
        col = vec3(1.0) * (dif + spe + fre * 0.5) * sh;
        col = mix(sky, col, ff);
    }
    
    glFragColor = vec4(col, 1.0);
}
