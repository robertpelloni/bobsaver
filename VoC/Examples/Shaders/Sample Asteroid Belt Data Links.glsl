#version 420

// original https://www.shadertoy.com/view/WdjBDz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//this is mostly a remix of https://www.shadertoy.com/view/tsjfRw but
//extending to the 4th dimension so we can do 4d rotations and get neat slices

//returns a vector pointing in the direction of the closest neighbouring cell
vec3 quadrant(vec3 p) {
    vec3 ap = abs(p);
    if (ap.x >= max(ap.y, ap.z)) return vec3(sign(p.x),0.,0.);
    if (ap.y >= max(ap.x, ap.z)) return vec3(0.,sign(p.y),0.);
    if (ap.z >= max(ap.x, ap.y)) return vec3(0.,0.,sign(p.z));
    return vec3(0);
}

float hash(float a, float b) {
    return fract(sin(a*1.2664745 + b*.9560333 + 3.) * 14958.5453);
}

bool domain_enabled(vec3 id) {
    //repeat random number along z axis so every active cell has at least one active neighbour
    id.z = floor(id.z/2.); 
    return hash(id.x, hash(id.y, id.z)) < .5;
}

float linedist(vec3 p, vec3 a, vec3 b) {
    float k = dot(p-a,b-a)/dot(b-a,b-a);
    return distance(p, mix(a,b,clamp(k,0.,1.)));
}

float linedist(vec4 p, vec4 a, vec4 b) {
    float k = dot(p-a,b-a)/dot(b-a,b-a);
    return distance(p, mix(a,b,clamp(k,0.,1.)));
}

vec4 wrot(vec4 p) {
    return vec4(dot(p,vec4(1)), p.yzw + p.wyz - p.zwy - p.xxx)/2.;
}

float box(vec4 p, vec4 d) {
    vec4 q = abs(p)-d;
    return length(max(q,0.))+min(0.,max(max(q.x,q.w),max(q.y,q.z)));
}

vec4 smin(vec4 a, vec4 b, float k) {
    vec4 h = max(vec4(0),-abs(a-b)+k)/k;
    return min(a,b)-h*h*h*k/6.;
}

vec3 erot(vec3 p, vec3 ax, float ro) {
    return mix(dot(p,ax)*ax, p, cos(ro)) + sin(ro)*cross(ax,p);
}

float weird_obj(vec4 p) {
    p.xyz = erot(p.xyz, normalize(sin(p.xyz)), time/4.);
    p = wrot(p);
    p = sqrt(p*p+0.001);
    p = wrot(p);
    p.w+=.5;
    p = sqrt(p*p+0.001);
    p = wrot(p);
    //p = smin(p,wrot(p),0.01);
    return box(p, vec4(1.2))-.2;
}

float ball;
float pipe;
float scene(vec3 p) {
    p.x+=sin(p.z/5.); p.y+=cos(p.z/5.);
    p.y+=sin(p.x/7.); p.z+=cos(p.x/7.);
    float w = sin(p.x/8.+time)*sin(p.y/8.+time)*sin(p.z/8.+time)*3.;
    vec4 p4 = vec4(p,w);
    p4 = mix(p4, wrot(p4), .2);
    float scale = 8.;
    vec3 id = floor(p.xyz/scale);
    p4.xyz = (fract(p.xyz/scale)-.5)*scale;
    if (!domain_enabled(id)) {
        //return distance to sphere in adjacent domain
        p4 = abs(p4);
        if (p4.x > p4.y) p4.xy = p4.yx;
        if (p4.y > p4.z) p4.yz = p4.zy;
        if (p4.x > p4.y) p4.xy = p4.yx;
        p4.z -= scale;
        pipe = length(p4)-.2;
        return weird_obj(p4);
    }
    float dist = weird_obj(p4);
    ball = dist;
    vec3 quad = quadrant(p4.xyz);
    if (domain_enabled(id+quad)) {
        //add pipe
        pipe = linedist(p4, vec4(0), vec4(quad,0.)*scale)-.2;
        dist = min(dist, pipe);
    } else {
        pipe = length(p4)-.2;
    }
    return dist;
}

vec3 norm(vec3 p) {
    mat3 k = mat3(p,p,p) - mat3(0.01);
    return normalize(scene(p)-vec3(scene(k[0]),scene(k[1]),scene(k[2])));
}

float stars(vec3 dir) {
    dir = erot(dir,normalize(vec3(1)),.2);
    float str = length(sin(dir*vec3(120,120,210)));
    dir = erot(dir,normalize(vec3(1,2,3)),.4);
    str += length(sin(dir*vec3(320,230,140)));
    dir = erot(dir,normalize(vec3(2,3,1)),.3);
    str += length(sin(dir*vec3(230,280,138)));
    return smoothstep(2.,1.5,str);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;

    vec3 cam  = normalize(vec3(1,uv));
    float time = (floor(time/3.)+pow(sin(fract(time/3.)*3.14/2.),20.))*5. + time*2.; //accelerates every 3 seconds
    cam = erot(cam, vec3(1,0,0), time/20.);
    cam = erot(cam, vec3(0,0,1), .4+cos(time/8.)*.1);
    vec3 init = vec3(time*2.-50.,-time,time)+cam;
    vec3 p = init;
    bool hit = false;
    float dist;
    float glow = 1000.;
    float glowdist = 0.;
    //raymarching
    for (int i = 0; i < 150; i++) {
        dist = scene(p);
        if (pipe < glow) {
            glow = pipe;
            glowdist = distance(p,init);
        }
        hit = dist*dist < 1e-6;
        p += cam*dist;
        if (distance(p,init) > 250.) break;
    }
    //shading
    glow = smoothstep(0.5, 0.,glow);
    float fog = pow(smoothstep(250.,50.,distance(p,init)),2.);
    vec3 n = norm(p);
    vec3 r = reflect(cam, n);
    float diff = max(0., dot(n, normalize(vec3(1,-1,1))))  + length(sin(n*vec3(3,2,1))*.5+.5)/sqrt(3.)*.1;
    float spec = max(0., dot(r, normalize(vec3(1,-1,1))))  + length(sin(r*vec3(3,2,1))*.5+.5)/sqrt(3.)*.1;
    float fresnel = 1.-abs(dot(n,r))*.98;
    vec3 matcol = vec3(0.3,.2,.2);
    vec3 col = matcol*matcol*diff*diff + pow(spec,2.)*fresnel + .005;
    vec3 glowcol = glow*.5 + abs(erot(vec3(.7,.4,.2), vec3(0,0,1), glowdist*.1))*glow;
    float glowfog = pow(smoothstep(250.,50.,glowdist),2.);
    vec3 bg = vec3(stars(cam));
    glFragColor.xyz = sqrt(hit ? mix(bg, col, fog) : bg) + glowfog*glowcol;
}
