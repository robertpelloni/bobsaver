#version 420

// original https://www.shadertoy.com/view/3tXXRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float bigsize = .8;
const float smallsize = .09;
const float span = .1;

const float PI = 3.14159;
const float PI2 = PI*2.;

mat2 rot2D(float r){
    return mat2(cos(r), sin(r), -sin(r), cos(r));
}
float nsin(float x) {
    return cos(x)*.5+.5;
}
vec3 hash32(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+19.19);
    return fract((p3.xxy+p3.yzz)*p3.zyx);
}
float opUnion( float d1, float d2 ) { return min(d1,d2); }
float opSubtraction( float d1, float d2 ) { return max(-d1,d2); }

float sdShape(vec2 p, float r) {
    return length(p+r*.5)-r;
}
void egg(inout vec2 sd, vec2 uv, float t, float r, float a) {
    if (r <= 0.) return;
    float yolk = sdShape((11./sqrt(2.))*uv*rot2D(a), r);
    float white = sdShape((5.2/sqrt(2.))*uv*rot2D(a), r);
    sd = vec2(opUnion(sd.x, white),
              opUnion(sd.y, yolk));
}

// invisible dots creating some kind of underlying disturbance
float under(vec2 N, float t) {
    const float sz = .001;
    const float range = 1.8;
    vec2 p1 = vec2(sin(-t*1.6666), cos(t)) * range;
    vec2 p2 = vec2(sin(t), sin(t*1.3333)) * range;
    float b = min(length(p1-N)-sz, length(p2-N)-sz);
    return b;
}

void smallEggField(inout vec2 sd, vec2 uv, vec2 uvbig, float t) {
    vec2 uvsmall = mod(uv+vec2(t*.3,0),span)-span*.5;// uv within small scroll period
    vec2 uvsmall_q = (uv-uvsmall);// uv of scrolling small egg field
    vec2 sdquant = vec2(1e6);
    // find the dist to the big egg, quantizing big egg's coords to small egg coords
    egg(sdquant, uvsmall_q, t, bigsize, under(uvsmall_q, t));
    egg(sd,uvsmall, t, smallsize * smoothstep(0.,.8,sdquant.x - .5), under(uvbig*10., t));
}

vec3 color(vec2 sd, float fact) {
    vec3 o;
    o.rgb = 1.-smoothstep(vec3(0),fact*vec3(.06,.03,.02), vec3(sd.x));
    o.rgb *= vec3(.9,.7,.7)*.8;
    o.g += .05;
    if (sd.x < 0.) o -= sd.x*.6;
    o = clamp(o,o-o,o-o+1.);
    
    vec3 ayolk = 1.-smoothstep(vec3(0),fact*vec3(.2,.1,.2),sd.yyy);
    o.rgb = mix(o.rgb, vec3(.5,.5,0), ayolk);
    if (sd.y < 0.) o -= sd.y*.1;
    o = clamp(o,o-o,o-o+1.);
    return o;
}

void main(void) //WARNING - variables void ( out vec4 o, in vec2 gl_FragCoord.xy ) need changing to glFragColor and gl_FragCoord
{
    vec4 o = glFragColor;

    vec2 uv = gl_FragCoord.xy/resolution.xy-.5;
    vec2 N = uv;
    uv.x *= resolution.x / resolution.y;
    float t = time;
    uv.y -= .1;
    vec2 sd = vec2(1e6);

    vec2 uvbig = uv;// uv of the big egg and disturbance layer both

    // big egg
    egg(sd, uv, t, bigsize, under(uvbig, t));

    // small eggs
    vec2 sdsmall = vec2(1e6);
    smallEggField(sdsmall, uv, uvbig, t);
    uv -= span * .5;
    smallEggField(sdsmall, uv, uvbig, t);

    o.rgb = mix(color(sd, 2.), color(sdsmall, .2), vec3(step(.1,sd.x)));

    o = pow(o, o-o+.5);
    o.rgb += (hash32(gl_FragCoord.xy+time)-.5)*.1;
    o = clamp(o,o-o,o-o+1.);
    o *= 1.-length(13.*pow(abs(N), vec2(4.)));// vingette
    o.a = 1.;

    glFragColor = o;
}

