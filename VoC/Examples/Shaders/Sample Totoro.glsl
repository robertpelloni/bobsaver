#version 420

// original https://www.shadertoy.com/view/MsKGWt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by David Bargo - davidbargo/2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

float circle(vec2 pos, float radius, float width)
{
    return abs(length(pos)-radius)-width;   
}

//-----------------------------------------------------------------
// From Maarten
float circleFill(vec2 pos, float radius)
{
    return length(pos)-radius;   
}

float smoothMerge(float d1, float d2, float k)
{
    float h = clamp(0.5 + 0.5*(d2 - d1)/k, 0.0, 1.0);
    return mix(d2, d1, h) - k * h * (1.0-h);
}

float line(vec2 p, vec2 start, vec2 end, float width)
{
    vec2 dir = start - end;
    float lngth = length(dir);
    dir /= lngth;
    vec2 proj = max(0.0, min(lngth, dot((start - p), dir)))*dir;
    return length( (start - p) - proj ) - (width / 2.0);
}

float fillMask(float dist)
{
    return clamp(-(dist+0.01)*100.0, 0.0, 1.0);
}

float innerBorderMask(float dist, float width)
{
    float alpha1 = clamp(dist + width, 0.0, 1.0);
    float alpha2 = clamp(dist, 0.0, 1.0);
    return alpha1 - alpha2;
}
//-----------------------------------------------------------------

void main(void)
{
    vec2 uv = gl_FragCoord.xy /resolution.xy;
    vec2 p = -1. + 2.*uv;
    p.x *= resolution.x / resolution.y;
    
    // animation
    float time = mod(time, 11.5);
    float heyes = smoothstep(0.1, 0.9, time);
    heyes = mix(heyes, -1.12, smoothstep(1.2, 2.6, time));
    heyes *= 1. - smoothstep(3.16, 3.7, time);
    float veyes = -0.2*smoothstep(0.2, 0.9, time);
    veyes = mix(veyes, -0.1, smoothstep(1.2, 1.9, time));
    veyes = mix(veyes, -0.2, smoothstep(1.9, 2.6, time));
    veyes = mix(veyes, 1., smoothstep(2.7, 3.7, time));
    veyes *= 1. - smoothstep(4.3, 5.3, time);
    float smile = smoothstep(5.1, 6.7, time);
    smile *= 1. - smoothstep(9., 11., time);
    
    // bg
    uv -= vec2(0.5, 0.55);
    uv *= 1.6;
    float f = length(uv);
    vec3 col = mix(vec3(0.65,0.5, 0.6), vec3(0.1,0.15,0.2), f);
    
    p *= 200.;
    vec2 p2 = p;
    p2.x = abs(p2.x);
    
    // eyes
    float d = circleFill((p2 + vec2(-125, -58))+50.*dot(uv, uv), 38.);
    
    // mouth
    float d2 = circleFill(p+vec2(0., -230.+smile*65.), 250.);  
    d2 = max(d2, circleFill(p2+vec2(28.*smile, 868.-smile*28.), 850.));   
    d = min(d, d2);
    col = mix(col, vec3(1, 1, 0.97), fillMask(d));
    col = mix(col, vec3(0.1), innerBorderMask(d, 2.));
    
    // pupils
    d = circleFill(vec2(abs(p.x + 13.*heyes)-121.,p.y -50.-18.*veyes), 15.);
    
    // teeth
    float td = 8.;
    float d3 = circle(vec2(abs(p.x + td)+368.,p.y+34.), 400., 0.5);
    d3 = min(d3, circle(vec2(abs(p.x + td)+152.,p.y+36.), 240., 0.5));
    d3 = min(d3, circle(vec2(abs(p.x + td)-56.,p.y+30.), 80., 0.5));
    d2 = max(d2, d3);
    d = min(d, d2);
    
    // whiskers
    d = min(d, line(p2, vec2(135.+smile*40.,  -5.+smile*10.), vec2(230.+smile*40., smile*40.), 1.));
    d = min(d, line(p2, vec2(140.+smile*50.,-20.+smile*10.), vec2(245.+smile*50.,-35.+smile*40.), 1.));
    d = min(d, line(p2, vec2(140.+smile*60.,-35.+smile*10.), vec2(250.+smile*50.,-70.+smile*30.), 1.));
    
    // nose
    d2 = circleFill(p*vec2(1.0, 4.0+0.004*p2.x) + vec2(0, -120. -smile*4.*10.), 40.);
    d3 = circleFill(p + vec2(0, -24.-smile*10.), 12.);   
    d2 = smoothMerge(d2, d3, 20.);
    d = min(d, d2);
    col = mix(col, vec3(0.1), fillMask(d));
    col = mix(col, vec3(0.1), innerBorderMask(d, 2.));
    
    // eye reflections
    d = circleFill(vec2(abs(p.x + 6. + 11.*heyes)-121.,p.y -56.- 16.*veyes), 4.5);
    d = min(d, circleFill(vec2(abs(p.x + 5.5 + 11.*heyes)-121.,p.y -49.- 16.*veyes),3.));   
    col = mix(col, vec3(1), fillMask(d));
    col = mix(col, vec3(0.1), innerBorderMask(d, 2.));
    
    glFragColor = vec4(col, 1.0);
}
