#version 420

// original https://www.shadertoy.com/view/3t3GDB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sun(vec2 uv, float battery)
{
     float val = smoothstep(0.3, 0.29, length(uv));
     float bloom = smoothstep(0.7, 0.0, length(uv));
    float cut = 3.0 * sin((uv.y + time * 0.2 * (battery + 0.02)) * 100.0) 
                + clamp(uv.y * 14.0 + 1.0, -6.0, 6.0);
    cut = clamp(cut, 0.0, 1.0);
    return clamp(val * cut, 0.0, 1.0) + bloom * 0.6;
}

float grid(vec2 uv, float battery)
{
    vec2 size = vec2(uv.y, uv.y * uv.y * 0.2) * 0.01;
    uv += vec2(0.0, time * 4.0 * (battery + 0.05));
    uv = abs(fract(uv) - 0.5);
     vec2 lines = smoothstep(size, vec2(0.0), uv);
     lines += smoothstep(size * 5.0, vec2(0.0), uv) * 0.4 * battery;
    return clamp(lines.x + lines.y, 0.0, 3.0);
}

void main(void)
{
    vec2 uv = (2.0 * gl_FragCoord.xy - resolution.xy)/resolution.y;
    float battery = 1.0;
    //if (mouse*resolution.xy.x > 1.0 && mouse*resolution.xy.y > 1.0) battery = mouse*resolution.xy.y / resolution.y;
    //else battery = 0.8;
    
    
    if (abs(uv.x) < (9.0 / 16.0))
    {
        float fog = smoothstep(0.1, -0.02, abs(uv.y + 0.2));
        vec3 col = vec3(0.0, 0.1, 0.2);
        if (uv.y < -0.2)
        {
            uv.y = 3.0 / (abs(uv.y + 0.2) + 0.05);
            uv.x *= uv.y * 1.0;
            float gridVal = grid(uv, battery);
            col = mix(col, vec3(1.0, 0.5, 1.0), gridVal);
        }
        else
        {
            uv.y -= battery * 1.1 - 0.51;
            col = vec3(1.0, 0.2, 1.0);
             float sunVal = sun(uv, battery);
            col = mix(col, vec3(1.0, 0.4, 0.1), uv.y * 2.0 + 0.2);
            col = mix(vec3(0.0, 0.0, 0.0), col, sunVal);
            col += vec3(0.0, 0.1, 0.2);
        }

        col += fog * fog * fog;
        col = mix(vec3(col.r, col.r, col.r) * 0.5, col, battery * 0.7);

        glFragColor = vec4(col,1.0);
    }
    else glFragColor = vec4(0.0);

    
}
