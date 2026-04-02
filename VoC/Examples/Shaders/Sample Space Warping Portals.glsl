#version 420

// original https://www.shadertoy.com/view/ws2fDW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Made by Plento
// An experiment with messing with space in a portal like fashion
vec2 R;

#define m vec2(R.x/R.y*(mouse*resolution.xy.x/R.x-.5),mouse*resolution.xy.y/R.y-.5)
#define FAR 64.
#define FAR2 12.

mat2 rot(float a){return mat2(cos(a), -sin(a), sin(a), cos(a));}

float box( vec3 p, vec3 b ){
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float hall(vec3 rp){
    float d  = 999.;
    rp.x = -abs(rp.x);
    d = min(d, box(rp-vec3(-2., 0.0, 11.0), vec3(0.1, 2., 5.0)));
    d = min(d, box(rp-vec3(0.0, 2.1, 11.0), vec3(2.1, 0.1, 5.0)));
    return d;
}

vec3 b = vec3(8., 0., 0.);

// distance field for hall and floor
float map(vec3 rp){
    float d = 999.;
    
    vec3 p = rp;
    p = mod(p, b)-b*0.5;
    
    d = min(d, 2. + rp.y);
    d = min(d, hall(p));
    
    return d;
}
// distance field for just portals
float mapPortal(vec3 rp){
    vec3 p = rp-vec3(0., 0., 6.);
    p = mod(p, b)-b*0.5;
    return box(p, vec3(1.9, 2., .001));
}

vec3 normal( in vec3 pos ){
    vec2 e = vec2(0.002, -0.002);
    return normalize(
        e.xyy * map(pos + e.xyy) + 
        e.yyx * map(pos + e.yyx) + 
        e.yxy * map(pos + e.yxy) + 
        e.xxx * map(pos + e.xxx));
}

// march scene for color
float march(vec3 rd, vec3 ro){
     float t = 0., d = 0.;  
    
    for(int i = 0; i < 99; i++){
        d = map(ro + rd*t);        
        if(abs(d) < .0025 || t > FAR) break;
        t += d * .95;
    }
    
    return t;
}

// march scene for just portals with reduced step count
float tracePortal(vec3 rd, vec3 ro){
     float t = 0., d = 0.;  
    
    for(int i = 0; i < 28; i++){
        d = mapPortal(ro + rd*t);        
        
        if(abs(d) < .0025) break;
        if(t > FAR2){t = FAR2; break;}
        
        t += d * .75;
    }
    return t;
}

vec3 color(vec3 p, vec3 rd, vec3 n, vec2 u, float t){
    vec3 lp = p+vec3(4., 16.0, -2.0);
    vec3 ld = normalize(lp-p);
       vec3 ref = reflect( rd, n );
    
    float lgd = length(lp - p);
    float faloff = 1.-exp(-(4. / lgd));
    
    float dom = smoothstep(-0.1, 0.1, ref.y);
    float dif = max(dot(n, ld), .025);
    
    vec3 col = vec3(0);    
    vec3 lig = vec3(0);
    
    if(p.y <= -1.85){
        vec2 id = floor(p.xz*1.);
        float chk = mod(id.x+id.y, 2.);
        col = mix(vec3(.6), vec3(0.), chk); 
    }
    else{col = vec3(1., 1., 1.);}
    
    lig += .4*dom*vec3(0.2,0.1,1.0)*dom;
    lig += 2.6*dif*vec3(1., 1., 1.) * faloff;
    col *= lig;
   
    vec3 sky = mix(vec3(0.2, 0.48, 0.88), vec3(0.8, 0.48, 0.88), abs(rd.y*7.8));
    col = mix(sky, col, exp(-t*t*t*0.00003));
    
    return col;   
}

void main(void) {
    vec2 u = gl_FragCoord.xy;
    R = resolution.xy;
    vec2 uv = vec2(u.xy - 0.5*R.xy)/R.y;
    
    vec3 rd = normalize(vec3(uv, 0.9));
    vec3 ro = vec3(time*3., 0., 0.);
    
    //if(mouse*resolution.xy.z > 0.){
    //     ro.x += m.x*42.;
    //    ro.y += m.y*8.;
    //}
    
    vec3 p = vec3(0);
    float t = 0.;
    
    vec3 col = vec3(0);
    vec3 n = vec3(0);
    
    float tp = tracePortal(rd, ro);
    
    if(tp < FAR2){ // hit portal, do wacky stuff with ray
        p = ro+rd*tp;        
        
        float id = floor(p.x/b.x);
        float seq = floor(mod(id, 6.));
        
        if(seq==0.) rd.z *= 5.0;
        else if(seq==1.) rd.z*=.1;   
        else if(seq==2.) rd.xz*=rot(.6);     
        else if(seq==3.) rd.xz*=rot(-.5);   
        else if(seq==4.) rd.yz*=rot(.4);     
        else if(seq==5.) rd.yz*=rot(-.23);     
         
        t = march(rd, p);
        p += rd*t;
        
        n = normal(p);
        col = color(p, rd, n, u, t);
    }
    else{ // trace scene like normal
        t = march(rd, ro);
        p = ro+rd*t;      
        n = normal(p);
        col = color(p, rd, n, u, t);  
    }
    
    col*=smoothstep(0.5, 0.0, abs(uv.y));
    glFragColor = vec4(sqrt(clamp(col, .0, 1.)), 1.);
    
}

