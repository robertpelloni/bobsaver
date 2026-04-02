#version 420

// original https://www.shadertoy.com/view/wdjfDK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rand(vec2 co, float i){
    return fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453 + 0.2 + sqrt(2.) * (i + floor(time/2.)));
}

float pattern(vec2 uv, vec2 seed, float seedi) {
    float v = rand(seed, seedi);
    if(v < 0.5) uv.xy = vec2(1.-uv.y,uv.x);
    if(distance(v,0.5) > 0.4) {
        return min(
            distance(distance(uv,vec2(0)),0.5)-1./6.,
            distance(distance(uv,vec2(1)),0.5)-1./6.
        );
    } else if(distance(v,0.5) > 0.1) {
        return min(
            distance(uv.y,0.5)-1./6.,
            max(
                distance(uv.x,0.5)-1./6.,
                - (distance(uv.y,0.5)-1./4.)
            )
        );
    } else {
        uv.y = abs(uv.y-0.5);
        return min(
            abs(uv.y)-1./6.,
            distance(uv,vec2(0.5,0.5))-1./6.
        );
    }
}

int hierarchy(vec2 uv) {
    float u = 1.0;
    for(int i=0;i<5;i++) {
        vec2 iuv = floor(uv*u)/u;
        float s = 1./u;
        if((distance(iuv.y,0.) > s || rand(iuv*u, float(i)) < 0.5) && iuv.y > s/4.) return i;
        u *= 2.;
    }
    return 5;
}

int chierarchy(vec2 uv) {
    float s = 1./64.;
    int h = 0;
    h = max(h, hierarchy(uv + vec2(-s,-s)));
    h = max(h, hierarchy(uv + vec2(+s,-s)));
    h = max(h, hierarchy(uv + vec2(-s,+s)));
    h = max(h, hierarchy(uv + vec2(+s,+s)));
    return h;
}

void main(void)
{
    float ut = fract(time/2.);
    float it = floor(time/2.);
    
    vec2 uv = gl_FragCoord.xy / resolution.y;
    vec2 scr = uv;
    uv.y += 0.075;
    uv.x -= resolution.x / resolution.y / 2.;
    uv *= 1.8 * pow(2.,-ut);
    
    float d = 0.;
    vec2 luv = fract(uv);
    int h = hierarchy(uv);
    float flip = cos(float(h)*3.1415926535);
    float s = pow(2.,float(h));
    luv = fract(uv*s);
    vec2 seed = floor(uv*s);
       d = pattern(luv, seed, float(h)) / s * flip;
    s = 1.0;
    for(int i=0;i<6;i++) {
        vec2 corner = floor(uv*s+.5)/s;
        int ch = chierarchy(corner);
        if(h <= i && i < ch) {
            float u = distance(uv, corner)-1./6./s;
            if(i%2 == 0) d = min(d, u);
            else d = max(d, -u);
        }
        s *= 2.;
    }
    d *= mod(it+0.5,2.) < 1.0 ? 1.0 : -1.0;
    d /= pow(2.,-ut) / pow(2.,-scr.y);
    
    vec3 dr = mix(vec3(0.,2.,1.), vec3(1.,0.5,0.), exp(-scr.y)) * exp(min(0.,d)*200.);
    vec3 br = mix(vec3(0.2,0.8,0.), vec3(0.8,0.6,0.2), exp(-scr.y));
    vec3 col = mix(dr,br,smoothstep(-1.,1.,d*resolution.y*2.));
    glFragColor = vec4(clamp(col,vec3(0.),vec3(1.)),1.0);
}
