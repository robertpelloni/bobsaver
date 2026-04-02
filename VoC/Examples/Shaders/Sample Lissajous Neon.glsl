#version 420

// original https://www.shadertoy.com/view/3syfDD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//2D Lissajous curve rotation illusion with Bezier segments and pastel colours.
//Colours from https://www.shadertoy.com/view/4d3SR4

#define POINT_COUNT 5
#define SEGMENTS 6.0

#define TWO_PI 6.283185

vec2 points[POINT_COUNT];
const float speed = 0.08;
const float rotation = 0.2;
const float len = 0.1;
const float scale = 0.2;

//Glow
float intensity = 1.2;
float radius = 0.012;

//https://www.shadertoy.com/view/MlKcDD
//Signed distance to a quadratic bezier
float sdBezier(vec2 pos, vec2 A, vec2 B, vec2 C){    
    vec2 a = B - A;
    vec2 b = A - 2.0*B + C;
    vec2 c = a * 2.0;
    vec2 d = A - pos;

    float kk = 1.0 / dot(b,b);
    float kx = kk * dot(a,b);
    float ky = kk * (2.0*dot(a,a)+dot(d,b)) / 3.0;
    float kz = kk * dot(d,a);      

    float res = 0.0;

    float p = ky - kx*kx;
    float p3 = p*p*p;
    float q = kx*(2.0*kx*kx - 3.0*ky) + kz;
    float h = q*q + 4.0*p3;

    if(h >= 0.0){ 
        h = sqrt(h);
        vec2 x = (vec2(h, -h) - q) / 2.0;
        vec2 uv = sign(x)*pow(abs(x), vec2(1.0/3.0));
        float t = uv.x + uv.y - kx;
        t = clamp( t, 0.0, 1.0 );

        // 1 root
        vec2 qos = d + (c + b*t)*t;
        res = length(qos);
    }else{
        float z = sqrt(-p);
        float v = acos( q/(p*z*2.0) ) / 3.0;
        float m = cos(v);
        float n = sin(v)*1.732050808;
        vec3 t = vec3(m + m, -n - m, n - m) * z - kx;
        t = clamp( t, 0.0, 1.0 );

        // 3 roots
        vec2 qos = d + (c + b*t.x)*t.x;
        float dis = dot(qos,qos);
        
        res = dis;

        qos = d + (c + b*t.y)*t.y;
        dis = dot(qos,qos);
        res = min(res,dis);

        qos = d + (c + b*t.z)*t.z;
        dis = dot(qos,qos);
        res = min(res,dis);

        res = sqrt( res );
    }
    
    return res;
}

vec2 getLissajousPosition(float a, float b, float t){
    const float A = 1.3;
    const float B = 1.0;
    //Making delta vary cyclically 0->2PI gives the illusion of rotation
    float delta = fract(rotation * time) * TWO_PI;
    return vec2(A * sin(a*t + delta), B * sin(b*t));
}

//https://www.shadertoy.com/view/3s3GDn
float getGlow(float dist, float radius, float intensity){
    return pow(radius/dist, intensity);
}

float getSegment(float t, vec2 pos, float offset){
    for(int i = 0; i < POINT_COUNT; i++){
        points[i] = getLissajousPosition(5.0, 
                                         7.0, 
                                         offset + float(i) * len + fract(speed * t) * TWO_PI);
    }
    
    vec2 c = (points[0] + points[1]) * 0.5;
    vec2 c_prev;
    float dist = 1e5;
    
    for(int i = 0; i < POINT_COUNT-1; i++){
        //https://tinyurl.com/y2htbwkm
        c_prev = c;
        c = (points[i] + points[i+1]) * 0.5;
        dist = min(dist, sdBezier(pos, scale * c_prev, scale * points[i], scale * c));
    }
    return max(0.0, dist);
}

//https://www.shadertoy.com/view/4d3SR4
vec3 getPastelGradient(float h) {
    h = fract(h + 0.92620819117478) * 6.2831853071796;
    vec2 cocg = 0.25 * vec2(cos(h), sin(h));
    vec2 br = vec2(-cocg.x,cocg.x) - cocg.y;
    vec3 c = 0.729 + vec3(br.y, cocg.y, br.x);
    return c * c;
}

//https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
vec3 ACESFilm(vec3 x){
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return clamp((x*(a*x+b))/(x*(c*x+d)+e), 0.0, 1.0);
}

void main(void) {
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    float widthHeightRatio = resolution.x/resolution.y;
    vec2 centre = vec2(0.5, 0.5);
    vec2 pos = centre - uv;
    pos.y /= widthHeightRatio;
    
    float dist;
    float glow;
    float f;
    
    vec3 col = vec3(0.0);
    
    for(float i = 0.0; i < SEGMENTS; i+=1.0){
        f = i/SEGMENTS;
        //Should be TWO_PI for symmetry but slightly off looks better
        dist = getSegment(time, pos, f * 6.0);
        glow = getGlow(dist, radius, intensity);

        col += glow * getPastelGradient(f + fract(0.3 * time));
    }

    //Tone mapping
    col = ACESFilm(col);
    
    //Gamma
    col = pow(col, vec3(0.4545));

    //Output to screen
    glFragColor = vec4(col,1.0);
}
