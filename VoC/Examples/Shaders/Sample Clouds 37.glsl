#version 420

// original https://www.shadertoy.com/view/wddGD4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

highp float rand( highp vec2 n) { 
    return fract(sin(dot(n, vec2(0.360,0.690))) * 1001.585);
}

highp float noise(highp vec2 p){
    highp vec2 ip = floor(p);
    highp vec2 u = fract(p);
    u = u*u*(3.0-2.0*u);
    
    highp float res = mix(
        mix(rand(ip),rand(ip+vec2(1.0,0.0)),u.x),
        mix(rand(ip+vec2(0.0,1.0)),rand(ip+vec2(1.0,1.0)),u.x),u.y);
    return res*res;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    highp vec3 color = vec3(0., 0., 1.);
    
    highp float speed = time * .35;
    const int n = 15;
    
    highp float awan = 0.;
    highp float d = 1.400;
    highp vec2 pos = uv*3.1;
    for(int i = 0; i < n; i++){
        awan += noise(pos) / d;
        pos *= 2.040;
        d *= 2.064;
        pos -= speed * 0.127 * pow(d, 0.9);
    }
    
    color += pow(abs(awan), 2.604);

    // Output to screen
    glFragColor = vec4(color,1.0);
}
