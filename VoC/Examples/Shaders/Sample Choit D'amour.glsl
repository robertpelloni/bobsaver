#version 420

// original https://www.shadertoy.com/view/MlyyWw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash( float n ) {
    return fract(sin(n)*43758.5453);
}

float noise( in vec3 x ) { // in [0,1]
    vec3 p = floor(x);
    vec3 f = fract(x);

    f = f*f*(3.-2.*f);

    float n = p.x + p.y*57. + 113.*p.z;

    return mix(mix(hash(n+  0.), hash(n+  1.),f.x),
               mix(hash(n+ 57.), hash(n+ 58.),f.x),f.y);
}

vec3 clampcolor (vec3 color, float max){ 
    return vec3(clamp (color.r,0.,max), clamp(color.g,0.,max), clamp (color.b,0.,max));
}

vec2 Within (vec2 uv, vec4 rect){
    return (uv-rect.xy)/(rect.zw-rect.xy);
}

vec4 Head (vec2 uv, vec2 m, float blur) {
    uv -=.5;
    uv.y -= uv.x*uv.x*-.5;
    uv.y -= cos(uv.x*15.-(length(m))*10.)*.01;
    uv.x -= sin(uv.y*15.-(length(m))*10.)*.01;
    
    vec4 col = vec4 (.1, .1, 1., 1.);
    col.a = smoothstep(.5+blur, .49, length(uv));
    
    col.rgb += smoothstep(1., .0, length(vec2(uv.x, uv.y-.1)))*.4; //degrade alpha
    
    vec4 shaddow;
    shaddow.a = smoothstep(.4, .6, length(vec2(uv.x, uv.y-.1)));
    shaddow.a *= noise(vec3(uv*300., 1.));
    
    col.rgb = mix (col.rgb, vec3 (0., .0, .0), shaddow.a);
    
    return col;
}

vec4 Ear(vec2 uv, vec4 head, vec2 m){
    uv -=.5;
    uv+= m*(.5-dot(uv, uv));        //UN PEU CACA
    uv.y -= uv.x*uv.x*-.5;
    uv.y -= cos(uv.x*15.-(length(m))*10.+3.)*.01;
    uv.x -= sin(uv.y*15.-(length(m))*10.+3.)*.01;
    
    vec4 col = vec4 (.2, .2, 1., 1.);
    col.a  = smoothstep(.5, .48, length(vec2(uv.x, uv.y))); //1st circle
    //col.a += smoothstep(.5, .48, length(vec2(uv.x-.3, uv.y-.3))) - 1.;     //intersect with 2d circle
    //col.a = clamp (col.a,0.,1.);                                            //
    col.rgb += smoothstep(.8, .0, length(vec2(uv.x-.3, uv.y-.3)))*.2; //white gradient
    col.a *= -head.a*noise(vec3(uv*300., 1.))+1.; //outline

    return col;
}

vec4 Eye (vec2 uv, float side, vec2 m) {
    uv -=.5;
    uv.x *= side; //unmirror

    //eyelid    
    vec2 eyelidUv = uv;
    eyelidUv.y *= .9;
    eyelidUv.y -= .02;
    eyelidUv.y += (uv.x*side*uv.x*side*(-length(m)+1.))*(-length(m)+1.)*1.; //"*side" remirror 
    eyelidUv.y += sin(uv.x*side+3.)*.5*(length(m));             
    float eyelid  = smoothstep(.5, .45, length(eyelidUv));         //1st circle
    eyelid += smoothstep(.5, .45, length(vec2(eyelidUv.x, eyelidUv.y+.2))) - 1.; //intersect with 2d circle
    eyelid = clamp (eyelid,0.,1.);
    
    vec4 colEyelid = vec4(.3, .3, 1., eyelid);
    
    //eyeball
    vec2 eyeballUv = uv;
    eyeballUv.y += (uv.x*side*uv.x*side*(-length(m)+1.))*(-length(m)+1.)*1.1;     //parable for happiness
    eyeballUv.y += sin(uv.x*side+3.)*1.*(length(m));             //sin for hapiness
    float eyeball = smoothstep(.5, .45, length(eyeballUv));     //1st circle
    eyeball += smoothstep(.5, .45, length(vec2(eyeballUv.x, eyeballUv.y+.2))) - 1.; //intersect with 2d circle
    eyeball = clamp (eyeball,0.,1.);
    
    vec4 col = vec4(1., .5, .5, eyeball);
    
    //iris
    if(length(m) < .3) { uv.x -= sin(uv.y*15.+time*10.)*.01; }
    if(length(m) < .14) { uv.x -= cos(uv.x*20.+time*30.)*.01; }
    
    
    vec2 irisUv = vec2( uv.x*side + .1, uv.y + .1); //"*side" for squint
    float iris = smoothstep(.40, .38, length(irisUv-m*.3));
    iris*= noise(vec3(irisUv*300., 1.));
    
    col.rgb = mix (col.rgb, vec3 (0., .0, .0), iris);
    
    iris = smoothstep(.35, .32, length(irisUv-m*.3));
    
    col.rgb = mix (col.rgb, vec3 (1., 0., .0), iris);
    
    //pupil
    float pupil = smoothstep(.6*(-length(m)+1.)*.5, .5*(-length(m)+1.)*.5, length(irisUv-m*.4));
    
    col.rgb = mix (col.rgb, vec3 (0., .0, .0), pupil);
    
    col = mix (colEyelid, col, col.a);
    
    return col;
}

vec4 Mouth (vec2 uv, vec4 head, vec2 m) {
    uv -=.5;

    vec4 col = vec4 (.0, .0, .0, 1.);
    
    float curve = (uv.x)*(uv.x)*-10.+.2;                        //smile
    curve += (uv.x*(length(m))*2.)*(uv.x*(length(m))*2.)*30.;    //angry, depend of m
    col.a = smoothstep (.2, .3, uv.y+curve) * smoothstep (.7, .6, uv.y+curve); //draw band
    col.a *= head.a;
    return col;
}

vec4 Bestiole (vec2 uv, vec2 m) {
    vec4 col = vec4 (0.);
    
    float side = sign(uv.x);//to unmirror later
    uv.x = abs(uv.x); //mirror

    vec4 head = Head(Within(uv, vec4(-.27,-.26,.27,.26)), m, 0.);
    vec4 headOutLine = Head(Within(uv, vec4(-.2,-.19,.20,.19)), m, .5);
    vec4 ear = Ear(Within(uv, vec4(-.1,-.15,.4,.26)), headOutLine, m);
        ear *= smoothstep(.7, .6, length(uv));// hide CACA of my Ear
    vec4 mouth = Mouth(Within(uv, vec4(-.3,-.24,.3,-.2)), head, m);
    vec4 eye1 = Eye(Within(uv, vec4(.02,-.01,.2,.16)), side, m);
    vec4 eye2 = Eye(Within(uv, vec4(.06,-.15,.24,.02)), side, m);
    
    col = mix(col, ear, ear.a);
    col = mix(col, head, head.a);
    col = mix(col, eye1, eye1.a);
    col = mix(col, eye2, eye2.a);
    col.w -= mouth.w;
    
    return col;
}

void main(void) {
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= .5;
    uv.x *= resolution.x/resolution.y;
    
    vec2 m = mouse*resolution.xy.xy/resolution.xy;
    m -= .5;
    uv-= m*(.15-dot(uv, uv));
    
    vec4 col = vec4 (.0,.0,.0,1.);//+noise(vec3(uv*100.,(time*12.)))-noise(vec3(uv*90.,(time*12.)));
    vec4 bestiole = Bestiole(uv, m);
    
    col = mix (col, bestiole, bestiole.a);
    glFragColor = col;
    
}
