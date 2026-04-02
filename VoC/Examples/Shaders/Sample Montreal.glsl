#version 420

// original https://www.shadertoy.com/view/ws3SDs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define time time

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy-0.5)/resolution.xy;
    float x = uv.x;
    float y = uv.y;
    
    // Screen adaptation from shadergif to shadertoy
    float ratio = resolution.y / resolution.x;
    vec2 p = uv - 0.5;
    p *= 0.8;
    p.x -= 0.03; // Tweak city positioon
    p.x /= ratio;
    
    vec4 col = vec4(0.0);

    #define _c(x) clamp(x,0.0,1.0)
    #define _s(x,f) (floor(x*f)/f)
    float h = 0.0;
    
    float reflection = 0.0;
    
    vec2 real_p = p;
    // reflection hack
    if(p.y < -0.26){
        reflection += 1.0;
        p.y = -p.y - 0.5;
        p.x += 0.002 * cos(pow(p.y-0.4,1.0) * 40.0 + time * 6.2832);
    }
    
    // Mountain
    float m = 0.05 * cos(p.x * 5.0 + 3.2) + 0.2;
    m += 0.0006 * cos(p.x * 200.0);
    m += 0.01 * cos(p.x * 24.0 + 2.4);
    m = 1.0 - _c((p.y + m)/0.004);
    col.rgba = vec4(0.2,0.3,0.3,1.0) * m + col.rgba * (1.0-m);
    
    // 1000 gauchetiere
    float i = 0.17;
    float g = _c((p.x-i)/0.004);
    g *= 1.0-_c((p.x-i-0.024)/0.004);
    g *= 1.0-_c((p.y+0.13 + (abs(p.x-i-0.014)))/0.004);
    g = _c(g);
    
    // Place Ville-Marie
    float v = _c(p.x - 0.3)/0.003;
    v *= _c(1.0-(p.y + 0.135)/0.003);
    v *= 1.0-_c(p.x - 0.34)/0.003;
    
    m = _c(v+m+g);
    
    h = 0.01 * _s(cos(p.x*3.0+2.3), 4.0);
    h += (h + 0.3) * 0.1 * _s(cos(p.x*10.0-0.1), 2.0);
    h += h * 0.3 * _s(cos(p.x*22.0+1.0), 2.0);
    h += h * 0.2 * _s(cos(p.x*24.0+2.1), 2.0);
    float sky = _c((p.y + 0.2 + h)/0.01);
    vec4 _sky = sky * vec4(0.4 - p.y * 0.4,0.2 - p.y * 0.4,0.2+p.y * 0.2,1.0);
    col = _sky * (1.0 - m);
    
    
    
    float city = _c(1.0 - sky + v + g);
    float windows = city;
    
    windows *= _c((cos(p.x * 1000.0 + h * 1e4 + cos(h * 40.0)*1e3) - 0.4));
    windows *= _c((cos(p.y * (500.0+cos(h*30.0)*1100.0)+h*1e2) - 0.1));
    windows *= 0.7 + 0.8 *cos(p.x * 10.0 + h * 100.0 + m * 2.0+ v * 2.0 + (p.y * 400.0 * v + g) + 0.3 * cos(time * 6.2832 + p.x * 10.0));
    windows *= 1.0 + 0.3 * cos(time * 6.2832 + p.x * 3e3);
    windows *= 1.0 + 0.3 * cos(time * 6.2832 + p.y * 3e6+ h * 10.0);
    windows *= (p.y + 0.24)/0.02;
    
    col.rg += vec2(0.8,0.4) * windows;
    
    // Left part city
    float glow = 1.2 * _c(1.0 - pow(2.0 * length(p - vec2(-0.3,-0.4)), 0.4));
    // right part city
    glow += 1.2 *_c(1.0 - pow(2.0 * length(p - vec2(0.2,-0.4)), 0.4));
    // sun
    glow += _c(1.0 - pow(1.1 * length(p - vec2(-0.5,-0.5)), 0.4));
    
    col.rg += vec2(0.6,0.4) * sky * glow;
    
    // Place ville-marie beacon
    vec2 bp = p;
    bp += vec2(-0.32,0.13);
    vec2 polar = vec2(atan(bp.y,bp.x), length(bp));
    polar.x += time * 8.0- 1.0;
    bp = polar.y * vec2(cos(polar.x), sin(polar.x));
    
    float b = 1.0-abs(bp.x) / 0.01;
    b *= _c(1.0 - abs(bp.x) / 0.01);
    b *= 1.0 - _c(bp.y / 0.3);
    b *= _c(bp.y / 0.005);
    b = _c(b);
    b *= _c(1.0-cos(time * 14.0 + 2.9));
    b = (time > 0.3)? 0.0:b;
    col.rgb += b * 0.09;
    
    // Autoroute bonaventure
    float a = 0.0;
    a = 1.0-(abs(p.y+0.24+cos(p.x * 4.0+1.0)*0.01))/0.005;
    a *= _c((-p.x+0.2)/0.1);
    a = _c(a);
    // red lights
    col.r += pow(a,1.9) * _c(cos(p.x * 200.0 + time * 6.2832) * cos(p.x * 30.0) * cos(p.x * 3.0)) * 2.9;
    // white lights
    col.rgb += a * _c(cos(p.x * 400.0 - time * 6.2832) * cos(p.x * 30.0) * cos(p.x * 3.0)) * 0.8;
    
    // Tweak reflection color
    col -= reflection * 0.04;
    col.g += reflection * 0.1;
    col.b += reflection * 0.1;
    col += reflection * 0.01 * cos(0.2 * cos(p.x*30.0) + p.y * 400.0 + time * 6.2832);
    
    col = _c(col);
    
    col += 0.025; // Instagram "fade"
    col = pow(0.7 * col, vec4(1.3)); // Contrast tweak
    col *= 1.0 - pow(1.6 * length(real_p), 2.0); // instagram vignette
    col.rgb += vec3(-0.1,0.0,0.00);
    col.a = 1.0;
    col.b *= 1.1;
    col = _c(col);

    

    // Output to screen
    glFragColor = col;
}
