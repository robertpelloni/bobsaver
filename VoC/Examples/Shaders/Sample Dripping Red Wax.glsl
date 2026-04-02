#version 420

// original https://www.shadertoy.com/view/mdjGWt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define BACKGROUND vec3(1, 1, 1)

const float PI = 3.14159265359;

float seed = 0.25;

float dripDistance = 0.1;
float density = 0.75;

float bCurve = 1.5;
float bFreq = 3.5;
float bRange = 0.35;

float fallSpeed = 6.0;

float sdfWidth = 0.14;

float scale = 0.5;

float rand(float x, float y) { return fract(1e4 * sin(17.0 * x + y * 0.1) * (0.1 + abs(sin(y * 13.0 + x)))); }

float dripSDF( vec2 uv )
{   
    uv.y *= -1.;
    uv.y += 1.0;
    float s = sdfWidth * abs((1.0-uv.y)-0.75) + 0.05;
    float o = 1.0;
    float drip = 9999.0;
    
    float x = uv.x * scale - sdfWidth;
    x += dripDistance - mod(x, dripDistance);
    
    x -= dripDistance;
    for( int i=0; i<3; i++ )
    {
        if( x > uv.x * scale + sdfWidth ) break;
        
        x += dripDistance;
        float isLine = floor(rand(x, seed) + density);
        if( isLine == 0.0 ) continue;
        
        float y = rand(seed,x) * 0.8 + 0.1;
        float animTime = time+(y*10.0);
        float bounce = 0.0 - (bCurve * mod(animTime, bFreq)) * exp(1.0-bCurve*mod(animTime, bFreq));
        y += bounce * bRange;
        y = min(y,uv.y);
        
        float t = mod(animTime, bFreq) * fallSpeed * bRange;
        float f = y + t;
        
        float d = distance(vec2(x,y), uv * vec2(scale, 1));
        
        o *= clamp(d/s, 0.0, 1.0);
        drip = min(drip, distance(vec2(x / scale,f), uv) * (0.5 + t * 0.45));
    }
    
    o = min( o, clamp(drip/s,0.0,1.0) );
    
    s = sin(uv.x * 20.0 + time * 0.5) * 0.1 + sin(0.5 * (uv.x * 20.0 + time * 0.5)) * 0.2 + 0.4;
    float sdf = o * clamp(uv.y/s,0.0,1.0);
    return sdf;
}

vec3 getNormal(vec2 p)
{
    vec3 e = vec3(vec2(1.0) / resolution.xy * 32.0 /*multiply for smooth normals*/, 0);
    float nx = (dripSDF(p - e.xz) - dripSDF(p + e.xz)) / (2.0 * e.x);
    float ny = (dripSDF(p - e.zy) - dripSDF(p + e.zy)) / (2.0 * e.y);
    vec3 n = normalize(vec3(nx, ny, 1.));
    return n;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / resolution.y;
    
    vec3 col = vec3(0.0);   
    
    float c = 1.0 / sdfWidth * 0.025;
    float w = 0.03;
    
    float d = dripSDF(uv);
    float m = 1.0 - smoothstep( c - w, c + w, d );
    
 
    col.r = m;
    vec3 rd = normalize(vec3(uv, 1));
    vec3 ro = vec3(0, 0, 0);
    vec3 p = ro + rd * d;
    vec3 l[4] = vec3[](vec3(700, -500, 50.0), vec3(-700, -500, 50.0), vec3(0, -500, 200.0), vec3(100, 500, 100.0));
    float light = 0.0;
    for(int i = 0; i < l.length(); ++i)
    {
    vec3 to_l = normalize(l[i] - p);
    vec3 to_ro = normalize(ro - p);
    vec3 n = getNormal(uv);
    float spec = pow(max(dot(reflect(-to_l, n), to_ro), 0.0), 8.0) * 0.75;
    float occl = pow(max(dot(reflect(to_l, n), to_ro), 0.0), 2.0);
    float diff = max(0.0, dot(to_l, n)) * 0.5;
    light += max(spec + diff - occl, 0.0);
    }
    col.rgb *= light + 0.5;
    col.gb += max(col.r - 1.0, 0.0);
    col.rgb = pow(col.rgb, 1.0 / vec3(2.2));
    col.rgb = mix(BACKGROUND, col.rgb, m);
    //col.rgb = vec3(d);
    
    glFragColor = vec4(col,1.0);
}
