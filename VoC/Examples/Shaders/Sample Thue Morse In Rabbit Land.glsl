#version 420

// original https://www.shadertoy.com/view/ll2GDw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU 6.283
float color(vec2 dv)
{
    float phi = atan(dv.y, dv.x);
    float t = time * 2.;
    float scale = 0.5;
    float ll = log(length(dv));
    float p1 = mod(ll + phi + t + TAU*1./8., TAU) - TAU/2.;
    float p2 = mod(ll + phi + t + TAU*2./8., TAU) - TAU/2.;
    float p3 = mod(ll + phi + t, TAU) - TAU/2.;
    float p4 = mod(-ll + phi + TAU*1./8., TAU) - TAU/2.;
    float p5 = mod(-ll + phi + TAU*2./8., TAU) - TAU/2.;
    float p6 = mod(-ll + phi, TAU) - TAU/2.;
    float sgn = sign(p1) * sign(p2) * sign(p3) * sign(p4) * sign(p5) * sign(p6);
    return step(0., sgn);
}
void main(void)
{
    vec2 center = resolution.xy / 2.;
    vec2 dv = gl_FragCoord.xy - center;
    dv.y *= resolution.x / resolution.y; // fix aspect
//    glFragColor = vec4(1.,1.,1.,1.) * color(dv);
//    return;
    // 3x3 aa
    float sum = 0.;
    sum += color(dv + vec2(-.33,-.33));
    sum += color(dv + vec2(-.33,0.));
    sum += color(dv + vec2(.33,.33));
    sum += color(dv + vec2(0.,-.33));
    sum += color(dv + vec2(0.,0.));
    sum += color(dv + vec2(0.,.33));
    sum += color(dv + vec2(.33,-.33));
    sum += color(dv + vec2(.33,0.));
    sum += color(dv + vec2(.33,.33));
    glFragColor = vec4(1.,1.,1.,1.) * sum / 9.;
}
