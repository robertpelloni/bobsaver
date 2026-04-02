#version 420

// original https://www.shadertoy.com/view/Wld3z4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const vec3 RING_COL = vec3(.6,.2,.1);
const float SCALE = 2.5;

float sdCircle(vec2 p, float r) {
    return length(p) - r;
}

float sdSquare(vec2 p, vec2 s) {
    vec2 b = abs(p) - s;
    return max(b.x,b.y);    
}

//Thanks iq
float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }
//Thanks again iq
float sdRoundedX( in vec2 p, in float w, in float r )
{
    p = abs(p);
    return length(p-clamp(p.x+p.y,0.0,w)*0.5) - r;
}

//Rotate a point about the origin
vec2 rotate(vec2 p, float a) {
    float s = sin(a);
      float c = cos(a);
    
    float xnew = p.x * c - p.y * s;
      float ynew = p.x * s + p.y * c;
    
    return vec2(xnew,ynew);
}

//Given a point, find the closest distance
float scene(vec2 p) {
    
    float st = sin(time);
    
    //p = rotate(p,length(p)*st);
    
    float repeat = .75;
    vec2 pr = mod(p,repeat)-repeat/2.;
    
    float square = abs(sdSquare(rotate(pr,time),vec2(.2)))-.025;
    float x = sdRoundedX(rotate(pr,0.7853982),.75,.1);
    
      //float circle = sdCircle(p-vec2(sin(time),cos(time))*.5,.2);
    
    return max(square,-x);
}

void main(void)
{
    // Normalized pixel coordinates (from -0.5 to 0.5)
    vec2 uv = (gl_FragCoord.xy/resolution.xy - .5) * SCALE;

    //Multiply by aspect
    uv.x *= resolution.x / resolution.y;
    
    //Get distance from point to nearest surface
    float dist = scene(uv);
    vec3 col;
    if (dist <= 0.) {
        col = vec3(1.);
    }else{
        //Get ring
        float rings = step(mod(dist*100.0-time*5.0,7.5),.5);

        col = mix(RING_COL,RING_COL*.75,rings)*(3.-dist);
        col = col * .5;
        
        //Get mouse position
        vec2 mp = (mouse*resolution.xy.xy / resolution.xy - .5) * SCALE;
        mp.x *= resolution.x / resolution.y;
        
        float mDist = distance(uv,mp);
        vec2 mDir = normalize(mp-uv);
        
        //Gradient for light, thanks cleiprelli
        col /= 1. + mDist*mDist;
        
        float t = 0.;
        float k;
        float minK = 1000.;
        while (t < mDist) {
            k = scene(uv+mDir*t);
            minK = min(k,minK);
            if (k < .0001) {
                col *= .5;
                break;
            }
            t += k;
        }
    }
    
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
