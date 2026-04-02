#version 420

// original https://www.shadertoy.com/view/wdVyDR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// SylvainLC 2020 
//
// I measure the difference between an hobbyist (me) and a CG professional like Shadertoy's top contributors.
// But the more important is to learn and have fun isn't it ?
// So thanks to IQ, Bigwings, Shane, Fabrice and you all guys ! 
// You are so good at teaching modeling, colors, lighing, all these technics ... 
// many thanks for your great tutorials and demos !
//

// Special thanks for this one to tdhooper Iridescent crystals
// https://www.shadertoy.com/view/llcXWM

#define PHI (1.618033988749895)
#define PI acos(-1.)
#define TAU 6.283185
#define MAX_STEPS 100
#define MAX_DIST 10.
#define SURF_DIST .001
#define S smoothstep

// Nearest icosahedron vertex and id
float quadrant(float a, float b) {
    return ((sign(a) + sign(b) * 2.) + 3.) / 2.;
}
vec4 icosahedronVertex(vec3 p) {
    vec3 v1, v2, v3, result, plane;
    float id;
    float idMod = 0.;
    v1 = vec3(sign(p.x) * PHI,sign(p.y) * 1.,0);
    v2 = vec3(sign(p.x) * 1.,0,sign(p.z) * PHI);
    v3 = vec3(0,sign(p.y) * PHI,sign(p.z) * 1.);
    plane = normalize(cross(
        mix(v1, v2, .5),
        cross(v1, v2)
    ));
    if (dot(p, plane) > 0.) {
        result = v1;
        id = quadrant(p.y, p.x);
    } else {
        result = v2;
        id = quadrant(p.x, p.z) + 4.;
    }
    plane = normalize(cross(
        mix(v3, result, .5),
        cross(v3, result)
    ));
    if (dot(p, plane) > 0.) {
        result = v3;
        id = quadrant(p.z, p.y) + 8.;
    }
    return vec4(normalize(result), id);
}

// --------------------------------------------------------
// http://math.stackexchange.com/a/897677
// --------------------------------------------------------

mat3 orientMatrix(vec3 A, vec3 B) {
    mat3 Fi = mat3(
        A,
        (B - dot(A, B) * A) / length(B - dot(A, B) * A),
        cross(B, A)
    );
    mat3 G = mat3(
        dot(A, B),              -length(cross(A, B)),   0,
        length(cross(A, B)),    dot(A, B),              0,
        0,                      0,                      1
    );
    return Fi * G * inverse(Fi);
}

vec3 hsv2rgb( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    return c.z * mix( vec3(1.0), rgb, c.y);
}

mat2 Rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}

//-------------------------------------------------
// https://www.shadertoy.com/view/4lyfzw
vec2 opRevolution( in vec3 p, float w )
{
    return vec2( length(p.xz) - w, p.y );
}
float opExtrussion( in vec3 p, in float sdf, in float h )
{
    vec2 w = vec2( sdf, abs(p.z) - h );
      return min(max(w.x,w.y),0.0) + length(max(w,0.0));
}

// http://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float sdVesica(vec2 p, float r, float d)
{
    p = abs(p);

    float b = sqrt(r*r-d*d); // can delay this sqrt
    return ((p.y-b)*d > p.x*b) 
            ? length(p-vec2(0.0,b))
            : length(p-vec2(-d,0.0))-r;
}
float sdCircle(vec2 p, float r)
{
    return length(p)-r; 
}
float sdCylinder( vec3 p, vec3 c )
{
  return length(p.xz-c.xy)-c.z;
}

// AKA ModPolar !
vec3 opRepRoundabout(vec3 p,float radius,float sectors) {
    float angle = TAU/sectors;
    float sector = round(atan(p.z,p.x)/angle); // thanks to IQ video https://youtu.be/sl9x19EnKng?t=1745
    p.xz *= Rot(-angle*sector);
    p.x -= radius;
    return p;
}

// http://iquilezles.org/www/articles/smin/smin.htm
float smax( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return max(a, b) + h*h*0.25/k;
}

float sdRocket( vec3 pos)
{
    vec3 q=pos;
    float d = -0.03+abs(-0.1 + sdVesica(opRevolution(q,0.0), 1.4, 1.1 ));  // ABS for onioning
    // porthole
    // hole with cylinder
    d = max(d,-max(-q.z,sdCylinder(q.yzx, vec3(0.,0.,0.15))));
    // 3 sectors for engines
    q = opRepRoundabout(pos,0.,3.);
    d = min(d, -0.05 + sdVesica(opRevolution(vec3(q.x-.6,q.y+.8,q.z),0.0), 0.65, 0.5 )) ;
    // cut the bottom
    d = smax( d, -pos.y-1.1, 0.05 );
    // link between engines and rocket's body
    q += vec3(0.1,1.13,0.0);
    float lnd = sdCircle(q.xy, 1.00 );
        lnd = max(lnd,-sdCircle(q.xy+vec2(-0.3,0.3),0.6));
        lnd = max(lnd,-sdCircle(q.xy+vec2(0.8,-1.1),1.3));
        lnd = max(lnd,q.x-0.8);
        lnd = max(lnd,-q.y+0.2);
    d = min(d,opExtrussion (q,lnd,0.02)-0.01);
    return d;
}

float sdCone( vec3 p, vec2 c )
{
    // c is the sin/cos of the angle
    vec2 q = vec2( length(p.xz), p.y );
    float d = length(q-c*max(dot(q,c), 0.0));
    return d * ((q.x*c.y-q.y*c.x<0.0)?-1.0:1.0);
}

vec4 getRocketPath(float key) {
    float h=2.*S(1.,2.,key)*S(10.,9.,key);
    float r=S(1.2,3.,key)*S(9.8,8.,key);
    float a = 3.*TAU*S(1.2,9.5,key);
    return vec4(0.,h+r*sin(a),r*cos(a),a);    
}

vec3 animateRocket(vec3 p,float time) {
    time*=.3;
    vec3 q=p;
    float key = 20.*fract(time);
    float key2 =  20.*fract(time+.01);
    vec4 p1 = getRocketPath(key);
    q-=p1.xyz;
    q.y-=1.05;
    q.yz*=Rot(p1.w);
    return q;   
}

vec2 GetDist(vec3 p) {
    float time = time;
    p.xz *= Rot(time*.01*6.2831);        
    p.yz *= Rot(time*.005*6.2831);        
    time=time*.2;
    vec3 q=p;
    vec4 ico = icosahedronVertex(q);
    float id = ico.w;
    q*=orientMatrix(ico.xyz,vec3(0.,1.,0.));
    float rocket = sdRocket(3.*animateRocket(q,time+id))*.333;
    float earth = length(p)-.7;
    float c = -sdCone(q,vec2(sin(PI/6.),cos(PI/6.)));   // disance to domain bouding cone 
    float d=min(rocket,earth);    
    d=min(d,max(c,.5));  // this is trying to slow down the ray marcher when approaching the bound of the cone over the face of the dode
    return vec2(d,id);
}

vec2 RayMarch(vec3 ro, vec3 rd) {
    float dO=0.;    
    vec2 m;
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd*dO;
        m = GetDist(p);
        float dS = m.x;
        dO += dS;
        if(dO>MAX_DIST || abs(dS)<SURF_DIST) break;
    }    
    return vec2(dO,m.y);
}

vec3 GetNormal(vec3 p) {
    float d = GetDist(p).x;
    vec2 e = vec2(.001, 0);
    vec3 n = d - vec3(
        GetDist(p-e.xyy).x,
        GetDist(p-e.yxy).x,
        GetDist(p-e.yyx).x);
    return normalize(n);
}

vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i);
    return d;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 mo = mouse*resolution.xy.xy/resolution.xy;
    vec3 col = vec3(0);
    vec3 ro = vec3(0, 3, -3);
    ro.yz *= Rot(-mo.y*6.2831);
    ro.xz *= Rot(-mo.x*6.2831);
    vec3 rd = GetRayDir(uv, ro, vec3(0), 1.);
    vec2 m = RayMarch(ro, rd);
    float d=m.x;
    
    if(d<MAX_DIST) {
        vec3 p = ro + rd * d;
        vec3 n = GetNormal(p);
        vec3  sun_lig = normalize( vec3(0.2, 0.35, -0.5) );        
        float dif = clamp(dot( n, sun_lig ), 0.0, 1.0 )+.1;
        vec3  sun_hal = normalize( sun_lig-rd );
        float sun_spe = pow(clamp(dot(n,sun_hal),0.0,1.0),8.0)*dif*(0.04+0.96*pow(clamp(1.0+dot(sun_hal,rd),0.0,1.0),5.0));
        float sun_sha = step(-RayMarch(p+0.01*n, sun_lig).x,-MAX_DIST);
        col += 1.*sun_spe*vec3(8.10,6.00,4.20)*sun_sha;
        vec3 c = hsv2rgb(vec3(m.y/12.+fract(time*.05),0.8,.9)); // nice ?
        col += dif*c*(sun_sha*.9+.1);  
    } else { col = vec3(.1)*(.5-abs(uv.y));}
    col = pow(col, vec3(.4545));    // gamma correction
    glFragColor = vec4(col,1.0);
}
