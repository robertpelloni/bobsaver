#version 420

// original https://www.shadertoy.com/view/3ddSWn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define STEREO 1

#define PI 3.14159
#define STEPS 100.
#define EPS 0.00001
#define EPSN 0.001
#define EPSOUT 0.0015

mat2 rot(float a){
    float c = cos(a);
    float s = sin(a);
    return mat2(c, -s, s, c);
}

float smoothmin(float a, float b, float k){
    float f = clamp(0.5 + 0.5 * (a - b) / k, 0., 1.);
    return mix(a, b, f) - k * f * (1. - f);
}

vec2 repeat(vec2 pos, float t){
    t = 2. * PI / t;
    float angle = mod(atan(pos.y, pos.x) , t) - 0.5 * t;
    float r = length(pos);
    return r * vec2(cos(angle), sin(angle));
}

float distEllipsoid(vec3 p, vec3 r){
    float lg = length(p /(r * r));
    return (length(p / r) - 1.) * (length(p / r)) / lg;
}

float distRing(vec3 p, vec2 r){
  vec2 t = vec2(length(p.xz)-r.x,p.y);
  return length(t)-r.y;
}

float distBox(vec3 p, vec3 r){
  vec3 t = abs(p) - r;
  return length(max(t,0.0)) + min(max(t.x,max(t.y,t.z)),0.0);
}

float distScene(in vec3 pos, out int object){
     
    pos.yz = rot(0.2 + 0.25 * (0.5 + 0.5 * sin(0.25 * time - 0.5 * PI))) * pos.yz;
    pos.xz = rot(0.25 * time) * pos.xz;
    pos.y += 0.1 + 0.0125 * sin(time);
    
    pos.xy = rot(-0.4) * pos.xy;
    pos.xz = rot(0.6) * pos.xz;
    pos.yz = rot(0.4) * pos.yz;

    //gem
    vec3 p = pos;
    p.y -= 0.155;
    float dist = length(p) - 0.05;
    object = 1;
    
    //gold ?
    p = pos;        
    p.y -= 0.11;
    float distGold = distEllipsoid(p, vec3(0.03, 0.01, 0.03));
    distGold = smoothmin(distGold, max(max(length(p.xz) - 0.0175, p.y), -p.y - 0.25), 0.035);
    distGold = smoothmin(distGold, distEllipsoid(p - vec3(0., -0.25, 0.), vec3(0.01, 0.01, 0.01)), 0.035);
    distGold = min(distGold, distEllipsoid(p, vec3(0.04, 0.01, 0.04)));
    distGold = min(distGold, distEllipsoid(p - vec3(0., -0.05, 0.), vec3(0.0225, 0.01, 0.0225)));
    distGold = min(distGold, distEllipsoid(p - vec3(0., -0.25, 0.), vec3(0.025, 0.01, 0.025)));
    distGold = min(distGold, distEllipsoid(p - vec3(0., -0.175, 0.), vec3(0.0225, 0.01, 0.0225)));

    p.y -= 0.115;
    distGold = smoothmin(distGold, distRing(p.xzy, vec2(0.12, 0.0075)), 0.02);
    
    p.y -= 0.015;
    p.xy = rot(3. * PI/2.) * p.xy;
    p.xy = repeat(p.xy, 5.);
    distGold = smoothmin(distGold, max(max(length(p.yz), length(p) - 0.15), -(length(p) - 0.08)), 0.03);
    
    float distStar = distEllipsoid(p, vec3(0.02, 0.02, 0.015));
    p.x -= 0.03;
    distStar = smoothmin(distStar, length(p), 0.03);
    distGold = min(distGold, distStar);
    
    p = pos;
    p.y -= 0.15;
    distGold = smoothmin(distGold, distRing(p.xzy, vec2(0.055, 0.006)), 0.00015);
    p.y += 0.24;
    p.x -= 0.02;
    distGold = min(distGold, distBox(p, vec3(0.02, 0.0075, 0.005)));
    p.y += 0.029;
    distGold = min(distGold, distBox(p, vec3(0.02, 0.01, 0.005)));
    p.y -= 0.01;
    distGold = min(distGold, distBox(p, vec3(0.01, 0.02, 0.005)));
    
    dist = min(dist, distGold);
    
    if(dist == distGold){
        object = 3;
    }
    
    if(dist == distStar){
        object = 4;
    }
    
    //wings
    p = pos;
    p.y -= 0.05 + 0.008 * sin(1.5 * time);
    p.x = abs(p.x) - 0.05;
    float distWing = length(p) - 0.015;
    vec3 pBranch = p;
    pBranch -= vec3(0.055, 0.04, 0.);
    float rt = 10. * pBranch.x;
    pBranch.xy = rot(rt * rt) * pBranch.xy;
    distWing = smoothmin(distWing, distEllipsoid(pBranch, vec3(0.08, 0.015, 0.02)), 0.01);
    pBranch = p;
    pBranch.xy = rot(-0.25) * pBranch.xy;
    pBranch -= vec3(0.052, 0.035, 0.);
    rt = 8. * pBranch.x;
    pBranch.xy = rot(rt * rt) * pBranch.xy;
    distWing = smoothmin(distWing, distEllipsoid(pBranch, vec3(0.07, 0.015, 0.0175)), 0.005);
    pBranch = p;
    pBranch.xy = rot(-0.5) * pBranch.xy;
    pBranch -= vec3(0.04, 0.025, 0.);
    rt = 8. * pBranch.x;
    pBranch.xy = rot(rt * rt) * pBranch.xy;
    distWing = smoothmin(distWing, distEllipsoid(pBranch, vec3(0.05, 0.0125, 0.015)), 0.0075);
        
    dist = min(dist, distWing);
    if(dist == distWing){
        object = 2;
    }
    return 0.5 * dist;

}

vec3 getNormal(vec3 p){
    int o;
    return normalize(vec3(distScene(p + vec3(EPSN, 0., 0.), o) - distScene(p - vec3(EPSN, 0., 0.), o),
                          distScene(p + vec3(0., EPSN, 0.), o) - distScene(p - vec3(0., EPSN, 0.), o),
                          distScene(p + vec3(0., 0., EPSN), o) - distScene(p - vec3(0., 0., EPSN), o)));
}

vec3 render(vec2 uv, float eyeOffset){
    
    //background
    vec3 bgColor = vec3(0.);
    vec3 inkColor = bgColor;
    vec2 uvbg = 5. * uv - vec2(0.25 * eyeOffset, 0.);
    float time = 0.05 * time;
    float angle = atan(uvbg.y, uvbg.x) + 2.0 * sin(PI * time);
    float radius = length(uvbg);      
    float k = 10. / 7.;
    float offset = 0.1 + sin(2.6 * sin(1.9 * sin(PI * time)));
        
    float res = 10000.0;    
    for(float i = 0.0; i < 7.; i++){
        angle += 2.0 * PI;
        res = min(res, abs(radius - (1. / (cos(k * angle) + offset))));
    }    
      res = min(res, abs(radius - offset - 0.8));
    res = min(res, abs(radius - offset - 1.));
    
    float bg = smoothstep(0., 0.01, res);
    vec3 col = mix(vec3(0.1, 0.1, 0.1), bgColor,  bg);
    
    //raymarch
    vec3 eye = vec3(eyeOffset, 0., 2.);
    vec3 up = vec3(0., 1., 0.);
    vec3 forward = normalize(-eye);
    vec3 ray = normalize(1.5 * forward + normalize(cross(forward, up)) * uv.x + up * uv.y);
    int o;
    float dist, step, c, prevDist;
    bool hit = false;
    vec3 pos = eye;
    dist = distScene(pos, o);
    float outline = 1.;
    
    for(step = 0.; step < STEPS; step++){
        prevDist = dist;
        dist = distScene(pos, o);
        if(dist > prevDist + EPS && dist < EPSOUT ){
            outline = min(outline, dist);
        }
        if(abs(dist) < EPS){
            hit = true;
            break;
        }
        if(length(pos) > 3.) break;
        pos += dist * ray;
    }
    outline /= EPSOUT;
    
    vec3 normal = getNormal(pos);
    
    //shading
    if(hit){
        vec3 light = vec3(10., 5., 12.);
        light.yz = rot(0.5) * light.yz;
        float shine = 30.;
        
        if(o == 1){
            col = vec3(0.65, 0.4, 0.9);
        }
        if(o == 2){
            col = mix(vec3(0.75, 0.75, 0.75), vec3(1.), 0.8 * c);
            shine = 5.;
        }
        if(o == 3){
            col = vec3(0.95, 0.85, 0.4);
            shine = 20.;
        }
        if(o == 4){
            col = vec3(0.75, 0.75, 0.75);
        }
        
        //diffuse
        vec3 l = normalize(light - pos);
        if(o == 1){
            float diff = dot(-normal, l);
            if(o != 0) col = mix(col, vec3(0., 0., 0.15), 0.45 * (1. - diff));
        }else{
            float diff = dot(normal, l);
            diff = smoothstep(0.3, 0.35, diff);
            if(o != 0) col = mix(col, vec3(0., 0., 0.5), 0.3 * (1. - diff));
        }
        
        //specular
        vec3 refl = reflect(-l, normal);
        float spec = pow(dot(normalize(eye - pos), refl), shine);
        spec = smoothstep(0.5, 0.55, spec);
        col += 0.02 * shine * spec;
        
        //outline
        outline = smoothstep(0.75, 0.95, outline);
        col = mix(inkColor, col, outline);
    }  
    return col;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.x;
    uv *= 0.8;
#if STEREO
    //using the Dubois anaglyph method for the colors
    vec3 colorLeft = render(uv, -0.05);
    mat3 transfoLeft = mat3(vec3(0.42, -0.05, -0.05),
                            vec3(0.47, -0.05, -0.06),
                               vec3(0.17, -0.03, 0.01));
    vec3 colorRight = render(uv, 0.05);
    mat3 transfoRight = mat3(vec3(-0.01, 0.38, -0.07),
                            vec3(-0.04, 0.73, -0.13),
                               vec3(-0.01, 0.01, 1.30));
    glFragColor = vec4(pow(transfoLeft * colorLeft + transfoRight * colorRight, vec3(1. / 2.2)),1.0);
#else
    glFragColor = vec4(pow(render(uv, 0.), vec3(1./2.2)), 1.);
#endif
}
