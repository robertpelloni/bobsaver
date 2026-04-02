#version 420

// original https://www.shadertoy.com/view/3tcfW4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R resolution.xy
#define MaxSteps 50.
#define MinDistance 0.001
#define eps 0.001

// more ideas for different Mandelboxes:
// http://archive.bridgesmathart.org/2018/bridges2018-547.pdf

float distFromOrigin = 0.0;
float lissoujasSize = 3.5;

vec3 magma(float t) { // from Mattz
    t *= 2.0;
    if(t > 1.0) { t = 2.0-t; }
    const vec3 c0 = vec3(-0.002136485053939582, -0.000749655052795221, -0.005386127855323933);
    const vec3 c1 = vec3(0.2516605407371642, 0.6775232436837668, 2.494026599312351);
    const vec3 c2 = vec3(8.353717279216625, -3.577719514958484, 0.3144679030132573);
    const vec3 c3 = vec3(-27.66873308576866, 14.26473078096533, -13.64921318813922);
    const vec3 c4 = vec3(52.17613981234068, -27.94360607168351, 12.94416944238394);
    const vec3 c5 = vec3(-50.76852536473588, 29.04658282127291, 4.23415299384598);
    const vec3 c6 = vec3(18.65570506591883, -11.48977351997711, -5.601961508734096);
    return c0+t*(c1+t*(c2+t*(c3+t*(c4+t*(c5+t*c6)))));
}

vec3 viridis_quintic( float x )
{
    x *= 2.0;
    if(x > 1.0) { x = 2.0-x; }
    //x = saturate( x );
    vec4 x1 = vec4( 1.0, x, x * x, x * x * x ); // 1 x x2 x3
    vec4 x2 = x1 * x1.w * x; // x4 x5 x6 x7
    return vec3(
        dot( x1.xyzw, vec4( +0.280268003, -0.143510503, +2.225793877, -14.815088879 ) ) + dot( x2.xy, vec2( +25.212752309, -11.772589584 ) ),
        dot( x1.xyzw, vec4( -0.002117546, +1.617109353, -1.909305070, +2.701152864 ) ) + dot( x2.xy, vec2( -1.685288385, +0.178738871 ) ),
        dot( x1.xyzw, vec4( +0.300805501, +2.614650302, -12.019139090, +28.933559110 ) ) + dot( x2.xy, vec2( -33.491294770, +13.762053843 ) ) );
}

mat3 rotateX(float angle) {
    float c = cos(angle), s = sin(angle);
    return mat3(1, 0, 0, 0, c, -s, 0, s, c);
}

mat3 rotateY(float angle) {
    float c = cos(angle), s = sin(angle);
    return mat3(c, 0, -s, 0, 1, 0, s, 0, c);
}

mat3 rotateZ(float angle) {
    float c = cos(angle), s = sin(angle);
    return mat3(c,-s,0,s,c,0,0,0,1);
}

float sdSphere(vec3 p, float r) {
    return length(p) - r;    
}

// from iq
float sdPlane(in vec3 p, in vec4 n)
{
  return dot(p,n.xyz) + n.w;
}

// from iq
float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return length(max(d,0.0));
        
}

// https://github.com/HackerPoet/MarbleMarcher/blob/master/assets/frag.glsl
vec3 boxFold(vec3 z, vec3 r) {
    return clamp(z.xyz, -r, r) * 2.0 - z.xyz;
}

// http://www.fractalforums.com/fragmentarium/fragmentarium-an-ide-for-exploring-3d-fractals-and-other-systems-on-the-gpu/15/
void sphereFold(inout vec3 z, inout float dz) {
    // float c2 = distFromOrigin / lissoujasSize * 3.5;
    float c2 = distFromOrigin / lissoujasSize * 3.8;
    float fixedRadius2 = 6.5 - c2;
    float minRadius2 = 0.3;
    float r2 = dot(z,z);
    if (r2< minRadius2) {
        float temp = (fixedRadius2/minRadius2);
        z*= temp;
        dz*=temp;
    } 
    else if (r2<fixedRadius2) {
        float temp =(fixedRadius2/r2);
        z*=temp;
        dz*=temp;
    }
}

// https://github.com/HackerPoet/MarbleMarcher/blob/master/assets/frag.glsl
vec3 mengerFold(vec3 z) {
    float a = min(z.x - z.y, 0.0);
    z.x -= a;
    z.y += a;
    a = min(z.x - z.z, 0.0);
    z.x -= a;
    z.z += a;
    a = min(z.y - z.z, 0.0);
    z.y -= a;
    z.z += a;
    return z;
}

// http://blog.hvidtfeldts.net/index.php/2011/11/distance-estimated-3d-fractals-vi-the-mandelbox/
vec2 DE(vec3 z)
{
    float Iterations = 20.;
    
    float c1 = (distFromOrigin/lissoujasSize)*2.5;
    float Scale = 2. + c1;
    
    //Scale = 5.8-(distFromOrigin/lissoujasSize)*1.5;

    vec3 offset = z;
    float dr = 1.0;
    float trap = 1e10;
    for (float n = 0.; n < Iterations; n++) {
        //z = mengerFold(z);
        z = boxFold(z, vec3(2.2));       // Reflect
        sphereFold(z, dr);    // Sphere Inversion
        z.xz = -z.zx;
        //sphereFold(z, dr);    // Sphere Inversion
        z = boxFold(z, vec3(0.9));       // Reflect
        
        sphereFold(z, dr);    // Sphere Inversion
        z=Scale*z + offset;  // Scale & Translate
        dr = dr*abs(Scale)+1.0;
        trap = min(trap, length(z));
    }
    float r = length(z);
    return vec2(r/abs(dr), trap);
}

vec2 scene(vec3 p) {  
    
    vec2 box = DE(p);
    return box;
}

float shadowScene(vec3 p){
    return DE(p).x;
}

// from iq
vec3 calcNormal(vec3 p) {
    float h = 0.001;
    vec2 k = vec2(1,-1);
    vec3 n = normalize( k.xyy*scene( p + k.xyy*h ).x + 
                  k.yyx*scene( p + k.yyx*h ).x + 
                  k.yxy*scene( p + k.yxy*h ).x + 
                  k.xxx*scene( p + k.xxx*h ).x );    
    return n;
}

// ro: ray origin, rd: ray direction
// returns t and the occlusion as a vec2
vec3 march(vec3 ro, vec3 rd) {
    float t = 0.2, i = 0.;
    for(i=0.; i < MaxSteps; i++) {
        vec3 p = ro + t * rd;
        vec2 hit = scene(p);
        float dt = hit.x;
        t += dt;
        if(dt < MinDistance*(1.0+t/10.0)) {
            return vec3(t-MinDistance, 1.-i/MaxSteps, hit.y);  
        }
    }
    return vec3(0.);
}

float marchShadow(vec3 ro, vec3 rd) {
    float t = 0., i = 0.;
    for(i=0.; i < MaxSteps; i++) {
        vec3 p = ro + t * rd;
        float dt = shadowScene(p);
        t += dt;
        if(dt < MinDistance) {
            return t-MinDistance;    
        }
    }
    return 0.;
}

float G1V(float dotNV, float k) {
    return 1.0 / (dotNV * (1.0 - k) + k);
}

// http://filmicworlds.com/blog/optimizing-ggx-shaders-with-dotlh/
float brdf_ggx(vec3 N, vec3 V, vec3 L, float roughness, float F0) {
    float alpha = roughness * roughness;
    vec3 H = normalize(V+L);
    float dotNL = clamp(dot(N,L), 0., 1.);
    float dotNV = clamp(dot(N,V), 0., 1.);
    float dotNH = clamp(dot(N,H), 0., 1.);
    float dotLH = clamp(dot(L,H), 0., 1.);
    float alphaSqr = alpha*alpha;
    float pi = 3.14159;
    float denom = dotNH * dotNH * (alphaSqr - 1.0) + 1.0;
    float D = alphaSqr / (pi * denom * denom);
    float dotLH5 = pow(1.0 - dotLH, 5.0);
    float F = F0 + (1.0 - F0) * dotLH5;
    float k = alpha / 2.0;
    float vis = G1V(dotNL, k) * G1V(dotNV, k);
    return dotNL * D * F * vis;
}

vec3 calcLight(vec3 P, vec3 N, vec3 Lpos, vec3 V, vec3 diffuse, vec3 specular) {
    vec3 L = normalize(Lpos-P);
    float NdotL = max(dot(N, L), 0.0);
    vec3 diff = NdotL * diffuse;
    vec3 spec = brdf_ggx(N, V, L, 0.3, 0.02) * specular;
    return diff + spec;
}

// p: point, sn: surface normal, rd: ray direction (view dir/ray from cam)
vec3 light(vec3 p, vec3 sn, vec3 rd, vec3 ro, float trap) {
    
    vec3 V = normalize(ro-p);
    vec3 L = normalize(ro-p);
    vec3 N = sn;
    vec3 Refl = reflect(L, N);
    float NdotL = max(0.0, dot(N, L));
    

    float pulse = smoothstep(.2, -.2, abs(fract(0.25*trap + 0.1)-0.5));
    
    vec3 ambient = vec3(0.);
    vec3 diffuse = magma(fract(0.15*trap)) 
        + 1.0*magma(fract(0.15*trap)) * pulse
        ;

    vec3 specular = magma(fract(0.15*trap));
    
    //diffuse = vec3(1.0);
    //specular = vec3(1.0);
    
    
    vec3 front = calcLight(p, N, ro, V, diffuse, vec3(1.0));
    vec3 bac = calcLight(p, N, vec3(0,1,0), V, diffuse, vec3(1.0));
    vec3 center = calcLight(p, N, vec3(0,0,0), V, diffuse, vec3(1.0));
    
    return ambient + 0.8*front + 0.3*bac + 0.55*center;
}

// https://iquilezles.org/www/articles/palettes/palettes.htm
vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d ) {
    return a + b*cos(6.28318 * (c*t + d));
}

vec3 camPos(float t) {
    float x = cos(5.0*t);
    float y = sin(3.0*t);
    float z = cos(7.0*t);
    return lissoujasSize*vec3(x,y,z);
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-R)/R.y;
    vec3 fog = vec3(.3,.2,.3) * 0.5;
    vec3 col = vec3(fog);

    float speed = 0.02;
    float time = (time +93.6) * speed;
    
    vec3 ro = camPos(time);
    
    distFromOrigin = length(ro);
    
    
    vec3 ta = camPos(time+speed);
    vec3 ww = normalize(ta-ro);
    vec3 uu = normalize(cross(ww, vec3(0,1,0)));
    vec3 vv = normalize(cross(uu,ww));
    vec3 rd = normalize(uv.x*uu + uv.y*vv + 1.0*ww);
    
    //mat3 rot = rotateX(0.2) * rotateZ(-3.1415/2. - 0.2) * rotateY(time/16.);
    
    //ro -= vec3(0,1,15);
    
    vec3 hit = march(ro, rd); // returns t and the occlusion value 
    float t = hit.x;
    
    if(t > eps) {
        vec3 p = ro + t * rd;
        vec3 n = calcNormal(p);
        col = clamp(light(p, n, rd, ro, hit.z), 0.0, 1.0);
        col *= (.5*hit.y+.5);   // occlusion 
        
        float fog_max = 5.5,
              fog_min = 4.;
        float fog_alpha = clamp(1. - (fog_max - t) / (fog_max - fog_min), 0.0, 1.0);
        col = mix(col, fog, fog_alpha);
    }
    else {
        col = vec3(fog);
    }

    glFragColor = vec4(col,1.0);
}
