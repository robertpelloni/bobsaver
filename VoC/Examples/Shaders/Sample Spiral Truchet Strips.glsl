#version 420

// original https://www.shadertoy.com/view/3sK3z1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float tense = 1.2;
/** even numbers work best for this in truchet mode */
float twist = 2.;
/** works best with odd numbers - even causes visible seam */
float radial = 5.;

#define PI 3.14159265
 
float hash(vec2 p) {
    p = fract(p*vec2(931.733,354.285));
    p += dot(p,p+39.37);
    return fract(p.x*p.y);
}

void main(void) {
    /** Set some basic stuff */
    float pix = 1./max(resolution.x,resolution.y);
    vec2 R = resolution.xy;
    vec2 uv = gl_FragCoord.xy;
    
    float speed = time * 1.2;
    
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
    float mask = smoothstep(pix, -pix, abs(d-.5)-width);

    float angle = atan(cUv.x, cUv.y);
    float stripes = sin(checker * angle * 30. + time * 15.);
    stripes = clamp(stripes,0.1,1.);
    /** Un/comment for solid shape */
    mask *= stripes;
    
    col *= mask;
    
    vec3 ref = vec3(0.0);//TEXTURE2D(iChannel1, uv).rgb;
    //col = mix(vec3(0.,0.6,.9),ref,col);
    col = mix(vec3(0.,0.6,.9),vec3(1.),col);
    
    glFragColor = vec4(col, 1.);
}

