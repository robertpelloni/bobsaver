#version 420

// original https://www.shadertoy.com/view/3ljyDW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float box(vec2 uv, float r, float t){
    float m = (step(r,abs(uv.x)))*.5-step(abs(uv.y),.5-r-t);
    m = max(m,(step(r,abs(uv.y)))*.5);
    m += (step(r+t,abs(uv.x)))-step(abs(uv.y),.5-r-t/4.);
    m = max(m,(step(r+t,abs(uv.y))));
    float p = (step(r,abs(uv.x))-step(r+t,abs(uv.x))-step(abs(uv.y),r+t))/2.;
    if (p>0.) m -= .5;
    return m;
}
float cros(vec2 uv, float r, float t){
    float m = step(abs(uv.x),r+t)*0.5;
    m = max(m,step(abs(uv.y),r+t)*0.5);
    m += step(abs(uv.x),r);
    m = max(m,step(abs(uv.y),r)-step(abs(uv.x),r+t));
    
    
    
    return m;
}

void main(void)
{
    
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    uv.y += cos(uv.y*3.+uv.x*4.+time*2.)*.05;
    float a = 3.142/4.;  
    uv = uv*mat2(cos(a),-sin(a),sin(a),cos(a));
    
    uv = fract(uv * 5.)-.5;
    vec3 col = vec3(0.);
    
    float m = cros(uv,.15,.04);
    col += m;
    m = box(uv,.3,.04);
    
    if (m>0.) col = vec3(m);
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
