#version 420

// original https://www.shadertoy.com/view/ssfGDB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926553589793238
// t : (start, end, inv)
vec2 ring(vec2 uv, vec3 t) {
    float id = floor(length(uv)), f = (id-t.x)/(t.y-t.x);
    return vec2((t.z == .0 ? f : 1.-f)*step(t.x, id)*(1.-step(t.y+1., id)), t.x <= id && id <= t.y);
}
vec2 mirror(vec2 uv, vec2 n) {
    return uv - n*min(2.*dot(uv, n), 0.);
}
vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d + time*.05) );
}
vec3 rnb(float t){
    return pal(t, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.33,0.67));
}
void main(void) {
    float fd = 1.0+.05*sin(time), fdd = 1.0+.005*sin(time);
    vec2 uv = (2.*gl_FragCoord.xy - resolution.xy)/resolution.x*58.;
    vec3 col = rnb(.3);
    vec3 r1 = vec3(0., 5., 0.), r2 = vec3(r1.y, r1.y + 10., 0.);
    vec3 r3 = vec3(5., r2.y-2., 0.), r4 = vec3(r3.y+.1, r3.y+1., 0.);
    vec2 r1id = ring(uv/fd, r1), r2id = ring(uv/fd, r2), r3id = ring(uv, r3), r4id = ring(uv, r4);
    vec2 p = vec2(atan(uv.y, uv.x), length(uv/fd))*vec2(1./(2.*PI), 1.);
    float leafs = 8., flr = 18.;
    float flower = flr*abs(fract(leafs*p.x-1./2.)-.5);
    float fm = smoothstep(.0, .01, flower-p.y+r2.x+1.);
    
    vec2 uv4 = mirror(abs(uv), normalize(vec2(1., -1.)));
    
    vec2 r5 = ring(uv4-vec2(16., 2.)/fd, vec3(3., 7., 0));
    vec2 r8 = ring(uv4-vec2(16., 2.)/fd, vec3(7., 8., 0));
    vec2 r6 = ring(uv4*fd, vec3(15., 21., 0));
    vec2 r7 = ring(uv4-vec2(31., 31.)*fdd, vec3(17., 23., 0));
    vec2 r9 = ring(uv4-vec2(3., 30.), vec3(31., 34., 0));
    vec2 r12 = ring(uv4-vec2(3., 30.), vec3(34., 36., 1.));
    vec2 r10 = ring(uv4-vec2(3., 30.), vec3(29., 30., 1.));
    vec2 r11 = ring(uv4-vec2(11.7, 10.)/fd, vec3(4., 8., 0.));
    vec2 r13 = ring(uv4, vec3(27., 27.1, 1.));
    vec2 r14 = ring(uv4, vec3(28., 31., 0.));
    vec2 r15 = ring(uv4, vec3(5., r2.y-1., 0.));
    
    float R = 31., Rm = smoothstep(0., 0.1, R-length(uv4));
    float m2 = step(0., dot(vec2(-sin(PI/8.), cos(PI/8.)), uv4))*Rm;
    float nm2 = step(0., dot(vec2(sin(PI/8.), -cos(PI/8.)), uv4))*Rm;
    
    col = mix(col, mix(rnb(.3)*.1, rnb(.3)+.3, r11.x), r11.y*nm2);
    col = mix(col, mix(rnb(.3)*.8, rnb(.3)*.5, r10.x), r10.y*nm2);
    col = mix(col, mix(vec3(1.), rnb(.5), r3id.x), r3id.y*nm2);
    col = mix(col, mix(vec3(1.), rnb(.3), r15.x),r15.y*m2);
    col = mix(col, rnb(.8), r4id.y*nm2);
    col = mix(col, mix(vec3(0), rnb(.5), r7.x), r7.y*m2);
    col = mix(col, rnb(.85)*r8.x, r8.y*m2);
    col = mix(col, mix(rnb(.2)*.9, rnb(.95), r6.x), r6.y*m2);
    col = mix(col, mix(vec3(0.), rnb(.86), r5.x), r5.y*m2);
    col = mix(col, mix(rnb(.3), rnb(.3)*2.1, r9.x), r9.y*nm2);
    col = mix(col, mix(rnb(.8)*.3, rnb(.8), r12.x), r12.y*nm2);
    col = mix(col, mix(rnb(.3), rnb(.5)*1.1, r14.x), r14.y);
    col = mix(col, vec3(r13.x)*rnb(.8), r13.y);
    col = mix(col, mix(rnb(.95), vec3(1.), r2id.x), fm);
    col = mix(col, mix(vec3(1.), rnb(.3), r1id.x), r1id.y);
    glFragColor = vec4(col,1.0);
}
