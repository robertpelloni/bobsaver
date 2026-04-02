#version 420

// original https://www.shadertoy.com/view/wldcRH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define sat(x) clamp(x, 0.0, 1.0)
const float PI = 3.1415926;

float RemapSinple(float t1, float t2, float x)
{
    return sat((x-t1)/ (t2-t1));
}

float Remap(float t1, float t2, float s1, float s2, float x)
{
    return sat((x-t1)/ (t2-t1)* (s2-s1)+ s1);
}

vec2 RectangleboxRemap(vec2 uv, vec4 rect)
{
    //x=left boundary, y=top boundary, z=x scale, w=y scale
    return (uv-rect.xy)/ (rect.zw-rect.xy);
}

vec4 Head(vec2 uv, float t)
{
    //Base Color
    vec4 col = vec4(mix(vec3(0.9333, 0.6431, 0.2118), vec3(0.9529, 0.0667, 0.0667), t), 1.0);
    float d = length(uv);
    col.a = smoothstep(0.5, 0.49, d);
    
    //Edge Darken
    float edgeval = RemapSinple(0.35, 0.5, d);
    edgeval *= edgeval;
    col.rgb *= 1.0- edgeval* 0.5;
    
    //Outline
    col.rgb = mix(col.rgb, mix(vec3(1.0, 0.6, 0.0), vec3(0.9, 0.0667, 0.0667), t), smoothstep(0.48, 0.5, d));
    
    //Highlight
    float highlight = smoothstep(0.4, 0.39, d);
    highlight *= Remap(0.4, -0.1, 0.75, 0.0, uv.y);
    highlight *= smoothstep(0.18, 0.19, length((uv-vec2(0.21, 0.1))));
    col.rgb = mix(col.rgb, vec3(1.0), highlight);
    
    //Cheek
    d = length(uv- vec2(0.25, -0.2));
    float cheek = smoothstep(0.2, 0.01, d);
    col.rgb = mix(col.rgb, mix(vec3(0.9216, 0.3451, 0.6627), vec3(0.9529, 0.4667, 0.0667), t), cheek);
    
    return col;    
}

vec4 Eye(vec2 uv, float side, vec2 m, float t)
{
    uv -= 0.5;
    uv.x *= side;
    
    //Base Color
    vec4 col = vec4(1.0);
    float d = length(uv);
    col.a *= smoothstep(0.5, 0.48, d);
    
    //Eye White
    vec3 eyewhite = vec3(0.1647, 0.6039, 0.6588);
    col.rgb = mix(col.rgb, eyewhite, smoothstep(0.1, 0.7, d));
    col.rgb *= 1.0- smoothstep(0.45, 0.5, d)* 0.5* sat(-uv.y-uv.x*side);        
    
    //Pupil
    d = length(uv-m*0.45);
    col.rgb = mix(col.rgb, vec3(0.0), smoothstep(0.3, 0.28, d));
    eyewhite *= 1.0+ smoothstep(0.28, 0.02, d);
    float eyemask = smoothstep(0.28, 0.25, d);
    col.rgb = mix(col.rgb, eyewhite, eyemask);
    
    d = length(uv-m*0.6);
    float pupilsize = mix(0.4, 0.16, t);
    col.rgb = mix(col.rgb, vec3(0.0), smoothstep(pupilsize, pupilsize*0.85, d)* eyemask);
    
    //Highlight
    float t2 = time* 3.0;
    vec2 offset = vec2(sin(uv.x* 25.0+ t2), sin(uv.y* 25.0+ t2));
    offset *= 0.01*(1.0-t);
    uv += offset;
    
    float highlight = smoothstep(0.1, 0.09, length((uv-vec2(-0.15, 0.15))));
    highlight += smoothstep(0.07, 0.06, length((uv+vec2(-0.08, 0.08))));
    col.rgb = mix(col.rgb, vec3(1.0), highlight);
    
    return col;
}

vec4 Mouth(vec2 uv, float t)
{
    uv -= 0.5;
    
    //Base Color
    vec4 col = vec4(0.502, 0.2196, 0.149, 1.0);
    float d = length(uv);
    
    //Teeth Shape Origin
    vec2 toptuv = uv;   
    toptuv.x *= mix(3.0, 1.0, t);
    toptuv.y += abs(toptuv.x)* 0.5* (1.0-t);
    float topteeth = length(toptuv- vec2(0.0, mix(0.6, 0.4, t)));
    float buttomteeth = length(uv+ vec2(0.0, mix(1.0 ,0.6, t)));
    
    
    //Mouth Shape and Color
    uv.y *= 1.5;
    uv.y += uv.x* uv.x* 2.5* t;
    uv.x *= mix(2.5, 1.0, t);
    d = length(uv);    
    col.a *= smoothstep(0.5, 0.48, d);
    
    //Tongue Shape
    float tongue = length(uv+ vec2(0.0, mix(0.5, 1.0, t)));
    
    //Teeth and Tongue Color
    vec3 teethcol = vec3(1.0) * smoothstep(0.6, 0.35, d);
    col.rgb = mix(col.rgb, vec3(0.9255, 0.549, 0.8118), smoothstep(0.5, 0.2, tongue));
    col.rgb = mix(col.rgb, teethcol, smoothstep(0.5, 0.48, topteeth));
    col.rgb = mix(col.rgb, teethcol, smoothstep(0.5, 0.48, buttomteeth));
    
    
    return col;
}

vec4 Brow(vec2 uv, float t)
{
    //Warp the Shape
    uv.y += uv.x* mix(0.5, -0.8, t)+ 0.03;
    uv.x += mix(-0.05, 0.15, t);
    uv -= 0.5;
    
    //Brow Shape
    vec4 col = vec4(0.0);
    float d1 = length(uv);
    float s1 = smoothstep(0.4, 0.3, d1);
    float d2 = length(uv+ vec2(0.1, mix(-0.2, 0.2, t))* 0.7);
    float s2 = smoothstep(0.4, 0.3, d2);
    float browmask = sat(s2-s1);
    
    //Brow Color
    float browhighlight = smoothstep(0.45, mix(0.0, 0.35, t), length(uv));
    vec4 browcol = mix(vec4(0.0), vec4(0.5137, 0.2078, 0.0039, 1.0), browmask);
    browcol.rgb = mix(browcol.rgb, vec3(1.0, 0.0667, 0.0), browhighlight);
    
    //Brow Shadow
    float shadowblur = mix(0.3, 0.1, t);
    uv.y += mix(0.15, 0.0, t);
    d1 = length(uv);
    s1 = smoothstep(0.4, 0.4-shadowblur, d1);
    d2 = length(uv+ vec2(0.1, mix(-0.2, 0.2, t))* 0.7);
    s2 = smoothstep(0.4, 0.4-shadowblur, d2);    
    float shadowmask = sat(s2-s1);
    col = mix(vec4(0.0), vec4(vec3(0.0), 1.0), smoothstep(0.0, 1.0, shadowmask)* 0.5);
    
    col = mix(col, browcol, smoothstep(0.45, 0.65, browmask));
    
    return col;
}

vec4 Face(vec2 uv, vec2 m, float t)
{
    vec4 col = vec4(0.0);
    float side = sign(uv.x);
    uv.x = abs(uv.x);
    
    vec4 head = Head(uv, t);
    vec4 eye = Eye(RectangleboxRemap(uv, vec4(0.03, -0.1, 0.4, 0.25)), side, m, t);
    vec4 mouth = Mouth(RectangleboxRemap(uv, vec4(-0.3, -0.4, 0.3, -0.1)), t);
    vec4 brow = Brow(RectangleboxRemap(uv, vec4(0.03, 0.2, 0.4, 0.45)), t);
    col = mix(col, head, head.a);
    col = mix(col, eye, eye.a);
    col = mix(col, mouth, mouth.a);
    col = mix(col, brow, brow.a);
    
    return col;

}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    uv -= 0.5;
    uv.x *= resolution.x/ resolution.y;
    
    //Time -> [0.0, 1.0]
    float t = sin(time- PI/2.0)* 0.5+ 0.5;
    
    //Normalize Mouse
    vec2 m = mouse*resolution.xy.xy/ resolution.xy;
    m -= 0.5;
    
    //Animate the shader when the mouse hasn't been used
    if (m.x < -0.49 && m.y < -0.49)
    {
        m = vec2(t-0.5, 0.0);           
    }
    
    //back to origin when exit fullscreen
    if (length(m) > 0.707) m*= 0.0;
    
    uv += m* (dot(uv, uv)- 0.25);

    // Output to screen
    vec4 col = Face(uv, m, t);
    glFragColor = vec4(col);
}
