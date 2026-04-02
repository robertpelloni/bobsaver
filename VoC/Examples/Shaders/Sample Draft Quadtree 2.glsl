#version 420

// original https://www.shadertoy.com/view/Nld3z7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

    Draft Quadtree [learning level 2]
    11/2/21 @byt3_m3chanic

    Ver2 of my last shader in just playing with quadtrees.
    
    @Shane has a good example for 2d tiles here:
    https://www.shadertoy.com/view/llcBD7

    Done in an attempt to learn the basics and how to use
    and match up ID's with spaces. IDK might delete later?
 
*/

#define R          resolution
#define M          mouse*resolution.xy
#define T          time
#define PI         3.14159265359
#define PI2        6.28318530718

mat2 rot (float a) { return mat2(cos(a),sin(a),-sin(a),cos(a)); }
float hash21(vec2 p){ return fract(sin(dot(p,vec2(26.34,45.32)))*4324.23); }
float lsp(float begin, float end, float t) { return clamp((t - begin) / (end - begin), 0.0, 1.0); }
float eoc(float t) { return (t = t - 1.0) * t * t + 1.0; }

vec3 hue(float t){ 
    t*=5.;//tweak for other color variations
    const vec3 d = vec3(0.067,0.812,0.915);
    return .35 + .45*cos(PI2*t*(vec3(.97,.97,.98)*d)); 
}

float box( in vec2 p, in vec2 b ){
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float px = .0231;

vec3 doHatch(vec2 p, float res) {
    p *= res/10.;
    vec2 id = floor(p*.5)-.5;
    float rnd = hash21(floor(p*.5));
    float chk = mod(id.y + id.x,2.) * 2. - 1.;
    if (chk > 0.5) p.x *=-1.;
    float hatch = clamp(sin((p.x - p.y)*PI*3.)*3. + 0.25, 0., 1.);
    if(rnd>.66) hatch = rnd;
    return vec3(clamp(hatch,.3,.7),id);
}

void main(void) {

    vec2 uv = (2.*gl_FragCoord.xy-R.xy)/max(R.x,R.y);
    vec2 ms = (2.*M.xy-R.xy)/max(R.x,R.y);
                
    px = fwidth(uv.x)*2.;
            
    vec2 vuv= uv*(2.+.25*sin(T*.135));
    vuv.xy*=rot(.5*sin(T*.2));

    vuv.y+=T*.35;
    float px = fwidth(uv.x);
    float level=1.;
    vec3 dht = doHatch(vuv,155.);
    float chk = mod(dht.z + dht.y,2.) * 2. - 1.;
    
    vec3 C = mix(hue((chk+vuv.x)*.05),vec3(.01),dht.x);
 
    vec2 muv = uv-vec2(.5*sin(T)/level,.25*cos(T)/level);
    float tp = length(muv)-.1;
    tp=smoothstep(px,.0,abs(tp)-.0075);

    
    for(int k=0; k<4; k++){
        vec2 id = floor(vuv*level);
        float rnd = hash21(id);
        
        // threshold or if last loop
        if(rnd>.45||k>2) {

            vec2 p = vuv -(id+.5)/level;
            rnd = hash21(rnd+id.yx);
            float dir = rnd>.5 ?-1.:1.;

                                    
            vec2 off1= clamp(vec2(muv*.17),vec2(-.1275),vec2(.1275));
            off1/=level;
            
            // make ring parts - very basic
            float angle = atan(p.x+off1.x, p.y+off1.y);
            float f = length(p);
            float width = .5/level;
            float amt = 24.;
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
            
            tid.x=mod(tid.x,2.);
            float ds = length(p+off1-vec2(.125/level))-.065/level;
            float dt = length(p+off1+vec2(.115/level))-.030/level;
            float d = length(p)-.455/level;
            float s = length(p)-.375/level;
            float c = box(q+vec2(0,.4/level),vec2(1.,.25)/level);
            float l = length(p+off1)-.195/level;
            float h = abs(l)-.014/level;
            
            float fd = smoothstep(.005+px,-px,abs(d)-.025/level);
            float md = smoothstep(.025+px,-px,length(p)-.275/level);
            d = smoothstep(.0075+px,-px,d);
            s = smoothstep(.05+px,-px,s);
            c = smoothstep(.01+px,-px,c);
            l = smoothstep(.01+px,-px,l);
            h = smoothstep(.01+px,-px,h);
            ds = smoothstep(.01+px,-px,ds);
            dt = smoothstep(.01+px,-px,dt);
            
            C=mix(C,vec3(.35),d);
            C=mix(C,vec3(.1),min(s,d));
            c=min(c,s);
            vec3 clr = hue(hash21(float(k)+tid.yx));
            if(tid.x<1.) clr = hue(hash21(tid.yx));
            C=mix(C,clr,min(c,d)+md );
            C=mix(C,vec3(.015),min(l,d));
            C=mix(C,vec3(.005),h);
            C=mix(C,vec3(.9),ds+dt+fd);
            break;
        }
        level*=2.;
    }
    
    C = mix(C,vec3(.01,.4,.9),tp);
    C = pow(C, vec3(.4545)); 
    glFragColor = vec4(C,1.0);
}

