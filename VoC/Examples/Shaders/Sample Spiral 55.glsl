#version 420

// original https://www.shadertoy.com/view/DtByDD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float random (vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

mat2 rotate2d(float _angle){
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}

mat2 scale(vec2 _scale){
    return mat2(_scale.x,0.0,
                0.0,_scale.y);
}

float plot(float st, float pct){
  return  smoothstep( pct-0.002, pct, st) -
          smoothstep( pct, pct+0.002, st);
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/min(resolution.x, resolution.y);

    uv = uv*rotate2d(-time*.23);

    float poly = 6.0; //poly

    float angle = (acos(0.)*4.)/poly;
    float dd = 0.0;

    float D = 8.; //sub
    float _delta =  angle/D;

    vec3 color = vec3(1.);
    float d = .4; // radius

    float a = atan(uv.y, uv.x)/acos(0.)/4.*poly;
    float e = fract(a);
    float q = floor(a);

    // if (e>0.995 || e < 0.005) {
    //     color = vec3(0.,1.,0.);
    // }

    float ww = cos(angle/2.)/cos(angle/2.-_delta);

    d = d/pow(ww,D*fract(time));

    float ss = floor(e*D);

    float start = d*pow(ww,ss);
    float end = d*pow(ww,ss+1.);

    float qq = (end - start)*pow(fract(e*D),1.) + start;

    float level_raw = log(length(uv)/qq)/D/log(ww);
    float level = floor(level_raw);

    // color = vec3(random(vec2(level, floor(a*D))));

    // if (length(uv) > qq) {
    //     color = vec3(.9);
    // }

    float x = floor(a*D);
    vec2 ccc = uv*rotate2d(-angle*.5-x*angle/D);

    color = mix(color, vec3(0.,0.,0.), plot(start*pow(ww,D* (level))*cos(angle/2.), ccc.x));
    for (float rcc = 0.; rcc < D-.5; rcc += 1.0) {
        color = mix(color, vec3(0.,0.,0.), plot(start*pow(ww,D* (level+1.))*cos(angle/2.), ccc.x));
        ccc = ccc*rotate2d(angle/D);
        start = start/ww ;
    }

    // for (float r = 0.; r < 2.*D ; r+=1.) {
    //     float a = atan(uv.y, uv.x)/acos(0.)/4.*poly;
    //     float e = fract(a);
    //     float q = floor(a);
    //     vec2 st = uv *rotate2d(angle*.5-angle*(q+1.));
    //     color = mix(color, vec3(0.), .5*plot(d*cos(angle/2.), st.x));
    //     dd += _delta;
    //     uv = uv * rotate2d(-_delta);
    //     d = d*cos(angle/2.)/cos(angle/2.-_delta);
    // }

    glFragColor = vec4(color,1.0);
}
