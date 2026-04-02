#version 420

// original https://www.shadertoy.com/view/7tK3DW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sdEquilateralTriangle( in vec2 p )
{
    const float k = sqrt(3.0);
    p.x = abs(p.x) - 1.0;
    p.y = p.y + 1.0/k;
    if( p.x+k*p.y>0.0 ) p = vec2(p.x-k*p.y,-k*p.x-p.y)/2.0;
    p.x -= clamp( p.x, -2.0, 0.0 );
    return -length(p)*sign(p.y);
}

float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float thc(float a, float b) {
    return tanh(a * cos(b)) / tanh(a);
}

float ths(float a, float b) {
    return tanh(a * sin(b)) / tanh(a);
}

float arrow(vec2 uv) {
    float h = 0.1;
    h += 0.2 * thc(4.,-40. * length(uv) + 3. * atan(uv.y,uv.x) + time);
    h += 0.5 * (0.5 + 0.5 * thc(2., length(uv)*3. - time));
    float d = sdEquilateralTriangle(uv-vec2(0.,0.25 - h));
    float s = 1.-smoothstep(-0.4,0.4,d+0.5);

    float d2 = sdBox(uv - vec2(0.,-h), vec2(0.05,0.2));
    float s2 = 1.-smoothstep(-0.4,0.4,d2);
    
    s += s2;
    return s;
}

vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

float h21 (vec2 a) {
    return fract(sin(dot(a.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

vec2 rot(vec2 uv, float a) {
    mat2 mat = mat2(cos(a), -sin(a), 
                    sin(a), cos(a));
    return mat * uv;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    
    float a = atan(uv.y, uv.x);
    float r = log(length(uv));
    
    float l = min(1., tanh(0.2 * time)/0.95);
    // 30000000. * a
    r *= 0.6 + 0.25 * l * thc(1., 3. * a + 2. * length(uv) - time);

    //float h = floor(8. * fract(0.1 * time)); // do h * a
    uv = rot(uv, time +  7. * a + 3.1415 * cos(9. * r + a - time));

    float s = arrow(uv);
    s *= 1. + 0.3 * s;

    vec3 col = 0.5 * s + s * pal(thc(2., s + 9. * r + a- time)  - 0.5 * time, vec3(1.), vec3(1.), vec3(1.), cos(s + time) * vec3(0.,1.,2.)/3.);
    //col *= smoothstep(0.,0.1,0.5-length(uv));
    col = mix(col, vec3(1, .97, .92)*2., smoothstep(0., 3.5, -r));
    glFragColor = vec4(col,1.0);
}
