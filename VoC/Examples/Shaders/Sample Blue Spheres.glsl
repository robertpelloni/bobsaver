#version 420

// original https://www.shadertoy.com/view/3lyGWV

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ZERO (min(frames,0))
#define PI 3.1415926535898
#define FAR 12.
#define bg_color vec3(0.02,0.15,0.5)
#define bg_color2 vec3(0.2,0.35,0.5)

float camYaw;
vec3 camPos;
vec2 global_uv;

// http://iquilezles.org/www/articles/checkerfiltering/checkerfiltering.htm
float checkersGradBox( in vec2 p )
{
    vec2 w = fwidth(p) + 0.001;
    vec2 i = 2.0*(abs(fract((p-0.5*w)*0.5)-0.5)-abs(fract((p+0.5*w)*0.5)-0.5))/w;
    return 0.5 - 0.5*i.x*i.y;
}

vec3 get_background( vec3 pos )
{
    return mix( bg_color2, bg_color, global_uv.y * 2. + 0.5 );
}

float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

vec3 distortPos(in vec3 pos)
{
    vec3 p = pos;
    float xx = (p - camPos).x;
    float zz = (p - camPos).z;
    float xxx = -(cos(camYaw)*zz-sin(camYaw)*xx);
    float zzz = -(cos(camYaw)*xx+sin(camYaw)*zz);
    float cx = cos(xxx * 0.3 ) * 1.1;
    if (cx < 0.0) cx *= 2.0;
    float cz = cos((zzz + 3.0)* 0.3 ) * 1.1;
    if (cz < 0.0) cz *= 1.5;
    p.y -= cx + cz;
    return p;
}

vec2 map(vec3 pos)
{
    vec3 p = distortPos(pos);
    vec2 res;

    res.x = FAR; // distance
    res.y = 0.0; // material id

    // floor plane
    if(p.y > 0.0) res = vec2(min(FAR, p.y), 1.);

    vec3 sPos;
    // blue spheres
    sPos.x = mod(p.x - 0.5, 2.0) -0.5;
    sPos.y = p.y - 0.15;
    sPos.z = mod(p.z - 0.5, 4.0) - 0.5;
    float d2 = sdSphere(sPos, 0.15);
    if (d2 < res.x) res = vec2(d2, 3.0);

    // red spheres
    sPos.x = mod(p.x - 1.5, 4.0) -0.5;
    sPos.z = mod(p.z - 1.5, 1.0) - 0.5;
    float d3 = sdSphere(sPos, 0.15);
    if (d3 < res.x) res =vec2(d3, 4.0);

    // white spheres
    sPos.x = mod(p.x - 0.5, 2.0) -0.5;
    sPos.z = mod(p.z - 1.5, 2.0) - 0.5;
    float d4 = sdSphere(sPos, 0.15);
    if (d4 < res.x) res = vec2(d4, 5.0);

    return res;
}

vec3 get_normal(vec3 p) {
    const vec2 e = vec2(0.0001, 0);
    return normalize(vec3(map(p + e.xyy).x-map(p - e.xyy).x,
                          map(p + e.yxy).x-map(p - e.yxy).x,
                          map(p + e.yyx).x-map(p - e.yyx).x));
}

float get_ao(vec3 p, vec3 n)
{
    float r = 0.0, w = 1.0, d;
    for(float i=1.0; i<5.0+1.1; i++)
    {
        d = i/5.0;
        r += w*(d - map(p + n*d).x);
        w *= 0.5;
    }
    return 1.0-clamp(r,0.0,1.0);
}

vec2 intersect(vec3 ro, vec3 rd)
{
    float t = 0.0, dt;
    vec2 r;
    for(int i=0; i<128; i++){
        r = map(ro + rd * t);
        dt = r.x;
        if(dt<0.002 || t>FAR){ break; }
        t += dt * 0.8;
    }
    return vec2(t,r.y);
}

// http://iquilezles.org/www/articles/rmshadows/rmshadows.htm
float calcSoftshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax )
{
    float res = 1.0;
    float t = mint;
    for( int i=ZERO; i<16; i++ )
    {
        float h = map( ro + rd*t ).x;
        res = min( res, 8.0*h/t );
        t += clamp( h, 0.02, 0.10 );
        if( res<0.005 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

vec3 star2d(in vec3 pos)
{
    // adapted from: http://pryme8.com/tag/glsl/
    vec3 c = vec3(1.5,1.5,1.5);
    vec2 offsetFix = vec2(1.,0.83);
    float ss, tt, angle, r, a;
    float starAngle = 2.*PI/5.;
    vec3 p0 = 0.14*vec3(cos(0.),sin(0.), 0.);
    vec3 p1 = 0.06*vec3(cos(starAngle/2.),sin(starAngle/2.), 0.);
    vec3 d0 = p1 - p0;
    vec3 d1;
    vec3 p = distortPos(pos);
    ss = mod(p.x,2.0) - offsetFix.x;
    tt = (1. - mod(p.y,2.0)) - offsetFix.y;
    angle = atan(ss, tt) + PI;
    r = sqrt(ss*ss + tt*tt);
    a = mod(angle, starAngle)/starAngle;
    if (a >= 0.5){a = 1.0 - a;}
    d1 = r*vec3(cos(a), sin(a), 0.) - p0;
    float in_out = smoothstep(0., 0.001, cross(d0 , d1).z);
    return mix(vec3(1.5), vec3(1.,0.,0.0), in_out); ;
}

vec3 lighting(vec3 rd, vec3 ro, vec3 pos, vec3 n, float matid)
{
    if ( matid < 1.0 ){
        return get_background( pos );
    }

    float z = length(pos - ro);

    vec3 mate = vec3(1.0);

    float spe_factor = 3.0;
    float fog_factor = 0.005;
    float black_rim_factor = 1.0;

    if (matid < 1.9)
    {
        mate = vec3(1.0,0.5,0.1) * (vec3(0.4) + vec3(checkersGradBox( vec2(pos.x, pos.z) ) ));
        spe_factor = 0.05;
        fog_factor = 0.002;
        black_rim_factor = 0.0;
    }
    else if (matid < 3.9)
    {
        // blue spheres
        mate = vec3(0.05,0.3,0.9);
    }
    else if (matid < 4.9){
        // red spheres
        mate = vec3(1.0,0.05,0.0);
    }
    else if (matid < 5.9)
    {
        // white spheres
        mate = star2d(pos);
    }

    vec3 lp0 = camPos +  vec3(0.0, 1.0, -1.0);
    vec3 ld0 = normalize(lp0 - pos);
    float dif = max(0.0, dot(n, ld0));
    vec3 lin = vec3(1.0);
    float spe = max(0.0, pow(clamp(dot(ld0, reflect(rd, n)), 0.0, 1.0), 20.0));
    float ao = get_ao(pos, n);
    lin = 10.0 * vec3(1.0) * spe * spe_factor;
    lin += (1.0 + dif) * ao;
    lin = lin * 0.22 * mate;
    vec3  lig = normalize( vec3(0.0, 1.0, 0.0) );
    lin *= vec3(0.5) + calcSoftshadow( pos, lig,  0.05, 1.0 );
    // extra black rim to mimic original game spheres shade
    float black_rim = max(dot(n,-rd),0.);
    black_rim += max(dot(n,vec3(0.,1.,0.)),0.);
    black_rim *= black_rim;
    black_rim = smoothstep(0.,0.6,black_rim);
    lin = mix( lin, lin * (0.25+0.75*black_rim), black_rim_factor);
    // fog
    lin = mix( lin, get_background(pos), 1.-exp(-fog_factor*z*z));

    return lin;
}

vec3 shade(vec3 ro, vec3 rd)
{
    vec3 col = get_background(camPos);
    vec2 res = intersect(ro, rd);
    if(res.x < FAR)
    {
        vec3 pos = ro + rd * res.x;
        vec3 n = get_normal(pos);
        col = lighting(rd,ro, pos, n, res.y);
    }
    return col;
}

void updateCamera(out vec3 rayOrigin, out vec3 rayDirection )
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy * 0.5)/ resolution.xy;
    uv.x *= resolution.x / resolution.y;
    global_uv = uv;
    float velocity = 1.25;

    float t = time;

    float xpos = 0.0;
    xpos = sin(t * 0.5)*cos(t * 0.25) * 4.0;

    float phase = t * 0.1;
    vec3 ro = vec3(xpos, 3.25+0.75*cos(phase)*cos(phase), -t * velocity);
    vec3 ta = ro + vec3( sin(phase), 0.85 - 0.25*sin(phase)*sin(phase) , cos(phase)*cos(phase));

    float FOV = 1.0;
    vec3 fwd = normalize(ro - ta);
    vec3 rgt = normalize(vec3(fwd.z, 0., -fwd.x ));
    vec3 up = cross(fwd, rgt);
    vec3 rd = fwd + FOV*(uv.x*rgt + uv.y*up);
    camYaw = atan( fwd.z, fwd.x );
    rd = normalize(rd);

    rayOrigin = ro;
    rayDirection = normalize(rd);

    camPos = ro;
}

void main(void)
{
    vec3 ro, rd;
    updateCamera(ro, rd );
    vec3 col = shade(ro, rd);
    col=pow(clamp(col,0.0,1.0),vec3(0.45));
    col=mix(col, vec3(dot(col, vec3(0.33))), -0.5);
    glFragColor = vec4(col, 1.0);
}
