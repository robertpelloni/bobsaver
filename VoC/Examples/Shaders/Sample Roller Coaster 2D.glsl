#version 420

// original https://www.shadertoy.com/view/wtV3RD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Plento

vec2 R;
#define st(a, b, t) smoothstep(a, b, t)

vec2 rot(vec2 p, float a){
     return vec2(p.x*cos(a) - p.y*sin(a), p.x*sin(a) + p.y*cos(a));   
}

float height(float x){
    return sin(x*2.)*.15 + sin(x*3.)*.13 + sin(x*6.)*.02;
}

// Get the angle that the cars should rotate on track
float aDx(float x){
    float h = .001;
    float y = height(x+h) - height(x);
    return atan(y, h);
}

float box(vec2 uv, vec2 dim, float b){
    uv = abs(uv);
    float bx = st(b, -b, uv.y - dim.y);
    bx *= st(b, -b, uv.x - dim.x );
    return bx;
}
float circle(vec2 uv, float r, float b){
     return st(r + b, r - b, length(uv));   
}
float rtr(vec2 uv, vec2 scale, float h,  float b){
    uv.y -= h;
    uv *= scale;
    
    float tri = st(b, -b, dot(uv, vec2(1., 1.)));
    tri *= st(-b, b, uv.y + h);
    tri *= st(-b, b, uv.x);
    
    return tri;
}

vec4 track(vec2 uv){
    float b = .01;
    float trk = .0;
    float sup = .0;
    
    trk += st(-.005, .005, uv.y + height(uv.x) + .007);
    trk *= st(.005, -.005, uv.y + height(uv.x) - .007);
    
    vec2 ruv = fract(uv*8.) - .5;
    
    sup += st(.08, .07, abs(dot(ruv, vec2(1., 1.))));
    sup += st(.08, .07, abs(dot(ruv, vec2(-1., 1.))));
    sup *= st(.001, -.001, uv.y + height(uv.x)+.007);
    
    vec3 col = vec3(.7, .7, .7)*trk;
    
    return vec4(col, trk + sup);
}

vec4 car(vec2 uv){
    float b = .02;
    
    vec3 col = vec3(0);
    float a = 0.;
    float wheel = 0.;
    
    a += box(uv, vec2(.7, .1), b);
    a += box(uv, vec2(0.75, .06), b);
    a += box(uv - vec2(0., .2), vec2(.5, .1), b);
    a += box(uv - vec2(0., -.2), vec2(.5, .1), b);
    
    a += rtr(vec2(-uv.x, uv.y)-vec2(.5, .1), vec2(1., 1.), .2, b);
    a += rtr(vec2(-uv.x, -uv.y)-vec2(.5, .1), vec2(1., 1.), .2, b);
    
    a += rtr(vec2(uv.x, uv.y)-vec2(.5, .1), vec2(1., 1.), .2, b);
    a += rtr(vec2(uv.x, -uv.y)-vec2(.5, .1), vec2(1., 1.), .2, b);
    
    a -= box(uv-vec2(-.25, .2), vec2(.15, .1), b);
    a -= box(uv-vec2(.25, .2), vec2(.15, .1), b);
    
    a = clamp(a, 0., 1.);
    
    wheel += circle(uv-vec2(.4,-.35), .15, .01);
    wheel += circle(uv-vec2(-.4,-.35), .15, .01);
    
    col = a * mix(vec3(.8, 0., 0.),vec3(.8, .8, 0.), 
                  st(.2, .06, abs(uv.y+.2)));
    col *= st(.01, .4, abs(uv.y+.44));
    col *= st(.0, .2, abs(uv.y-.38));
    col *= st(.0, .9, abs(uv.x+1.15));
    
    col *= 1.-wheel;
    
    return vec4(col, a + wheel);
}

vec4 hill(vec2 uv){
     float a = st(0.015, -0.015, uv.y - height(uv.x));
    vec3 col = vec3(0);
    col += max(uv.y+.9, .1)*vec3(0.1, 0.43, 0.2) * a;
    return vec4(col, a);
}

void main(void) {
    R = resolution.xy;
    vec2 uv = vec2(gl_FragCoord.xy - 0.5*R.xy)/R.y;
    vec2 m = vec2(0.0);//mouse*resolution.xy.xy / R.xy-.5; 
    m.x *= R.x/R.y;
    
    vec3 col = mix(vec3(0.6, 0.6, 0.66), vec3(0., .28,.88), uv.y+.5);
    col = mix(col, vec3(0.9, 0.9, 0.5), exp(-length((uv-vec2(-.6, .3))*14.)));
    
    uv *= 1.5;
    
    vec2 p = uv, p2 = uv;
   
    uv.x += time + m.x*5.;
    
    vec4 Hill = hill(vec2(2.*uv.x - time*.7, uv.y));
    
    col = mix(col, Hill.rgb, Hill.a); 
    
    
    float pos = -.8;
    vec4 cars = vec4(0);
    
    for(float i = 0.; i < 5.; i++){
        p = p2;
        pos +=.25;
        
        float ht = height(uv.x - (p.x+pos));    
        p = p2 + vec2(pos , ht);
        p = rot(p, aDx(uv.x - p.x));
    
        cars = car((p-vec2(0., .072)) * 7.);
        col = mix(col,cars.rgb,cars.a); 
    }
    
    
    vec4 trk = track(uv);
    col = mix(col, trk.rgb,trk.a); 
    
    //col = 1.-exp(-col*1.4);
    glFragColor = vec4(col, 1.0)*1.05;
}

