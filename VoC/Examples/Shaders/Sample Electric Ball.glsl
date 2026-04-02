#version 420

// original https://www.shadertoy.com/view/WdBSWR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float ringAmp = 0.025;
float ringThickness = 0.01;
float ringFreq = 20.0;

// random/hash function              
float hash( float n )
{
  return fract(cos(n)*41415.92653);
}

// 3d noise function
float noise( in vec3 x )
{
  vec3 p  = floor(x);
  vec3 f  = smoothstep(0.0, 1.0, fract(x));
  float n = p.x + p.y*57.0 + 113.0*p.z;

  return mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
    mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y),
    mix(mix( hash(n+113.0), hash(n+114.0),f.x),
    mix( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
}

vec2 hash( vec2 p ) {
    p = vec2(dot(p,vec2(127.1,311.7)), dot(p,vec2(269.5,183.3)));
    return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

float noise( in vec2 p ) {
    const float K1 = 0.366025404; // (sqrt(3)-1)/2;
    const float K2 = 0.211324865; // (3-sqrt(3))/6;
    vec2 i = floor(p + (p.x+p.y)*K1);    
    vec2 a = p - i + (i.x+i.y)*K2;
    vec2 o = (a.x>a.y) ? vec2(1.0,0.0) : vec2(0.0,1.0); //vec2 of = 0.5 + 0.5*vec2(sign(a.x-a.y), sign(a.y-a.x));
    vec2 b = a - o + K2;
    vec2 c = a - 1.0 + 2.0*K2;
    vec3 h = max(0.5-vec3(dot(a,a), dot(b,b), dot(c,c) ), 0.0 );
    vec3 n = h*h*h*h*vec3( dot(a,hash(i+0.0)), dot(b,hash(i+o)), dot(c,hash(i+1.0)));
    return dot(n, vec3(70.0));    
}

vec4 quatForAxisAngle(float angle, vec3 axis) {
    vec4 q;
    
    float half_angle = angle/2.0;
    q.x = axis.x * sin(half_angle);
    q.y = axis.y * sin(half_angle);
    q.z = axis.z * sin(half_angle);
    q.w = cos(half_angle);
    return q;
}

vec3 spherePos(vec2 uv, vec3 ro, float radius, out float h) {
    //vec3( 0.0, 0.0, 5.0 );
    vec3 rd = normalize( vec3( uv, -radius ) );

    // intersect sphere
    float b = dot(ro,rd);
    float c = dot(ro,ro) - 1.0; 
    h = b*b - c;
    
    float t = -b - sqrt(h);
    vec3 pos = ro + t*rd;
    return pos;
}

vec3 rotateVectorY(vec3 v, float angle) {
    vec4 q = quatForAxisAngle(angle, vec3(0.0, 1.0, 0.0));
    vec3 temp = cross(q.xyz, v) + q.w * v;
    return v + 2.0*cross(q.xyz, temp); 
}

vec3 ringColor(vec3 bg, float pct) {
    vec3 baseColor = vec3(0.3, 0.3, 1.0);
    vec3 boost = (1.0 + (1.0-pct)) * vec3(3.5, 3.5, 3.5);
    float a = (1.0 - pct) * 0.6;
    
    return mix(bg, baseColor * boost, a);
}

vec3 doRing(vec3 col, vec3 pos, vec2 uv, float down) {
    float centerDist = 0.7 - abs(0.5 - uv.x);
    centerDist = pow(centerDist, 4.0);
    
    float normSin = sin(pos.z * ringFreq + time * 15.0) * ringAmp + 0.5 - (centerDist * 0.5 * down);
    
    normSin += noise(pos*15.0) * 0.02;
    normSin += noise(pos*2.0) * 0.02;
    //normSin += noise(pos*15.0) * 0.02;
    
    float d = abs(normSin - uv.y);
    if(d < ringThickness)
    {
        col = ringColor(col, d / ringThickness);
    }
    
    return col;
}

vec2 rotate2d(vec2 p, float a) {
    vec2 rpt = vec2(0.5, 0.5);
    p = p - rpt;
    float x = p.x * cos(a) - p.y * sin(a);
    float y = p.y * cos(a) + p.x * sin(a);
    return vec2(x, y) + rpt;
}

vec3 DoRings(vec2 uv, vec2 p, float angle) {
    float h;
    uv = rotate2d(uv, angle);
    
    vec3 pos = spherePos(p, vec3( 0.0, 0.0, -2.5 ), -2.0, h);
    vec3 posRotated = rotateVectorY(pos, time * -0.5);    
    vec3 col;
    col = doRing(col.rgb, posRotated, uv, -1.0);    
    pos = spherePos(p, vec3( 0.0, 0.0, 2.5 ), 2.0, h);
    
    posRotated = rotateVectorY(pos, time * -0.5); 
    col = doRing(col.rgb, posRotated, uv, 1.0);
    
    return col;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 p = (-resolution.xy + 2.0*gl_FragCoord.xy) / resolution.y;
    
        
    vec4 col = vec4(0.0);      

#if 1
    col.rgb += DoRings(uv, p, 0.0);
    col.rgb += DoRings(uv, p, 3.14 * 0.5);
    col.rgb += DoRings(uv, p, 3.14 * 0.35);
    col.rgb += DoRings(uv, p, 3.14 * 0.65);
#else     
    col.rgb += DoRings(uv, p, 0.0 + time *0.2);
    //col.rgb += DoRings(uv, p, 3.14 * 0.5 + time*0.3);
    col.rgb += DoRings(uv, p, 3.14 * 0.25 + time*-0.25);
    //col.rgb += DoRings(uv, p, 3.14 * 0.75 + time*-0.1);
    //col.rgb += DoRings(uv, p, 3.14 * 0.15 + time*0.05);
    //col.rgb += DoRings(uv, p, 3.14 * 0.65 + time*-0.15);
#endif
    
    
    glFragColor = col;
}
