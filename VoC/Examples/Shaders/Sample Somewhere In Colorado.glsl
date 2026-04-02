#version 420

// original https://www.shadertoy.com/view/WlBcD3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Plento

#define R resolution.xy
#define ss(a, b, t) smoothstep(a, b, t)

mat2 rot(float a) {
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

vec3 hash31(float p){
   vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
   p3 += dot(p3, p3.yzx+33.33);
   return fract((p3.xxy+p3.yzz)*p3.zyx); 
}
float sdBox( in vec2 p, in vec2 b ){
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}
float box(vec2 uv, vec2 dim, float b){
    uv = abs(uv);
    float bx = ss(b, -b, uv.y - dim.y );
    bx *= ss(b, -b, uv.x - dim.x);
    return bx;
}

vec3 frameCol = 0.9*vec3(0.4, 0.3, 0.1);
vec3 winCol = .8*vec3(0.3, 0.9, 0.9);

vec4 ground(vec2 uv){
    float y = uv.y + 0.5;
    float a = 1.-step(.21, y);
    float sw = .6 * ss(-.1, 0.1, abs(cos(10.*(-uv.x + uv.y*2. + .12))));
    vec3 col = mix(vec3(.16), mix(vec3(.34), vec3(sw), step(.115, y)), step(.1, y));
    col = mix(col, vec3(1), step(.21, y));
    return vec4(col, a);
}

vec4 fence(vec2 uv){
    float a = ss(.0543,.054, abs(uv.y+.05));
     vec3 col = .9*vec3(0.9, 0.76, 0.6) * a;   
    col *= ss(-.3, .3, abs(sin(uv.x*140.)));
    return vec4(col, a);
}

vec4 mountains(vec2 uv){
    uv.y -= .12;
    vec3 col = vec3(0);
    float a = 0.;
    float snow = 0.;
    
    for(float i = 0.; i < 2.; i++){ 
        uv.x += time*.05;
        
        float ht = 0.0;//texture(iChannel0, uv*16.).x;
        
        float nse = cos(uv.x*14. + i*345.)*.01 + cos(uv.x*44. + i*123.)*.003
            + cos(uv.x*2. + i*654.)*.01;
        
        vec2 p = uv + nse;
        float t = (1.3-i*.02)*p.x*.8 + i*9.;
        float h = .06*asin(sin(6.*t + 2.5*i)*0.999);
        float c = ss(.104,.1, p.y - h - i*.01 + .02);
        a = mix(a, 1., c);
        
        col = mix(col, mix(vec3(.2, .3, .3),1.3*vec3(0.13, 0.26, 0.18),i), c);
        col +=ht*.06;
        snow = ss(.66, .674, (uv.y + 0.522)+nse*1.4);
        col = mix(col, vec3(3), snow); 
    }
    return vec4(col, a);
}

float snow(vec2 uv){
    float nse = cos(uv.x*60.)*.001 + cos(uv.x*170.)*.0006 + cos(uv.x*10. + 24.32)*.003
        + cos(uv.x*30. + 65.32)*.003;
    uv.y += nse;
     float a = ss(.1,.1038, abs(uv.y+.2));   
    vec3 col = vec3(0);
    return a;
}

float houseShape(vec2 uv, vec2 dim){
    float ox = dim.x;
    dim.x -= uv.y;
    dim.x = min(ox, dim.x);                      
    return box(uv, dim, .001);
}

vec4 roofShape(vec2 uv){
    float p = uv.x;
    
    uv.x = abs(uv.x);
    uv *= rot(7.05);
    
    float a = box(uv-vec2(-0.13, .32), vec2(.2, .01), .0001);
    vec3 col = frameCol * a;
    
    if(uv.y < 0.321)
        uv.y -= (cos(p*171.)*.01 + cos(p*50.)*.003 + cos(p*70.)*.005);
    
    float snow = box(uv-vec2(-0.13, .33), vec2(.21, .008), .005);
    col += vec3(6.) * snow;
    
    a += snow;
    return vec4(col, a);
}

vec4 house(vec2 uv, vec3 hc, bool front){
    vec3 col = hc;
    
    float a = houseShape(uv-vec2(0., .21), vec2(0.24, 0.35));
    vec2 p = (uv - vec2(0., 0.17)) * 6.5;
    
    vec2 b = vec2(0.91, 1.3);
    vec2 wv = mod(p + 0.5*b, b) - 0.5*b;
    
    if(front){
        float glass = box(wv, vec2(.26, .28), .001);
        float frame = box(wv, vec2(.22, .24), .001);
        frame *= step(.01, abs(wv.x))*step(.01, abs(wv.y));
    
        glass += frame;
    
        vec3 window = mix(frameCol, winCol, step(2., glass));
    
        glass *= 1.-step(.26, uv.y);
    
        col = mix(col, window, min(glass*3., 1.));
    
        float dr = box(uv-vec2(0., -0.04), vec2(.048, .076), .001);
        float doorframe = box(uv-vec2(0., -0.04), vec2(.04, .07), .001);
        float des = sdBox(uv-vec2(-0.02, 0.), vec2(.01, .02));
        des = min(des, sdBox(uv-vec2(0.02, 0.), vec2(.01, .02)));
        des = min(des, length(uv-vec2(0.02, -0.045))-.005);
        col = mix(col, .7*vec3(0.9, 0.8, 0.7), doorframe);
        col *= max(ss(.0,.0005, abs(des) - .001), 0.7);
        
        dr -= doorframe;
        col = mix(frameCol, col, 1.-dr);
    
        float steps = box(uv - vec2(0., -.137), vec2(.1, .005), .001);
        steps += box(uv - vec2(0., -.126), vec2(.08, .005), .001);
            steps += box(uv - vec2(0., -.115), vec2(.06, .005), .001);
    
        col = mix(col, vec3(.5), steps);
    }
    
    return vec4(col, a);
}

vec4 garage(vec2 uv, vec3 hc){
    vec3 col = hc;
     float a = houseShape(uv-vec2(0.55, .068), vec2(0.20, 0.22));   
    float door = box(uv-vec2(0.55, -0.05), vec2(.15, .1), .001);
    col = mix(col, frameCol*ss(-.5, .5,abs(sin(uv.y*150. + 1.5))), door);
    col *= max(min(abs((uv.y-.07)*310.), 1.), .8);
    return vec4(col, a);
}
 

vec4 walkway(vec2 uv){
    vec3 col = vec3(0);
     
    vec2 p = uv-vec2(0.48, 0.08);
    vec2 def = cos(uv*30.) * .01 + cos(uv*60. + 123.32) * .005 + cos(uv*250. + 123.32)*.0018;
    p += def;
    
    p.x -= sin(p.y*8.)*.5;
    p.y += cos(p.x*4.)*.1;
    
    float a = box(p - vec2(0.0, -0.2), vec2(.085, .1), .005);
    
    col = vec3(.65) * a;
    
    uv += def;
    float w2 = box(uv - vec2(0.55, -0.22), vec2(.1 - uv.y*.4, .175), .002);
    
    a = min(a+w2, 1.);
    col = mix(col, vec3(.65), a);
    
    return vec4(col, a);
}

void main(void) { //WARNING - variables void ( out vec4 f, in vec2 u ){ need changing to glFragColor and gl_FragCoord.xy
    vec2 u = gl_FragCoord.xy;
    vec4 f = glFragColor;

    vec2 uv = vec2(u.xy - 0.5*R.xy)/R.y;
    vec2 p = uv;
    
    uv.x += time*.2;
    
    vec3 col = vec3(.7, 0.9, 1.0);
    
    float spc = 1.8;
    vec2 b = vec2(spc, 0.0);
    vec2 ruv = mod(uv + 0.5*b, b) - 0.5*b;
    ruv.x += .3;
    float id = floor((uv.x - .5)/spc);
    
    
    float ht = 0.0;//texture(iChannel0, uv*16.).x;
    
    // Mountains
    vec4 mnt = mountains(p);
    col = mix(col, mnt.rgb, mnt.a);
    
    
   
    float spc2 = 1.1;
    vec2 b2 = vec2(spc2, 0.0);
    vec2 p2 = p-vec2(0.0, 0.);
    p2.x += time*.13;
    vec2 ruv2 = mod(p2 + 0.5*b2, b2) - 0.5*b2;
    ruv2.x += .3;
    float id2 = floor((p2.x - .5)/spc2);
    
    float ht2 = 0.0;//texture(iChannel0, p2*16.).x;
    
    vec3 hcb = .2 + .5 * hash31(id2*223.32 + 88.);
    hcb += ht2*.15;
    
    vec4 bhse = house((ruv2 - vec2(0.0, 0.))*1.8, hcb, false);
    col = mix(col, bhse.rgb*.8, bhse.a);
    vec4 rf3 = roofShape(ruv2*1.9);
    col = mix(col, rf3.rgb, rf3.a);
        
    
    // Fence
    vec4 fnc = fence(uv);
    col = mix(col, fnc.rgb, fnc.a);
    
    
    // Snowy yard
    float snw = snow(uv);
    col = mix(vec3(1), col, snw);
    
    
    // walkway/ driveway
    vec4 wlk = walkway(ruv);
    col = mix(col, wlk.rgb, wlk.a);
    
    
    // Sidewalk and road
    vec4 gnd = ground(uv);
    col = mix(col, gnd.rgb, gnd.a);
    
    // house color
    vec3 hc = .2 + .5 * hash31(id*623.32 + 5.);
    hc += ht*.15;
    
    // house
    vec4 hse = house(ruv, hc, true);
    col = mix(col, hse.rgb, hse.a); 
    
    vec2 pc = ruv;
    pc.xy += cos(uv.yx*40.+3.)*.005 + cos(uv.yx*80.+324.3)*.002 + cos(uv.yx*180.+324.3)*.001;
    float det = box(pc-vec2(-0.42, -.18), vec2(.33, .05), .002);
    det += box(-pc-vec2(-0.17, .143), vec2(.07, .01), .002);
    col = mix(col, vec3(1), det);
    
    
    // roof
    vec4 roof = roofShape(ruv);
    col = mix(col, roof.rgb, roof.a);
    
    // garage
    vec4 grg = garage(ruv, hc);
    col = mix(col, grg.rgb, grg.a); 
    
    // garage roof
    vec4 groof = roofShape(1.2*ruv-vec2(0.66, -0.13));
    col = mix(col, groof.rgb, groof.a);
    
    
    glFragColor = vec4(col, 1.0);

    
}

