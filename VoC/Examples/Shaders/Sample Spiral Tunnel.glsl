#version 420

// original https://www.shadertoy.com/view/cdc3RX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float noise(uint i){
    i ^= i * 314159265u;
    return float(i)/4294967296.;
}

mat2 rot(float th){
    return mat2(cos(th),sin(th),-sin(th),cos(th));
}

void main(void)
{
    uint n_iter=8u;
    float s=0.;
    for(uint k=0u;k<n_iter;k++){
        float t = time + 0.003 * float(k);
        float th = 0.1*t;
        float a = 0.4+0.3*mod(floor(t*0.1/6.2832), 3.0);    
        vec2 p = (2.0 * gl_FragCoord.xy - resolution.xy) / min(resolution.x, resolution.y);
        for (int i=0;i<100;++i){
            p.x += a * abs(p.y) - 0.3;
            p *= rot(th);
        }
        s += step(p.y,0.0);
    }
    s /= float(n_iter);
    glFragColor = vec4(vec3(s),1);
}
