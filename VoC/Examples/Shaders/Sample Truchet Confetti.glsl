#version 420

// original https://www.shadertoy.com/view/wdG3WR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

precision mediump float;

/** works best with odd numbers - even causes visible seam     */
float radial = 5.;
/** must be even number */
float freq = 2.;  
float width = .2;
float twist = 2.;

#define PI 3.141592
#define TP 6.28318

#define PI 3.141592
#define TP 6.28318

float hash(vec2 p) {
    p = fract(p*vec2(931.733,354.285));
    p += dot(p,p+39.37);
    return fract(p.x*p.y);
}

void main(void) {
    /** Set some basic stuff */
    vec2 R = resolution.xy;
    vec2 uv = gl_FragCoord.xy;
    vec2 UV = gl_FragCoord.xy/resolution.xy;

    float time = time;
    float speed = time * 1.15;

    /** Do the warp and spin - trying to understand the math */
    uv = (uv.xy + uv.xy-R)/R.y;
    uv= vec2(0., speed - log2(length(uv))) + atan(uv.y, uv.x) * twist / 6.283;
    uv.x *=radial;

    /** Start the tile design */
    vec2 tile_uv = fract(uv) -.5;
    vec2 id = floor(uv);
    float n = hash(id);
    float checker = mod(id.y + id.x,2.) * 2. - 1.;
    vec3 col = vec3(1.);

    /** Un/comment for Spiral style Spin */
    /** However glitch in seam with animation */
    if(n>.5)tile_uv.x *= -1.;
    /** Un/comment to see circles offset */
    //if(checker>.5)tile_uv.x *= -1.;

    float d = abs(abs(tile_uv.x+tile_uv.y)-.5);
    vec2 cUv = tile_uv-sign(tile_uv.x+tile_uv.y+.001)*.5;
    d = length(cUv);

    float width = .15;
    float pix = fwidth(uv.x);
    float mask = smoothstep(pix, -pix, abs(d-.5)-width);

    float angle = atan(cUv.x, cUv.y);
    float freq = 2.; // <-- must be even
    float stripes = sin(checker * angle * freq + time * 8.);
    float k = freq*checker;
    pix = fwidth(angle); 
    if (pix>1.) {
        pix=.05;
        //-=3.14159; why not? artifacts?
    }
    
    stripes = smoothstep(1., -1., stripes/abs(k*pix))
              * smoothstep(0.,1.,PI/abs(k)/pix);
    mask *= stripes;

    col *= mask;
    col = mix(vec3(UV.y,1.-UV.y,.9),vec3(1.,UV.y,1.-UV.y),col);

    glFragColor = vec4(col, 1.);
}

  
