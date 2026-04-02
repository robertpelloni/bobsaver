#version 420

// original https://www.shadertoy.com/view/3tlGW4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// All the distance functions from:http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
// Edge detection code from:https://www.shadertoy.com/view/MsSGD1
#define rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
#define matRotateX(rad) mat3(1,0,0,0,cos(rad),-sin(rad),0,sin(rad),cos(rad))
#define matRotateY(rad) mat3(cos(rad),0,-sin(rad),0,1,0,sin(rad),0,cos(rad))
#define matRotateZ(rad) mat3(cos(rad),-sin(rad),0,sin(rad),cos(rad),0,0,0,1)
#define hash(h) fract(sin(h) * 43758.5453123)
#define EDGE_WIDTH 0.05

mat3 m = mat3( 0.00,  0.80,  0.60,
              -0.80,  0.36, -0.48,
              -0.60, -0.48,  0.64 );

float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);

    f = f*f*(3.0-2.0*f);

    float n = p.x + p.y*57.0 + 113.0*p.z;

    float res = mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
                        mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y),
                    mix(mix( hash(n+113.0), hash(n+114.0),f.x),
                        mix( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
    return res;
}

float fbm( vec3 p )
{
    float f;
    f  = 0.5000*noise( p ); p = m*p*2.02;
    f += 0.2500*noise( p ); p = m*p*2.03;
    f += 0.1250*noise( p );
    return f;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0))-0.08;
}

float dBox2d(vec2 p, vec2 b) {
    return max(abs(p.x) - b.x, abs(p.y) - b.y);
}

float sdHexPrism( vec3 p, vec2 h )
{
    const vec3 k = vec3(-0.8660254, 0.5, 0.57735);
    p = abs(p);
    p.xy -= 2.0*min(dot(k.xy, p.xy), 0.0)*k.xy;
    vec2 d = vec2(
       length(p.xy-vec2(clamp(p.x,-k.z*h.x,k.z*h.x), h.x))*sign(p.y-h.x),
       p.z-h.y );
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdRoundedCylinder( vec3 p, float ra, float rb, float h )
{
    vec2 d = vec2( length(p.xz)-2.0*ra+rb, abs(p.y) - h );
    return min(max(d.x,d.y),0.0) + length(max(d,0.0)) - rb;
}

vec4 combine(vec4 val1, vec4 val2 ){
    if ( val1.w < val2.w ) {
        return val1;
    }
    return val2;
}

float sdTorus(vec3 p, vec2 t) {
    vec2 q = vec2(length(p.xz)-t.x,p.y);
    return length(q)-t.y;
}

vec3 tireTex(vec2 uv) {
    vec3 col = vec3(1.0,0.0,0.0);
    float d0 = length(uv+vec2(0.5,0.5))-0.36;
    float d1 = length(uv+vec2(0.5,0.5))-0.33;
    float d2 = length(uv+vec2(-0.5,0.5))-0.36;
    float d3 = length(uv+vec2(-0.5,0.5))-0.33;
    
    float size = 0.01;
    
    col = mix( col, vec3(1.0), 1.0-smoothstep(0.01,0.02,d0) );
    col = mix( col, vec3(1.0,0.0,0.0), 1.0-smoothstep(0.01,0.02,d1) );
    col = mix( col, vec3(1.0), 1.0-smoothstep(0.01,0.02,d2) );
    col = mix( col, vec3(1.0,0.0,0.0), 1.0-smoothstep(0.01,0.02,d3) );
    
    return col;
}

vec3 bodyTex(vec2 uv) {
    vec3 col = vec3(1.0,0.0,0.0);
    float d0 = dBox2d(uv+vec2(-0.4,0.2),vec2(0.1,0.03));
    float d1 = dBox2d(uv+vec2(0.4,0.2),vec2(0.1,0.03));
    col = mix( col, vec3(1.0), 1.0-smoothstep(0.04,0.05,d0) );
    col = mix( col, vec3(1.0), 1.0-smoothstep(0.04,0.05,d1) );
    
    return col;
}

vec3 animateTex(vec2 uv, float dir) {
    vec3 col = vec3(1.0,0.0,0.0);
    uv.y+=(dir == 0.0)?time*-0.1:time*0.1;
    uv.y = mod(uv.y,0.1)-0.05;
    float d0 = dBox2d(uv+vec2(0.0,0.0),vec2(0.1,0.02));
    col = mix( col, vec3(1.0,1.0,0.0), 1.0-smoothstep(0.01,0.02,d0) );
    return col;
}

vec3 seatTex(vec2 uv) {
    vec3 col = vec3(1.0,0.0,0.0);
    float d0 = dBox2d(uv+vec2(0.0,0.0),vec2(0.25,0.4));
    col = mix( col, vec3(0.2), 1.0-smoothstep(0.01,0.02,d0) );
    return col;
}

vec3 floorTex(vec2 uv) {
    vec3 col = vec3(0.9,0.6,0.6);
    float w = 2.0;
    col = (uv.x>=-w && uv.x< w)? vec3(0.8):col;
    uv.y+=time*30.0;
    uv.y = mod(uv.y,8.0)-4.0;
    float d0 = dBox2d(uv+vec2(1.5,0.0),vec2(0.05,2.5));
    float d1 = dBox2d(uv+vec2(-1.5,0.0),vec2(0.05,2.5));
    col = mix( col, vec3(1.0), 1.0-smoothstep(0.01,0.03,d0) );
    col = mix( col, vec3(1.0), 1.0-smoothstep(0.01,0.03,d1) );
    
    return col;
}

vec4 sdBike(vec3 p) {
    vec3 pref = p;
    vec2 uv = p.xy;
    
    vec4 tireF = vec4(vec3(0.0,0.0,0.0),sdTorus((p+vec3(0.0,0.55,1.2))*matRotateZ(radians(90.0)),vec2(0.3,0.12)));
    vec4 tireF2 = vec4(tireTex(uv),length(p+vec3(0.0,0.55,1.2))-0.3);
    
    vec4 tireB = vec4(vec3(0.0,0.0,0.0),sdTorus((p+vec3(0.0,0.55,-1.2))*matRotateZ(radians(90.0)),vec2(0.3,0.12)));
    vec4 tireB2 = vec4(tireTex(uv),length(p+vec3(0.0,0.55,-1.2))-0.3);

    p.x = abs(p.x);
    vec4 rearFrame = vec4(bodyTex(uv),sdBox((p+vec3(-0.3,0.3,0.9))*matRotateX(radians(40.0)), vec3(0.002,0.17,0.45)));
    p = pref;
    
    vec4 body0 = vec4(seatTex(uv),sdBox((p+vec3(0.0,0.2,0.4))*matRotateX(radians(-60.0)), vec3(0.2,0.17,0.45)));
    vec4 body1 = vec4(vec3(1.0,0.0,0.0),sdBox(p+vec3(0.0,0.6,-0.12), vec3(0.2,0.1,0.4)));
    vec4 body2 = vec4(vec3(1.0,0.0,0.0),sdBox((p+vec3(0.0,0.35,-0.55))*matRotateX(radians(-20.0)), vec3(0.2,0.3,0.1)));
    
    p.x = abs(p.x);
    vec4 frontFrame = vec4(bodyTex(uv),sdBox((p+vec3(-0.25,0.2,-0.8))*matRotateX(radians(-25.0)), vec3(0.002,0.15,0.45)));
    p = pref;
    
    vec4 frontGlass = vec4(animateTex(uv,0.0),sdBox(( p+vec3(0.0,-0.03,-0.80))*matRotateX(radians(-25.0)),vec3(0.25,0.05,0.55)));
    p = pref;
    
    p.x = abs(p.x);
    vec4 engine = vec4(vec3(1.0,0.0,0.0),sdRoundedCylinder((p+vec3(-0.25,0.65,0.3))*matRotateZ(radians(90.0)), 0.11,0.05,0.05));
    vec4 engine2 = vec4(vec3(1.0,0.0,0.0),sdRoundedCylinder((p+vec3(-0.25,0.75,-0.05))*matRotateZ(radians(90.0)), 0.08,0.05,0.05));
    p = pref;
    
    vec4 rearMudguard = vec4(animateTex(uv,1.0),sdBox((p+vec3(0.0,-0.17,0.77))*matRotateX(radians(20.0)), vec3(0.2,0.02,0.3)));
    
    p.x = abs(p.x);
    vec4 handle = vec4(vec3(0.2),sdBox((p+vec3(-0.25,-0.1,-0.3))*matRotateX(radians(20.0))*matRotateY(radians(45.0)), vec3(0.2,0.0001,0.0001)));
    
    return combine(combine(combine(combine(combine(combine(combine(tireF,tireF2), combine(tireB,tireB2)),combine(rearFrame,body0)),combine(body1,body2)),combine(frontFrame,frontGlass)),combine(engine,engine2)),combine(rearMudguard,handle));
}

vec4 map(vec3 p){    
    vec3 pref = p;
    vec2 uv = p.xy;
    vec4 f = vec4(floorTex( p.xz),p.y+1.0);
    p.z += time*30.0;
    p.z = mod(p.z,20.0)-10.0;

    float d0 = sdHexPrism((p+ vec3(0.0,-1.5,0.0)),vec2(4.5,1.0));
    float d1 = sdHexPrism((p+ vec3(0.0,-1.5,0.0)),vec2(4.7,0.7));
    d0 = max(-d0,d1);
    vec4 cell = vec4(vec3(1.0,0.0,0.0),max(sdBox(pref,vec3(9.0,9.0,70.0)),d0));
    return combine(combine(f,sdBike(pref*matRotateZ(radians(sin(time*1.2)*15.0)))),cell);
}

vec3 normalMap(vec3 p){
    float d = 0.0001;
    return normalize(vec3(
        map(p + vec3(  d, 0.0, 0.0)).w - map(p + vec3( -d, 0.0, 0.0)).w,
        map(p + vec3(0.0,   d, 0.0)).w - map(p + vec3(0.0,  -d, 0.0)).w,
        map(p + vec3(0.0, 0.0,   d)).w - map(p + vec3(0.0, 0.0,  -d)).w
    ));
}

float shadowMap(vec3 ro, vec3 rd){
    float h = 0.0;
    float c = 0.001;
    float r = 1.0;
    float shadow = 0.5;
    for(float t = 0.0; t < 30.0; t++){
        h = map(ro + rd * c).w;
        if(h < 0.001){
            return shadow;
        }
        r = min(r, h * 16.0 / c);
        c += h;
    }
    return 1.0 - shadow + r * shadow;
}

// from simon green and others
float ambientOcclusion(vec3 p, vec3 n)
{
    const int steps = 4;
    const float delta = 0.15;

    float a = 0.0;
    float weight = 4.;
    for(int i=1; i<=steps; i++) {
        float d = (float(i) / float(steps)) * delta; 
        a += weight*(d - map(p + n*d).w);
        weight *= 0.5;
    }
    return clamp(1.0 - a, 0.0, 1.0);
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv =          ( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void main(void) {
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    vec2 uv = p;
    
    p.x+=(mod(time,4.0)<0.5)?sin(floor(p.y*60.0)*time*30.)*0.05:0.0;
    
    float time = time*2.0;
    
    float handShakeY = fbm(vec3(time,time*1.1,time*1.2))*0.5;
    float handShakeX = fbm(vec3(time*1.1,time*1.2,time))*0.3;
    
    vec3 ro = vec3( handShakeX+0.5+3.5*cos(0.1*time + 6.0), handShakeY + 1.0, -0.5+5.5*sin(0.1*time + 6.0) );
    vec3 ta = vec3( 0.5, -0.4, -0.5 );
    mat3 ca = setCamera( ro, ta, 0.0 );
    vec3 rd = ca * normalize( vec3(p.xy,2.0) );
    
    float t, dist;
    float lastDistEval = 1e10;
    float edge = 0.0;
    t = 0.0;
    vec3 distPos = ro+rd;
    vec4 distCl = vec4(0.0);
    for(int i = 0; i < 64; i++){
        distCl = map(distPos);
        dist = distCl.w;
        t += dist;
        distPos = ro+rd*t;
        
        if (lastDistEval < EDGE_WIDTH && dist > lastDistEval + 0.001) {
            edge = 1.0;
        }
        if (dist < lastDistEval) lastDistEval = dist;
        if(dist < 0.01 || dist > 30.0) break;
    }

    vec3 color;
    float shadow = 1.0;
    if(dist < 1.0){
        // lighting
        vec3 lightDir = vec3(0.0, 1.0, 0.0);
        vec3 light = normalize(lightDir + vec3(0.5, 0.0, 0.9));
        vec3 normal = normalMap(distPos);

        // difuse color
        float diffuse = clamp(dot(light, normal), 0.5, 1.0);
        float lambert = max(.0, dot( normal, light));
        
        // ambient occlusion
        float ao = ambientOcclusion(distPos,normal);
        
        // shadow
        shadow = shadowMap(distPos + normal * 0.001, light);

        // result
        color += vec3(lambert);
        color = ao*diffuse*(distCl.xyz+(.1-length(p.xy)/3.))*vec3(1.0, 1.0, 1.0);
        
    }else{
        color =.84*max(mix(vec3(0.9,0.81,0.85)+(.1-length(p.xy)/3.),vec3(1),.1),0.);
    }

    // rendering result
    float brightness = 1.5;
    vec3 dst = (color * max(0.8, shadow))*brightness;
    
    // add edge detection result
    dst = mix(dst,vec3(0.1,0.1,0.1),edge);
    
    // UI
    vec3 uicol = vec3(0.0);
    vec3 barColor = vec3(0.7,0.2,0.2);
    
    float numBar = 20.0;
    float deg = 360.0/numBar;
    vec2 pos = vec2(0.0,0.0);
    for(float i = 0.0; i<numBar; i+=1.0) {
        float rotVal = radians(i*deg+time*10.0);
        mat2 m = rot(rotVal);
        float animateVal = sin(hash(i)*(i*deg)*time*0.1)*0.1;
        float bdist = 0.8;
        float x = pos.x+cos(rotVal)*(bdist+animateVal);
        float y = pos.y+sin(rotVal)*(bdist+animateVal);
        float bar = dBox2d((uv+vec2(y, x))*m, vec2(0.01,0.12+animateVal));
        uicol = mix( uicol, barColor, 1.0-smoothstep(0.01,0.02,bar) );
    }
    
    vec2 ruv = uv*rot(radians(time*60.0));
    float circleD = (ruv.y<-0.3)?length(ruv)-0.6:10.0;
    float circleD2 = (ruv.y>=0.3)?length(ruv)-0.6:10.0;
    
    uicol = mix( uicol, barColor, 1.0-smoothstep(0.01,0.015,abs(min(circleD,circleD2))) );
    glFragColor = vec4(dst+uicol, 1.0);
}
