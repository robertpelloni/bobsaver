#version 420

// original https://www.shadertoy.com/view/NtfSWH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void drawRectangle(vec2 pos, vec2 e1, vec2 e2, float border_width, 
                    vec4 border_color, vec4 fill_color, inout vec4 color)
{
    
    float scr_ratio = resolution.y / resolution.x;
    
    float exmax = max(e1.x, e2.x);
    float exmin = min(e1.x, e2.x);
    float eymax = max(e1.y, e2.y);
    float eymin = min(e1.y, e2.y);
    
    
    if ( pos.x >= exmin - border_width / 2. * scr_ratio &&
         pos.x <= exmax + border_width / 2. * scr_ratio && 
         pos.y >= eymin - border_width / 2. && 
         pos.y <= eymax + border_width / 2.)
    {
        if ( pos.x > exmin - border_width / 2. * scr_ratio && pos.x < exmin + border_width / 2. * scr_ratio || 
             pos.x > exmax - border_width / 2. * scr_ratio && pos.x < exmax + border_width / 2. * scr_ratio ||
             pos.y > eymin - border_width / 2. && pos.y < eymin + border_width / 2. || 
             pos.y > eymax - border_width / 2. && pos.y < eymax + border_width / 2.)
        {
            color = border_color;
        }
        else color = fill_color;
    }
}

void main(void)
{
    float scr_ratio = resolution.y / resolution.x;
    float b_w = 0.02;
    
    vec4 mn_w = vec4(vec3(249.) / 255.0, 1.);
    vec4 mn_y = vec4(vec3(255., 240., 1.) / 255.0, 1.);
    vec4 mn_b = vec4(vec3(1., 1., 253.) / 255.0, 1.);
    vec4 mn_r = vec4(vec3(255., 1., 1.) / 255.0, 1.);
    vec4 mn_g = vec4(vec3(48., 48., 58.) / 255.0, 1.);
    

    float width = 0.1;
    vec2 st = gl_FragCoord.xy/resolution.xy;
    
    vec2 p1 = vec2((sin(time) / 4.0 + 0.5) * scr_ratio, (cos(time) / 4.0 + 0.5));
    vec2 p2 = vec2(0.0,p1.y);
    vec2 p3 = vec2((cos(3. * time) / 6.0 + 0.5) * p1.x, 1.0);
    vec2 p4 = vec2(cos(2. * time) / 8.0 + 0.8, sin(time + 1.) / 4.0 + 0.5); 
    vec2 p5 = vec2(mix(p1.x, p4.x, 0.5), max(p1.y, p4.y));
    vec2 p6 = vec2(1.0, mix(p5.y, p3.y, 0.3));
    vec2 p7 = vec2(p5.x, min(p4.y, p5.y));
    vec2 p8 = vec2(p5.x, p6.y);
    vec2 p9 = vec2(mix(p5.x, 1.0, 0.5 + cos(time +2.) / 4.), 1.);
    
    vec4 color = vec4(1.);
    
    drawRectangle(st, vec2(0.0, 0.0), p1, b_w, mn_g, mn_y, color);
    drawRectangle(st, vec2(0.0, p1.y / 3.0), p1, b_w, mn_g, mn_w, color); 
    drawRectangle(st, p2, p3, b_w, mn_g, mn_b, color);
    drawRectangle(st, vec2(p1.x, 0.0), p4, b_w, mn_g, mn_w, color);
    drawRectangle(st, vec2(mix(p1.x, p4.x, 0.7), 0.0), p4, b_w, mn_g, mn_r, color);
    drawRectangle(st, vec2(p1.x, 0.0), vec2(mix(p1.x, p4.x, 0.7), 2. * p4.y / 3. * (cos(2. * time + 2.) / 3. + 0.6666)), b_w, mn_g, mn_b, color);
    drawRectangle(st, p5, p3, b_w, mn_g, mn_w, color);
    drawRectangle(st, vec2(p3.x, p1.y), vec2(p1.x, p5.y), b_w, mn_g, mn_r, color);
    drawRectangle(st, p6, p7, b_w, mn_g, mn_w, color);
    drawRectangle(st, p7, vec2(p1.x, max(p1.y, p4.y)), b_w, mn_g, mn_y, color);
    drawRectangle(st, p8, p9, b_w, mn_g, mn_y, color);
    drawRectangle(st, vec2(p9.x, p6.y), vec2(1.), b_w, mn_g, mn_w, color);
    drawRectangle(st, p4, vec2(1., p4.y / 2.), b_w, mn_g, mn_b, color);
    drawRectangle(st, vec2(p4.x, p4.y / 2.), vec2(1., 0.), b_w, mn_g, mn_w, color);
    
    glFragColor = vec4(color);
}
