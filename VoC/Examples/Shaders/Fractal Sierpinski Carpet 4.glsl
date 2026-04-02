#version 420

// original https://www.shadertoy.com/view/MtcBRn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 pos = gl_FragCoord.xy - resolution.xy / 2.0;
    vec2 offset = vec2(-0.5);
    
    float col = 0.0;
    float t = time / 1.5;
    
    float scale = pow(3.0, mod(t, 2.0) + 1.0);
    float size = resolution.y * scale;
    float rot = t / 2.0;

    pos = mat2(cos(-rot), sin(-rot), -sin(-rot), cos(-rot)) * pos;
    pos += offset * resolution.y * (scale * 0.5 - 0.5);

    while(size > 1.0) {
        size /= 3.0;
        ivec2 ip = ivec2(round(pos / size));

        if(ip.x == 0 && ip.y == 0) {
            col = min(size*size, 1.0);
            break;
        } else {
            pos -= vec2(ip) * size;
        }
    }

    // Output to screen
    glFragColor = vec4(col, col, col, 1.0);
}
