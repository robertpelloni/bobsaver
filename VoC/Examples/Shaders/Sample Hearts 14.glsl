#version 420

// original https://www.shadertoy.com/view/3tdSWj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float heartSDF(vec2 uv){
      float x = uv.x; float y = uv.y;
    
      //             L'ÉQUATION EST LÀ
    
    //     | | | | | | | | | | | | | | | | | |
    //     v v v v v v v v v v v v v v v v v v
    return pow(x*x + y*y - 1., 3.) - x*x*y*y*y;
}

float rand(vec2 id){
      vec2 r = fract(id * vec2(127.34, 456.21));  
     r += dot(r, r+475.32);
    return fract(r.x*r.y);
}

vec3 rand3(vec2 id){
    return vec3(rand(id), rand(id*714.62), rand(id*164397.241));
}

float smin(float a, float b, float k) {
    float res = exp2( -k*a ) + exp2( -k*b );
    return -log2( res )/k;
}

float singlePuls(vec2 id, float phase){
    float puls = 2.2 + 1.7*rand(id);
    float s = 0.5*pow(sin(puls*(time + phase) + rand(id)*15.), 2.0);
    return smin(s, 0., 32.);
}

float heartbeatPuls(vec2 id) {
    return (singlePuls(id, 0.)
         +  singlePuls(id, 0.35)) *0.5;
}

float heart(vec2 uv, vec2 id){
    uv += 0.6* (rand(id)-0.5);
    uv *= 2.8 * (1. + 4.*heartbeatPuls(id));
    
    float margin = 0.00001;
    return smoothstep(margin, -margin, heartSDF(uv)) - smoothstep(margin, -margin, heartSDF(uv*1.14));
}

void main(void)
{
    vec3 heartCol = vec3(1.0, 0.2, 0.8);
    vec3 backCol  = vec3(1.0, 0.65, 0.92);
    //vec3 backCol  = vec3(255, 237, 110)/255.;
    //vec3 backCol  = vec3(182, 196, 250)/255.;
    //vec3 backCol  = vec3(255, 194, 89)/255.;
    
    vec2 uv = gl_FragCoord.xy/resolution.y - vec2(0.5 * resolution.x/resolution.y, 0.5);
       uv *= 4.;
    
    vec2 gv = fract(uv) - 0.5;
    vec2 id = floor(uv);
    
    float t = 0.;
    vec3 col = vec3(0.);
    for (float x = -1.; x < 1.5; x+=1.){
        for (float y = -1.; y < 1.5; y+=1.){
            vec2 off = vec2(x, y);
            float h = heart(gv - off, id + off);
            t += h;
            if (h>0.5)
                col = heartCol + (rand3(id+off)-0.5)*vec3(0.3, 0.5, 0.5);
        }
    }
    //t = min(t, 1.);
    //col = t * heartCol + (1.-t) * backCol;
    
    if (t < 0.5)
        col = backCol;
    
    glFragColor = vec4(col,1.0);
}
