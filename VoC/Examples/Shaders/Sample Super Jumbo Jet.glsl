#version 420

// original https://www.shadertoy.com/view/ttVfWG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Cole Peterson (Plento)

// A 2D infinite airplane !

#define R resolution.xy
#define m vec2(R.x/R.y*(mouse*resolution.xy.x/R.x-.5),mouse*resolution.xy.y/R.y-.5)
#define ss(a, b, t) smoothstep(a, b, t)
#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))

// Distance funcs from https://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float box( in vec2 p, in vec2 b, float r){
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0) - r;
}

float line( in vec2 p, in vec2 a, in vec2 b ){
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

// Uneven capsule
float ucap( vec2 p, float r1, float r2, float h ){
    p.x = abs(p.x);
    float b = (r1-r2)/h;
    float a = sqrt(1.0-b*b);
    float k = dot(p,vec2(-b,a));
    if( k < 0.0 ) return length(p) - r1;
    if( k > a*h ) return length(p-vec2(0.0,h)) - r2;
    return dot(p, vec2(a,b) ) - r1;
}

// Noise stuff
float rand(vec2 n){ 
    return fract(sin(dot(n, vec2(17.12037, 5.71713))) * 12345.6789);
}
float noise(vec2 n){
    vec2 d = vec2(0.0, 1.0);
    vec2 b = floor(n), f = smoothstep(vec2(0.0), vec2(1.0), fract(n));
    return mix(mix(rand(b + d.xx), rand(b + d.yx), f.x), mix(rand(b + d.xy), rand(b + d.yy), f.x), f.y);
}
float fbm(vec2 n, float t){
    float sum = 0.0, amp = 1.0;
    for (int i = 0; i < 10; i++){
        n.x += t;
        sum += noise(n) * amp;
        n += n;
        amp *= 0.5;
    }
    return sum;
}

void main(void) {
    vec2 uv = vec2(gl_FragCoord.xy - 0.5*R.xy)/R.y;
    vec2 nv = uv;
    
    // Time scrubbing
    float t = time;// + mouse*resolution.xy.x*.02 + 3.;
    
    // Slight curvyness
    float k = exp((sin(uv.y*4. - 1.55)))+0.8;
    uv.x *= k;
    uv.x += t*.2;
    
    // Noise for clouds and fuselage
    float nse = fbm(5.*vec2(uv.x, uv.y*14.5), 0.)-.5;
    float nse2 = fbm(nv*4., time*.14)-.5;
    vec3 cloud = vec3(nse2)*0.7;
    
    // Bg color
    vec3 col = mix(vec3(.7, .8, .99), vec3(.8, .8, .8), nv.y) + cloud*cloud*.5;
    
    // plane base color
    vec3 pcol = .97*abs(uv.y+.6)*vec3(.95, .95, 1.)*1.1;
    
    // Add the line details
    pcol -= .04*ss(.004, .000, abs(uv.y-.02 + nse*.002));
    pcol -= .05*ss(.008, .00, abs(uv.y+.2 + nse*.002));
    
    // Add metal like shine and noise
    vec3 shn = vec3(.85, .9, .9)*.12*ss(-.99, .99, cos(uv.x*5.));
    pcol += shn;
    pcol -= nse*.03;
    
    // Darken underside 
    pcol *= max(ss(.01, .24, abs(uv.y+.36)), .8);
    
    // Add the fuselage
    col = mix(col, pcol, ss(.3 + .005, .3, abs(uv.y)));
    
    // Window coords
    vec2 wv = uv*4.;
    wv.x = mod(wv.x, 1.)-.5;
    
    // Window color
    vec3 winc = nse*.04+(.8+.08*cos(uv.x*20. + k*10.))*vec3(.75, .85, .98)+uv.y*4.;
    
    // Window shape
    float window = box(wv, vec2(.1, .15), .07);
    
    // Add windows
    col = mix(winc, col, ss(-.006, .006, window));
    col -= .3*ss(.013, .002, abs(window-.02));
    
    // Exit door coord
    vec2 exv = uv*2.;
    exv.x = mod(exv.x+.3, 8.)-8.*.5;
    
    // Exit door shape
    float ex = box(exv, vec2(.13, .17), .07);
    float exw = box(exv-vec2(0., .1), vec2(.04, .05), .02);
    
    // Add door color
    col = mix(shn*.5+vec3(.65)+nse*.04+cos(exv.y*10.+exv.x*10.)*.04, col, ss(.0, .01, ex));
    col += ss(.01, .0, exw)*vec3(0.7, 0.85, 0.99)*.13;
    col -= .4*ss(.006, -.006, abs(ex) - .001);
    col -= .7*ss(.007, -.007, abs(exw)-.001);
    col -= .3*ss(.004, -.004, abs(length(exv-vec2(.1, -.04))-.016)-.002);
    
    // Engine/ wing coords
    vec2 ev = nv;
    ev.x = mod(ev.x + t*.18, 2.5)-.5*2.5 + .25;
    
    // Engine shape
    float eh = exp(-(ev.x*ev.x)*18.)*.1*sign(uv.y);
    float eng = box(ev-vec2(0., -.31), vec2(.15, .03 - eh*.4), .02);
    eng = min(eng, box(ev-vec2(0.04, -.31), vec2(.18, .03), .02));
    
    // Engine color
    vec3 ecol = ss(.2, .3, abs(ev.y))*vec3(.5) + cos(ev.y*50.)*.07;
    ecol -= .2*ss(.005, 0.0, abs(abs(ev.x-.04)-.13));
    
    // Add engines
    col = mix(ecol, col, ss(-.001, .001, eng));
    col *= ss(.0, .003, abs(eng)-.001);
    
    ev.x-=.25;
    // Wing shape and color
    float wing = ucap(rot(1.55)*(ev-vec2(.7, -.2)), .02, .06, 1.3);
    vec3 wcol = 1.7*max(ss(.21, .4, abs(ev.y+.5))*vec3(.5), .1) + nse*.03;
    
    // Add wing
    col = mix(wcol, col, ss(-.001, .001, wing));
    col *= ss(-.002, .002, abs(wing)-.001);
    
    // Add a bit of sky blue-ness to everything
    col += vec3(0., .01, .026)*.7;
    
    // Makes it pop a bit
    col = col*col*col*col*col*1.3;
    
    // A tiny bit of cloud in foreground
    col += (-nv.y-.05)*cloud*cloud*cloud*.6;
    
    // Smoothly clamp values > 1
    col = 1.-exp(-col*1.3);
    
    // Side darkening
    col *= ss(.95, .7, abs(nv.x));
    
    // Intro thing
    if(time < 2.)
        col *= ss(0.001, -0.001, length(nv)-time*1.6);
    
    
    glFragColor = vec4(sqrt(clamp(col, 0.0, 1.0)), 1.0);
}

