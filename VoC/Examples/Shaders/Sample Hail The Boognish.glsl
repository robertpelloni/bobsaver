#version 420

// original https://www.shadertoy.com/view/wdjBRc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// A tribute to Ween //
// By Plento

#define R resolution.xy
#define ss(a, b, t) smoothstep(a, b, t)

float line( in vec2 p, in vec2 a, in vec2 b ){
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}
float box( in vec2 p, in vec2 b ){
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float dist(vec2 uv){
    float d = 999.;
    uv.y += .07;
    
    vec2 p0 = vec2(uv.x*.9+sin(uv.y*1.)*.2, .88*uv.y-pow(uv.x, 2.)); // hair
    vec2 p1 = vec2((uv.x-.004)*.813+cos(uv.y*15.)*.01,uv.y+sin(uv.x*15.)*.01)-vec2(0.,-.15); // head
    vec2 p3 = vec2(abs(uv.x)-.16, uv.y+cos(uv.x*32. + 2.)*.008); // eyes
    vec2 p4 = uv-vec2(0., -.48+exp(-uv.x*uv.x)*.3); // mouth
    
    float hair = abs(length(p0)- (.45-abs(cos(atan(uv.y, uv.x)*7.))*.16))-.02;
    hair = max(hair, -(length(vec2(uv.x*.4, uv.y-.04)-vec2(0., -.5))-.51));
    
    d = min(abs(length(p1)-.29)-.0086, hair); // head
    d = min(d, min(abs(length(p3)-.03)-.0002,abs(length(p3)-.001)-.001)); // eyes
    d = min(d, abs(box(p4, vec2(.26, .12))) - 0.001); // mouth
    
    float teeth = 999.;
    for(float i = 0.; i < 10.;i++){
         teeth = min(teeth, line(uv, vec2(-.25+i*.05+sin(i*2.)*.01, -.5), 
                                vec2(-.25+i*.05+cos(i*5.)*.016, .5)));}
    teeth = max(teeth, box(p4, vec2(.26, .12)));
   
    return min(d, teeth);
}

void main(void) {
    vec2 u = gl_FragCoord.xy;
    
    vec2 uv = 1.3*vec2(u.xy - .5*R.xy)/R.y;
    uv*=1.-pow(cos(length(uv*8.) + time)*0.2, 2.);
    
    vec3 col = vec3(0);
    
    float d = dist(uv);
    float thk = .008;
    
    col += .6+.32*cos(vec3(.5, .2, .4)*d*80.-time*2.+vec3(4.7, 0., 2.));
    col *= ss(thk, thk+.006, d);
    
    col *= ss(1.55, .1, length(uv));
    glFragColor = vec4(col, 1.);
}
