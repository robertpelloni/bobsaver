#version 420

// original https://www.shadertoy.com/view/llsyDM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define getNormal getNormalCube

#define FAR 330.
#define INFINITY 1e32
#define t time
#define mt iChannelTime[1]
#define FOV 80.0
#define FOG .06

#define PI 3.14159265
#define TAU (2*PI)
#define PHI (1.618033988749895)

float vol = 0.;
bool inball = false;
float iter = 0.;

// Repeat in three dimensions
vec3 pMod3(inout vec3 p, vec3 size) {
    vec3 c = floor((p + size*0.5)/size);
    p = mod(p + size*0.5, size) - size*0.5;
    return c;
}

float noiseShort(vec3 p)
{
    vec3 ip=floor(p);
    p-=ip; 
    vec3 s=vec3(7,157,113);
    vec4 h=vec4(0.,s.yz,s.y+s.z)+dot(ip,s);
    p=p*p*(3.-2.*p); 
    h=mix(fract(sin(h)*43758.5),fract(sin(h+s.x)*43758.5),p.x);
    h.xy=mix(h.xz,h.yw,p.y);
    return mix(h.x,h.y,p.z); 
}
vec3 fromRGB(int r, int g, int b) {
     return vec3(float(r), float(g), float(b)) / 255.;   
}
    
vec3 
    light = vec3(0.0),
    p = vec3(0.),
    p2 = vec3(0.),
    lightDir = vec3(0.);

vec3 lightColour = normalize(vec3(1.8, 1.0, 0.3)); 

void pR(inout vec2 p, float a) {
    p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

vec3 opU2( vec3 d1, vec3 d2 ) {
    if (d1.x < d2.x) return d1;
    return d2;
}

struct geometry {
    float dist;
    vec3 space;
    vec2 material;
    int iterations;
    float glow;
};

float fSphere(vec3 p, float r) {
    return length(p) - r;
}

vec3 DE(vec3 p)
{
     const float scale = 1.45;
    const float offset = 2.0;
    const int FRACTALITERATIONS = 15;
    vec3 modifier = vec3(-12.3 , -4.1, -4.1);
    p.y = -p.y;
    for(int n=0; n< FRACTALITERATIONS; n++)
    {
        
        
        p.xy = (p.x + p.y <= 0.0) ? -p.yx : p.xy;
        p.xz = (p.x + p.z <= 0.0) ? -p.zx : p.xz;
        p.zy = (p.z + p.y <= 0.0) ? -p.yz : p.zy;

        p.y -= 4.1;
        pR(p.xz, 0.82915);
        
        p.yz = -p.zy * vec2(1., -1.);
        p.x -= 25.;
        pR(p.zx, -.16915);

        p = scale*p-offset*(scale-1.0) * modifier;
    }
     vec3 obj;
    obj.x = length(p) * pow(scale, -float(FRACTALITERATIONS)); 

    return obj;
}

vec3 map(vec3 p) {
    
    vec3 bp = p;
   // p += 15.;
    vec3 r = pMod3(p, vec3(100.));
    p += noiseShort(r) * 20.;
    vec3 obj, obj2;
    obj2.x = FAR;
    obj.x = FAR;
    obj.y = 2.;

    if (inball) {
        obj.x = min(obj.x, DE(p).x);
        obj2.y = 3.;
        obj = opU2(obj, obj2);
    } else {
        obj.x = min(obj.x, fSphere(p, noiseShort(p * .05 + t) * 2. + 30. * sin(length(r)))); 

    }

    return obj;
}

vec3 trace(vec3 ro, vec3 rd) {
    vec3 tr = vec3(.5, -1., 0.0);
    for (int i = 0; i < 126; i++) {
        vec3 d = map(ro + rd * tr.x);
        tr.x += d.x * 0.4; // Using more accuracy, in the first pass.
        tr.yz = d.yz;
        if (abs(d.x) < 0.02 || tr.x > FAR) break;
        iter += 1.;
    }
    return tr;
}

float softShadow(vec3 ro, vec3 lp, float k) {
    const int maxIterationsShad = 8;
    vec3 rd = (lp - ro); // Unnormalized direction ray.

    float shade = 1.;
    float dist = 4.5;
    float end = max(length(rd), 0.01);
    float stepDist = end / float(maxIterationsShad);

    rd /= end;
    for (int i = 0; i < maxIterationsShad; i++) {
        float h = map(ro + rd * dist).x;
        //shade = min(shade, k*h/dist);
        shade = min(shade, smoothstep(0.0, 1.0, k * h / dist)); 
        dist += min(h, stepDist * 2.); 
        if (h < 0.001 || dist > end) break;
    }
    return min(max(shade, 0.2), 1.0);
}

#define EPSILON .001
vec3 getNormalHex(vec3 pos)
{
    float d=map(pos).x;
    return normalize(
        vec3(
            map(
                pos+vec3(EPSILON,0,0)).x-d,
                map(pos+vec3(0,EPSILON,0)).x-d,
                map(pos+vec3(0,0,EPSILON)).x-d 
            )
        );
}

#define delta vec3(.001, 0., 0.)
vec3 getNormalCube(vec3 pos)   
{    
   vec3 n;  
   n.x = map( pos + delta.xyy ).x - map( pos - delta.xyy ).x;
   n.y = map( pos + delta.yxy ).x - map( pos - delta.yxy ).x;
   n.z = map( pos + delta.yyx ).x - map( pos - delta.yyx ).x;
   
   return normalize(n);
}

float getAO(vec3 hitp, vec3 normal, float dist)
{
    vec3 spos = hitp + normal * dist;
    float sdist = map(spos).x;
    return clamp(sdist / dist, 0.0, 1.0);
}

vec3 Sky(in vec3 rd, bool showSun, vec3 lightDir)
{
   
   float sunSize = 3.5;
   float sunAmount = max(dot(rd, lightDir), 0.4);
   float v = pow(1. - max(rd.y, 0.0), .1);
   vec3 sky = mix(fromRGB(0,136,254), vec3(.1, .2, .3) * .1, v);
   if (showSun == false) sunSize = .1;
   sky += lightColour * sunAmount * sunAmount * 1. + lightColour * min(pow(sunAmount, 122.0)* sunSize, 0.2 * sunSize);
   
   return clamp(sky / noiseShort(rd * 3.), 0.0, 1.0);
}

vec3 getObjectColor(vec3 p, vec3 n, geometry obj) {
    vec3 col = vec3(.0);
    
    if (obj.material.x == 0.0) { 
        col = vec3(1., .6, .5);       
    };
    
    if (obj.material.x == 1.0) { col = fromRGB(255,128,0); }
    if (obj.material.x == 2.0) { 
        col = fromRGB(255,128,50);     
    }
    
    if (obj.material.x == 4.0) { 
        col = vec3(1., .6, .5); 
    };
    return col;

}

vec3 doColor( in vec3 sp, in vec3 rd, in vec3 sn, in vec3 lp, geometry obj) {
    vec3 sceneCol = vec3(0.0);
    lp = sp + lp;
    vec3 ld = lp - sp; // Light direction vector.
    float lDist = max(length(ld / 2.), 0.001); // Light to surface distance.
    ld /= lDist; // Normalizing the light vector.

    // Attenuating the light, based on distance.
    float atten = 1. / (1.0 + lDist * 0.025 + lDist * lDist * 0.2);

    // Standard diffuse term.
    float diff = max(dot(sn, ld), 7.);
    // Standard specualr term.
    float spec = pow(max(dot(reflect(-ld, sn), -rd), 1.), 1.);

    // Coloring the object. You could set it to a single color, to
    // make things simpler, if you wanted.
    vec3 objCol = getObjectColor(sp, sn, obj);

    // Combining the above terms to produce the final scene color.
    sceneCol += (objCol * (diff + .15) * spec * .1);// * atten;

    // Return the color. Done once every pass... of which there are
    // only two, in this particular instance.
    
    return sceneCol;
}

void main(void) {
    
    vec2 ouv = gl_FragCoord.xy / resolution.xy;
    vec2 uv = ouv - .5;
    
    uv *= tan(radians (FOV) / 2.0) * 1.1;

    float t2 = t - 35.;
    float 
        sk = sin(-t2 * .04) * 26.0, 
        ck = cos(-t2 * .07) * 32.0 - sk,
        
        mat = 0.;
    
    light = vec3(0., 17., 100.);        
    lightDir = light;
        
    vec3 
        vuv = vec3(sin(t / 10.), 1., sin(t / 10.)), // up
        ro = vec3(-2., ck, sk);// + vec3(mouse*resolution.xy.x / 20.,mouse*resolution.xy.y / 10. - 1., 10.); // pos
    ro -= 120.;
    vec3
        vrp =  vec3(sin(t / 30.) * 12., + sin(t * 2.) / 5., 10.) +
            vec3(
                -2., 
                0. + sin(t) / 3., 
                0. + sin(t / 3.) / 4.), // lookat    */
        
        vpn = normalize(vrp - ro),
        u = normalize(cross(vuv, vpn)),
        v = cross(vpn, u),
        vcv = (ro + vpn),
        scrCoord = (vcv + uv.x * u * resolution.x/resolution.y + uv.y * v),
        rd = normalize(scrCoord - ro),
        hit;        
    
    vec3 sceneColor = vec3(0.);

    vec3 tr = trace(ro, rd);    
    
    float fog = smoothstep(FAR * FOG, 0., tr.x);
    hit = ro + rd * tr.x;
    vec3 otr = tr;
    vec3 sn = getNormal(hit);    
    
    float sh = softShadow(hit, hit + light, 3.);
    
    float 
        ao = getAO(hit, sn, 15.2);

    vec3 sky = Sky(rd, true, normalize(light)) * 1.;
    vec3 skyNoSun = Sky(rd, false, normalize(light)) * 1.;
        
    if (tr.x < FAR) { 
        sceneColor += 0.2;
        inball = true;
        vec3 bcol = vec3(0.);
        if (tr.x > 0.) {
            rd = refract(rd, sn, 1. - min(1., tr.x / 100.));
            bcol = vec3(1., .9, 1.0) * pow(noiseShort(sn * 1.) * 1.3, 7.) * .3;
            bcol += pow(max(0., dot(rd, normalize(light))), 13.);
            tr = trace(hit, rd);
        } else {
            tr = trace(ro, rd);
        }
        
        if (tr.x < FAR) {
            hit = hit + rd * (tr.x);
            sceneColor += 9. / pow(tr.x, 1.1);
            sceneColor = mix(sceneColor, sky, clamp(tr.x / 30., 0., 1.));
        } else {
            sceneColor += sky;
        }
        sceneColor += bcol;

    } else {
        sceneColor = sky;

    }
    sceneColor += pow(sin(float(iter) / 500.), 1.9) ;
    sceneColor = mix(sceneColor, sky, clamp(otr.x / 400., 0., 1.));
    glFragColor = vec4(clamp(sceneColor * (1. - length(uv) / 2.5), 0.0, 1.0), 1.0);
    
}
