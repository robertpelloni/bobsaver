#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// turn on for nipples
#define NSFW

// INIGO QULIEZ
// exponential smooth min (k = 32);
float smin( float a, float b, float k )
{
    float res = exp2( -k*a ) + exp2( -k*b );
    return -log2( res )/k;
}
//

mat2 rotate(float a) {
    float c = cos(a),
        s = sin(a);
    return mat2(c, s, -s, c);
}

float osc(float a, float x, float y) {
    return mix(x, y, .5 * sin(a) + .5);
}

#define SET_OBJ(d, i) if (d < dMin) { dMin = d; id = i; }

vec2 map(vec3 p) 
{
    
    float dMin = 1e10, id = -1.;
    float d = 0.;
    
    d=p.y + 1.;
    SET_OBJ(d, 0.)
    
        
    p.xz = mod(p.xz, 4.) - 2.;
    p.y -= 2.;
    
    p.xz *= rotate(osc(time, -.5, .5));

    vec3 v = p;
    v.z -= .2 + sin(v.y * 2.) * .3;

    d = length(v + vec3(.6, .1, 0.)) - .8;
    d = smin(d, length(v + vec3(-.6, .1, 0.)) - .8, 32.);
    d = smin(d, length(v + vec3(.0, 0., -.6)) - 1., 32.);
    //v = p;
    d = smin(d, length(v + vec3(.0, 1., -.6)) - 1., 32.);
    d = smin(d, length(v + vec3(.0, -.3, -.5)) - .5, 32.);
    SET_OBJ(d, 1.);
    //v = p;

#ifdef NSFW
    v = p;
    d = length(v + vec3(.7, .3, .8)) - .05;
    d = smin(d, length(v + vec3(-.7, .3, .8)) - .05, 32.);
    SET_OBJ(d, 2.)
#endif
    return vec2(dMin, id);
}

vec3 normal(vec3 p) 
{
    vec2 e = vec2(.001, .0);
    return normalize(vec3(
        map(p + e.xyy).x - map(p - e.xyy).x,
        map(p + e.yxy).x - map(p - e.yxy).x,
        map(p + e.yyx).x - map(p - e.yyx).x
    ));
}

float lighting(vec3 ro, vec3 p, vec3 n, vec3 l) 
{
    vec3 lp = normalize(l - p);
    float diffuse = max(dot(lp, n), 0.);
    vec3 ref = reflect(-lp, n);
    float spec = pow(.35 * max(dot(ref, normalize(ro)), 0.), 5.);
    return diffuse + spec;
}

vec3 render(vec2 uv, float T) 
{
    vec3 ro = vec3(2., 4., T);
    vec3 rd = vec3(uv, 1.);
    vec3 color = vec3(1.);
    float t = 0., id = -1.;
    for (int i = 0; i < 128; i++) 
    {
        vec2 d = map(ro + rd * t);
        if (d.x < .001 || t > 1000.) break; 
        id = d.y; 
        t += .3 * d.x;
    }
    vec3 p=ro+rd*t;
    if (id == 0.) color = vec3(1., 0., sin(p.x*0.542+p.y*0.563+time));
    if (id == 1.) color = vec3(1., .5, .2);
    if (id == 2.) color = vec3(.2, .0, .0);
    
    vec3 n = normal(p);
    vec3 l = vec3(1., 1., -1.);
    color = .3 * color + .3 * lighting(ro, p, n, l);
    color*=1./(1.+pow(t,2.)*.01);
    if (t > 1000.) color = vec3(0);
    return color;
}

void main( void ) 
{
    vec2 uv = (2. * gl_FragCoord.xy - resolution) / resolution.y;
    glFragColor = vec4(render(uv, time), 1.);
    glFragColor.a *= step(abs(uv.y), .8) ;
}
