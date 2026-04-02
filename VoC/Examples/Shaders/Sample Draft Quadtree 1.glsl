#version 420

// original https://www.shadertoy.com/view/7tc3zN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

    Draft Quadtree [learning]
    11/2/21 @byt3_m3chanic

    Trying to learn multiscale truchet / but I need to master
    quadtrees first - I made one attempt that was pretty crude
    and brute force - https://www.shadertoy.com/view/fl33zn
    
    it's not right and has issues - so going back and looking
    into some examples by @Shane which is the basis of this shader.
    @Shane https://www.shadertoy.com/view/llcBD7

    Done in an attempt to learn the basics and how to use
    and match up ID's with spaces. 
 
*/

#define R          resolution
#define M          mouse*resolution.xy
#define T          time
#define PI         3.14159265359
#define PI2        6.28318530718

mat2 rot (float a) { return mat2(cos(a),sin(a),-sin(a),cos(a)); }
float hash21(vec2 p){ return fract(sin(dot(p,vec2(26.34,45.32)))*4324.23); }

vec3 hue(float t){ 
    t*=5.;//tweak for other color variations
    const vec3 d = vec3(0.067,0.812,0.910);
    return .35 + .45*cos(PI2*t*(vec3(.95,.97,.98)*d)); 
}

float box( in vec2 p, in vec2 b ){
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float px = .0231;

float doHatch(vec2 p, float res) {
    p *= res/10.;
    vec2 id = floor(p*.5)-.5;
    float rnd = hash21(floor(p*.5));
    float chk = mod(id.y + id.x,2.) * 2. - 1.;
    if (chk > 0.5) p.x *=-1.;
    float hatch = clamp(sin((p.x - p.y)*PI*3.)*3. + 0.25, 0., 1.);
    if(rnd>.66) hatch = rnd;
    return clamp(hatch,.3,.7);
}

void main(void) {

    vec2 uv = (2.*gl_FragCoord.xy-R.xy)/max(R.x,R.y);
       
    vec2 vuv= uv*(3.+.45*sin(T*.135));
    vuv.xy*=rot(.5*sin(T*.2));

    vuv.y+=T*.35;
    float px = fwidth(uv.x);
    float level=1.;

    vec3 C = vec3(.25*.25)*doHatch(vuv,155.);
    px = fwidth(uv.x)*2.;
    for(int k=0; k<5; k++){
        vec2 id = floor(vuv*level);
        float rnd = hash21(id);
        
        // threshold or if last loop
        if(rnd>.45||k>3) {
            
 
            vec2 p = vuv -(id+.5)/level;
            rnd = hash21(rnd+id.yx);
            float dir = rnd>.5 ?-1.:1.;

            // make ring parts - very basic
            float angle = atan(p.x, p.y);
            float f = length(p);
            float width = .5/level;
            float amt = 6.;
            //vec for moving ring
            vec2 q = vec2(
                fract(dir*amt*angle/PI+T*1.75)/level,
                f-width
            );
            //id for moving ring
            vec2 tid = vec2(
                floor(dir*amt*angle/PI+T*1.75),
                floor(f-width)
            );
            
            tid.x=mod(tid.x,amt);
            
            float d = length(p)-.465/level;
            float s = length(p)-.325/level;
            float c = box(q+vec2(0,.5/level),vec2(1.,.25)/level);
            float l = length(p)-.155/level;
            float h = abs(l)-.014/level;
            
            d = smoothstep(px,-px,d);
            s = smoothstep(px,-px,s);
            c = smoothstep(px,-px,c);
            l = smoothstep(px,-px,l);
            h = smoothstep(px,-px,h);
            
            C=mix(C,vec3(.4*.4),d);
            C=mix(C,vec3(.18*.18),min(s,d));
            c=min(c,s);
            C=mix(C,hue(hash21(tid)),min(c,d));
            C=mix(C,vec3(.05*.05),min(l,d));
            C=mix(C,vec3(.185*.185),h);
            
            break;
        }
        level*=2.;
    }
    
    C = pow(C, vec3(.4545));        
    glFragColor = vec4(C,1.0);
}

