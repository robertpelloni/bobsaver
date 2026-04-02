#version 420

// original https://www.shadertoy.com/view/3dtXD7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// SHADERTOBER 25 Tasty (actually, it's a snake)
// Poulet Vert 27-10-2019
// thanks iq, leon, flopine

#define VOLUME 0.001
#define PI 3.14159

float sdSphere(vec3 p, float r)
{
    return length(p)-r;
}

vec2 opU2( vec2 d1, vec2 d2 )
{
    return (d1.x < d2.x) ? d1 : d2;
}

float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }

vec3 palette( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

// Scene setup
vec2 map(vec3 pos)
{
    vec2 scene = vec2(0.0, 0.0);
    
    scene.x = pos.y;
    
    vec3 sp = pos + vec3(sin(pos.z+time), -.1, 0.0);
    float snake = sdSphere(sp, .5);
    
    for(int i=0;i<10;i++)
    {
        vec3 tsp = sp + vec3(0.0, 0.0, 1.0+1.0*float(i));
        snake = opSmoothUnion(snake, sdSphere(tsp, .5), .5);
    }
    
    // Materials
    scene = opU2(scene, vec2(snake, 1.0));
    
    return scene;
}

vec2 CastRay(vec3 ro, vec3 rd)
{
    float t = 0.0;
    
    for(int i=0 ; i<128 ; i++)
    {
        vec2 ray = map(ro + rd * t);
        
        if(ray.x < (0.0001*t))
        {
            return vec2(t, ray.y);
        }
        
        t += ray.x;
    }
    
    return vec2(-1.0, 0.0);
}

float GetShadow (vec3 pos, vec3 at, float k) {
    vec3 dir = normalize(at - pos);
    float maxt = length(at - pos);
    float f = 01.;
    float t = VOLUME*50.;
    for (float i = 0.; i <= 10.0; i += .1) {
        float dist = map(pos + dir * t).x;
        if (dist < VOLUME) return 0.;
        f = min(f, k * dist / t);
        t += dist;
        if (t >= maxt) break;
    }
    return f;
}

vec3 GetNormal (vec3 p)
{
    float c = map(p).x;
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(map(p+e.xyy).x, map(p+e.yxy).x, map(p+e.yyx).x) - c);
}

float GetLight(vec3 N, vec3 lightPos)
{
    return max(dot(N, normalize(lightPos)), 0.0);
}

vec3 TriPlanar(vec3 pos, vec3 nor)
{
    vec3 x = vec3(1.0, 0.0, 0.0);
    vec3 y = vec3(0.0, 1.0, 0.0);
    vec3 z = vec3(0.0, 0.0, 1.0);
    vec3 p = normalize(abs(pos));
    vec3 col = x * abs(p.x) * abs(nor.x);
    col = mix(col, y, abs(p.y) * abs(nor.y));
    col = mix(col, z, abs(-p.z) * abs(nor.z));
    return col;
}

float random (vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

float pcurve( float x, float a, float b )
{
    float k = pow(a+b,a+b) / (pow(a,a)*pow(b,b));
    return k * pow( x, a ) * pow( 1.0-x, b );
}

vec3 GroundTexture(vec2 uv)
{   
    uv.x += sin(uv.y*40.)*.01;
    float x = pcurve(fract(uv.x * 10.), .3, .1);
    float y = pcurve(fract(uv.x * 100.), .7, .1);
    x = mix(x,y,.1);
    x -= random(uv) * .1;
    return vec3(1.0, .9, 0.0) * x;
}

vec3 Render(vec3 ro, vec3 rd, vec2 uv)
{
    vec2 t = CastRay(ro, rd);
    vec3 pos = vec3(ro + rd * t.x);
    
    vec3 col = vec3(0.0);
    vec3 polyCol = palette(fract(pos.y-time), vec3(.5), vec3(.5), vec3(1.0), vec3(0.0, 0.33, 0.67));
    
    if(t.x == -1.0)
    {
        col = vec3(0.0);
    }
    else
    {    
        vec3 N = GetNormal(pos);
        
        vec3 mainL = vec3(2.0, 5.0, 0.0);
        float mainlight = GetLight(N, mainL);
        
        vec2 ledFreq = vec2(.15, .17);
        vec2 ledUV =  vec2(-pos.x+5.08, -pos.y-.5);
        
        float shade = GetShadow(pos, mainL, 4.0);
        
        
        if(t.y == 0.0) // ground
        {
            col = vec3(1.0-length(pos*.1))*.3;
            vec2 groundUV = pos.xz * .1;
            groundUV.y += time*.1;
            col *= GroundTexture(groundUV);
            
            
        }
        else if(t.y == 1.0) // triplanar snake
        {
            col = TriPlanar(pos, N);
            col += polyCol;
            
        }
        
        col -= (1.0-shade) * .5;
    }
    
    return col;
}

vec3 GetViewDir(vec2 uv, vec3 cp, vec3 ct)
{
    vec3 forward = normalize(ct - cp);
    vec3 right = normalize(cross(vec3(0.0, -1.0, 0.0), forward));
    vec3 up = normalize(cross(right, forward));
    
    return normalize(uv.x * right + uv.y * up + 2.0 * forward);
}

void main(void)
{
    vec2 uv = 2.0 * gl_FragCoord.xy / resolution.xy - 1.0;
    uv.x *= resolution.x/resolution.y;
    vec2 screenUV = gl_FragCoord.xy / resolution.xy;
    
    
    vec3 cp = vec3(0.0, 5.0, -10.0);
    vec3 ct = vec3(0.0, 0.0, 0.0);
    
    vec3 vd = GetViewDir(uv, cp, ct);
    
    vec3 col = Render(cp, vd, screenUV);
    
    col = sqrt(clamp(col, 0.0, 1.0));
    
    glFragColor = vec4(col,1.0);
}
