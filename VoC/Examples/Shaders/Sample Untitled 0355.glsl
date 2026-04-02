#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rotate(float a) 
{
    float c = cos(a),
    s = sin(a);
    return mat2(c, -s, s, c);
}

void main() {
    vec2 uv = 1.2*(2. * gl_FragCoord.xy - resolution) / resolution.y;
    vec3 color = vec3(0);
    uv.y+=0.0;
    vec3 rd = vec3(uv, mouse.y *2.0);
        
    float s = .5;
    for (int i = 0; i < 8; i++) {
        rd = abs(rd) / dot(rd, rd); // kali iteration!! Thanks Kali
        rd -= s;
        rd.xy *= rotate(0.1 + time *0.110);
        rd.xz *= rotate(0.2 - time *0.123);
        rd.zy *= rotate(0.3 + time *0.131);
        s *= -mouse.x;
        float b = 0.005;
        float ax = abs(rd.x);
        float ay = abs(rd.y);
        float az = abs(rd.z);
        //color.gb += .014 / max(abs(rd.x*0.8), abs(rd.y*0.8));
        color.gb +=  length(vec2(ax, ay))*0.08/max(ax*0.2, 6.2*ay);
        //color.rb += .015 / max(abs(rd.y*0.6), abs(rd.z*0.6));
        color.rb +=  length(vec2(ay, az))*0.09/max(ay*0.2, 6.2*az);
        //color.rg += .010 / max(abs(rd.x*0.7), abs(rd.z*0.9));
        color.rg +=  length(vec2(ax, az))*0.07/max(ax*0.2, 6.2*az);
    }
    color *= 0.6;
    glFragColor = vec4(color, 1.);
}
